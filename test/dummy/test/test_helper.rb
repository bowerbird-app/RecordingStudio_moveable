# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../../dummy/config/environment"
require "rails/test_help"

module DummyMoveableTestHelpers
  def compatible_access_model
    return RecordingStudioAccessible::Access if defined?(RecordingStudioAccessible::Access)
    return RecordingStudio.const_get(:Access) if defined?(RecordingStudio) && RecordingStudio.const_defined?(:Access)

    nil
  end

  def restore_dummy_moveable_capabilities!
    [ RecordingStudioFolder, RecordingStudioPage ].each do |recordable_type|
      RecordingStudio.set_capability_options(
        :movable,
        on: recordable_type.name,
        allow_cross_root: true
      )
    end
  end

  def create_workspace_root
    workspace = Workspace.create!(name: "Workspace #{SecureRandom.hex(4)}")
    root = RecordingStudio.root_recording_for(workspace)
    [ workspace, root ]
  end

  def create_user(email: "user-#{SecureRandom.hex(4)}@example.com")
    User.create!(email: email, password: "Password", password_confirmation: "Password")
  end

  def bootstrap_demo_for(actor)
    MoveableDemo::Bootstrap.call(actor: actor)
  end

  def grant_root_access(root:, actor:, role: :admin)
    RecordingStudioAccessible.grant_access(
      recording: root,
      actor: actor,
      role: role,
      manager_actor: actor
    ).value!
  end
end

class ActiveSupport::TestCase
  parallelize(workers: 1)
  include DummyMoveableTestHelpers

  setup do
    RecordingStudio::Event.delete_all
    RecordingStudio::DeviceSession.delete_all if defined?(RecordingStudio::DeviceSession)
    RecordingStudio::Recording.delete_all
    compatible_access_model&.delete_all
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
