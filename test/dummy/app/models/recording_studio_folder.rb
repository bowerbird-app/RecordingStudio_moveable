class RecordingStudioFolder < ApplicationRecord
  recording_studio_recordable(
    label: "Folder",
    plural_label: "Folders",
    root: false,
    allowed_parent_types: [ "Workspace", "RecordingStudioFolder" ]
  )

  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "folder",
    variant: :outline

  include RecordingStudio::Capabilities::Moveable.enabled(allow_cross_root: true)

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
