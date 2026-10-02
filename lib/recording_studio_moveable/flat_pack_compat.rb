# frozen_string_literal: true

module RecordingStudioMoveable
  # RecordingStudio 4.2.0 still passes FlatPack PageNav kwargs from before the
  # 0.1.130 param rename (anchor_url / secondary_anchor_url / back_url). Map them
  # so moveable hosts can bump FlatPack without waiting on a RecordingStudio cut.
  module FlatPackPageNavCompat
    def initialize(**kwargs)
      remap_legacy_page_nav_kwargs!(kwargs)
      # Remapped kwargs must be forwarded explicitly; bare `super` would replay the
      # caller's original keywords (including the pre-rename names).
      super(**kwargs) # rubocop:disable Style/SuperArguments
    end

    private

    def remap_legacy_page_nav_kwargs!(kwargs)
      take_legacy_href!(kwargs, from: :anchor_url, to: :anchor_href)
      take_legacy_href!(kwargs, from: :secondary_anchor_url, to: :secondary_anchor_href)
      kwargs.delete(:back_url)
    end

    def take_legacy_href!(kwargs, from:, to:)
      return unless kwargs.key?(from)
      return if kwargs.key?(to)

      kwargs[to] = kwargs.delete(from)
    end
  end
end
