class RecordingStudioArchiveBox < ApplicationRecord
  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "document-duplicate",
    variant: :outline

  validates :name, presence: true

  def self.recordable_type_label
    "Archive box"
  end

  class << self
    alias_method :recording_studio_type_label, :recordable_type_label
  end
end
