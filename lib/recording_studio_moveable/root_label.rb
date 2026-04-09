# frozen_string_literal: true

module RecordingStudioMoveable
  module RootLabel
    module_function

    def resolve(context = nil, count: 1)
      label = if context.respond_to?(:recording_studio_moveable_root_label, true)
                context.recording_studio_moveable_root_label(count: count)
              end

      label.to_s.presence || default(count: count)
    end

    def default(count: 1)
      count.to_i == 1 ? "workspace" : "workspaces"
    end
  end
end
