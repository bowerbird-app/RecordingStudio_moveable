# RecordingStudio Moveable Addon

`RecordingStudio_moveable` extracts move behavior from legacy RecordingStudio built-ins into an addon-owned implementation.

## What this addon provides

- Addon-owned capability module with addon-facing naming:
  - `RecordingStudio::Capabilities::Moveable.to(allow_cross_root: ...)` (host verb)
  - `RecordingStudio::Capabilities::Moveable.enabled(...)` (alias of `.to`)
  - `RecordingStudio::Capabilities::Movable.to(...)` (compat alias)
- `move_to!` behavior equivalent to legacy `movable` behavior:
  - remains in the same root by default
  - can transfer across roots when `allow_cross_root: true`
  - cannot move under itself or descendants
  - destination parent rules come from RecordingStudio core recordable declarations
  - logs event metadata with parent ids and root ids
  - supports `actor`, optional `impersonator`, optional `metadata`
- Authorization modes:
  - **Built-in mode (default):** uses `recording_studio_accessible` public access API to resolve roles and direct grants, and raises `RecordingStudio::AccessDenied` on failures
  - **Optional hook with built-in fallback:** keep built-in mode on and set `authorization_hook`; `true` allows, `false` denies, `nil` falls through to the Accessible `:edit` checks
  - **Custom hook mode:** disable built-in mode and provide your own `authorization_hook`
- Gem-provided reusable move UI:
  - full-page mode
  - modal mode
  - destination picker powered by `FlatPack::Picker::Component`
  - only shows destinations that pass core parent rules, Moveable same-root/cross-root rules, self/descendant protection, and authorization
  - returns not found for inaccessible source recordings
  - move action redirects to root page with success flash

## Installation

Add to your Gemfile:

```ruby
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.6"
gem "recording_studio_moveable"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.209"
```

Then bundle install and mount the moveable engine UI routes:

```ruby
# config/routes.rb
mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable", as: :recording_studio_moveable
```

Add the engine JavaScript to your app entrypoint so modal links work out of the box:

```js
import "recording_studio_moveable"
```

## Capability usage

Define structural parent rules with RecordingStudio core, then include the Moveable capability on recordable models:

```ruby
class RecordingStudioFolder < ApplicationRecord
  recording_studio_recordable \
    label: "Folder",
    root: false,
    allowed_parent_types: ["Workspace", "RecordingStudioFolder"]

  include RecordingStudio::Capabilities::Moveable.to
end

class RecordingStudioPage < ApplicationRecord
  recording_studio_recordable \
    label: "Page",
    root: false,
    allowed_parent_types: ["Workspace", "RecordingStudioFolder"]

  include RecordingStudio::Capabilities::Moveable.to(allow_cross_root: true)
end
```

Moveable no longer owns destination type definitions. Set `allow_cross_root: true` only for recordables that should be transferable between workspace roots; same-root moves remain the default.

`.to` is keyword-only and wraps `RecordingStudio::Capabilities.include_for(:movable, **options)`. Installing the gem registers `:movable` but does not enable it on any recordable type. Parent rules stay on `recording_studio_recordable`. Positional destination types still raise.

`.enabled(...)` remains as an alias of `.to`. Keep using `.to` in host apps.

### Migration note from legacy built-in gate

This addon registers `:movable` without a legacy feature gate so it can continue working even when legacy move built-in is disabled.

## Authorization configuration

### Default (built-in) mode

Install `recording_studio_accessible` `~> 0.6` and enable the Accessible capability on root recordables that should accept direct access grants. In this mode:

- source requires `:edit`
- destination requires `:edit`
- move UI source visibility requires `:edit`
- move UI only lists destinations the actor can move into
- failures raise `RecordingStudio::AccessDenied`

Under the hood, move authorization is resolved through `RecordingStudioAccessible.authorized?`, `RecordingStudioAccessible.role_for`, and related public access helpers. The dummy app uses `RecordingStudioAccessible.grant_access` for seeding and management flows.

