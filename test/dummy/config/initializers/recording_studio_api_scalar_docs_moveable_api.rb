# frozen_string_literal: true

RecordingStudioApi.configure do |config|
  api = config.api(:public)
  api.documentation_enabled = true
  api.documentation_access = :authenticated
  api.documentation_layout_name = "flat_pack_sidebar"
end
