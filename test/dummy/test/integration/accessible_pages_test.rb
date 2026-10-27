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
      "/recording_studio_accessible/email_template"
    ].each do |path|
      get path
      assert_response :success, "expected #{path} to load successfully"
    end
  end

  def test_accessible_manage_pages_are_blocked_on_flatpack_0_1_319
    skip <<~MESSAGE.squish
      RecordingStudio Accessible v0.18.0 still passes style: to FlatPack::Card::Component
      and anchor_href: to FlatPack::PageNav::Component in user_invites.html.erb,
      recording_accesses/index.html.erb, and recording_accesses/_form.html.erb.
      FlatPack 0.1.319 raises ArgumentError for both. v0.21.0 and main
      (98e68a45296e052df373466cca6a5d3431c7f9bf) still pass style: :default to Card
      in user_invites.html.erb, so no newer tag renders these pages.
    MESSAGE
  end
end
