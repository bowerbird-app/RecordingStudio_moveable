# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_moveable.gemspec
gemspec

gem "flat_pack", "~> 0.2", github: "bowerbird-app/flatpack", tag: "v0.2.0"
gem "recording_studio", "~> 7.8", github: "bowerbird-app/RecordingStudio", tag: "v7.8.0"
gem "recording_studio_accessible", "~> 0.56",
    github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.56.0"
gem "recording_studio_icons", "~> 0.5", github: "bowerbird-app/RecordingStudio_icons", tag: "v0.5.0"
gem "view_component", "4.19.0"
# Trashable gemspec dep is git-only; pin for Bundler resolution.
gem "recording_studio_metrics", "~> 0.10", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.10.0",
                                           require: false
# Accessible query-only trash helpers. require: false so Bundler does not auto-load the Trashable engine.
gem "recording_studio_trashable", "~> 1.2", github: "bowerbird-app/RecordingStudio_trashable",
                                            tag: "v1.2.3", require: false

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest", "~> 5.26"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
