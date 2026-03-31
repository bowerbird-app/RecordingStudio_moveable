# frozen_string_literal: true

require "recording_studio/moveable/configuration"
require "recording_studio/moveable/authorization"
require "recording_studio/moveable/destination_search"
require "recording_studio/moveable/capabilities/moveable"

module RecordingStudio
  module Moveable
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration) if block_given?
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end

  Movable = Moveable unless const_defined?(:Movable)
end
