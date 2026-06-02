# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-06-02

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v0.1.0...v2.0.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/releases/tag/v0.1.0
