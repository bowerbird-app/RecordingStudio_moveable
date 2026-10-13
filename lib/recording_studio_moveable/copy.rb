# frozen_string_literal: true

require "erb"
require "i18n"

module RecordingStudioMoveable
  module Copy
    PREFIX = "recording_studio.moveable"
    UNSET = Object.new.freeze
    LEGACY_KEYS = {
      "flashes.moved" => "recording_studio_moveable.moveables.update.notice"
    }.freeze

    # English defaults for every shipped key so a host locale with no fallback
    # never shows "translation missing". Values must stay byte-identical to
    # config/locales/en.yml. I18n interpolation uses %{name}-style tokens.
    # rubocop:disable Style/FormatStringToken
    DEFAULTS = {
      "layout.title" => "Move",
      "dialog.title" => "Move %{name}",
      "dialog.subtitle" => "Choose destination",
      "dialog.change" => "Change",
      "dialog.change_workspace_title" => "Change %{workspace}",
      "dialog.search_destinations" => "Search destinations",
      "dialog.search_workspaces" => "Search %{workspaces}",
      "dialog.empty_destinations" =>
        "No allowed destinations found. Try a different search term or review your move permissions.",
      "dialog.empty_workspaces" => "No other %{workspaces} are available for this move.",
      "dialog.back" => "Return to previous page",
      "dialog.workspace_description" => "Choose destinations in %{name}",
      "roots" => { one: "workspace", other: "workspaces" },
      "flashes.moved" => "Moved successfully.",
      "js.updating" => "Updating destinations...",
      "js.moving" => "Moving item...",
      "js.load_error" => "Unable to load the move view right now. Please try again.",
      "errors.actor_required" => "A current actor is required to move recordings",
      "errors.destination_not_allowed" => "Destination is not allowed for this move",
      "errors.cannot_move_under_itself" => "Cannot move a recording under itself",
      "errors.cannot_move_under_descendant" => "Cannot move a recording under its descendant",
      "errors.destination_wrong_root" => "Destination must belong to this root recording",
      "errors.hook_denied" => "Move authorization hook denied this move",
      "errors.source_edit_denied" => "Actor does not have edit access on the source recording",
      "errors.destination_edit_denied" => "Actor does not have edit access on the target recording"
    }.freeze
    # rubocop:enable Style/FormatStringToken

    module_function

    def t(key, **options)
      full_key = "#{PREFIX}.#{key}"
      key_s = key.to_s
      options = with_english_default(key_s, options)

      legacy = LEGACY_KEYS[key_s]
      return I18n.t(legacy, **options) if legacy && I18n.exists?(legacy)

      translate_nested(full_key, key_s, options)
    end

    def l(object, **)
      I18n.l(object, **)
    end

    def provided?(value)
      !value.equal?(UNSET)
    end

    def value(override, key, **)
      provided?(override) ? override : t(key, **)
    end

    # Host config that still matches the English default follows the locale.
    # A different string (including blank after presence) is host copy and wins.
    def defaulted(value, default, key, **)
      return t(key, **) if value.nil? || value == default

      value
    end

    def with_english_default(key_s, options)
      return options if options.key?(:default) || !DEFAULTS.key?(key_s)

      options.merge(default: DEFAULTS.fetch(key_s))
    end
    module_function :with_english_default
    private_class_method :with_english_default

    def translate_nested(full_key, key_s, options)
      return I18n.t(full_key, **options) unless key_s.end_with?("_html")

      escaped = options.transform_values { |value| value.is_a?(String) ? ERB::Util.html_escape(value) : value }
      I18n.t(full_key, **escaped).to_s.html_safe
    end
    module_function :translate_nested
    private_class_method :translate_nested
  end
end
