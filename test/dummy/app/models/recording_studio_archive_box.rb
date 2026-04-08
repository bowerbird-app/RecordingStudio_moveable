class RecordingStudioArchiveBox < ApplicationRecord
  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "document-duplicate",
    variant: :outline

  validates :name, presence: true
end
