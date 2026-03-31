# frozen_string_literal: true

module RecordingStudio
  module Moveable
    module Capabilities
      module Moveable
        def self.to(*allowed_parent_types)
          type_names = capability_type_names(allowed_parent_types)

          build_capability_module(type_names)
        end

        def self.build_capability_module(type_names)
          Module.new do
            extend ActiveSupport::Concern

            included do |base|
              RecordingStudio::Moveable::Capabilities::Moveable.apply_capability(base, type_names)
            end
          end
        end

        def self.apply_capability(base, type_names)
          RecordingStudio.enable_capability(:movable, on: base.name)
          RecordingStudio.set_capability_options(
            :movable,
            on: base.name,
            allowed_parent_types: type_names
          )
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
              ordered_ids = [id, new_parent.id].compact.uniq.sort
              ordered_ids.each { |recording_id| self.class.lock.find(recording_id) }

              reload
              new_parent = self.class.find(new_parent.id)

              assert_capability!(:movable)
              assert_recording_belongs_to_root!(new_parent)
              assert_parent_recording_not_self_or_descendant!(new_parent)

              opts = RecordingStudio.capability_options(:movable, for_type: recordable_type) || {}
              allowed_types = Array(opts[:allowed_parent_types]).map(&:to_s)
              unless allowed_types.include?(new_parent.recordable_type)
                raise ArgumentError,
                      "Cannot move to #{new_parent.recordable_type}; allowed: #{allowed_types.join(', ')}"
              end

              RecordingStudio::Moveable::Authorization.assert_move_allowed!(
                actor: actor,
                source: self,
                destination: new_parent,
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
                  to_parent_id: new_parent.id
                )
              )
              update!(parent_recording: new_parent)
            end
          end
          # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength

          alias moveable_to! move_to!
        end
      end
    end
  end
end

module RecordingStudio
  module Capabilities
    Moveable = RecordingStudio::Moveable::Capabilities::Moveable

    module Movable
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
