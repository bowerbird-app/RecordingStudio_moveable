# frozen_string_literal: true

require_relative "../../app/helpers/recording_studio_moveable/moveables_helper"

module RecordingStudioMoveable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioMoveable

    initializer "recording_studio_moveable.view_helpers" do
      ActiveSupport.on_load(:action_view) do
        include RecordingStudioMoveable::MoveablesHelper
      end
    end

    initializer "recording_studio_moveable.assets.precompile" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    initializer "recording_studio_moveable.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
    end

    initializer "recording_studio_moveable.before_initialize",
                before: "recording_studio_moveable.load_config" do |_app|
      RecordingStudioMoveable::Hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_moveable.load_config" do |app|
      RecordingStudioMoveable::Engine.send(:load_yaml_config, app) if app.respond_to?(:config_for)

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_moveable)
        RecordingStudioMoveable::Engine.send(:load_x_config, app.config.x.recording_studio_moveable)
      end

      RecordingStudioMoveable::Hooks.run(:on_configuration, RecordingStudioMoveable.configuration)
    end

    initializer "recording_studio_moveable.after_initialize",
                after: "recording_studio_moveable.load_config" do |_app|
      RecordingStudioMoveable::Hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_moveable.apply_model_extensions" do
      ActiveSupport.on_load(:active_record) do
        RecordingStudioMoveable::Hooks.run(:active_record_loaded, self)
      end
    end

    initializer "recording_studio_moveable.apply_controller_extensions" do
      ActiveSupport.on_load(:action_controller) do
        RecordingStudioMoveable::Hooks.run(:action_controller_loaded, self)
      end
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
