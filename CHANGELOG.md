# Changelog

All notable changes to this project will be documented in this file.

Reconstructed from this repository's git history: each release lists the
feature and fix commits it carried. Version bumps, screenshot additions
and CI syncs are left out.

## [1.1.14] - 2026-08-05

### Added
- Add ES and DE translations

### Changed
- Add screenshot to README
- Add issue/PR templates and CONTRIBUTING.md

## [1.1.13] - 2026-08-04

### Changed
- Symlink common/ to shared game-common

## [1.1.11] - 2026-07-29

### Fixed
- Drop deprecated name field from _meta.lua

## [1.1.10] - 2026-07-29

### Fixed
- Keep score centered under board across width changes

## [1.1.8] - 2026-07-28

### Changed
- Add GPL-3.0 LICENSE

## [1.1.5] - 2026-07-21

### Added
- Own translations locally instead of via game-common

## [1.1.3] - 2026-07-15

### Added
- Adopt TitleBar header, sync common/ with game-common

## [1.1.2] - 2026-07-13

### Fixed
- OnBoardSwipe gesture arg was nil (crash on swipe) (v1.1.2)

## [1.1.1] - 2026-07-10

### Changed
- Remove ../game-common/ fallback from package.path

### Fixed
- Gesture tap detection (GestureRange range function)

## [1.1.0] - 2026-07-08

### Added
- I18n FR/EN translation + bump to 1.1.0
