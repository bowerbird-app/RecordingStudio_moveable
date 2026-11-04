# frozen_string_literal: true

module RecordingStudioMoveable
  module CopyHelper
    def moveable_t(...)
      Copy.t(...)
    end

    def moveable_copy(override, key, **)
      Copy.value(override, key, **)
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
