# frozen_string_literal: true

require_relative "../test_helper"

class SidebarIndexesTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "sidebar@example.com")
    bootstrap_demo_for(@user)
    sign_in @user
  end

  def test_sidebar_links_render_remaining_navigation
    get root_path

    assert_response :success
    assert_not_includes response.body, "Recordings"
    assert_not_includes response.body, "Folder Recordables"
    assert_not_includes response.body, "Pages Recordables"
    assert_includes response.body, "Events"
    assert_includes response.body, "Data"
    assert_not_includes response.body, "Moveable Docs"
    assert_includes response.body, "Destinations"
    assert_includes response.body, "Setup"
    assert_includes response.body, "Methods"
    assert_includes response.body, "Redirects"

    get events_path
    assert_response :success
    assert_includes response.body, "Events"
    assert_includes response.body, "created"

    get data_path
    assert_response :success
    assert_includes response.body, "Data"
    assert_includes response.body, "Workspaces"
    assert_includes response.body, "Access"
    assert_includes response.body, "Folders"
    assert_includes response.body, "Parent"
    assert_includes response.body, "Pages"
    assert_includes response.body, "Mix Prep"
    assert_includes response.body, "Users"
    assert_includes response.body, "Archive Boxes"
    assert_includes response.body, "Studio Workspace"
    assert_includes response.body, "Client Workspace"
    assert_includes response.body, "Restricted Workspace"
    assert_includes response.body, "Songwriting"
    assert_includes response.body, "Lyric Draft"
    assert_includes response.body, "sidebar@example.com"
    assert_includes response.body, "No users"
    assert_includes response.body, "Archive Box A"

    get access_docs_path
    assert_response :success
    assert_includes response.body, "Destinations"
    assert_includes response.body, "Where something can be moved in your app"
    assert_includes response.body, "RecordingStudio::Capabilities::Moveable.enabled"
    assert_includes response.body, "allow_cross_root: true"
    assert_includes response.body, "Same root by default"
    assert_includes response.body, "No self or descendants"

    get setup_docs_path
    assert_response :success
    assert_includes response.body, "Setup"
    assert_includes response.body, "How to mark a recordable model as moveable in your app"
    assert_includes response.body, "include RecordingStudio::Capabilities::Moveable.enabled"
    assert_includes response.body, "class RecordingStudioPage &lt; ApplicationRecord"
    assert_includes response.body, "class RecordingStudioFolder &lt; ApplicationRecord"

    get methods_docs_path
    assert_response :success
    assert_includes response.body, "Methods"
    assert_includes response.body, "Reference links and helper methods you can use to launch and support the move flow"
    assert_includes response.body, "recording_studio_moveable.move_recording_path(recording_id: recording.id)"
    assert_includes response.body, "recording_studio_moveable_modal_template"
    assert_includes response.body, "move_recording_modal_path"
    assert_includes response.body, "link_to &quot;Move&quot;, recording_studio_moveable.move_recording_path(recording_id: recording.id)"

    get redirects_docs_path
    assert_response :success
    assert_includes response.body, "Redirects"
    assert_includes response.body, "How move redirects work in this demo"
    assert_includes response.body, "default_redirect_mode = :moved_record"
    assert_includes response.body, "previous_page"
    assert_includes response.body, "destination"

    get "/docs/moveable"
    assert_response :not_found
  end
end
