# frozen_string_literal: true

require_relative "../test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = create_user(email: "admin@admin.com")
    bootstrap_demo_for(@user)
  end

  def test_user_can_sign_in_with_valid_credentials
    get new_user_session_path

    assert_response :success

    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "Password"
      }
    }

    assert_redirected_to root_path

    follow_redirect!

    assert_response :success
    assert_includes response.body, "Studio Workspace"
    refute_includes response.body, "Log in"
  end
end
