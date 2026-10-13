# frozen_string_literal: true

require_relative "../test_helper"

# Always-loaded host override under test/dummy/config/locales proves gem English
# loses to a host file on the real Rails boot load path. The key is rarely shown
# (disallowed-destination flash only) so default move chrome stays gem English.
class BootOrderHostOverrideTest < ActionDispatch::IntegrationTest
  HOST_FILE = File.expand_path(
    "../../config/locales/recording_studio_moveable_host.en.yml",
    __dir__
  ).freeze

  def setup
    super

    @user = create_user(email: "boot-order-host@example.com")
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
    ) { |page| page.title = "Boot Order Page" }
  end

  def test_always_loaded_host_override_wins_on_disallowed_destination_flash
    assert File.exist?(HOST_FILE), "expected always-loaded host override at #{HOST_FILE}"
    assert_includes File.expand_path(HOST_FILE), "/config/locales/"

    assert_equal "HOST Destination is not allowed for this move",
                 I18n.t("recording_studio.moveable.errors.destination_not_allowed"),
                 "boot-loaded host override must win for the rarely shown key"

    get recording_studio_moveable.move_recording_path(recording_id: @page.id)

    assert_response :success
    assert_includes response.body, "Choose destination"
    assert_includes response.body, "Search destinations"
    refute_includes response.body, "HOST Destination is not allowed for this move"

    post recording_studio_moveable.move_recording_path(recording_id: @page.id), params: {
      destination_id: @page.id
    }

    assert_response :redirect
    assert_equal "HOST Destination is not allowed for this move", flash[:alert]
    follow_redirect!
    assert_includes response.body, "HOST Destination is not allowed for this move"
    refute_includes response.body, ">Destination is not allowed for this move<"
  end
end
