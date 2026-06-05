# Upgrading RecordingStudio Moveable for RecordingStudio 3

The next RecordingStudio Moveable compatibility release targets RecordingStudio core V3. Moveable no longer defines destination parent types.

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
