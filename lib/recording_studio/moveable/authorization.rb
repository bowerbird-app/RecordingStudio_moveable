# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Authorization
      module_function

      def source_visible?(actor:, source:, impersonator: nil, metadata: {})
        _ignored_impersonator = impersonator
        _ignored_metadata = metadata

        source_allowed?(actor: actor, source: source)
      end

      def source_allowed?(actor:, source:)
        return custom_allowed?(actor: actor, source: source, destination: source) unless built_in_access?

        RecordingStudio::Services::AccessCheck.allowed?(actor: actor, recording: source, role: :edit)
      end

      def destination_visible?(actor:, source:, destination:, impersonator: nil, metadata: {})
        destination_allowed?(actor: actor, source: source, destination: destination, impersonator: impersonator,
                             metadata: metadata)
      end

      def destination_allowed?(actor:, source:, destination:, impersonator: nil, metadata: {})
        unless built_in_access?
          return custom_allowed?(actor: actor, source: source, destination: destination, impersonator: impersonator,
                                 metadata: metadata)
        end

        built_in_destination_allowed?(actor: actor, source: source, destination: destination)
      end

      def built_in_destination_allowed?(actor:, source:, destination:)
        source_allowed?(actor: actor, source: source) && RecordingStudio::Services::AccessCheck.allowed?(
          actor: actor,
          recording: destination,
          role: :edit
        )
      end

      def filter_visible_destinations(actor:, source:, destinations:, impersonator: nil, metadata: {})
        Array(destinations).select do |destination|
          destination_visible?(actor: actor, source: source, destination: destination, impersonator: impersonator,
                               metadata: metadata)
        end
      end

      def assert_move_allowed!(actor:, source:, destination:, impersonator: nil, metadata: {})
        return built_in_move_allowed!(actor: actor, source: source, destination: destination) if built_in_access?

        assert_custom_move_allowed!(
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        )
      end

      def assert_custom_move_allowed!(actor:, source:, destination:, impersonator:, metadata:)
        allowed = custom_allowed?(
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        )

        return true if allowed

        raise RecordingStudio::AccessDenied, "Move authorization hook denied this move"
      end

      def built_in_move_allowed!(actor:, source:, destination:)
        assert_edit_access!(actor: actor, recording: source,
                            message: "Actor does not have edit access on the source recording")
        assert_edit_access!(actor: actor, recording: destination,
                            message: "Actor does not have edit access on the target recording")
      end

      def assert_edit_access!(actor:, recording:, message:)
        return if RecordingStudio::Services::AccessCheck.allowed?(actor: actor, recording: recording, role: :edit)

        raise RecordingStudio::AccessDenied, message
      end

      def built_in_access?
        RecordingStudio::Moveable.configuration.use_builtin_access
      end

      def custom_allowed?(actor:, source:, destination:, impersonator: nil, metadata: {})
        RecordingStudio::Moveable.configuration.authorize_move?(
          actor: actor,
          source: source,
          destination: destination,
          impersonator: impersonator,
          metadata: metadata
        )
      end
    end
  end
end