Example root recordable setup:

```ruby
class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true, allowed_parent_types: []

  RecordingStudio.enable_capability(:accessible, on: self)
end
```

If your app is adopting the extracted access addon directly, run the accessible setup as part of installation:

```bash
bin/rails generate recording_studio_accessible:install
bin/rails generate recording_studio_accessible:migrations
bin/rails db:migrate
```

Mount `RecordingStudioAccessible::Engine` as well if you want the addon-owned access management pages in your host app. On current `recording_studio` releases that still ship access tables/constants, `recording_studio_accessible` runs in compatibility mode, so your existing access migrations may already satisfy the database setup. In that setup, runtime authorization still flows through the Accessible gem's public APIs rather than legacy `recording_studio` access-check helpers.

Move screens read the acting principal from `Current.actor` by default. If your host app uses a different controller-level source, configure it explicitly:

```ruby
RecordingStudioMoveable.configure do |config|
  config.current_actor_resolver = ->(controller:) { controller.current_user }
end
```

### Authorization hook with built-in fallback

Keep `use_builtin_access = true` and set `authorization_hook` when a host rule should allow or deny a move before Accessible `:edit` is checked. Return `true` to allow without tree access, `false` to deny even when the actor has `:edit`, or `nil` to use the built-in source and destination edit checks. The move UI (`source_editable?`, `destination_selectable?`) and `authorize_move!` share this order.

```ruby
RecordingStudio::Moveable.configure do |config|
  config.use_builtin_access = true
  config.authorization_hook = lambda do |actor:, source:, destination:, impersonator:, metadata:|
    next true if actor.respond_to?(:staff?) && actor.staff? && actor.allowed_to?(:edit)
    next false if actor.blank?
    nil
  end
end
```

### Custom authorization hook mode

`recording_studio_accessible` remains a runtime dependency of this gem. Custom hook mode disables Moveable's built-in Accessible authorization checks for move decisions.

```ruby
RecordingStudio::Moveable.configure do |config|
  config.use_builtin_access = false
  config.authorization_hook = lambda do |actor:, source:, destination:, impersonator:, metadata:|
    next false if actor.blank?

    AppMovePolicy.new(actor, impersonator: impersonator).allowed?(source: source, destination: destination, metadata: metadata)
  end
end
```

If your hook returns false, move is denied with `RecordingStudio::AccessDenied`.
Your hook must enforce your application's source and destination permissions. Structural checks such as same-root comparisons are useful isolation rules, but they are not a substitute for authorization.

The same authorization layer is also used by the move UI. In custom hook mode:

- the source recording must pass the hook before the move screen is rendered
- each listed destination must pass the hook
- the source and each descendant must pass the hook before a subtree move is persisted
- inaccessible source recordings return not found instead of rendering the move screen

Metadata submitted through the public move UI is namespaced under `client_metadata`.
Treat those values as untrusted request input in custom authorization hooks.

## UI usage examples

### Full page

```erb
<%= link_to "Move", recording_studio_moveable.move_recording_path(recording_id: recording.id) %>
```

### Modal mode

```erb
<%= link_to "Move", recording_studio_moveable.move_recording_path(recording_id: recording.id), data: { recording_studio_moveable_modal: true } %>
```

The modal shell is rendered on demand by the gem. Host pages do not need to preload a FlatPack modal container.

## Move UI access rules

The addon enforces access checks inside the gem-owned move controller.

- The move screen only renders when the current actor can access the source recording under the addon authorization policy.
- Inaccessible sources return not found so the UI does not disclose record titles or available actions.
- Destination lists are filtered through the same gem authorization layer that protects `move_to!`.
- Destination lists also use `RecordingStudio.allowed_parent_types_for` and `RecordingStudio.parent_allowed?`, so the picker never offers destinations core hierarchy validation would reject.
- The write path still re-checks authorization inside `move_to!`; UI filtering is not the only enforcement layer.
- The write path calls `RecordingStudio.assert_parent_allowed!` before updating hierarchy.

