# frozen_string_literal: true

require_relative "lib/recording_studio_moveable/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_moveable"
  spec.version     = RecordingStudioMoveable::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_moveable"
  spec.summary     = "RecordingStudio move capability addon with reusable move UI"
  spec.description = "Addon for RecordingStudio that provides moveable capability extraction, integration " \
                     "with RecordingStudio Accessible authorization, and reusable full-page/modal move UI."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_moveable"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_moveable/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  # FlatPack UI component library >= 0.1.12 is required as a peer dependency.
  # Host applications must declare: gem "flat_pack", github: "bowerbird-app/flatpack"
  spec.add_dependency "rails", ">= 8.1.0", "< 9.0"
  spec.add_dependency "recording_studio", "~> 4.0"
  spec.add_dependency "recording_studio_accessible", "~> 0.6"
  spec.add_dependency "recording_studio_icons", ">= 0.1.0"
end
