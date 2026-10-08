# frozen_string_literal: true

require_relative "../test_helper"

class CustomerI18nTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "i18n@example.com")
    sign_in @user

    @workspace, @root = create_workspace_root
    grant_root_access(root: @root, actor: @user, role: :admin)
    @other_workspace, @other_root = create_workspace_root
    grant_root_access(root: @other_root, actor: @user, role: :admin)

    @source_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |folder| folder.name = "Source" }
    @target_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |folder| folder.name = "Target" }
    @page = @root.record(RecordingStudioPage, actor: @user, parent_recording: @source_folder) { |page| page.title = "Move Me" }
  end

  def test_language_selector_sits_in_the_dummy_top_nav_left_of_the_workspace_switcher
    get root_path

    assert_response :success
    assert_select "form[action='/recording_studio_internationalization/locale']"
    assert_includes response.body, "English"
    assert_includes response.body, "Français"
    assert_select "html[lang='en']"
    header = response.body[/<header[\s\S]*?<\/header>/].to_s
    language_at = header.index("dummy-language-selector")
    switcher_at = header.index("workspace-switcher")
    assert language_at, "expected a language selector in the top nav"
    assert switcher_at, "expected a workspace switcher in the top nav"
    assert language_at < switcher_at, "language selector should sit left of the workspace switcher"
  end

  def test_move_dialog_stays_english_by_default
    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Move Move Me"
    assert_includes response.body, "Choose destination"
    assert_includes response.body, "Search destinations"
    assert_includes response.body, ">Change<"
    assert_includes response.body, "Move Me"
    refute_includes response.body, "Choisir une destination"
  end

  def test_move_dialog_and_flash_switch_to_french
    switch_to_french

    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Déplacer Move Me"
    assert_includes response.body, "Choisir une destination"
    assert_includes response.body, "Rechercher une destination"
    assert_includes response.body, ">Changer<"
    assert_includes response.body, "Move Me"
    refute_includes response.body, "Choose destination"
    refute_includes response.body, "Search destinations"

    get recording_studio_moveable.move_recording_modal_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Déplacer Move Me"
    assert_includes response.body, "Choisir une destination"
    assert_includes response.body, "data-recording-studio-moveable-updating="
    assert_includes response.body, "Mise à jour des destinations"
    assert_includes response.body, "Move Me"

    get recording_studio_moveable.move_recording_workspaces_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Changer : espace"
    assert_includes response.body, "Rechercher des espaces"
    refute_includes response.body, "Change workspace"
    assert_includes response.body, @other_workspace.name

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id
    }

    assert_equal "Déplacé.", flash[:notice]
    follow_redirect!
    assert_includes response.body, "Déplacé."
    refute_includes response.body, "Moved successfully"
    assert_equal @target_folder.id, @page.reload.parent_recording_id
  end

  def test_legacy_notice_override_still_wins_in_french
    I18n.backend.store_translations(:fr, {
      recording_studio_moveable: { moveables: { update: { notice: "Host moved it." } } }
    })
    switch_to_french

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @target_folder.id
    }

    assert_equal "Host moved it.", flash[:notice]
  ensure
    I18n.backend.store_translations(:fr, {
      recording_studio_moveable: { moveables: { update: { notice: nil } } }
    })
  end

  def test_root_label_helper_override_still_wins_over_french
    ApplicationHelper.class_eval do
      def recording_studio_moveable_root_label(count: 1)
        count.to_i == 1 ? "space" : "spaces"
      end
    end
    switch_to_french

    get recording_studio_moveable.move_recording_workspaces_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Changer : space"
    assert_includes response.body, "Rechercher des spaces"
    refute_includes response.body, "Changer : espace"
  ensure
    ApplicationHelper.class_eval do
      remove_method :recording_studio_moveable_root_label if method_defined?(:recording_studio_moveable_root_label)
    end
  end

  private

  def switch_to_french
    patch "/recording_studio_internationalization/locale", params: { locale: "fr", return_to: "/" }
    follow_redirect!
  end
end
