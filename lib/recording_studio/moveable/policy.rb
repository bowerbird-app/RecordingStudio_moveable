# frozen_string_literal: true

module RecordingStudio
  module Moveable
    class Policy
      attr_reader :actor, :source, :impersonator, :metadata

      def initialize(actor:, source:, impersonator: nil, metadata: {})
        @actor = actor
        @source = source
        @impersonator = impersonator
        @metadata = metadata
      end

      def source_visible?
        source_editable?
      end

      def source_editable?
        return custom_allowed?(destination: source) unless built_in_access?

        editable_recording?(source)
      end

      def destination_visible?(destination:)
        destination_selectable?(destination: destination)
      end

      def destination_selectable?(destination:)
        return custom_allowed?(destination: destination) unless built_in_access?

        source_editable? && editable_recording?(destination)
      end

      def filter_visible_destinations(destinations:)
        Array(destinations).select do |destination|
          destination_visible?(destination: destination)
        end
      end

      def authorize_move!(destination:)
        return built_in_move_allowed!(destination: destination) if built_in_access?

        return true if custom_allowed?(destination: destination)

        raise RecordingStudio::AccessDenied, "Move authorization hook denied this move"
      end

      private

      def built_in_move_allowed!(destination:)
        assert_edit_access!(
          recording: source,
          message: "Actor does not have edit access on the source recording"
        )
        assert_edit_access!(
          recording: destination,
          message: "Actor does not have edit access on the target recording"
        )
      end

      def assert_edit_access!(recording:, message:)
        return if editable_recording?(recording)

        raise RecordingStudio::AccessDenied, message
      end

      def editable_recording?(recording)
        ensure_access_check_available!
        RecordingStudio::Services::AccessCheck.allowed?(actor: actor, recording: recording, role: :edit)
      end

      def built_in_access?
        RecordingStudio::Moveable.configuration.use_builtin_access
      end

      def custom_allowed?(destination:)
        RecordingStudio::Moveable.configuration.authorize_move?(
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        )
      end

      def ensure_access_check_available!
        return if defined?(RecordingStudio::Services::AccessCheck)

        require "recording_studio_accessible"
      rescue LoadError => e
        raise LoadError, <<~MESSAGE.squish
          RecordingStudio Moveable built-in authorization requires the recording_studio_accessible gem.
          Add `gem "recording_studio_accessible"` to your Gemfile or set
          `RecordingStudio::Moveable.configure { |config| config.use_builtin_access = false }`.
          Original error: #{e.message}
        MESSAGE
      end
    end
  end
end
