# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Authorization
      module_function

      def source_visible?(actor:, source:, impersonator: nil, metadata: {})
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
        return custom_allowed?(actor: actor, source: source, destination: destination, impersonator: impersonator,
                               metadata: metadata) unless built_in_access?

        source_allowed = source_allowed?(actor: actor, source: source)
        destination_allowed = RecordingStudio::Services::AccessCheck.allowed?(
          actor: actor,
          recording: destination,
          role: :edit
        )

        source_allowed && destination_allowed
      end

      def filter_visible_destinations(actor:, source:, destinations:, impersonator: nil, metadata: {})
        Array(destinations).select do |destination|
          destination_visible?(actor: actor, source: source, destination: destination, impersonator: impersonator,
                               metadata: metadata)
        end
      end

      def assert_move_allowed!(actor:, source:, destination:, impersonator: nil, metadata: {})
        if built_in_access?
          unless RecordingStudio::Services::AccessCheck.allowed?(actor: actor, recording: source, role: :edit)
            raise RecordingStudio::AccessDenied, "Actor does not have edit access on the source recording"
          end

          unless RecordingStudio::Services::AccessCheck.allowed?(actor: actor, recording: destination, role: :edit)
            raise RecordingStudio::AccessDenied, "Actor does not have edit access on the target recording"
          end

          return true
        end

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
