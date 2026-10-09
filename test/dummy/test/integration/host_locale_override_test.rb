# frozen_string_literal: true

require_relative "../test_helper"

# Proves a host nested `recording_studio.moveable.*` override wins over gem
# English on a real page. The YAML lives outside config/locales so the default
# dummy UI keeps gem English. This test appends the fixture LAST to
# I18n.load_path, reloads, asserts, then restores the path.
class HostLocaleOverrideTest < ActionDispatch::IntegrationTest
  HOST_OVERRIDE = File.expand_path("../locales/host_override.en.yml", __dir__).freeze

  def setup
    super

    @original_load_path = I18n.load_path.dup
    @user = create_user(email: "host-locale-override@example.com")
    sign_in @user

    @workspace, @root = create_workspace_root
    grant_root_access(root: @root, actor: @user, role: :admin)
    @source_folder = @root.record(
      RecordingStudioFolder,
      actor: @user,
      parent_recording: @root
    ) { |folder| folder.name = "Source" }
    @page = @root.record(
      RecordingStudioPage,
      actor: @user,
      parent_recording: @source_folder
    ) { |page| page.title = "Override Me" }
  end

  def teardown
    restore_i18n_load_path!
    assert_equal @original_load_path, I18n.load_path,
                 "tests must not leave I18n.load_path modified"
    super
  end

  def test_host_nested_locale_override_wins_on_the_move_modal
    assert File.exist?(HOST_OVERRIDE), "expected test-only host override at #{HOST_OVERRIDE}"
    refute_includes File.expand_path(HOST_OVERRIDE), "/config/locales/"
    refute_includes File.read(HOST_OVERRIDE), "I18n.load_path"

    assert_equal "Unable to load the move view right now. Please try again.",
                 I18n.t("recording_studio.moveable.js.load_error"),
                 "default dummy UI must keep gem English before the override is loaded"

    I18n.load_path << HOST_OVERRIDE
    I18n.reload!

    assert_equal "HOST unable to load the move view.",
                 I18n.t("recording_studio.moveable.js.load_error")

    get recording_studio_moveable.move_recording_modal_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, 'data-recording-studio-moveable-load-error="HOST unable to load the move view."'
    refute_includes response.body, "Unable to load the move view right now. Please try again."
    assert_includes response.body, "Move Override Me"
    assert_includes response.body, "Choose destination"
    assert_includes response.body, "Search destinations"
  ensure
    restore_i18n_load_path!
  end

  private

  def restore_i18n_load_path!
    return unless defined?(@original_load_path) && @original_load_path

    I18n.load_path.replace(@original_load_path)
    I18n.reload!
  end
end
