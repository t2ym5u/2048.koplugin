# Changelog

All notable changes to this project will be documented in this file.

Reconstructed from this repository's git history: each release lists the
feature and fix commits it carried. Version bumps, screenshot additions
and CI syncs are left out.

## [1.2.0] - 2026-10-30

### Changed
- Redesigned play screen. The board fills the room the title bar and controls
  leave, with one edge instead of the frame's second outline around its own
  grey background, and the four small arrow buttons became a full-width action
  bar.
- The status line reads "4×4 · Score: … · Best: …" and wraps in landscape
  instead of being cut off. The "Max" part is gone: the board already shows
  the largest tile.
- The size entry in the title-bar menu reads "Size: 4×4" instead of a bare
  "4×4".
- Once the board is stuck, the action bar shows New game and Undo in place of
  the arrows, so the next round (or taking back the losing move) no longer
  needs the menu.
- The rules mention the arrow buttons as well as swiping.

### Fixed
- Tile numbers overflowed their tiles on high-DPI screens: their size was a
  fixed fraction of the tile, which `Font:getFace()` then scaled again by DPI.
  Each digit count now gets the largest size that fits, including a smaller
  one for five-digit tiles (65536), and the "Game over" banner is fitted the
  same way.

## [1.1.16] - 2026-10-07

### Fixed
- The Tools menu entry is translated again. `main.lua` took `_` from
  KOReader's `gettext`, which knows nothing of this plugin's strings, so the
  menu label stayed English while the game's own screen, which goes through
  `i18n`, was translated. `_` now comes from `i18n` here too.


## [1.1.15] - 2026-10-01

### Fixed
- Picks up game-common v1.5.0. Play statistics were recorded under a key no
  tool could match: `ReaderUI`/`FileManager:registerModule()` rewrite a plugin
  instance's `name` to `reader<id>` / `filemanager<id>` right after it is
  built, so this game's sessions were split across two rows and neither
  carried its plugin id. Rows written under the old keys are merged back on
  first read. The same release brings the `stopPlugin()` /
  `deletePluginSettings()` hooks KOReader 2026.07 calls when a plugin is
  deleted from the device (PR #15240).

  No change to this plugin's own code -- it inherits all of it from the
  shared library.

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
