class RecordingStudioFolder < ApplicationRecord
  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder")

  validates :name, presence: true
end
