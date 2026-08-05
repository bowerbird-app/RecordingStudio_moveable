# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.1] - 2026-08-05

### Changed
- Upgrade the dummy application and optional integration documentation to RecordingStudio API 0.2.0.
- Use RecordingStudio API's gem-owned, authenticated Scalar documentation surface in the dummy application.
- Register Moveable's action independently on public and named API 0.2.0 surfaces and filter named-route keys.

## [2.1.0] - 2026-07-29

### Added
- Optional `RecordingStudio::Moveable::API` integration that registers a move action for RecordingStudio API clients.
- API action documentation and dummy application coverage, including Scalar API reference navigation.

## [2.0.0] - 2026-06-05

### Breaking
- Require RecordingStudio `~> 3.0` and RecordingStudioAccessible `~> 0.3`, dropping compatibility with RecordingStudio 2.x.

### Changed
- Replace legacy Accessible child setup with RecordingStudio 3 capability enablement.
- Use `RecordingStudioAccessible.grant_access` in dummy setup and tests.
- Update installation, configuration, and upgrade documentation for RecordingStudio 3 capability setup.

## [1.0.0] - 2026-06-02

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/2.1.1...HEAD
[2.1.1]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v1.0.0...2.0.0
[1.0.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_moveable/releases/tag/v0.1.0
