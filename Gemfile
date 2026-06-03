# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_moveable.gemspec
gemspec

gem "flat_pack", github: "bowerbird-app/flatpack"
gem "recording_studio", github: "bowerbird-app/RecordingStudio"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible"
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
