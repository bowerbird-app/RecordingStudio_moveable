# frozen_string_literal: true

Rails.application.config.recording_studio_icons = {
  default_library: :heroicons
}

RecordingStudioIcons.register_renderer(:heroicons, RecordingStudioIcons::Renderers::Heroicons)

unless RecordingStudioIcons::Renderers::Heroicons.singleton_class.ancestors.any? { |ancestor| ancestor.name == "RecordingStudioDocumentIconAlias" }
  module RecordingStudioDocumentIconAlias
    def icon_definition(icon_reference)
      if icon_reference.name == "document" && (icon_reference.variant || :outline) == :outline
        return RecordingStudioIcons::Renderers::HEROICON_DEFINITIONS[["document-text", :outline]]
      end

      super
    end
  end

  RecordingStudioIcons::Renderers::Heroicons.singleton_class.prepend(RecordingStudioDocumentIconAlias)
end