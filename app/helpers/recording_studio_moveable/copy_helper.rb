# frozen_string_literal: true

module RecordingStudioMoveable
  module CopyHelper
    def moveable_t(...)
      Copy.t(...)
    end

    def moveable_copy(override, key, **)
      Copy.value(override, key, **)
    end

    def moveable_document_attributes(extra = {})
      extra = extra.to_h
      attributes = { lang: I18n.locale.to_s }.merge(extra)
      attributes.merge!(recording_studio_locale_attributes) if respond_to?(:recording_studio_locale_attributes)
      return attributes unless respond_to?(:flat_pack_copy_data)

      attributes[:data] = (attributes[:data] || {}).merge(flat_pack_copy_data)
      attributes
    end

    def moveable_modal_copy_data
      {
        recording_studio_moveable_updating: Copy.t("js.updating"),
        recording_studio_moveable_moving: Copy.t("js.moving"),
        recording_studio_moveable_load_error: Copy.t("js.load_error")
      }
    end
  end
end
