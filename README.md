# RecordingStudio Moveable Addon

`RecordingStudio_moveable` extracts move behavior from legacy RecordingStudio built-ins into an addon-owned implementation.

## What this addon provides

- Addon-owned capability module with addon-facing naming:
  - `RecordingStudio::Capabilities::Moveable.to(*types)` (preferred)
  - `RecordingStudio::Capabilities::Movable.to(*types)` (compat alias)
- `move_to!` behavior equivalent to legacy `movable` behavior:
  - remains in the same root by default
  - can transfer across roots when `allow_cross_root: true`
  - cannot move under itself or descendants
  - destination type must be in `allowed_parent_types`
  - logs event metadata with parent ids and root ids
  - supports `actor`, optional `impersonator`, optional `metadata`
- Authorization modes:
  - **Built-in mode (default):** uses `RecordingStudio::Services::AccessCheck` and raises `RecordingStudio::AccessDenied` on failures
  - **Custom hook mode:** disable built-in mode and provide your own `authorization_hook`
- Gem-provided reusable move UI:
  - full-page mode
  - modal mode
  - destination picker powered by `FlatPack::Picker::Component`
  - only shows destinations that pass gem-owned move visibility checks
  - returns not found for inaccessible source recordings
  - move action redirects to root page with success flash

## Installation

Add to your Gemfile:

```ruby
gem "recording_studio_moveable"
gem "flat_pack", github: "bowerbird-app/flatpack"
```

Then bundle install and mount the engine UI routes:

```ruby
# config/routes.rb
mount RecordingStudioMoveable::Engine, at: "/recording_studio_moveable", as: :recording_studio_moveable
```

Add the engine JavaScript to your app entrypoint so modal links work out of the box:

```js
import "recording_studio_moveable"
```

## Capability usage

Include move capability on recordable models and define allowed parent types:

```ruby
class RecordingStudioFolder < ApplicationRecord
  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder")
end

class RecordingStudioPage < ApplicationRecord
  include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder", allow_cross_root: true)
end
```

Set `allow_cross_root: true` only for recordables that should be transferable between workspace roots.

### Migration note from legacy built-in gate

This addon registers `:movable` without a legacy feature gate so it can continue working even when legacy move built-in is disabled.

## Authorization configuration

### Default (built-in) mode

No extra setup required. In this mode:

- source requires `:edit`
- destination requires `:edit`
- move UI source visibility requires `:edit`
- move UI only lists destinations the actor can move into
- failures raise `RecordingStudio::AccessDenied`

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
- inaccessible source recordings return not found instead of rendering the move screen

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
- The write path still re-checks authorization inside `move_to!`; UI filtering is not the only enforcement layer.

## Dummy app demo

The dummy app includes:

- `Workspace` root recordable
- `RecordingStudioFolder` and `RecordingStudioPage` (move-enabled)
- `RecordingStudioArchiveBox` (disallowed destination type demo)
- routes/controllers/views to demonstrate same-workspace and cross-workspace move flows

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
