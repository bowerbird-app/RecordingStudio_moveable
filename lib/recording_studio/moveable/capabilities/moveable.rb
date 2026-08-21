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

          # Equivalent behavior to legacy RecordingStudio::Capabilities::Movable#move_to!
          # with addon-owned authorization handling and metadata logging.
          # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
          def move_to!(new_parent:, actor:, impersonator: nil, metadata: {})
            self.class.transaction do
              ordered_ids = [new_parent.id, id, *descendant_ids].compact.uniq.sort
              ordered_ids.each { |recording_id| self.class.lock.find(recording_id) }

              reload
              new_parent = self.class.find(new_parent.id)

              assert_capability!(:movable)
              assert_parent_recording_not_self_or_descendant!(new_parent)

              if cross_root?(new_parent) && !moveable_allows_cross_root?
                raise ArgumentError, "Destination must belong to this root recording"
              end

              assert_recording_belongs_to_root!(new_parent) unless cross_root_move?(new_parent)
              RecordingStudio.assert_parent_allowed!(child_type: recordable_type, parent_recording: new_parent)

              policy = RecordingStudio::Moveable::Policy.new(
                actor: actor,
                source: self,
                impersonator: impersonator,
                metadata: metadata
              )
              descendants = descendant_recordings
              policy.authorize_move!(destination: new_parent)
              authorize_descendant_moves!(
                descendants,
                destination: new_parent,
                actor: actor,
                impersonator: impersonator,
                metadata: metadata
              )

              from_id = parent_recording_id
              log_event!(
                action: "moved",
                actor: actor,
                impersonator: impersonator,
                metadata: metadata.to_h.merge(
                  from_parent_id: from_id,
                  to_parent_id: new_parent.id,
                  from_root_id: resolved_root_id(self),
                  to_root_id: resolved_root_id(new_parent)
                )
              )

              if cross_root_move?(new_parent)
                transfer_to_root!(new_parent, descendants: descendants.map(&:id))
              else
                update!(parent_recording: new_parent)
              end
            end
          end
          # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength

          alias moveable_to! move_to!

          private

          def moveable_allows_cross_root?
            options = RecordingStudio.capability_options(:movable, for_type: recordable_type) || {}
            options[:allow_cross_root] == true
          end

          def assert_parent_recording_not_self_or_descendant!(new_parent)
            raise ArgumentError, "Cannot move a recording under itself" if new_parent.id == id

            return unless descendant_ids.include?(new_parent.id)

            raise ArgumentError, "Cannot move a recording under its descendant"
          end

          def cross_root_move?(new_parent)
            cross_root?(new_parent)
          end

          def cross_root?(recording)
            resolved_root_id(recording) != resolved_root_id(self)
          end

          def resolved_root_id(recording)
            RecordingStudio.root_recording_id_for(recording)
          end

          def descendant_ids
            descendants = []
            frontier = [id]

            until frontier.empty?
              children = self.class.where(parent_recording_id: frontier).pluck(:id)
              descendants.concat(children)
              frontier = children
            end

            descendants
          end

          def descendant_recordings
            descendant_ids.map { |descendant_id| self.class.find(descendant_id) }
          end

          def authorize_descendant_moves!(descendants, destination:, actor:, impersonator:, metadata:)
            descendants.each do |descendant|
              RecordingStudio::Moveable::Policy.new(
                actor: actor,
                source: descendant,
                impersonator: impersonator,
                metadata: metadata
              ).authorize_move!(destination: destination)
            end
          end

          def transfer_to_root!(new_parent, descendants: nil)
            new_root_id = resolved_root_id(new_parent)
            descendant_ids = descendants || self.descendant_ids

            self.class.where(id: descendant_ids).update_all(root_recording_id: new_root_id) if descendant_ids.any?
            update!(parent_recording: new_parent, root_recording_id: new_root_id)
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
