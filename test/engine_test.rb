# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioMoveable.instance_variable_get(:@configuration)
    RecordingStudioMoveable.instance_variable_set(:@configuration, RecordingStudioMoveable::Configuration.new)
  end

  def teardown
    RecordingStudioMoveable.configuration.hooks.clear!
    RecordingStudioMoveable.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioMoveable.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioMoveable.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_moveable.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_moveable.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioMoveable.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_moveable).new({ enable_feature_x: true })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { api_key: "from_yaml", timeout: 12 }
      end
    end.new(app_config)

    find_initializer("recording_studio_moveable.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioMoveable.configuration, hook_payload
    assert_equal "from_yaml", RecordingStudioMoveable.configuration.api_key
    assert_equal 12, RecordingStudioMoveable.configuration.timeout
    assert_equal true, RecordingStudioMoveable.configuration.enable_feature_x
  end

  def test_load_config_handles_errors_and_each_pair_fallback
    pair_config = Class.new do
      def each_pair
        yield(:timeout, 15)
      end
    end.new

    xcfg = Struct.new(:recording_studio_moveable).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)

    app = Struct.new(:config) do
      def config_for(_name)
        raise "missing file"
      end
    end.new(app_config)

    find_initializer("recording_studio_moveable.load_config").block.call(app)

    assert_equal 15, RecordingStudioMoveable.configuration.timeout
  end

  def test_load_config_swallow_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    xcfg = Struct.new(:recording_studio_moveable).new(bad_pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { api_key: "ok" }
      end
    end.new(app_config)

    # Should not raise even if xcfg.each_pair fails.
    find_initializer("recording_studio_moveable.load_config").block.call(app)

    assert_equal "ok", RecordingStudioMoveable.configuration.api_key
  end

  def test_apply_extension_initializers_register_active_support_on_load_callbacks
    events = []
    on_load_stub = proc do |event, &block|
      events << event
      block&.call
    end

    ActiveSupport.stub(:on_load, on_load_stub) do
      find_initializer("recording_studio_moveable.apply_model_extensions").block.call
      find_initializer("recording_studio_moveable.apply_controller_extensions").block.call
    end

    assert_includes events, :active_record
    assert_includes events, :action_controller
  end

  private

  def find_initializer(name)
    RecordingStudioMoveable::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
