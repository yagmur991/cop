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
