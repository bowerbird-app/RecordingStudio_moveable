# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_moveable.gemspec
gemspec

gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.132"
gem "recording_studio", "~> 4.0", github: "bowerbird-app/RecordingStudio", tag: "v4.0.0"
# Accessible 0.6.0 (RecordingStudio 4 support) — pin the release branch until the tag ships.
gem "recording_studio_accessible", "~> 0.6",
    github: "bowerbird-app/RecordingStudio_accessible",
    branch: "cursor/support-recording-studio-4-8e1e"
gem "recording_studio_icons", github: "bowerbird-app/RecordingStudio_icons"

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest", "~> 5.26"
  gem "minitest-mock"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
