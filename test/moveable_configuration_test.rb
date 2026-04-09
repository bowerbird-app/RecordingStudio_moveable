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

  def test_default_redirect_mode_defaults_to_previous_page
    assert_equal "previous_page", RecordingStudio::Moveable.configuration.default_redirect_mode
  end

  def test_custom_redirect_resolver_falls_back_when_blank
    RecordingStudio::Moveable.configure do |config|
      config.redirect_resolver = ->(**) {}
    end

    resolved = RecordingStudio::Moveable.configuration.resolve_redirect(
      recording: :recording,
      helpers: :helpers,
      fallback: "/fallback",
      mode: "moved_record"
    )

    assert_equal "/fallback", resolved
  end

  def test_custom_redirect_resolver_receives_context
    received = nil

    RecordingStudio::Moveable.configure do |config|
      config.redirect_resolver = lambda do |recording:, helpers:, fallback:, mode:|
        received = { recording: recording, helpers: helpers, fallback: fallback, mode: mode }
        "/custom-destination"
      end
    end

    resolved = RecordingStudio::Moveable.configuration.resolve_redirect(
      recording: :recording,
      helpers: :helpers,
      fallback: "/fallback",
      mode: "destination"
    )

    assert_equal "/custom-destination", resolved
    assert_equal({
                   recording: :recording,
                   helpers: :helpers,
                   fallback: "/fallback",
                   mode: "destination"
                 }, received)
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
