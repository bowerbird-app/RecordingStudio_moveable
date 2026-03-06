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
    assert_includes response.body, "Move Move Me to..."
    assert_includes response.body, "Choose a destination for Move Me"
    assert_includes response.body, "aria-label=\"Breadcrumb\""
    assert_includes response.body, "Back"
    assert_includes response.body, %(href="/")
    assert_includes response.body, "#icon-chevron-left"
    assert_includes response.body, "Main navigation"
    assert_includes response.body, "Toggle sidebar"
    assert_includes response.body, "Search destinations"
    assert_includes response.body, %(class="mt-4 max-w-3xl")
    refute_includes response.body, "container mx-auto max-w-6xl px-4 pb-10 pt-6"
    refute_includes response.body, "Move item"
    refute_includes response.body, "Current location"
    refute_includes response.body, "What happens next"
    refute_includes response.body, "Search + choose"
    refute_includes response.body, "5 allowed destinations"

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, display: "modal")
    assert_response :success
    assert_includes response.body, "Choose a destination for Move Me"
    refute_includes response.body, "aria-label=\"Breadcrumb\""
    assert_includes response.body, %(class="mt-4 max-w-3xl")
    refute_includes response.body, "Main navigation"
  end

  def test_full_page_move_defaults_redirect_to_previous_page
    referer = recording_studio_folder_path(@source_folder.recordable)

    get recording_studio_moveable.move_recording_path(recording_id: @page.id), headers: { "HTTP_REFERER" => referer }

    assert_response :success
    assert_includes response.body, %(href="#{referer}")
    assert_includes response.body, %(name="redirect_to")
    assert_includes response.body, %(value="#{referer}")

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      redirect_to: referer
    }

    assert_redirected_to referer
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_modal_move_defaults_redirect_to_previous_page
    referer = recording_studio_page_path(@page.recordable)

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, display: "modal"), headers: { "HTTP_REFERER" => referer }

    assert_response :success
    assert_includes response.body, %(name="redirect_to")
    assert_includes response.body, %(value="#{referer}")

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      display: "modal",
      redirect_to: referer
    }

    assert_redirected_to referer
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_destination_filtering_shows_only_allowed_destinations
    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, %(action="/recording_studio_moveable/move/#{@page.id}")
    assert_includes response.body, %(name="destination_id")
    assert_includes response.body, %(value="#{@target_folder.id}")
    assert_includes response.body, %(type="submit")
    refute_includes response.body, %(data-turbo-method="post")
    refute_includes response.body, "/recording_studio_moveable/cable"
    assert_includes response.body, @target_folder.recordable.name
    refute_includes response.body, @archive.recordable.name
  end

  def test_client_feedback_page_uses_shared_move_view
    client_feedback = @root.record(RecordingStudioPage, actor: @user, parent_recording: @source_folder) do |page|
      page.title = "Client Feedback"
    end

    get recording_studio_moveable.move_recording_path(recording_id: client_feedback.id)

    assert_response :success
    assert_includes response.body, "Search destinations"
    refute_includes response.body, "Move item"
    refute_includes response.body, "What happens next"
    refute_includes response.body, "Current location"
  end

  def test_move_action_redirects_to_root_with_flash_when_no_previous_page_is_available
    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: { destination_id: @target_folder.id }

    assert_redirected_to "/"
    follow_redirect!
    assert_includes response.body, "Moved successfully"
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_move_action_rejects_external_redirect_to_and_falls_back
    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      redirect_to: "https://example.com/phish"
    }

    assert_redirected_to "/"
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end
end
