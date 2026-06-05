# RecordingStudio Moveable 2.0.0 Release Notes

Released: June 5, 2026

## Summary

`2.0.0` updates `recording_studio_moveable` for the RecordingStudio 3 ecosystem. This release aligns the gem with RecordingStudio `~> 3.0`, updates Accessible integration for the current capability model, and refreshes the installation and upgrade guidance to match the new setup.

## Breaking Changes

- Require `recording_studio ~> 3.0`.
- Require `recording_studio_accessible ~> 0.3`.
- Drop compatibility with RecordingStudio 2.x applications.

## Key Changes

- Replace legacy Accessible child setup with RecordingStudio 3 capability enablement.
- Use `RecordingStudioAccessible.grant_access` in dummy setup and tests.
- Keep move destination filtering and `move_to!` aligned with RecordingStudio core parent APIs.
- Update README, installation, configuration, and upgrade docs for RecordingStudio 3 setup.

## Upgrade Notes

- Host apps must upgrade to RecordingStudio 3 before adopting this release.
- Existing Accessible setup should move to the RecordingStudio 3 capability-based API.
- No new runtime dependency was added on `recording_studio_root_switchable`; Moveable remains independent of root-switching state.
