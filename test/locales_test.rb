# frozen_string_literal: true

require "test_helper"
require "yaml"

class LocalesTest < Minitest::Test
  Copy = RecordingStudioMoveable::Copy

  def test_engine_ships_only_english_locale_files
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  def test_rails_i18n_load_path_includes_the_gem_english_locale_file
    # Real guard: never append i18n.load_path from lib (the previous body set
    # I18n.load_path then asserted inclusion, which always passed).
    lib_dir = File.expand_path("../lib", __dir__)
    ruby_files = Dir[File.join(lib_dir, "**", "*.rb")]

    refute_empty ruby_files, "expected lib/**/*.rb files to scan"

    ruby_files.each do |path|
      source = File.read(path)

      refute_includes source, "i18n.load_path", "#{path} must not touch i18n.load_path"
      refute_includes source, "I18n.load_path", "#{path} must not touch I18n.load_path"
    end
  end

  def test_lib_sources_do_not_append_i18n_load_path
    lib_dir = File.expand_path("../lib", __dir__)
    ruby_files = Dir[File.join(lib_dir, "**", "*.rb")]

    refute_empty ruby_files, "expected lib/**/*.rb files to scan"

    ruby_files.each do |path|
      source = File.read(path)

      refute_includes source, "i18n.load_path", "#{path} must not touch i18n.load_path"
      refute_includes source, "I18n.load_path", "#{path} must not touch I18n.load_path"
    end
  end

  def test_copy_t_missing_key_matches_main_translation_missing_string
    # Copy.t must not inject English defaults: a locale with no key and no
    # fallbacks returns the same "Translation missing: ..." string as I18n.t.
    previous_available = I18n.available_locales.dup
    previous_default = I18n.default_locale
    previous_locale = I18n.locale
    previous_backend = I18n.backend
    previous_exception_handler = I18n.exception_handler if I18n.respond_to?(:exception_handler)

    I18n.backend = I18n::Backend::Simple.new
    I18n.available_locales = %i[zz en]
    I18n.default_locale = :zz
    I18n.locale = :zz
    I18n.exception_handler = I18n::ExceptionHandler.new if I18n.respond_to?(:exception_handler=)

    expected = I18n.t("recording_studio.moveable.flashes.moved")
    assert_equal "Translation missing: zz.recording_studio.moveable.flashes.moved", expected
    assert_equal expected, Copy.t("flashes.moved")

    assert_raises(I18n::MissingTranslationData) do
      I18n.t("recording_studio.moveable.flashes.moved", raise: true)
    end
    assert_raises(I18n::MissingTranslationData) do
      Copy.t("flashes.moved", raise: true)
    end
  ensure
    I18n.backend = previous_backend
    I18n.available_locales = previous_available
    I18n.default_locale = previous_default
    I18n.locale = previous_locale
    I18n.exception_handler = previous_exception_handler if previous_exception_handler
  end

  def test_dummy_french_covers_every_engine_english_key
    english = flatten_keys(locale_tree(File.join(engine_locales_dir, "en.yml"), "en"))
    french = flatten_keys(locale_tree(File.join(dummy_locales_dir, "fr.yml"), "fr"))
    missing = english - french

    assert_empty missing, "dummy fr.yml is missing keys present in engine en.yml: #{missing.join(', ')}"
  end

  def test_english_default_copy_is_unchanged
    with_gem_english_locale_only do
      I18n.with_locale(:en) do
        assert_equal "Move %{name}", Copy.t("dialog.title") # rubocop:disable Style/FormatStringToken
        assert_equal "Choose destination", Copy.t("dialog.subtitle")
        assert_equal "Change", Copy.t("dialog.change")
        assert_equal "Search destinations", Copy.t("dialog.search_destinations")
        assert_equal "Return to previous page", Copy.t("dialog.back")
        assert_equal "Moved successfully.", Copy.t("flashes.moved")
        assert_equal "workspace", Copy.t("roots", count: 1)
        assert_equal "workspaces", Copy.t("roots", count: 2)
        assert_equal "Updating destinations...", Copy.t("js.updating")
        assert_equal "Moving item...", Copy.t("js.moving")
        assert_equal "Unable to load the move view right now. Please try again.", Copy.t("js.load_error")
        assert_equal "Destination is not allowed for this move", Copy.t("errors.destination_not_allowed")
        assert_equal "Cannot move a recording under itself", Copy.t("errors.cannot_move_under_itself")
        assert_equal "Move", Copy.t("layout.title", default: "Move")
      end
    end
  end

  def test_nested_keys_resolve_through_i18n_without_missing_translations
    with_gem_english_locale_only do
      I18n.with_locale(:en) do
        %w[
          dialog.subtitle
          dialog.search_destinations
          flashes.moved
          js.load_error
          layout.title
          errors.destination_not_allowed
        ].each do |key|
          full_key = "recording_studio.moveable.#{key}"
          translation = I18n.t(full_key, default: nil)

          refute_nil translation, "#{full_key} should resolve"
          assert_equal translation, I18n.t(full_key, raise: true)
        end
      end
    end
  end

  def test_legacy_moved_notice_key_still_wins
    I18n.backend.store_translations(:en, legacy_notice("Host moved it."))

    assert_equal "Host moved it.", Copy.t("flashes.moved")
  ensure
    I18n.backend.store_translations(:en, wipe_legacy_notice)
    I18n.backend.store_translations(:en, default_moved)
  end

  def test_moved_flash_uses_gem_english_when_legacy_key_is_absent
    with_gem_english_locale_only do
      I18n.backend.store_translations(:en, wipe_legacy_notice)
      I18n.backend.load_translations

      assert_equal "Moved successfully.", Copy.t("flashes.moved")
    end
  end

  def test_component_text_overrides_win_including_nil
    assert_equal "Choose destination", Copy.value(Copy::UNSET, "dialog.subtitle")
    assert_equal "Pick a home", Copy.value("Pick a home", "dialog.subtitle")
    assert_nil Copy.value(nil, "dialog.subtitle")
  end

  def test_defaulted_follows_locale_until_the_host_changes_the_string
    I18n.with_locale(:en) do
      assert_equal "Choose destination", Copy.defaulted("Choose destination", "Choose destination", "dialog.subtitle")
      assert_equal "Pick a home", Copy.defaulted("Pick a home", "Choose destination", "dialog.subtitle")
      assert_equal "Choose destination", Copy.defaulted(nil, "Choose destination", "dialog.subtitle")
    end
  end

  def test_host_translation_overrides_english
    I18n.backend.store_translations(:en, acme_subtitle)
    assert_equal "Acme destination", Copy.t("dialog.subtitle")
  ensure
    I18n.backend.store_translations(:en, default_subtitle)
  end

  def test_root_label_helper_override_still_wins
    helper = Class.new do
      include RecordingStudioMoveable::MoveablesHelper

      def recording_studio_moveable_root_label(count: 1)
        count.to_i == 1 ? "space" : "spaces"
      end
    end.new

    I18n.with_locale(:en) do
      assert_equal "space", helper.moveable_root_label
      assert_equal "spaces", helper.moveable_root_label(count: 2)
    end
  end

  def test_gemspec_does_not_depend_on_internationalization
    gemspec = File.read(File.expand_path("../recording_studio_moveable.gemspec", __dir__))

    refute_includes gemspec, "recording_studio_internationalization"
    refute_includes gemspec, "RecordingStudio_Internationalization"
  end

  def test_gem_does_not_ship_legacy_namespace_english_for_moved_flash
    tree = YAML.safe_load_file(File.join(engine_locales_dir, "en.yml"), aliases: true).fetch("en")

    refute tree.key?("recording_studio_moveable"),
           "do not ship gem English under the deprecated recording_studio_moveable.* namespace"
  end

  private

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def dummy_locales_dir
    File.expand_path("dummy/config/locales", __dir__)
  end

  def locale_tree(path, locale)
    yaml = YAML.safe_load_file(path, aliases: true)
    yaml.fetch(locale).fetch("recording_studio").fetch("moveable")
  end

  def flatten_keys(hash, prefix = [])
    hash.flat_map do |key, value|
      path = prefix + [key.to_s]
      value.is_a?(Hash) ? flatten_keys(value, path) : [path.join(".")]
    end
  end

  def acme_subtitle
    { recording_studio: { moveable: { dialog: { subtitle: "Acme destination" } } } }
  end

  def default_subtitle
    { recording_studio: { moveable: { dialog: { subtitle: "Choose destination" } } } }
  end

  def default_moved
    { recording_studio: { moveable: { flashes: { moved: "Moved successfully." } } } }
  end

  def legacy_notice(text)
    { recording_studio_moveable: { moveables: { update: { notice: text } } } }
  end

  def wipe_legacy_notice
    { recording_studio_moveable: { moveables: { update: { notice: nil } } } }
  end

  # Gem English assertions load only the engine en.yml. Always restore
  # I18n.load_path, then re-seed the unit-suite backend (unit tests do not put
  # gem locales on the load path).
  def with_gem_english_locale_only
    previous = I18n.load_path.dup
    I18n.load_path = [File.join(engine_locales_dir, "en.yml")]
    I18n.backend.load_translations
    yield
  ensure
    I18n.load_path = previous
    I18n.backend.load_translations
    I18n.backend.store_translations(:en, gem_english_tree)
  end

  def gem_english_tree
    YAML.safe_load_file(File.join(engine_locales_dir, "en.yml"), aliases: true).fetch("en")
  end

end
