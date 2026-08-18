# Upgrading RecordingStudio Moveable

## Upgrading to Moveable 3.0 / RecordingStudio 4

Moveable 3.0 requires RecordingStudio `~> 4.0` and Accessible `~> 0.6`. Move behavior itself is unchanged: destination parent types still come from core declarations, and Moveable still owns same-root / cross-root rules, authorization, UI, and move event logging.

### Dependency bump

```ruby
gem "recording_studio", "~> 4.0"
gem "recording_studio_accessible", "~> 0.6"
gem "recording_studio_moveable", "~> 3.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.132"
```

Stay on Moveable `2.1.x` if the host must remain on RecordingStudio 3.

### RecordingStudio 4 host steps

1. Run `bin/rails generate recording_studio:migrations` and `bin/rails db:migrate` so the harden / unique-root indexes are installed.
2. Replace any reliance on Recording's old implicit newest-first order with `.recent` or an explicit `order:`.
3. Keep Event history append-only; use SQL `delete_all` for intentional purges.
4. Configure Accessible actor allowlisting before creating new grants:

```ruby
RecordingStudioAccessible.configure do |config|
  config.access_actor_types = ["User"]
end
```

### Optional API

Moveable still registers an optional `move` action when `recording_studio_api` is present. Re-enable that engine in host apps only after API declares RecordingStudio `~> 4.0`. Until then, keep Moveable UI and Accessible authorization as the supported path.

### FlatPack notes

Hosts on FlatPack `0.1.132+` should use:

- `FlatPack::Sidebar::Item::Component` with `text:` (not `label:`)
- `FlatPack::PageNav::Component` with `secondary_anchor_href:` / `anchor_href:` (not `anchor_url:`)

---

# Upgrading RecordingStudio Moveable for RecordingStudio 3

The RecordingStudio Moveable 2.x line targets RecordingStudio core V3. Moveable no longer defines destination parent types.

## What changed

- RecordingStudio core owns structural hierarchy through `recording_studio_recordable`.
- Moveable owns move behavior, cross-root opt-in, self/descendant protection, authorization integration, destination UI, and move event logging.
- Destination UI uses core allowed-parent declarations, then applies Moveable same-root/cross-root rules, self/descendant protection, and authorization filtering.
- The move write path calls `RecordingStudio.assert_parent_allowed!`, so core hierarchy validation is enforced before hierarchy fields are updated.
- Root recordables should be created through `RecordingStudio.root_recording_for(recordable)`.

## Replace `Moveable.to(...)`

Before:

```ruby
class RecordingStudioPage < ApplicationRecord
  include RecordingStudio::Capabilities::Moveable.to(
    "Workspace",
    "RecordingStudioFolder",
    allow_cross_root: true
  )
end
```

After:

```ruby
class RecordingStudioPage < ApplicationRecord
  recording_studio_recordable \
    label: "Page",
    root: false,
    allowed_parent_types: ["Workspace", "RecordingStudioFolder"]

  include RecordingStudio::Capabilities::Moveable.enabled(allow_cross_root: true)
end
```

`allow_cross_root:` remains Moveable-specific. Destination and parent types must be declared only in core `recording_studio_recordable allowed_parent_types:`.

## Root declarations

Apps must define declarations for every configured recordable type:

```ruby
class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true, allowed_parent_types: []

  RecordingStudio.enable_capability(:accessible, on: self)
end
```

Create or find root recordings with:

```ruby
RecordingStudio.root_recording_for(workspace)
```

Do not bypass core root eligibility with direct `RecordingStudio::Recording.create!` calls for root recordables.

## Removed API

These calls are no longer supported:

```ruby
include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder")
include RecordingStudio::Capabilities::Moveable.to("Workspace", "RecordingStudioFolder", allow_cross_root: true)
include RecordingStudio::Capabilities::Movable.to("Workspace", "RecordingStudioFolder")
```

If `.to` is present, it raises an `ArgumentError` explaining that destination parent types moved to core declarations and callers should use `Moveable.enabled(...)`.
