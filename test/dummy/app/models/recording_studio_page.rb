class RecordingStudioPage < ApplicationRecord
  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "document",
    variant: :outline

  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder")

  validates :title, presence: true
end
