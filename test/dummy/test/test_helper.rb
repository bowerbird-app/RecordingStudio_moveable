# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../../dummy/config/environment"
require "rails/test_help"

module DummyMoveableTestHelpers
  def create_workspace_root
    workspace = Workspace.create!(name: "Workspace #{SecureRandom.hex(4)}")
    root = RecordingStudio::Recording.create!(recordable: workspace)
    [workspace, root]
  end

  def create_user(email: "user-#{SecureRandom.hex(4)}@example.com")
    User.create!(email: email, password: "Password", password_confirmation: "Password")
  end

  def grant_root_access(root:, actor:, role: :admin)
    root.record(RecordingStudio::Access, actor: actor, parent_recording: root) do |access|
      access.actor = actor
      access.role = role
    end
  end
end

class ActiveSupport::TestCase
  parallelize(workers: 1)
  include DummyMoveableTestHelpers

  setup do
    RecordingStudio::Event.delete_all
    RecordingStudio::DeviceSession.delete_all
    RecordingStudio::Recording.delete_all
    RecordingStudio::Access.delete_all
    RecordingStudioFolder.delete_all
    RecordingStudioPage.delete_all
    RecordingStudioArchiveBox.delete_all
    Workspace.delete_all
    User.delete_all
    RecordingStudio::Moveable.reset_configuration!
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include DummyMoveableTestHelpers
end
