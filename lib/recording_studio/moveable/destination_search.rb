# frozen_string_literal: true

module RecordingStudio
  module Moveable
    # rubocop:disable Metrics/ClassLength
    class DestinationSearch
      DEFAULT_LIMIT = 200

      def initialize(actor:, source:, impersonator: nil, metadata: {}, policy: nil)
        @actor = actor
        @source = source
        @impersonator = impersonator
        @metadata = metadata
        @policy = policy
      end

      def results(query: nil, limit: DEFAULT_LIMIT, root: nil)
        destinations = structurally_allowed_destinations(root: root)
        destinations = policy.filter_visible_destinations(destinations: destinations)
        destinations = filter_by_query(destinations, query)
        destinations = promote_workspace_root(destinations)

        limit ? destinations.first(limit) : destinations
      end

      def workspace_results(query: nil, limit: DEFAULT_LIMIT)
        roots = cross_root_workspace_destinations
        roots = filter_by_query(roots, query)

        limit ? roots.first(limit) : roots
      end

      def allowed_workspace_root?(root_recording)
        workspace_root_ids.include?(resolved_root_id(root_recording))
      end

      def allowed_destination?(destination)
        structurally_allowed_destination?(destination) && policy.destination_selectable?(destination: destination)
      end

      private

      attr_reader :actor, :source, :impersonator, :metadata

      def policy
        @policy ||= RecordingStudio::Moveable::Policy.new(
          actor: actor,
          source: source,
          impersonator: impersonator,
          metadata: metadata
        )
      end

      def structurally_allowed_destinations(root: nil, across_roots: false)
        scope = RecordingStudio::Recording.all
        scope = scope.where(root_recording_id: resolved_root_id(root || source)) unless across_roots

        scope.where(recordable_type: allowed_parent_types)
             .where.not(id: excluded_destination_ids)
             .includes(:recordable)
             .order(updated_at: :desc)
             .to_a
      end

      def allowed_parent_types
        options = RecordingStudio.capability_options(:movable, for_type: source.recordable_type) || {}
        Array(options[:allowed_parent_types]).map(&:to_s)
      end

      def excluded_destination_ids
        [source.id, *descendant_ids(source), *current_root_no_op_destination_ids]
      end

      def current_root_no_op_destination_ids
        return [] unless source_directly_under_root?

        [resolved_root_id(source)]
      end

      def source_directly_under_root?
        source.parent_recording_id.present? && source.parent_recording_id == resolved_root_id(source)
      end

      def structurally_allowed_destination?(destination)
        allowed_root?(destination) &&
          allowed_parent_types.include?(destination.recordable_type.to_s) &&
          excluded_destination_ids.exclude?(destination.id)
      end

      def allowed_root?(destination)
        same_root?(destination) || allow_cross_root?
      end

      def same_root?(destination)
        resolved_root_id(destination) == resolved_root_id(source)
      end

      def allow_cross_root?
        options = RecordingStudio.capability_options(:movable, for_type: source.recordable_type) || {}
        options[:allow_cross_root] == true
      end

      def cross_root_workspace_destinations
        return [] unless allow_cross_root?

        RecordingStudio::Recording.where(id: workspace_root_ids)
                                  .includes(:recordable)
                                  .order(updated_at: :desc)
                                  .to_a
      end

      def workspace_root_ids
        @workspace_root_ids ||= begin
          destinations = structurally_allowed_destinations(across_roots: true)
          destinations = policy.filter_visible_destinations(destinations: destinations)

          destinations.filter_map do |destination|
            root_id = resolved_root_id(destination)
            root_id unless root_id == resolved_root_id(source)
          end.uniq
        end
      end

      def descendant_ids(recording)
        descendants = []
        frontier = [recording.id]

        until frontier.empty?
          children = RecordingStudio::Recording.where(parent_recording_id: frontier).pluck(:id)
          descendants.concat(children)
          frontier = children
        end

        descendants
      end

      def filter_by_query(destinations, query)
        normalized_query = query.to_s.strip.downcase
        return destinations if normalized_query.empty?

        destinations.select do |recording|
          searchable_terms(recording).any? { |term| term.include?(normalized_query) }
        end
      end

      def promote_workspace_root(destinations)
        root_destinations, nested_destinations = destinations.partition do |recording|
          recording.parent_recording_id.blank?
        end
        root_destinations + nested_destinations
      end

      def searchable_terms(recording)
        recordable = recording.recordable

        [
          recordable_title(recordable),
          recordable_name(recordable),
          recording.recordable_type.to_s.demodulize.titleize,
          recording.id.to_s
        ].compact.map { |term| term.to_s.downcase }
      end

      def recordable_title(recordable)
        return unless recordable.respond_to?(:title)

        recordable.title.presence
      end

      def recordable_name(recordable)
        return unless recordable.respond_to?(:name)

        recordable.name.presence
      end

      def resolved_root_id(recording)
        recording.root_recording_id.presence || recording.id
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
