class RecordingStudioFolder < ApplicationRecord
  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "folder",
    variant: :outline

  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder", allow_cross_root: true)

  validates :name, presence: true

  def self.recordable_type_label
    "Folder"
  end

  class << self
    alias_method :recording_studio_type_label, :recordable_type_label
  end

  def recordable_name
    label = name.to_s.squish.presence || self.class.recordable_type_label
    "📁 #{label}"
  end

  alias_method :recording_studio_label, :recordable_name
end
