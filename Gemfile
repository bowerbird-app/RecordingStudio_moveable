# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_moveable.gemspec
gemspec

gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.209"
gem "recording_studio", "~> 4.2", github: "bowerbird-app/RecordingStudio", tag: "v4.5.0"
gem "recording_studio_accessible", "~> 0.6", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.17.0"
gem "recording_studio_icons", github: "bowerbird-app/RecordingStudio_icons"
# Trashable gemspec dep is git-only; pin for Bundler resolution.
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.0",
                                require: false
# Accessible 0.17 query-only trash helpers (gemspec "~> 0.10"); require: false so Bundler
# does not auto-load the Trashable engine.
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable",
                                  tag: "v0.10.0", require: false

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
