# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../../dummy/config/environment"
require "rails/test_help"

module DummyMoveableTestHelpers
  def restore_dummy_moveable_capabilities!
    [ RecordingStudioFolder, RecordingStudioPage ].each do |recordable_type|
      RecordingStudio.set_capability_options(
        :movable,
        on: recordable_type.name,
        allowed_parent_types: [ "Workspace", "RecordingStudioFolder" ],
        allow_cross_root: true
      )
    end
  end

  def create_workspace_root
    workspace = Workspace.create!(name: "Workspace #{SecureRandom.hex(4)}")
    root = RecordingStudio::Recording.create!(recordable: workspace)
    [ workspace, root ]
  end

  def create_user(email: "user-#{SecureRandom.hex(4)}@example.com")
    User.create!(email: email, password: "Password", password_confirmation: "Password")
  end

  def bootstrap_demo_for(actor)
    MoveableDemo::Bootstrap.call(actor: actor)
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
    restore_dummy_moveable_capabilities!
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include DummyMoveableTestHelpers

  setup do
    restore_dummy_moveable_capabilities!
  end
end
