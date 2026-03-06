# frozen_string_literal: true

module GemTemplate
  module MoveablesHelper
    def moveable_title_for(recording)
      "Move #{moveable_label_for(recording)}"
    end

    def moveable_label_for(recording)
      recordable = recording.recordable

      return recordable.title if recordable.respond_to?(:title) && recordable.title.present?
      return recordable.name if recordable.respond_to?(:name) && recordable.name.present?

      "#{moveable_type_for(recording)} ##{recording.id}"
    end

    def moveable_type_for(recording)
      recording.recordable_type.demodulize.titleize
    end

    def moveable_parent_label_for(recording)
      parent = recording.parent_recording
      return "Workspace root" if parent.blank?

      moveable_label_for(parent)
    end

    def flat_pack_search_available?
      defined?(FlatPack::SearchInput::Component)
    end
  end
end
