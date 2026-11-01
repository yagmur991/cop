# SAVE GAIA (Godot 4.x)

Platformer about collecting, sorting and recycling waste to save the planet.
Fight trash monsters, carry each kind of waste to the right recycling bin, open the boss gate, and clean up three levels
before pollution wins.

## Quick start

1. Open `project.godot` with Godot 4.2+ (made with 4.7) and press F5.
2. Menu: **New Game** (difficulty -> intro -> character select -> tutorial), **Continue**, **How to Play**, **Options**, **Credits**, **Quit**.
3. Take each trash type (glass, metal, paper, plastic) to the matching bin. When the bins are full the boss gate opens.
4. Beat the boss. Three levels, then one of two endings.

## Controls

| Key | Action |
|-----|--------|
| A / D (or arrows) | Move |
| Space / W / Up | Jump (double jump after the power-up) |
| J / X / Z | Attack |
| **E** | Put the selected trash into the bin you are standing in |
| **Q** or **1-4** | Choose which trash type you hold |
| B | Inventory |
| Esc | Pause |
| F11 | Fullscreen |

## How it plays

- **Enemies** drop either **trash** (pollution up, +damage) or a **sapling** (pollution down, random power-up: double jump, speed, shield, +1 HP).
- **Real sorting:** trash is carried by type. Stand in a bin and press E. The right bin lowers pollution, a wrong bin spoils the item and raises it (`recycle_bin.gd`, `game_state.gd`).
- **Boss gate:** locked until the bins are done. One bin less than the total is enough to open it; filling all of them gives the **PERFECT SORTING** bonus (pollution -12).
- **Pollution** also rises on its own. Above a threshold (depends on difficulty) heat waves start hurting you.
- **Endings:** finish with pollution under 50% for the clean ending, otherwise the dirty one.

## Difficulty

Chosen on New Game and stored in the save (`game_state.gd`, `diff_*()`).

| | Easy | Normal | Hard |
|---|------|--------|------|
| Pollution speed | x0.6 | x1.0 | x1.4 |
| Enemy speed | x0.8 | x1.0 | x1.25 |
| Boss health | x0.75 | x1.0 | x1.3 |
| Starting HP | +2 | +0 | -1 |
| Heat waves begin at | 95% | 85% | 70% |

## Levels

| # | Card | Theme | Boss | Music |
|---|------|-------|------|-------|
| 1 | Save the Sea | ocean + plastic pollution | Plastic boss | `level1` / `boss_plastic` |
| 2 | Save the Air | factories, smoke, carbon | Factory boss | `level2` / `boss_factory` |
| 3 | Save the Land | farmland vs. landfill | Landfill Titan (final, 3 phases) | `level3` / `boss_land` |

Each level starts with a title card (`level_card.gd`). Backgrounds are per theme (`background.gd`); platform and gate looks follow
the theme / boss. Boss gates are painted per boss (no text on them). Landfill Titan hazards live in `hazard.gd` and always show a warning first.
Bosses telegraph every attack with a red `!`.

## Saving

Auto-save only, no manual save. The game writes `user://savegame.json` at **every level start** (which is right after a boss) and
**right before every boss fight**. **Continue** loads the last save; dying restarts from the last checkpoint of the level / arena.
The save is deleted after the ending.

## Options

Language (English / Turkish), fullscreen, **Music Volume**, **Sound Volume**. Saved in `user://settings.cfg` (`loc.gd`).
Language can also be switched with the EN / TR chips on the main menu.

## Sprites

All PNG sprites are registered in `scripts/sprites.gd` (pixel-art, nearest filtering).

| File | Used for |
|------|----------|
| `Gren`, `Blu`, `Yello`, `Purp`, `Pinkie` | Playable heroes, characters 1-5 (also shown in character select and the tutorial) |
| `Basic Monster` | All enemies (the theme only changes the death particles) |
| `Boss 1` / `Boss 2` / `Boss 3` | Plastic boss / factory boss / Landfill Titan |
| `Recycle bin glass / metal / Paper / plastic` | The four sorting bins |
| `gaia_01` / `gaia_02` | Prof. Gaia in cutscenes: worried (intro, bad ending) / happy (good ending) |
| `Sprite-0001-Sheet` | Trash chest |
| `PlasticRecycleBin-Sheet` | Old bin sheet, currently not used |

Still drawn in code: trash / sapling item icons, platforms, boss gates, hazards, backgrounds, cutscene scenery, HUD (`art.gd`).

## Audio

- **Music** (`assets/music/*.ogg`, looped and crossfaded by `music.gd`, autoload `Music`):

| Where | Track |
|-------|-------|
| Main menu / pause menu | `menu` |
| Intro cutscene, character select, tutorial | `intro` |
| Level 1 / 2 / 3 | `level1` / `level2` / `level3` |
| Boss fights (plastic / factory / land) | `boss_plastic` / `boss_factory` / `boss_land` |
| Ending (pollution < 50% / otherwise) | `ending_good` / `ending_bad` |

  `start_level()` in `main.gd` picks the level or boss track. Dying and restarting does not restart the music.
- **Sound effects** (`assets/sfx/*.wav`, `sfx.gd`, autoload `Sfx`): `Sfx.play("name")`.
  Menu: `ui_move`, `ui_select`, `ui_back`, `card_start`. Gameplay: `jump`, `attack`, `hurt`, `pickup_clean`, `pickup_trash`, `chest`,
  `enemy_pop`, `deposit`, `bin_full`, `unlock`, `warn`, `boss_hit`, `boss_down`.
- **Cutscene voices:** `blip_narrator.wav` / `blip_gaia.wav` play while the text types out (`cutscene.gd`); Gaia is pitched higher.
- Both audio autoloads keep running while the game is paused, so the pause menu has music and click sounds.

## Systems

- **Did you know?** eco fact card under the pollution bar (`fact_card.gd`) and on the level summary.
- **Level summary** after every boss: sorting accuracy, kills, pollution, upgrades, 0-3 saplings (`summary_card.gd`).
- **Carry bar** (top right) shows the four trash types you hold; the highlighted one is what E drops (`carry_bar.gd`).
- **Boss HUD:** name banner and top health bar (`boss_bar.gd`).
- **Game feel:** screen shake, freeze frame on hits, particle bursts, white hit-flash shader (`burst.gd`, `sprites.gd`, hooks in `main.gd`).
- **Illustrated How to Play** pages, reused as the tutorial after the intro (`howto.gd`).
- **Localization:** every string lives in `loc.gd` as `[English, Turkish]`; use `Loc.t("key")`.
- **Fonts:** `fonts.gd` holds the three fonts used by every screen (Young Serif for titles, Lora Bold / Regular).

## Project layout

```
main.tscn            only a Node2D with scripts/main.gd (all scenes are built in code)
scripts/main.gd      game flow: menu -> intro -> play -> summary -> ending, levels, pause, auto-save
scripts/game_state.gd  autoload: stats, upgrades, difficulty, save / load
scripts/loc.gd         autoload: translations + settings
scripts/music.gd, sfx.gd  autoloads: audio
assets/              sprites, fonts/, music/, sfx/
```

## Credits and licenses

- Recycling bin sprites: yureino-kage (itch.io).
- Other sprites, music and sound effects: made for this game by the Save Gaia team.
- Fonts: Young Serif and Lora, SIL Open Font License (see `assets/fonts/`).
- Made with Godot Engine.
