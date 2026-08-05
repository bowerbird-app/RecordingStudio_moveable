# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_moveable.gemspec
gemspec

gem "flat_pack", github: "bowerbird-app/flatpack"
gem "recording_studio", "~> 3.0", github: "bowerbird-app/RecordingStudio", tag: "v3.0.3"
gem "recording_studio_accessible", "~> 0.3", github: "bowerbird-app/RecordingStudio_accessible", tag: "0.3.1"
gem "recording_studio_icons", github: "bowerbird-app/RecordingStudio_icons"

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
