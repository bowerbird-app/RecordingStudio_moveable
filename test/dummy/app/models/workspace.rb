class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", plural_label: "Workspaces", root: true, allowed_parent_types: []

  RecordingStudio.enable_capability(:accessible, on: self)
  # :api_access_point returns when recording_studio_api supports RecordingStudio 4.

  RecordingStudioIcons.register_default_icon self,
    library: :heroicons,
    name: "rectangle-stack",
    variant: :outline

  def self.recordable_type_label
    "Workspace"
  end

  class << self
    alias_method :recording_studio_type_label, :recordable_type_label
  end

  def recordable_name
    name.to_s.squish.presence || self.class.recordable_type_label
  end

  alias_method :recording_studio_label, :recordable_name
end
