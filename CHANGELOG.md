# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Point the Unreleased compare link at `v4.0.1...HEAD`.
- Replace leftover `gem_template` names in CI Postgres, RuboCop excludes, and GitHub agent docs.
- Set gemspec authors to Bowerbird.
- Align optional API docs with this gem's RecordingStudio `>= 6.1.0` requirement. Admin is not a Moveable dependency.
- Remove stale `UPDATE_SUMMARY.md`.

## [4.0.2] - 2026-10-28

### Changed
- The move screen's Change control is `FlatPack::Button::Component` (`text:`, `href:`, `style: :ghost`, `size: :sm`) instead of a raw `link_to`. Label, destination, and authorization are unchanged.

### Upgrade Notes
- Install Moveable `4.0.2`. No migration. The Change link is now a FlatPack ghost/sm button, so the control looks different. Hosts that restyle the old Change `link_to` CSS should target `.fp-button`.

## [4.0.1] - 2026-10-28

### Fixed
- OAuth-driven API moves stamp `authorized_by_type` and `authorized_by_id` on the `moved` event when the API action context provides `with_authorized_by`. API-key and client-credentials calls stay on the existing `api_action` / `api_client_id` / `api_credential_id` metadata. Contexts without the helper are unchanged.

### Upgrade Notes
- Install Moveable `4.0.1`. No migration. Hosts on RecordingStudio API `0.16.0` or later get the OAuth authorizer on move events. Older API contexts and API-key writes keep the previous metadata.

## [4.0.0] - 2026-10-27

### Breaking
- Require `recording_studio` `>= 6.1.0` and `flat_pack` `>= 0.1.315`. Development and the dummy pin RecordingStudio tag `v6.1.0` and FlatPack commit `1fcbafe94f8eb118f0a22182f63f5110fcc97a56` (`FlatPack::VERSION` `0.1.319`). The newest FlatPack tag is `v0.1.315`.
- Require `view_component` `>= 4.14`, `< 5`. The lock is `4.19.0`.
- Remove `RecordingStudioMoveable.configuration.full_page_layout`. Full-page screens use `config.layout`, which defaults to `nil`.
- Remove `RecordingStudio::UsesDefaultLayout` and hard-coded `layout "recording_studio/default_layout"`. Controllers call `recording_studio_layout { RecordingStudioMoveable.configuration.layout }`.
- Remove `recording_studio_page_nav` and inline page titles on full-page move screens. The default layout renders one `FlatPack::PageTitle` from `content_for :title` and `content_for :subtitle`. Back uses `flat_pack_page_nav`. Modal responses still render the title inside the dialog and use `layout: false`.

### Upgrade Notes
- Install Moveable `4.0.0` with RecordingStudio `v6.1.0` and FlatPack `>= 0.1.315` (this repo pins commit `1fcbafe` for `0.1.319`). `flat_pack` is git-only.
- Delete `config.full_page_layout`. Set `config.layout` only when this gem should use a different layout than `RecordingStudio.configuration.layout`. `nil` falls through to that setting, then `"recording_studio/default_layout"`. `false` skips the layout. A callable must be `->(controller:) { ... }` and return a String, `nil`, or `false`.
- Replace `recording_studio_page_nav` with `flat_pack_page_nav(round: true, style: :default, back_href:, back_tooltip:, anchor_href:, anchor_tooltip:)`. Register page actions with `register_page_nav`. Put the visible title in `content_for :title` so the layout renders one `<h1>`.
- `Card` no longer accepts `style:`. Use `background:`, `border:`, and `shadow:`.
- Accessible `v0.21.0`, Metrics `v0.6.1`, Trashable `v0.11.0`, and Internationalization `v0.1.7` still require `recording_studio` below 5. This repo loads `test/support/widen_recording_studio_requirement.rb` so Bundler can resolve `6.1.0`. Trashable `v0.12.0` already allows `>= 6.1.0`.
- Accessible `v0.18.0` manage screens do not render on FlatPack `0.1.319`. `user_invites.html.erb` passes `style:` to Card. `recording_accesses/index.html.erb` and `_form.html.erb` pass `anchor_href:` to `FlatPack::PageNav::Component`. `v0.21.0` and main `98e68a45` still pass `style: :default` to Card in `user_invites.html.erb`. Move behavior is unchanged. Same-root and descendant rules, `RecordingStudio.assert_parent_allowed!`, the hierarchy transaction, both authorization modes, and the 404 for an inaccessible source stay as they are.

