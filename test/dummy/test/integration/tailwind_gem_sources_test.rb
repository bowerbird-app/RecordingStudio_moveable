# frozen_string_literal: true

require "rake"
require_relative "../test_helper"

class TailwindGemSourcesTest < ActiveSupport::TestCase
  def test_build_scans_installed_flatpack_and_recording_studio_gems
    Rails.application.load_tasks unless Rake::Task.task_defined?("tailwindcss:gem_sources")

    assert_includes Rake::Task["tailwindcss:build"].prerequisites, "tailwindcss:gem_sources"

    Rake::Task["tailwindcss:gem_sources"].reenable
    Rake::Task["tailwindcss:gem_sources"].invoke

    sources = Rails.root.join("app/assets/builds/tailwind/gem_sources.css").read
    flatpack = Gem.loaded_specs.fetch("flat_pack").full_gem_path
    recording_studio = Gem.loaded_specs.fetch("recording_studio").full_gem_path

    assert_includes sources, %(@source "#{flatpack}/app/components/**/*.rb";)
    assert_includes sources, %(@source "#{recording_studio}/app/views/**/*.erb";)
    refute_includes sources, "../usr/local"

    css_path = Rails.root.join("app/assets/builds/tailwind.css")
    assert css_path.file?, "Run bin/rails tailwindcss:build so the dummy compiles Flatpack utilities"
    css = css_path.read
    assert_includes css, "alert-success-background-color"
    assert_includes css, "modal-surface-color"
  end
end
