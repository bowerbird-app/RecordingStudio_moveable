# RecordingStudio Moveable 3.0.0 Release Notes

Released: August 21, 2026

## Summary

`3.0.0` pins Moveable to RecordingStudio 4.2.0 and converts enablement to core's `include_for` factory. Hosts opt each recordable in with one keyword-only verb.

## Breaking Changes

- Require `recording_studio ~> 4.2`.
- Require `recording_studio_accessible ~> 0.6`.
- Enable Moveable with `include RecordingStudio::Capabilities::Moveable.to(allow_cross_root: true)`.
- Drop compatibility with RecordingStudio 3.x applications.

## Key Changes

- `.to` wraps `RecordingStudio::Capabilities.include_for(:movable, **options)`.
- `.enabled` aliases `.to`.
- Positional destination types still raise.
- Installing the gem registers `:movable` but does not enable it.
- Full-page move screens use RecordingStudio's default layout.

## Upgrade Notes

- Host apps must upgrade to RecordingStudio 4.2 before adopting this release.
- Configure Accessible `access_actor_types` before granting access.
- Stay on Moveable `2.1.x` while remaining on RecordingStudio 3.
- See [docs/recording_studio_moveable/UPGRADING.md](docs/recording_studio_moveable/UPGRADING.md).
