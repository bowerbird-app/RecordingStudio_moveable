# frozen_string_literal: true

require "test_helper"

class MoveableConfigurationTest < Minitest::Test
  def setup
    RecordingStudio::Moveable.reset_configuration!
  end

  def teardown
    RecordingStudio::Moveable.reset_configuration!
  end

  def test_default_configuration_uses_builtin_access
    assert RecordingStudio::Moveable.configuration.use_builtin_access
  end

  def test_custom_authorization_hook_is_invoked
    called = false
    RecordingStudio::Moveable.configure do |config|
      config.use_builtin_access = false
      config.authorization_hook = lambda do |actor:, source:, destination:, **|
        called = true
        actor == :actor && source == :source && destination == :destination
      end
    end

    assert RecordingStudio::Moveable.configuration.authorize_move?(
      actor: :actor,
      source: :source,
      destination: :destination,
      metadata: {}
    )
    assert called
  end
end
