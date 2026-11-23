# frozen_string_literal: true

require_relative "../../app/helpers/recording_studio_moveable/copy_helper"
require_relative "../../app/helpers/recording_studio_moveable/moveables_helper"
require_relative "mcp_copy"

module RecordingStudioMoveable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioMoveable

    initializer "recording_studio_moveable.view_helpers" do
      ActiveSupport.on_load(:action_view) do
        include RecordingStudioMoveable::CopyHelper
        include RecordingStudioMoveable::MoveablesHelper
      end
    end

    initializer "recording_studio_moveable.assets.precompile" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    initializer "recording_studio_moveable.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
    end

    initializer "recording_studio_moveable.load_config" do |app|
      RecordingStudioMoveable::Engine.send(:load_yaml_config, app) if app.respond_to?(:config_for)

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_moveable)
        RecordingStudioMoveable::Engine.send(:load_x_config, app.config.x.recording_studio_moveable)
      end
    end

    initializer "recording_studio_moveable.register_recording_studio_api_action",
                before: "recording_studio_api.after_initialize" do
      RecordingStudio::Moveable::Api.register_capability_action!
    end

    initializer "recording_studio_moveable.mcp",
                after: "recording_studio_moveable.register_recording_studio_api_action" do
      config.to_prepare { RecordingStudioMoveable::McpCopy.register! }
    end

    class << self
      private

      def load_yaml_config(app)
        yaml = app.config_for(:recording_studio_moveable)
        RecordingStudioMoveable.configuration.merge!(yaml) if yaml.respond_to?(:each)
      rescue StandardError => e
        log_configuration_load_error("config_for(:recording_studio_moveable)", e)
      end

      def load_x_config(config)
        values = if config.respond_to?(:to_h)
                   config.to_h
                 else
                   each_pair_config(config)
                 end

        RecordingStudioMoveable.configuration.merge!(values) if values.respond_to?(:any?) && values.any?
      end

      def each_pair_config(config)
        return {} unless config.respond_to?(:each_pair)

        {}.tap do |values|
          config.each_pair { |key, value| values[key] = value }
        end
      rescue StandardError => e
        log_configuration_load_error("config.x.recording_studio_moveable.each_pair", e)
        {}
      end

      def log_configuration_load_error(source, error)
        return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

        Rails.logger.debug { "[RecordingStudioMoveable] Failed to load #{source}: #{error.message}" }
      end
    end
  end
end
