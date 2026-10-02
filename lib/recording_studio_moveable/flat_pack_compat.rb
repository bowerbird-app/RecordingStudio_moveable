# frozen_string_literal: true

module RecordingStudioMoveable
  # RecordingStudio 4.2.0 still passes FlatPack PageNav kwargs from before the
  # 0.1.130 param rename (anchor_url / secondary_anchor_url / back_url). Map them
  # so moveable hosts can bump FlatPack without waiting on a RecordingStudio cut.
  module FlatPackPageNavCompat
    def initialize(**kwargs)
      if kwargs.key?(:anchor_url) && !kwargs.key?(:anchor_href)
        kwargs[:anchor_href] = kwargs.delete(:anchor_url)
      end

      if kwargs.key?(:secondary_anchor_url) && !kwargs.key?(:secondary_anchor_href)
        kwargs[:secondary_anchor_href] = kwargs.delete(:secondary_anchor_url)
      end

      kwargs.delete(:back_url)

      super(**kwargs)
    end
  end
end
