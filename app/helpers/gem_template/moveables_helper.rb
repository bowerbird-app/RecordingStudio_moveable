# frozen_string_literal: true

module GemTemplate
  module MoveablesHelper
    def recording_studio_moveable_meta_tags
      tag.meta(name: "recording-studio-moveable", content: "enabled")
    end

    def recording_studio_moveable_modal_template
      content_tag(:div, data: { recording_studio_moveable_modal_root: true }) do
        recording_studio_moveable_modal_component
      end
    end

    def recording_studio_moveable_modal_component
      render FlatPack::Modal::Component.new(
        id: "recording-studio-moveable-modal",
        size: :lg,
        body_height_mode: :fixed,
        body_height: "70vh",
        data: { recording_studio_moveable_modal_element: true }
      ) do |modal|
        modal.body_content { tag.div("", data: { recording_studio_moveable_modal_body: true }) }
      end
    end

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

    def moveable_picker_items_for(destinations)
      destinations.map { |destination| moveable_picker_item_for(destination) }
    end

    def moveable_picker_item_for(recording)
      {
        id: recording.id,
        kind: "record",
        name: moveable_label_for(recording),
        label: moveable_label_for(recording),
        description: moveable_parent_label_for(recording),
        badge: moveable_type_for(recording),
        meta: "ID #{recording.id}",
        payload: { id: recording.id }
      }
    end
  end
end
