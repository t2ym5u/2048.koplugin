# 2048.koplugin

A 2048 plugin for [KOReader](https://github.com/koreader/koreader).


## Screenshot

*(Screenshot to be added.)*

## Rules

Slide all tiles in one direction. When two tiles with the same number collide they merge and double in value. A new tile (2 or 4) appears after each move. Reach **2048** to win — but keep going for a higher score! The game ends when no more moves are possible.

## Concept

Slide numbered tiles on a 4×4 grid. When two tiles with the same number collide
they merge into one tile with their sum. Reach the 2048 tile to win — or keep
going for a higher score!

## Features

- **Classic 4×4 grid** with optional 5×5 and 6×6 variants
- **Swipe or button controls** — swipe in any direction or use on-screen arrow buttons
- **Score and best score** — current score and all-time high score
- **Undo** — take back the last slide
- **Animations** — minimal slide animation compatible with partial e-ink refresh
- **Continue after 2048** — keep playing past the winning tile
- **Auto-save** — board state and score saved automatically

## Controls

| Action | How |
|--------|-----|
| Slide tiles | Swipe left / right / up / down |
| Slide tiles (alternative) | Tap directional arrow buttons |
| Undo last move | Tap **Undo** |
| New game | Tap **New game** |
| Change grid size | Tap **Grid** |
| Show rules | Tap **Rules** |

## Why e-ink friendly?

Each move is a single swipe that shifts all tiles at once — very few screen
updates per interaction. The partial-refresh mode of modern e-ink panels handles
the simple tile-slide animation without ghosting.

## License

GPL-3.0
