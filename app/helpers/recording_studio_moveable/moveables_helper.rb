# frozen_string_literal: true

module RecordingStudioMoveable
  module MoveablesHelper
    def recording_studio_moveable_meta_tags
      tag.meta(name: "recording-studio-moveable", content: "enabled")
    end

    def recording_studio_moveable_asset_available?(asset_name)
      assets = Rails.application.assets
      return false unless assets.respond_to?(:load_path)

      assets.load_path.find(asset_name).present?
    rescue StandardError
      false
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
        modal.body { tag.div("", data: { recording_studio_moveable_modal_body: true }) }
      end
    end

    def moveable_title_for(recording)
      "Move #{moveable_label_for(recording)}"
    end

    def moveable_root_label(count: 1)
      RecordingStudioMoveable::RootLabel.resolve(self, count: count)
    end

    def moveable_label_for(recording)
      recordable = recording.recordable

      return recordable.title if recordable.respond_to?(:title) && recordable.title.present?
      return recordable.name if recordable.respond_to?(:name) && recordable.name.present?

      "#{moveable_type_for(recording)} ##{recording.id}"
    end

    def moveable_type_for(recording)
      recording.recordable_type.to_s.demodulize.sub(/^RecordingStudio/, "").underscore.humanize
    end

    def moveable_picker_items_for(destinations)
      destinations.map { |destination| moveable_picker_item_for(destination) }
    end

    def moveable_workspace_picker_items_for(workspace_roots)
      workspace_roots.map do |workspace_root|
        moveable_picker_item_attributes(workspace_root).merge(
          kind: "workspace",
          description: "Choose destinations in #{moveable_label_for(workspace_root)}"
        )
      end
    end

    def moveable_picker_item_for(recording)
      moveable_picker_item_attributes(recording).merge(
        description: moveable_type_for(recording)
      )
    end

    private

    def moveable_picker_item_attributes(recording)
      label = moveable_label_for(recording)

      {
        id: recording.id,
        kind: "record",
        name: label,
        label: label,
        payload: { id: recording.id }
      }
    end
  end
end