## [3.4.0] - 2026-10-13

### Added
- Always-loaded dummy boot-order host override on the rarely shown `errors.destination_not_allowed` key (`test/dummy/config/locales/recording_studio_moveable_host.en.yml`), with a real-page flash assertion. Default move chrome stays on gem English.
- English controller-level coverage that a legacy `recording_studio_moveable.moveables.update.notice` host override still wins for the success flash.
- Locale regression: a locale with no key and no fallbacks returns the same `Translation missing: ...` string from `Copy.t` as from `I18n.t` (no injected English defaults).

### Changed
- `test_rails_i18n_load_path_includes_the_gem_english_locale_file` is a real `lib/**/*.rb` scan for `i18n.load_path` / `I18n.load_path` (it previously set the load path and then asserted inclusion).

### Upgrade Notes
- Install Moveable `3.4.0`. No migration. Host overrides of `recording_studio.moveable.*` and the legacy notice key keep working. Copy nested keys into host locale files for other languages. English output is unchanged from `3.3.x`. `Copy.t` still surfaces I18n “Translation missing” when a key is absent and no fallbacks are configured.

## [3.3.0] - 2026-10-09

### Added
- Host English override coverage: test-only fixture `test/dummy/test/locales/host_override.en.yml` plus an integration test that appends it last to `I18n.load_path`, reloads, asserts a nested `recording_studio.moveable.*` key wins on a real move modal, then restores the load path. The default dummy UI stays on gem English.
- Locale regression: every `lib/**/*.rb` file must not mention `i18n.load_path` / `I18n.load_path`; layout title / `application-name` meta pass an English `default:` so non-HTML surfaces never emit “Translation missing”.

### Changed
- Document the deprecated legacy flash key `recording_studio_moveable.moveables.update.notice` and that hosts override by defining the same nested keys in their own `config/locales` (the engine does not re-append its locales).

### Upgrade Notes
- Install Moveable `3.3.0`. No migration. Host overrides of `recording_studio.moveable.*` and the legacy notice key keep working. Copy nested keys into host locale files for other languages.

## [3.2.0] - 2026-10-08

### Added
- When `use_builtin_access` is true and a host sets `authorization_hook`, the hook runs first: `true` allows, `false` denies, `nil` falls through to the existing Accessible `:edit` checks on source and destination. The move UI and `authorize_move!` share this order.

### Upgrade Notes
- Install Moveable `3.2.0`. No migration. Hosts that leave the hook unset keep built-in-only behavior. Hosts that set `use_builtin_access = false` still let the hook decide alone.

## [3.1.0] - 2026-10-08

### Added
- Customer move-dialog, flash, helper, and user-facing error copy uses Rails I18n under `recording_studio.moveable.*`. The gem ships English only in `config/locales/en.yml`.
- Dummy app adds Recording Studio Internationalization (dummy only) with a French locale file covering every engine key.

### Changed
- Success flash key moves from `recording_studio_moveable.moveables.update.notice` to `recording_studio.moveable.flashes.moved`. A host override of the old key still wins.
- Dummy pins FlatPack `v0.1.209`. Destination and workspace pickers pass `empty_text` so I18n empty-state copy shows.
- Pin development and dummy bundles to RecordingStudio `v4.2.2` / tag `v4.3.0`.
- Pin development and dummy bundles to RecordingStudioAccessible `v0.11.1`.
- Upgrade the dummy app to Accessible `0.11`: string `role` values, `depends_on_recording_id`, access invitations, first-owner `bootstrap_owner_access!`, and later grants through `RecordingStudioAccessible.grant_access`.

