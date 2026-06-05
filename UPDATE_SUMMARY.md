# RecordingStudio 3 Compatibility Update Summary

## Update Completed: June 5, 2026

### Changes Made

#### 1. RecordingStudio ecosystem dependencies updated
- `recording_studio` now targets `~> 3.0` and the tagged release `recording_studio/v3.0.0` in development lockfiles.
- `recording_studio_accessible` now targets `~> 0.3` and the tagged release `0.3.1` in development lockfiles.
- `recording_studio_root_switchable` was not added as a runtime dependency; Moveable remains independent of root-switching state.

#### 2. Accessible setup updated
- Root recordables now enable direct access grants with `RecordingStudio.enable_capability(:accessible, on: self)`.
- Legacy Accessible child setup usage has been removed.
- Dummy app grants now use `RecordingStudioAccessible.grant_access` instead of lower-level service constants.

#### 3. RecordingStudio 3 hierarchy compatibility retained
- Dummy app recordables continue to declare `recording_studio_recordable` hierarchy metadata.
- Moveable destination filtering and `move_to!` continue to use RecordingStudio core parent APIs.

#### 4. Documentation updated
- README, install docs, upgrade docs, generated install notes, and configuration docs now describe RecordingStudio 3 / Accessible 0.3 setup.

### Breaking Changes

This update is a breaking compatibility change for applications still on RecordingStudio 2.x because `recording_studio_moveable` now requires RecordingStudio `~> 3.0` and RecordingStudioAccessible `~> 0.3`.

### Release Classification

Expected release classification: **major**. The breaking-change signal should be preserved in merge/PR metadata because this repository uses automatic versioning on merges to `main`.
