# frozen_string_literal: true

require_relative "../test_helper"

# Proves a host nested `recording_studio.moveable.*` override in
# config/locales wins over gem English on a real page. Uses js.load_error
# (modal data attribute only) so the dummy UI and other rendered tests keep
# default English for common labels. Does not touch I18n.load_path.
class HostLocaleOverrideTest < ActionDispatch::IntegrationTest
  def setup
    super

    @original_load_path = I18n.load_path.dup
    @user = create_user(email: "host-locale-override@example.com")
    sign_in @user

    @workspace, @root = create_workspace_root
    grant_root_access(root: @root, actor: @user, role: :admin)
    @source_folder = @root.record(RecordingStudioFolder, actor: @user, parent_recording: @root) { |folder| folder.name = "Source" }
    @page = @root.record(RecordingStudioPage, actor: @user, parent_recording: @source_folder) { |page| page.title = "Override Me" }
  end

  def teardown
    assert_equal @original_load_path, I18n.load_path,
                 "tests must not leave I18n.load_path modified"
    super
  end

  def test_host_nested_locale_override_wins_on_the_move_modal
    host_locale = Rails.root.join("config/locales/moveable_host_override.en.yml")
    assert File.exist?(host_locale), "expected host override file at #{host_locale}"
    refute_includes File.read(host_locale), "I18n.load_path"

    assert_equal "HOST unable to load the move view.",
                 I18n.t("recording_studio.moveable.js.load_error")

    get recording_studio_moveable.move_recording_modal_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, 'data-recording-studio-moveable-load-error="HOST unable to load the move view."'
    refute_includes response.body, "Unable to load the move view right now. Please try again."
    assert_includes response.body, "Move Override Me"
    assert_includes response.body, "Choose destination"
    assert_includes response.body, "Search destinations"
  end
end