### Upgrade Notes
- Install Moveable `3.1.0`. No migration. This is a minor release: the old notice key still works as a fallback, so hosts that overrode it are not silently broken.
- Copy `recording_studio.moveable.*` into host locale files for other languages.
- Helper override `recording_studio_moveable_root_label` and host I18n overrides still win over locale defaults.
- Recording and folder names stay data and are not translated.
- Support's HEAD gemspec pins `recording_studio_moveable ~> 3.0`, which includes `3.1.0` (`>= 3.0` and `< 4.0`). It does not exclude this version.

## [3.0.1] - 2026-09-02

Cloud Agent Builds match RecordingStudio_billing v0.9.13.

### Added
- Tracked `.cursor/` boot files: `environment.json`, `install.sh`, `fetch-skills.sh`, and `start.sh`.
- `test/cursor_install_test.rb` plus a dummy boot-files test that environment terminals point at `test/dummy`.
- [Cursor skills in Cloud Agents](docs/cursor-skills.md).

### Upgrade Notes
- No host or schema changes. Rebuild the Cloud Agent environment with Draft off so Build loads the pack.

## [3.0.0] - 2026-08-21

### Breaking
- Require RecordingStudio `~> 4.2` and RecordingStudioAccessible `~> 0.6`, dropping compatibility with RecordingStudio 3.x / Accessible 0.3–0.5.
- Host apps enable Moveable with keyword-only `RecordingStudio::Capabilities::Moveable.to(allow_cross_root: ...)`, which wraps `RecordingStudio::Capabilities.include_for(:movable, **options)`.
- Positional destination types on `.to` still raise. `.enabled` is now an alias of `.to`.
- Host apps must install RecordingStudio 4's harden / unique-root indexes and configure Accessible `access_actor_types` before granting access.

### Changed
- Pin development and dummy bundles to RecordingStudio `v4.2.0`, Accessible `v0.6.0`, and FlatPack `v0.1.129`.
- Dummy Tailwind `@source` globs scan vendored Flatpack and RecordingStudio templates so demo CSS compiles.
- Default full-page move screens to RecordingStudio's `recording_studio/default_layout`.
- Defer the optional RecordingStudio API dummy integration until that gem declares RecordingStudio `~> 4.2`. The Moveable API adapter remains and still registers when the API engine is loaded.

### Upgrade Notes
- See [docs/recording_studio_moveable/UPGRADING.md](docs/recording_studio_moveable/UPGRADING.md) for the RecordingStudio 4.2 path.
- Stay on Moveable `2.1.x` while remaining on RecordingStudio 3.

## [2.1.1] - 2026-08-05

### Changed
- Upgrade the dummy application and optional integration documentation to RecordingStudio API 0.2.0.
- Use RecordingStudio API's gem-owned, authenticated Scalar documentation surface in the dummy application.
- Register Moveable's action independently on public and named API 0.2.0 surfaces and filter named-route keys.

## [2.1.0] - 2026-07-29

### Added
- Optional `RecordingStudio::Moveable::API` integration that registers a move action for RecordingStudio API clients.
- API action documentation and dummy application coverage, including Scalar API reference navigation.

## [2.0.0] - 2026-06-05

### Breaking
- Require RecordingStudio `~> 3.0` and RecordingStudioAccessible `~> 0.3`, dropping compatibility with RecordingStudio 2.x.

### Changed
- Replace legacy Accessible child setup with RecordingStudio 3 capability enablement.
- Use `RecordingStudioAccessible.grant_access` in dummy setup and tests.
- Update installation, configuration, and upgrade documentation for RecordingStudio 3 capability setup.

## [1.0.0] - 2026-06-02

### Changed
- Require RecordingStudio core V2 and use core recordable hierarchy declarations for move parent validation.
- Replace `Moveable.to(...)` destination configuration with `Moveable.enabled(...)`.
- Use core root-recording helpers in dummy setup and move logic.

### Removed
- Removed Moveable-owned destination parent definitions from capability options.
- Removed support for positional destination arguments on `Moveable.to(...)` and `Movable.to(...)`.

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v4.0.2...HEAD
[4.0.2]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v4.0.1...v4.0.2
[3.4.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/3.1.0...3.2.0
[3.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/3.0.1...3.1.0
[3.0.1]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/2.1.1...3.0.0
[2.1.1]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v1.0.0...2.0.0
[1.0.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/releases/tag/v0.1.0