## Internationalization

The gem ships **English only** in `config/locales/en.yml`. Keys nest under `recording_studio.moveable.*`:

```ruby
t("recording_studio.moveable.dialog.title", name: "Lyric Draft")
t("recording_studio.moveable.flashes.moved")
t("recording_studio.moveable.errors.destination_not_allowed")
```

Hosts own other languages. Copy `recording_studio.moveable.*` into `config/locales/<locale>.yml` and list that locale in `config.i18n.available_locales`. Hosts override gem English by defining the same keys in their own `config/locales`. The engine does not append its own `i18n.load_path`. Do not add `RecordingStudio_Internationalization` as a dependency of this gem — it is optional on the host (the dummy uses it to switch English/French).

**Deprecated:** `recording_studio_moveable.moveables.update.notice`. A host override of that legacy key still wins for the success flash. New hosts should set `recording_studio.moveable.flashes.moved`. The gem does not ship English under the legacy namespace.

`recording_studio_moveable_root_label` and any host I18n override still win over locale defaults. Stored names stay data: recording titles, folder names, and workspace names are not translated.

Engine demo/docs pages, generator text, API action developer errors (`parent_id is required for move`, destination-not-found in API scope, move-not-supported for a type), and capability setup errors stay English.

Add [Recording Studio Internationalization](https://github.com/bowerbird-app/RecordingStudio_Internationalization) on the host when you want a language selector.

## Dummy app demo

The dummy app explicitly installs `recording_studio` `~> 4.2` (tag `v4.3.0`), `recording_studio_accessible` (tag `v0.11.1`), and `recording_studio_moveable`. Hosts still depend on Accessible `~> 0.6`. The dummy itself is on Accessible `0.11`, so its schema stores access `role` as a string (`view` / `edit` / `admin`), keeps `depends_on_recording_id`, and has access invitations. Seeds and tests grant the first owner with `RecordingStudioAccessible.bootstrap_owner_access!` and later grants with `grant_access`. Dummy pins FlatPack `v0.1.209` and (dummy only) Recording Studio Internationalization `v0.1.2`. Dummy offers English and French. The language selector sits in the top nav, to the left of the workspace switcher. French keys live in `test/dummy/config/locales/fr.yml`. The engine does not ship French.

It includes:

- `Workspace` root recordable
- `RecordingStudioFolder` and `RecordingStudioPage` (move-enabled)
- `RecordingStudioArchiveBox` (child-only destination filtering demo)
- routes/controllers/views to demonstrate same-workspace and cross-workspace move flows
- Recording Studio Accessible integration for workspace discovery, access management pages, and seeded access grants

### Seed reset instructions

From `test/dummy`:

```bash
bin/rails db:prepare db:seed
```

Optional hard reset:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

Seeds are idempotent and create substantial folders/pages for destination search demos.

Dummy credentials (`test/dummy/config/credentials.yml.enc`) are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or put that key in `test/dummy/config/master.key` (gitignored). Keep the encrypted file; do not generate a per-repo dummy key.

## Cloud Agent boot

Cloud Agent Builds run `.cursor/install.sh`, then `.cursor/fetch-skills.sh`.
The install hook provisions a cold image. On a warm snapshot it skips apt,
ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are
already usable. If `RAILS_MASTER_KEY` is set, it writes gitignored
`test/dummy/config/master.key` so dummy credentials decrypt. Fetch-skills
always runs last. `.cursor/start.sh` starts PostgreSQL on each boot. Rebuild
with Draft off to load a new pack. See
[Cursor skills in Cloud Agents](docs/cursor-skills.md).

## Tests added

- capability behavior
  - allowed/disallowed destination
  - same-root enforcement
  - opt-in cross-root transfer with subtree root updates
  - self/descendant protection
  - move event metadata
- authorization modes
  - built-in access mode
  - custom hook mode
- UI behavior
  - full page and modal rendering
  - destination filtering
  - workspace picker flow for cross-root moves
  - move action redirect + flash
