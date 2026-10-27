# frozen_string_literal: true

# These installed tags still require recording_studio below 5. No newer tag
# or main ref allows 6.1.0 yet:
#   recording_studio_accessible v0.21.0 (~> 4.7, >= 4.7.1)
#   recording_studio_metrics v0.6.1 (~> 4.2)
#   recording_studio_trashable v0.11.0 (~> 4.7). v0.12.0 already allows >= 6.1.0.
#   recording_studio_internationalization v0.1.7 (~> 4.2)
# Rewrite the requirement when Bundler loads those gemspecs.
module WidenRecordingStudioRequirement
  def add_dependency(name, *requirements)
    if name.to_s == "recording_studio" && requirements.none? { |requirement| requirement.to_s.include?("6") }
      requirements = [">= 6.1.0"]
    end

    super
  end
end

unless Gem::Specification.ancestors.include?(WidenRecordingStudioRequirement)
  Gem::Specification.prepend(WidenRecordingStudioRequirement)
end
