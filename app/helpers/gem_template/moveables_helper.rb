# frozen_string_literal: true

module GemTemplate
  module MoveablesHelper
    def moveable_title_for(recording)
      "Move #{recording.recordable_type.demodulize.titleize}"
    end

    def moveable_label_for(recording)
      recordable = recording.recordable

      return recordable.title if recordable.respond_to?(:title) && recordable.title.present?
      return recordable.name if recordable.respond_to?(:name) && recordable.name.present?

      "#{recording.recordable_type.demodulize.titleize} ##{recording.id}"
    end

    def flat_pack_search_available?
      defined?(FlatPack::SearchInput::Component)
    end
  end
end
