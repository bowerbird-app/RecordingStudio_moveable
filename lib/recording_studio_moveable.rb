# frozen_string_literal: true

require "recording_studio_moveable/version"
require "recording_studio_moveable/configuration"
require "recording_studio_moveable/hooks"
require "recording_studio_moveable/labels"
require "recording_studio_moveable/root_label"
require "recording_studio_moveable/services/base_service"
require "recording_studio_moveable/services/example_service"
require "recording_studio"

module RecordingStudio
  AccessDenied = Class.new(StandardError) unless const_defined?(:AccessDenied)
end

begin
  require "recording_studio/labels"
rescue LoadError => e
  warn(e.message) if ENV["RECORDING_STUDIO_MOVEABLE_DEBUG"] == "true"
end
require "recording_studio/moveable"
require "recording_studio_moveable/engine"

module RecordingStudioMoveable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
