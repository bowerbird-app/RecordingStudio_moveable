# frozen_string_literal: true

require_relative "../test_helper"

class AccessiblePagesTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "accessible-pages@example.com")
    @root = bootstrap_demo_for(@user)
    sign_in @user
    @access_recording = RecordingStudioAccessible.access_recordings_for(@root).first
  end

  def test_accessible_engine_pages_render_successfully
    [
      "/recording_studio_accessible",
      "/recording_studio_accessible/overview",
      "/recording_studio_accessible/methods",
      "/recording_studio_accessible/user_invites",
      "/recording_studio_accessible/email_template",
      "/recording_studio_accessible/recordings/#{@root.id}/accesses",
      "/recording_studio_accessible/recordings/#{@root.id}/accesses/new",
      "/recording_studio_accessible/recordings/#{@root.id}/accesses/#{@access_recording.id}/edit"
    ].each do |path|
      get path
      assert_response :success, "expected #{path} to load successfully"
    end
  end
end
