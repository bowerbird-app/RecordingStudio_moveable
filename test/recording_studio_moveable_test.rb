# frozen_string_literal: true

require "test_helper"

class RecordingStudioMoveableTest < Minitest::Test
  def test_version_exists
    assert_equal "6.1.1", ::RecordingStudioMoveable::VERSION

    root = File.expand_path("..", __dir__)
    changelog = File.read(File.join(root, "CHANGELOG.md"))
    assert_includes changelog, "## [6.1.1] - 2026-11-23"
    assert_includes changelog, "## [6.1.0] - 2026-11-19"
    assert_includes changelog, "## [6.0.3] - 2026-11-18"
    assert_includes changelog,
                    "[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v6.1.1...HEAD"
    assert_includes changelog,
                    "[6.1.1]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v6.1.0...v6.1.1"
    assert_includes changelog,
                    "[6.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v6.0.3...v6.1.0"
    assert_includes changelog,
                    "[6.0.3]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v6.0.2...v6.0.3"
    assert_includes changelog,
                    "Hosts MUST run the Recording Studio 7.4, 7.5 and 7.7 migrations if they have not."
    assert_includes changelog,
                    "flat_pack 0.2.0 is supported; hosts moving to 0.2 must remove the manual " \
                    "`flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller registration."

    upgrading = File.read(File.join(root, "docs/recording_studio_moveable/UPGRADING.md"))
    assert_includes upgrading, "Hosts that install RecordingStudio 7.7 MUST run"
    assert_includes upgrading, "20261116230000_add_recording_studio_recordings_root_type_creation_index"
    assert_includes upgrading, "20261117120000_enforce_recording_studio_recording_root_invariant"
    assert_includes upgrading, "20261117200000_replace_recording_studio_recordings_root_index"

    gemfile = File.read(File.join(root, "Gemfile"))
    dummy_gemfile = File.read(File.join(root, "test/dummy/Gemfile"))
    %w[v7.8.0 v0.56.0 v1.2.3 v0.10.0 v0.5.0 v0.2.0].each do |tag|
      assert_includes gemfile, tag
      assert_includes dummy_gemfile, tag
    end
    assert_includes dummy_gemfile, "v0.3.1"
    assert_includes dummy_gemfile, "v1.21.3"
    assert_includes dummy_gemfile, '"~> 1.21"'
    assert_includes dummy_gemfile, "v0.45.2"
    assert_includes dummy_gemfile, '">= 0.45", "~> 0.45"'
    assert_includes dummy_gemfile, "v0.9.0"
    assert_includes changelog, "previously skipped API and accessible-pages tests now run"
    assert_includes gemfile, '"~> 7.8"'
    assert_includes gemfile, '"~> 0.2"'
    assert_includes gemfile, '"~> 0.56"'
    assert_includes gemfile, '"~> 0.5"'
    assert_includes gemfile, '"~> 0.10"'
    assert_includes gemfile, '"~> 1.2"'
    assert_includes dummy_gemfile, '"~> 7.8"'
    assert_includes dummy_gemfile, '"~> 0.2"'
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioMoveable::Engine
  end

  def test_dummy_app_uses_flatpack_sidebar_layout
    layout_path = File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__)
    assert File.exist?(layout_path)

    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    assert_includes controller_source, "flat_pack_sidebar"
  end

  def test_dummy_app_uses_moveable_addon_configuration
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "RecordingStudioFolder"
    assert_includes initializer_source, "RecordingStudioPage"
    assert_includes initializer_source, "moveable addon capability"
  end
end
