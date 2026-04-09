class RecordingStudioFolder < ApplicationRecord
  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "folder",
    variant: :outline

  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder", allow_cross_root: true)

  validates :name, presence: true
end
