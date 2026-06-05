# RecordingStudio Moveable Addon

`RecordingStudio_moveable` extracts move behavior from legacy RecordingStudio built-ins into an addon-owned implementation.

## What this addon provides

- Addon-owned capability module with addon-facing naming:
  - `RecordingStudio::Capabilities::Moveable.enabled(...)` (preferred)
  - `RecordingStudio::Capabilities::Movable.enabled(...)` (compat alias)
- `move_to!` behavior equivalent to legacy `movable` behavior:
  - remains in the same root by default
  - can transfer across roots when `allow_cross_root: true`
  - cannot move under itself or descendants
  - destination parent rules come from RecordingStudio core recordable declarations
  - logs event metadata with parent ids and root ids
  - supports `actor`, optional `impersonator`, optional `metadata`
- Authorization modes:
  - **Built-in mode (default):** uses `recording_studio_accessible` public access API to resolve roles and direct grants, and raises `RecordingStudio::AccessDenied` on failures
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
gem "recording_studio", "~> 3.0"
gem "recording_studio_accessible", "~> 0.3"
gem "recording_studio_moveable"
gem "flat_pack", github: "bowerbird-app/flatpack"
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

  include RecordingStudio::Capabilities::Moveable.enabled
end

class RecordingStudioPage < ApplicationRecord
  recording_studio_recordable \
    label: "Page",
    root: false,
    allowed_parent_types: ["Workspace", "RecordingStudioFolder"]

  include RecordingStudio::Capabilities::Moveable.enabled(allow_cross_root: true)
end
```

Moveable no longer owns destination type definitions. Set `allow_cross_root: true` only for recordables that should be transferable between workspace roots; same-root moves remain the default.

`Moveable.to(...)` and `Movable.to(...)` are no longer supported. If present, they raise an `ArgumentError` that directs callers to core `recording_studio_recordable allowed_parent_types:` declarations and `Moveable.enabled(...)`.

### Migration note from legacy built-in gate

This addon registers `:movable` without a legacy feature gate so it can continue working even when legacy move built-in is disabled.

## Authorization configuration

### Default (built-in) mode

Install `recording_studio_accessible` and enable the `:accessible` capability on root recordables. In this mode:

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

### Custom authorization hook mode

```ruby
RecordingStudio::Moveable.configure do |config|
  config.use_builtin_access = false
  config.authorization_hook = lambda do |actor:, source:, destination:, impersonator:, metadata:|
    actor.present? && source.root_recording_id == destination.root_recording_id
  end
end
```

If your hook returns false, move is denied with `RecordingStudio::AccessDenied`.

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

## Dummy app demo

The dummy app explicitly installs both `recording_studio_accessible` and `recording_studio_moveable`. It includes:

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
