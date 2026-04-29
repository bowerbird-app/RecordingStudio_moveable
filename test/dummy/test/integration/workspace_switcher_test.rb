# frozen_string_literal: true

require_relative "../test_helper"

class WorkspaceSwitcherTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "switcher@example.com")
    bootstrap_demo_for(@user)
    sign_in @user
  end

  def test_top_nav_shows_workspace_switcher_for_accessible_roots
    get root_path

    assert_response :success
    assert_includes response.body, 'id="workspace-switcher"'
    assert_includes response.body, "Studio Workspace"
    assert_includes response.body, "Client Workspace"
    refute_includes response.body, "Restricted Workspace"
  end

  def test_top_nav_uses_accessible_public_authorization_api_for_workspace_roots
    accessible_root_ids = Workspace.where(name: [ "Studio Workspace", "Client Workspace" ]).map do |workspace|
      RecordingStudio::Recording.find_by!(recordable: workspace, parent_recording_id: nil).id
    end
    calls = []

    authorized = lambda do |actor:, recording:, role:|
      calls << { actor: actor, recording: recording, role: role }
      accessible_root_ids.include?(recording.id)
    end

    accessible_singleton = RecordingStudioAccessible.singleton_class
    original_method = accessible_singleton.instance_method(:authorized?)

    accessible_singleton.define_method(:authorized?, authorized)

    begin
      get root_path
    ensure
      accessible_singleton.define_method(:authorized?, original_method)
    end

    assert_response :success
    assert_equal [ @user ], calls.map { |call| call[:actor] }.uniq
    assert_equal [ :view ], calls.map { |call| call[:role] }.uniq
    assert_equal(
      [ "Client Workspace", "Restricted Workspace", "Studio Workspace" ],
      calls.map { |call| call[:recording].recordable.name }.sort
    )
    assert_includes response.body, "Studio Workspace"
    assert_includes response.body, "Client Workspace"
    refute_includes response.body, "Restricted Workspace"
  end

  def test_switcher_changes_the_active_workspace
    get root_path

    target_root = RecordingStudio::Recording.find_by!(recordable: Workspace.find_by!(name: "Client Workspace"), parent_recording_id: nil)

    patch workspace_selection_path, params: { root_recording_id: target_root.id, return_to: root_path }

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Client Workspace"
    assert_includes response.body, "Incoming"
    refute_includes response.body, "Songwriting"
  end

  def test_switcher_rejects_inaccessible_workspace_selection
    get root_path

    restricted_root = RecordingStudio::Recording.find_by!(recordable: Workspace.find_by!(name: "Restricted Workspace"), parent_recording_id: nil)

    patch workspace_selection_path, params: { root_recording_id: restricted_root.id, return_to: root_path }

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Workspace is not available"
    assert_includes response.body, "Studio Workspace"
    refute_includes response.body, "Restricted Workspace"
  end
end
