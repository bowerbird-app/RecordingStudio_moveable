# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Capabilities
      module Moveable
        def self.to(*allowed_parent_types)
          options = allowed_parent_types.last.is_a?(Hash) ? allowed_parent_types.pop : {}
          type_names = capability_type_names(allowed_parent_types)

          build_capability_module(type_names, capability_options(options))
        end

        def self.build_capability_module(type_names, options)
          Module.new do
            extend ActiveSupport::Concern

            included do |base|
              RecordingStudio::Moveable::Capabilities::Moveable.apply_capability(base, type_names, options)
            end
          end
        end

        def self.apply_capability(base, type_names, options)
          RecordingStudio.enable_capability(:movable, on: base.name)
          RecordingStudio.set_capability_options(
            :movable,
            on: base.name,
            allowed_parent_types: type_names,
            allow_cross_root: options[:allow_cross_root]
          )
        end

        def self.capability_options(options)
          {
            allow_cross_root: options[:allow_cross_root] == true
          }
        end

        def self.capability_type_names(allowed_parent_types)
          allowed_parent_types.flatten.filter_map do |type|
            next if type.nil?

            type.is_a?(Class) ? type.name : type.to_s
          end.uniq
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
              assert_recording_belongs_to_root!(new_parent) unless cross_root_move?(new_parent)
              assert_parent_recording_not_self_or_descendant!(new_parent)

              allowed_types = moveable_allowed_parent_types
              unless allowed_types.include?(new_parent.recordable_type)
                raise ArgumentError,
                      "Cannot move to #{new_parent.recordable_type}; allowed: #{allowed_types.join(', ')}"
              end

              if cross_root?(new_parent) && !moveable_allows_cross_root?
                raise ArgumentError, "Destination must belong to this root recording"
              end

              RecordingStudio::Moveable::Policy.new(
                actor: actor,
                source: self,
                impersonator: impersonator,
                metadata: metadata
              ).authorize_move!(destination: new_parent)

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

              cross_root_move?(new_parent) ? transfer_to_root!(new_parent) : update!(parent_recording: new_parent)
            end
          end
          # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength

          alias moveable_to! move_to!

          private

          def moveable_allowed_parent_types
            options = RecordingStudio.capability_options(:movable, for_type: recordable_type) || {}
            Array(options[:allowed_parent_types]).map(&:to_s)
          end

          def moveable_allows_cross_root?
            options = RecordingStudio.capability_options(:movable, for_type: recordable_type) || {}
            options[:allow_cross_root] == true
          end

          def cross_root_move?(new_parent)
            cross_root?(new_parent)
          end

          def cross_root?(recording)
            resolved_root_id(recording) != resolved_root_id(self)
          end

          def resolved_root_id(recording)
            recording.root_recording_id.presence || recording.id
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

          def transfer_to_root!(new_parent)
            new_root_id = resolved_root_id(new_parent)
            descendants = descendant_ids

            self.class.where(id: descendants).update_all(root_recording_id: new_root_id) if descendants.any?
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

      def self.to(*allowed_parent_types)
        RecordingStudio::Moveable::Capabilities::Moveable.to(*allowed_parent_types)
      end
    end
  end
end

RecordingStudio.register_capability(
  :movable,
  RecordingStudio::Moveable::Capabilities::Moveable::RecordingMethods
)
