class RecordingStudioPage < ApplicationRecord
  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder")

  validates :title, presence: true
end
