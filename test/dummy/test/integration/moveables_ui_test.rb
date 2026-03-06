# frozen_string_literal: true

require_relative "../test_helper"

class MoveablesUiTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "ui@example.com")
    sign_in @user

    _, @root = create_workspace_root
    grant_root_access(root: @root, actor: @user, role: :admin)

    @source_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |f| f.name = "Source" }
    @target_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |f| f.name = "Target" }
    @page = @root.record(RecordingStudioPage, actor: @user, parent_recording: @source_folder) { |p| p.title = "Move Me" }
    @archive = @root.record(RecordingStudioArchiveBox, actor: @user, parent_recording: @root) { |a| a.name = "Archive" }
  end

  def test_full_page_and_modal_render
    get recording_studio_moveable.move_recording_path(recording_id: @page.id)
    assert_response :success
    assert_includes response.body, "Move Recording Studio Page to…"

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, display: "modal")
    assert_response :success
    assert_includes response.body, "Choose a destination"
  end

  def test_destination_filtering_shows_only_allowed_destinations
    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, @target_folder.recordable.name
    refute_includes response.body, @archive.recordable.name
  end

  def test_move_action_redirects_to_root_with_flash
    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: { destination_id: @target_folder.id }

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Moved successfully"
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end
end
