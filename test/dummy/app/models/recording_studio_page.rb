class RecordingStudioPage < ApplicationRecord
  recording_studio_recordable(
    label: "Page",
    plural_label: "Pages",
    root: false,
    allowed_parent_types: [ "Workspace", "RecordingStudioFolder" ]
  )

  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "document",
    variant: :outline

  include RecordingStudio::Capabilities::Moveable.to(allow_cross_root: true)

  validates :title, presence: true

  def self.recordable_type_label
    "Page"
  end

  class << self
    alias_method :recording_studio_type_label, :recordable_type_label
  end
end
