# frozen_string_literal: true

require_relative "../test_helper"

class MoveablesUiTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "ui@example.com")
    sign_in @user

    @workspace, @root = create_workspace_root
    grant_root_access(root: @root, actor: @user, role: :admin)
    @other_workspace, @other_root = create_workspace_root
    grant_root_access(root: @other_root, actor: @user, role: :admin)

    @source_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |f| f.name = "Source" }
    @target_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |f| f.name = "Target" }
    @other_target_folder = @other_root.record(RecordingStudioFolder, actor: @user, parent_recording: @other_root) { |f| f.name = "Shared Across Workspaces" }
    @page = @root.record(RecordingStudioPage, actor: @user, parent_recording: @source_folder) { |p| p.title = "Move Me" }
    @archive = @root.record(RecordingStudioArchiveBox, actor: @user, parent_recording: @root) { |a| a.name = "Archive" }
  end

  def test_home_page_layout_exposes_moveable_helpers
    get root_path

    assert_response :success
    assert_includes response.body, 'name="recording-studio-moveable"'
    assert_includes response.body, 'data-recording-studio-moveable-modal-root="true"'
    assert_includes response.body, 'data-recording-studio-moveable-modal-body="true"'
  end

  def test_full_page_and_modal_render
    get recording_studio_moveable.move_recording_path(recording_id: @page.id)
    assert_response :success
    root_index = response.body.index(@workspace.name)
    change_index = response.body.index(">Change<")
    picker_index = response.body.index(%(id="move-destination-picker-#{@page.id}"))

    assert_includes response.body, "Move Move Me"
    assert_includes response.body, "Choose destination"
    refute_includes response.body, "Move Move Me to..."
    refute_includes response.body, "Search or choose a destination below."
    refute_includes response.body, "Choose a destination for Move Me"
    assert_includes response.body, "aria-label=\"Page navigation\""
    refute_includes response.body, "aria-label=\"Breadcrumb\""
    assert_includes response.body, %(href="/")
    assert_includes response.body, %(data-controller="flat-pack--page-nav")
    assert_includes response.body, "Search destinations"
    assert_includes response.body, @workspace.name
    assert_includes response.body, ">Change<"
    assert_includes response.body, %(data-controller="flat-pack--picker")
    assert_includes response.body, %(id="move-destination-picker-#{@page.id}")
    assert_operator root_index, :<, change_index
    assert_operator change_index, :<, picker_index
    assert_includes response.body, "!border-0 !bg-transparent !shadow-none !rounded-none !p-0 sm:!p-0"
    refute_includes response.body, "container mx-auto max-w-6xl px-4 pb-10 pt-6"
    refute_includes response.body, "Main navigation"
    refute_includes response.body, "Toggle sidebar"
    refute_includes response.body, "Move item"
    refute_includes response.body, "Current location"
    refute_includes response.body, "What happens next"
    refute_includes response.body, "Search + choose"
    refute_includes response.body, "5 allowed destinations"
    refute_includes response.body, ">Search<"

    get recording_studio_moveable.move_recording_modal_path(recording_id: @page.id)
    assert_response :success
    assert_includes response.body, 'data-recording-studio-moveable-modal-root="true"'
    assert_includes response.body, 'data-recording-studio-moveable-modal-body="true"'
    assert_includes response.body, 'data-recording-studio-moveable-modal-element="true"'
    assert_includes response.body, "Move Move Me"
    assert_includes response.body, "Choose destination"
    refute_includes response.body, "Search or choose a destination below."
    assert_includes response.body, %(data-controller="flat-pack--picker")
    assert_includes response.body, "!border-0 !bg-transparent !shadow-none !rounded-none !p-0 sm:!p-0"
    refute_includes response.body, "Main navigation"

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, display: "modal")
    assert_response :success
    refute_includes response.body, "Choose a destination for Move Me"
    refute_includes response.body, "aria-label=\"Breadcrumb\""
    refute_includes response.body, "aria-label=\"Page navigation\""
    assert_includes response.body, %(data-controller="flat-pack--picker")
    refute_includes response.body, "Main navigation"
  end

  def test_full_page_move_defaults_redirect_to_previous_page
    referer = recording_studio_folder_path(@source_folder.recordable)

    get recording_studio_moveable.move_recording_path(recording_id: @page.id), headers: { "HTTP_REFERER" => referer }

    assert_response :success
    assert_includes response.body, %(href="#{referer}")
    assert_includes response.body, "redirect_to=#{ERB::Util.url_encode(referer)}"
    assert_includes response.body, "aria-label=\"Page navigation\""

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
    assert_includes response.body, "redirect_to=#{ERB::Util.url_encode(referer)}"
    refute_includes response.body, "aria-label=\"Page navigation\""

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      display: "modal",
      redirect_to: referer
    }

    assert_redirected_to referer
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_full_page_move_can_follow_moved_record
    expected_path = "/recording_studio_pages/#{@page.recordable.id}"

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, redirect_mode: "moved_record")

    assert_response :success
    assert_includes response.body, "redirect_mode=moved_record"

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      redirect_mode: "moved_record"
    }

    assert_redirected_to expected_path
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_full_page_move_can_follow_destination
    expected_path = "/recording_studio_folders/#{@target_folder.recordable.id}"

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, redirect_mode: "destination")

    assert_response :success
    assert_includes response.body, "redirect_mode=destination"

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      redirect_mode: "destination"
    }

    assert_redirected_to expected_path
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_default_redirect_mode_can_follow_moved_record
    RecordingStudio::Moveable.configure do |config|
      config.default_redirect_mode = :moved_record
    end

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id
    }

    assert_redirected_to "/recording_studio_pages/#{@page.recordable.id}"
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_folder_show_hides_page_level_move_buttons_and_keeps_card_actions
    get recording_studio_folder_path(@source_folder.recordable)

    assert_response :success
    refute_includes response.body, "Move folder"
    refute_includes response.body, "Move folder in modal"
    assert_includes response.body, ">Move<"
    assert_includes response.body, ">Modal<"
    assert_includes response.body, 'data-recording-studio-moveable-modal="true"'
  end

  def test_page_show_renders_page_level_move_buttons
    get recording_studio_page_path(@page.recordable)

    assert_response :success
    assert_includes response.body, "Move (full page)"
    assert_includes response.body, "Move (modal mode)"
    assert_includes response.body, 'data-recording-studio-moveable-modal="true"'
  end

  def test_destination_filtering_shows_only_allowed_destinations
    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, %(/recording_studio_moveable/move/#{@page.id}?display=full_page)
    assert_includes response.body, %(data-flat-pack--picker-form-value=)
    assert_includes response.body, %(data-flat-pack--picker-auto-confirm-value="true")
    assert_includes response.body, @target_folder.id.to_s
    assert_includes response.body, @target_folder.recordable.recordable_name
    refute_includes response.body, "Move here"
    refute_includes response.body, "Clear selection"
    refute_includes response.body, @archive.recordable.name

    workspace_index = response.body.index(@workspace.name)
    target_index = response.body.index(@target_folder.recordable.recordable_name)

    assert workspace_index.present?, "Expected workspace root to be rendered as a destination"
    assert target_index.present?, "Expected target folder to be rendered as a destination"
    assert_operator workspace_index, :<, target_index, "Expected workspace root to appear before nested destinations"
    assert_includes response.body, %(&quot;description&quot;:&quot;Folder&quot;)
    refute_includes response.body, %(&quot;description&quot;:&quot;#{@workspace.name}&quot;)
  end

  def test_destination_search_filters_allowed_destinations
    other_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |f| f.name = "Elsewhere" }

    get recording_studio_moveable.move_recording_path(recording_id: @page.id), params: { q: "Target" }

    assert_response :success
    assert_includes response.body, @target_folder.recordable.recordable_name
    refute_includes response.body, other_folder.recordable.recordable_name
    refute_includes response.body, @archive.recordable.name
  end

  def test_destination_search_finds_matches_beyond_initial_result_window
    205.times do |index|
      @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) do |folder|
        folder.name = "Filler #{index}"
      end
    end

    get recording_studio_moveable.move_recording_path(recording_id: @page.id), params: { q: "Target" }

    assert_response :success
    assert_includes response.body, @target_folder.recordable.recordable_name
  end

  def test_root_level_folder_does_not_offer_current_workspace_as_destination
    get recording_studio_moveable.move_recording_path(recording_id: @target_folder.id)

    assert_response :success
    assert_includes response.body, @workspace.name
    assert_includes response.body, @source_folder.recordable.recordable_name
    assert_equal 1, response.body.scan(@workspace.name).count
  end

  def test_workspace_picker_lists_other_workspaces_only
    get recording_studio_moveable.move_recording_workspaces_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Change workspace"
    assert_includes response.body, @other_workspace.name
    refute_includes response.body, @workspace.name
    assert_includes response.body, %(id="move-workspace-picker-#{@page.id}")
  end

  def test_workspace_picker_back_returns_to_move_view_while_move_view_keeps_launch_origin
    launch_origin = recording_studio_folder_path(@source_folder.recordable)
    workspace_path = recording_studio_moveable.move_recording_workspaces_path(
      recording_id: @page.id,
      redirect_to: launch_origin,
      redirect_mode: "previous_page"
    )
    move_path = recording_studio_moveable.move_recording_path(
      recording_id: @page.id,
      redirect_to: launch_origin,
      redirect_mode: "previous_page"
    )
    workspace_href = workspace_path.gsub("&", "&amp;")
    move_href = move_path.gsub("&", "&amp;")

    get recording_studio_moveable.move_recording_path(recording_id: @page.id), headers: { "HTTP_REFERER" => launch_origin }

    assert_response :success
    assert_includes response.body, %(href="#{launch_origin}")
    assert_includes response.body, %(href="#{workspace_href}")
    assert_includes response.body, "aria-label=\"Page navigation\""

    get workspace_path

    assert_response :success
    refute_includes response.body, %(href="#{move_href}")
    assert_includes response.body, %(href="#{launch_origin}")
    assert_includes response.body, "aria-label=\"Page navigation\""

    get move_path

    assert_response :success
    assert_includes response.body, %(href="#{launch_origin}")
  end

  def test_cross_workspace_selection_scopes_destinations_to_selected_root
    get recording_studio_moveable.move_recording_path(recording_id: @page.id, target_root_id: @other_root.id)

    assert_response :success
    assert_includes response.body, @other_workspace.name
    assert_includes response.body, ">Change<"
    assert_includes response.body, @other_target_folder.recordable.recordable_name
    refute_includes response.body, @target_folder.recordable.recordable_name
  end

  def test_cross_workspace_move_failure_preserves_selected_workspace_for_retry
    other_archive = @other_root.record(RecordingStudioArchiveBox, actor: @user, parent_recording: @other_root) do |box|
      box.name = "Cross Workspace Archive"
    end

    get recording_studio_moveable.move_recording_path(recording_id: @page.id, target_root_id: @other_root.id)

    assert_response :success
    assert_includes response.body, "target_root_id=#{@other_root.id}"

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: other_archive.id,
      target_root_id: @other_root.id,
      redirect_mode: "root"
    }

    assert_redirected_to recording_studio_moveable.move_recording_path(
      recording_id: @page.id,
      target_root_id: @other_root.id,
      redirect_mode: "root"
    )

    follow_redirect!

    assert_response :success
    assert_includes response.body, @other_workspace.name
    assert_includes response.body, @other_target_folder.recordable.recordable_name
    refute_includes response.body, @target_folder.recordable.recordable_name
  end

  def test_cross_workspace_move_updates_the_record_root
    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @other_target_folder.id,
      redirect_mode: "root"
    }

    assert_redirected_to "/"
    assert_equal @other_target_folder.id, @page.reload.parent_recording_id
    assert_equal @other_root.id, @page.root_recording_id
  end

  def test_move_screen_returns_not_found_when_actor_cannot_access_source
    sign_out @user

    outsider = create_user(email: "outsider-ui@example.com")
    sign_in outsider

    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :not_found
  end

  def test_page_show_returns_not_found_when_actor_cannot_access_page
    sign_out @user

    outsider = create_user(email: "outsider-page@example.com")
    sign_in outsider

    get recording_studio_page_path(@page.recordable)

    assert_response :not_found
  end

  def test_folder_show_returns_not_found_when_actor_cannot_access_folder
    sign_out @user

    outsider = create_user(email: "outsider-folder@example.com")
    sign_in outsider

    get recording_studio_folder_path(@source_folder.recordable)

    assert_response :not_found
  end

  def test_move_screen_uses_gem_authorization_to_hide_inaccessible_destinations
    hidden_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |f| f.name = "Hidden" }

    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = lambda do |actor:, source:, destination:, **|
        actor == @user && source == @page && [ @page, @target_folder ].include?(destination)
      end
    end

    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, @target_folder.recordable.recordable_name
    refute_includes response.body, hidden_folder.recordable.recordable_name
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

  def test_redirect_to_takes_precedence_over_redirect_mode
    referer = recording_studio_folder_path(@source_folder.recordable)

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id,
      redirect_to: referer,
      redirect_mode: "moved_record"
    }

    assert_redirected_to referer
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end
end
