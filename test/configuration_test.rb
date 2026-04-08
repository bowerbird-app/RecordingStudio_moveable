# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioMoveable::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(
      api_key: "abc123",
      timeout: 9,
      enable_feature_x: true,
      move_modal_prefetch_enabled: false,
      move_modal_prefetch_delay_ms: 150,
      move_modal_prefetch_ttl_ms: 20_000,
      move_modal_reuse_shell: false
    )

    assert_equal "abc123", @configuration.api_key
    assert_equal 9, @configuration.timeout
    assert_equal true, @configuration.enable_feature_x
    assert_equal false, @configuration.move_modal_prefetch_enabled
    assert_equal 150, @configuration.move_modal_prefetch_delay_ms
    assert_equal 20_000, @configuration.move_modal_prefetch_ttl_ms
    assert_equal false, @configuration.move_modal_reuse_shell
  end

  def test_merge_ignores_unknown_keys
    updates = { unknown_key: "ignored", timeout: 7 }
    @configuration.merge!(updates)

    assert_equal false, @configuration.respond_to?(:unknown_key)
    assert_equal 7, @configuration.timeout
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_nil @configuration.api_key if original[:api_key].nil?
    assert_equal original[:api_key], @configuration.api_key unless original[:api_key].nil?
    assert_equal original[:timeout], @configuration.timeout
    assert_equal original[:enable_feature_x], @configuration.enable_feature_x
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_move_modal_configuration_defaults
    assert_equal true, @configuration.move_modal_prefetch_enabled
    assert_equal 80, @configuration.move_modal_prefetch_delay_ms
    assert_equal 10_000, @configuration.move_modal_prefetch_ttl_ms
    assert_equal true, @configuration.move_modal_reuse_shell
  end

  def test_configure_without_block_is_safe
    RecordingStudioMoveable.configure

    assert_kind_of RecordingStudioMoveable::Configuration, RecordingStudioMoveable.configuration
  end
end
