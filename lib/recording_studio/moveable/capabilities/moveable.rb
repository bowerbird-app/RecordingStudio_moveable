# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Capabilities
      module Moveable
        VALID_OPTIONS = [:allow_cross_root].freeze
        DESTINATION_API_REMOVED_MESSAGE = "RecordingStudio::Capabilities::Moveable.to no longer accepts " \
                                          "destination types. Define structural parent rules with " \
                                          "recording_studio_recordable allowed_parent_types: [...] and use " \
                                          "RecordingStudio::Capabilities::Moveable.to(allow_cross_root: ...)."

        def self.to(*args, **options)
          raise ArgumentError, DESTINATION_API_REMOVED_MESSAGE if args.any?

          RecordingStudio::Capabilities.include_for(:movable, **capability_options(options))
        end

        class << self
          alias enabled to
        end

        def self.capability_options(options)
          unknown_options = options.keys - VALID_OPTIONS
          raise ArgumentError, "Unknown Moveable option(s): #{unknown_options.join(', ')}" if unknown_options.any?

          {
            allow_cross_root: options[:allow_cross_root] == true
          }
        end

        module RecordingMethods
          include RecordingStudio::Capability

          MOVE_ATTEMPTS = 5

          # Locks come from RecordingStudio.lock_for_move!. Moveable still owns
          # the cycle check, cross-root opt-in, authorization, and the moved event.
          def move_to!(new_parent:, actor:, impersonator: nil, metadata: {})
            attempts = 0
            begin
              attempts += 1
              self.class.transaction { lock_and_commit_move!(new_parent:, actor:, impersonator:, metadata:) }
            rescue RecordingStudio::MoveConflict
              retry if attempts < MOVE_ATTEMPTS
              raise
            end
          end

          alias moveable_to! move_to!

          private

          def lock_and_commit_move!(new_parent:, actor:, impersonator:, metadata:)
            to_root = RecordingStudio.root_recording_or_self(new_parent)
            locks = RecordingStudio.lock_for_move!(self, to_parent: new_parent, to_root: to_root)
            locks[:recording].send(:commit_locked_move!, locks, actor:, impersonator:, metadata:)
          end

          def commit_locked_move!(locks, actor:, impersonator:, metadata:)
            parent = locks[:to_parent]
            descendant_ids = locks[:descendant_ids]
            assert_move_allowed!(locks, parent, descendant_ids)
            authorize_move_tree!(parent, descendant_ids, actor:, impersonator:, metadata:)
            log_moved_event!(parent, actor:, impersonator:, metadata:)
            write_descendant_roots!(locks) if across_roots?(locks)
            update!(parent_recording: parent, root_recording_id: locks[:to_root].id)
          end

          def assert_move_allowed!(locks, parent, descendant_ids)
            assert_capability!(:movable)
            assert_parent_recording_not_self_or_descendant!(parent, descendant_ids: descendant_ids)
            reject_disallowed_cross_root!(locks)
            assert_recording_belongs_to_root!(parent) unless across_roots?(locks)
            RecordingStudio.assert_parent_allowed!(child_type: recordable_type, parent_recording: parent)
          end

          def reject_disallowed_cross_root!(locks)
            return unless across_roots?(locks) && !moveable_allows_cross_root?

            raise ArgumentError, RecordingStudioMoveable::Copy.t("errors.destination_wrong_root")
          end

          def moveable_allows_cross_root?
            options = RecordingStudio.capability_options(:movable, for_type: recordable_type) || {}
            options[:allow_cross_root] == true
          end

          def assert_parent_recording_not_self_or_descendant!(new_parent, descendant_ids:)
            if new_parent.id.to_s == id.to_s
              raise ArgumentError, RecordingStudioMoveable::Copy.t("errors.cannot_move_under_itself")
            end

            return unless descendant_ids.map(&:to_s).include?(new_parent.id.to_s)

            raise ArgumentError, RecordingStudioMoveable::Copy.t("errors.cannot_move_under_descendant")
          end

          def across_roots?(locks)
            locks[:to_root].id.to_s != locks[:source_root].id.to_s
          end

          def cross_root?(recording)
            resolved_root_id(recording) != resolved_root_id(self)
          end

          def resolved_root_id(recording)
            RecordingStudio.root_recording_id_for(recording)
          end

          def authorize_move_tree!(destination, descendant_ids, actor:, impersonator:, metadata:)
            authorize_one_move!(self, destination, actor:, impersonator:, metadata:)
            descendant_ids.each do |descendant_id|
              authorize_one_move!(
                self.class.find(descendant_id),
                destination,
                actor:,
                impersonator:,
                metadata:
              )
            end
          end

          def authorize_one_move!(recording, destination, actor:, impersonator:, metadata:)
            RecordingStudio::Moveable::Policy.new(
              actor: actor,
              source: recording,
              impersonator: impersonator,
              metadata: metadata
            ).authorize_move!(destination: destination)
          end

          def log_moved_event!(new_parent, actor:, impersonator:, metadata:)
            log_event!(
              action: "moved",
              actor: actor,
              impersonator: impersonator,
              metadata: move_event_metadata(new_parent, metadata)
            )
          end

          def move_event_metadata(new_parent, metadata)
            metadata.to_h.merge(
              from_parent_id: parent_recording_id,
              to_parent_id: new_parent.id,
              from_root_id: resolved_root_id(self),
              to_root_id: resolved_root_id(new_parent)
            )
          end

          # Before update! so core's callback rewrites event roots, including moved.
          def write_descendant_roots!(locks)
            descendant_ids = locks[:descendant_ids]
            return if descendant_ids.empty?

            self.class.where(id: descendant_ids).update_all(root_recording_id: locks[:to_root].id)
          end
        end
      end
    end
  end
end

module RecordingStudio
  module Capabilities
    Moveable = RecordingStudio::Moveable::Capabilities::Moveable

    module Movable
      singleton_class.send(:remove_method, :to) if singleton_class.method_defined?(:to)
      singleton_class.send(:remove_method, :enabled) if singleton_class.method_defined?(:enabled)

      def self.to(*, **)
        RecordingStudio::Moveable::Capabilities::Moveable.to(*, **)
      end

      class << self
        alias enabled to
      end
    end
  end
end

RecordingStudio.register_capability(
  :movable,
  RecordingStudio::Moveable::Capabilities::Moveable::RecordingMethods
)
