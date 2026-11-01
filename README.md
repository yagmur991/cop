# SAVE GAIA (Godot 4.x)

Platformer about collecting, sorting and recycling waste to save the planet.

1. Open `project.godot` with Godot 4.2+ and press F5.
2. Menu: New Game (difficulty -> intro -> character -> tutorial), Continue, How to Play, Options (language EN/TR, fullscreen), Credits.
3. Controls: A/D move, Space/W jump, J/X attack, B inventory, Esc pause.
4. Take each trash type (glass, metal, paper, plastic) to the matching bin; when all bins are full the boss gate opens.
5. The game auto-saves at every level start and before/after every boss (Continue loads the last save).

## Sprites
- Recycling bin sprites: `assets/<Type>RecycleBin-Sheet.png` (Plastic included; Glass, Metal, Paper are picked up automatically when added).
- Everything else is drawn in code; replace `_draw()` with `Sprite2D` when art is ready.
- Translations live in `scripts/loc.gd` (English / Turkish).

## Levels

| # | Card | Theme | Boss |
|---|------|-------|------|
| 1 | Save the Sea | ocean + plastic pollution | Plastic boss |
| 2 | Save the Air | factories, smoke, carbon | Factory boss |
| 3 | Save the Land | farmland vs. landfill | Landfill Titan (final, 3 phases) |

Each level starts with a title card (`scripts/level_card.gd`). Backgrounds are per theme (`scripts/background.gd`),
platform and gate looks follow the theme / boss. Landfill Titan hazards live in `scripts/hazard.gd`.

## Controls

A/D move, Space/W jump, J/X attack, **E put the selected trash in a bin**, **Q or 1-4 choose which trash**, B inventory, Esc pause.

## Systems added

- **Real sorting:** trash is carried by type; stand in a bin and press E. Wrong bin = spoiled item + pollution (`recycle_bin.gd`, `game_state.gd`).
- **Did you know?** fact on the level summary card.
- **Game feel:** screen shake, freeze frame on hits, particle bursts (`burst.gd`, hooks in `main.gd`).
- **Boss HUD:** name banner + top health bar (`boss_bar.gd`).
- **Level summary** after every boss: accuracy, kills, pollution, upgrades, 0-3 saplings (`summary_card.gd`).
- **Themed enemies:** plastic-bag jellyfish (sea), smog puff (air), tire monster (land) (`enemy.gd`).
- **Fonts:** `fonts.gd` holds the three cozy fonts used by every screen.

