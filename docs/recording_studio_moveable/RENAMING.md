> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_moveable](https://github.com/bowerbird-app/RecordingStudio_moveable/tree/main/docs/recording_studio_moveable)
> *   **Last Updated:** December 12, 2025
>
> *Maintainers: Please update the date above when modifying this file.*

---

# Rename History

This repository started from a generic Rails engine template and has now been fully cut over to the `RecordingStudioMoveable` namespace.

## Current State

- Runtime code, generators, routes, and tests now use `RecordingStudioMoveable` and `recording_studio_moveable`.
- The old template compatibility files have been removed.
- Rename verification is expected to pass as part of normal maintenance.

## Why This File Exists

The repository still includes `bin/rename_gem`, but it is no longer part of the normal workflow for this addon. This document exists only to explain why older commits or historical notes may mention the template origin.

## If You Fork This Repository

If you intentionally want to repurpose this repository as a different gem, review `bin/rename_gem` and `test/rename_verification_test.rb` first, then run the rename in a clean working tree and rerun the full test suite.
