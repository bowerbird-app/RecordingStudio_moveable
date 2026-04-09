# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Authorization
      module_function

      def source_visible?(actor:, source:, impersonator: nil, metadata: {})
        policy(actor: actor, source: source, impersonator: impersonator, metadata: metadata).source_visible?
      end

      def source_allowed?(actor:, source:)
        policy(actor: actor, source: source).source_editable?
      end

      def destination_visible?(actor:, source:, destination:, impersonator: nil, metadata: {})
        policy(actor: actor, source: source, impersonator: impersonator, metadata: metadata)
          .destination_visible?(destination: destination)
      end

      def destination_allowed?(actor:, source:, destination:, impersonator: nil, metadata: {})
        policy(actor: actor, source: source, impersonator: impersonator, metadata: metadata)
          .destination_selectable?(destination: destination)
      end

      def filter_visible_destinations(actor:, source:, destinations:, impersonator: nil, metadata: {})
        policy(actor: actor, source: source, impersonator: impersonator, metadata: metadata)
          .filter_visible_destinations(destinations: destinations)
      end

      def assert_move_allowed!(actor:, source:, destination:, impersonator: nil, metadata: {})
        policy(actor: actor, source: source, impersonator: impersonator, metadata: metadata)
          .authorize_move!(destination: destination)
      end

      def policy(actor:, source:, impersonator: nil, metadata: {})
        RecordingStudio::Moveable::Policy.new(
          actor: actor,
          source: source,
          impersonator: impersonator,
          metadata: metadata
        )
      end
    end
  end
end
