extends Node2D

const PlayerS = preload("res://scripts/player.gd")
const EnemyS = preload("res://scripts/enemy.gd")
const ChestS = preload("res://scripts/chest.gd")
const PlatformS = preload("res://scripts/platform.gd")
const HudS = preload("res://scripts/hud.gd")
const BossS = preload("res://scripts/boss.gd")
const BinS = preload("res://scripts/recycle_bin.gd")
const GateS = preload("res://scripts/gate.gd")
const BackgroundS = preload("res://scripts/background.gd")
const CutsceneS = preload("res://scripts/cutscene.gd")
const CharSelectS = preload("res://scripts/char_select.gd")
const MenuS = preload("res://scripts/menu.gd")
const HowToS = preload("res://scripts/howto.gd")

const ARENA := [
    Rect2(0, 650, 1280, 70), Rect2(140, 530, 200, 20), Rect2(940, 530, 200, 20), Rect2(540, 410, 200, 20)]

# Level verisi: platformlar, düşmanlar, sandıklar [pos, tür], kutular [pos, çöp türü, ihtiyaç]
var levels := [
    {
        "end_x": 4000.0, "boss": "plastic",
        "platforms": [
            Rect2(0, 650, 900, 70), Rect2(1050, 650, 700, 70), Rect2(1900, 650, 800, 70), Rect2(2850, 650, 1350, 70),
            Rect2(350, 540, 160, 20), Rect2(600, 450, 160, 20), Rect2(1150, 540, 200, 20), Rect2(1400, 450, 200, 20),
            Rect2(2000, 520, 180, 20), Rect2(2250, 430, 180, 20), Rect2(2500, 520, 160, 20),
            Rect2(3050, 540, 200, 20), Rect2(3300, 450, 200, 20)],
        "enemies": [Vector2(550, 630), Vector2(1300, 630), Vector2(1480, 430), Vector2(2100, 630), Vector2(2350, 410),
            Vector2(2600, 630), Vector2(3150, 520), Vector2(3500, 630), Vector2(3700, 630)],
        "chests": [[Vector2(430, 540), "recycle"], [Vector2(1250, 540), "trash"], [Vector2(2330, 430), "trash"],
            [Vector2(2600, 650), "trash"], [Vector2(3400, 450), "recycle"]],
        "bins": [[Vector2(2000, 650), "glass", 2], [Vector2(2300, 650), "metal", 2],
            [Vector2(3300, 650), "paper", 2], [Vector2(3800, 650), "plastic", 2]],
    },
    {
        "end_x": 4000.0, "boss": "factory",
        "platforms": [
            Rect2(0, 650, 600, 70), Rect2(750, 650, 400, 70), Rect2(1300, 650, 300, 70), Rect2(1750, 650, 500, 70), Rect2(2400, 650, 1800, 70),
            Rect2(620, 550, 130, 20), Rect2(900, 500, 140, 20), Rect2(1200, 480, 140, 20), Rect2(1500, 540, 160, 20),
            Rect2(1900, 520, 160, 20), Rect2(2100, 430, 160, 20), Rect2(2500, 540, 180, 20), Rect2(2750, 450, 180, 20),
            Rect2(3000, 540, 180, 20), Rect2(3300, 450, 200, 20), Rect2(3600, 540, 200, 20)],
        "enemies": [Vector2(300, 630), Vector2(900, 630), Vector2(970, 480), Vector2(1400, 630), Vector2(1980, 500),
            Vector2(2500, 630), Vector2(2840, 430), Vector2(3090, 520), Vector2(3400, 630), Vector2(3750, 630)],
        "chests": [[Vector2(680, 550), "recycle"], [Vector2(950, 500), "trash"], [Vector2(1250, 480), "recycle"],
            [Vector2(2180, 430), "trash"], [Vector2(2600, 540), "recycle"], [Vector2(3400, 450), "trash"]],
        "bins": [[Vector2(1500, 650), "glass", 2], [Vector2(1900, 650), "metal", 2],
            [Vector2(3000, 650), "paper", 2], [Vector2(3750, 650), "plastic", 2]],
    },
]

var level_idx := 0
var in_arena := false
var playing := false
var level_root: Node2D
var hud: CanvasLayer
var bg_layer: CanvasLayer
var overlay: CanvasLayer
var pause_layer: CanvasLayer
var transitioning := false
var pause_block := 0.0
var cp_pollution := 0.0
var cp_stock := {}


func _ready() -> void:
    bg_layer = CanvasLayer.new()
    bg_layer.layer = -1
    bg_layer.add_child(BackgroundS.new())
    bg_layer.hide()
    add_child(bg_layer)
    hud = HudS.new()
    hud.hide()
    add_child(hud)
    _show_menu()


# ---------------- flow: menu -> difficulty -> intro -> character -> tutorial -> play -> ending ----------------
func _put_overlay(node: Node) -> void:
    overlay = CanvasLayer.new()
    overlay.layer = 40
    overlay.add_child(node)
    add_child(overlay)


func _clear_overlay() -> void:
    if overlay:
        overlay.queue_free()
        overlay = null


func _clear_pause() -> void:
    if pause_layer:
        pause_layer.queue_free()
        pause_layer = null


func _show_menu() -> void:
    playing = false
    get_tree().paused = false
    GameState.running = false
    _clear_pause()
    _clear_overlay()
    if level_root:
        level_root.queue_free()
        level_root = null
    hud.hide()
    bg_layer.hide()
    var m := MenuS.new()
    m.new_game.connect(_on_new_game)
    m.continue_game.connect(_on_continue)
    _put_overlay(m)


func _on_new_game(diff: int) -> void:
    _clear_overlay()
    GameState.reset()
    GameState.difficulty = diff
    var cs := CutsceneS.new()
    cs.slides = CutsceneS.intro_slides()
    cs.finished.connect(_on_intro_done)
    _put_overlay(cs)


func _on_intro_done() -> void:
    _clear_overlay()
    var cs := CharSelectS.new()
    cs.finished.connect(_on_char_done)
    _put_overlay(cs)


func _on_char_done() -> void:
    _clear_overlay()
    GameState.apply_character()
    var h := HowToS.new()
    h.tutorial_mode = true
    h.finished.connect(_on_tutorial_done)
    _put_overlay(h)


func _on_tutorial_done() -> void:
    _clear_overlay()
    _begin_play(0, false)


func _on_continue() -> void:
    var info := GameState.load_game()
    if info.is_empty():
        return
    _clear_overlay()
    _begin_play(int(info["level"]), bool(info["arena"]))


func _begin_play(i: int, arena: bool) -> void:
    playing = true
    pause_block = 0.5
    hud.show()
    bg_layer.show()
    start_level(i, arena)
    if i == 0 and not arena:
        GameState.item_collected.emit(Loc.t("msg_intro"))


# ---------------- pause ----------------
func _open_pause() -> void:
    get_tree().paused = true
    pause_layer = CanvasLayer.new()
    pause_layer.layer = 50
    pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    var m := MenuS.new()
    m.is_pause = true
    m.resume.connect(_close_pause)
    m.quit_to_menu.connect(_show_menu)
    pause_layer.add_child(m)
    add_child(pause_layer)


func _close_pause() -> void:
    get_tree().paused = false
    pause_block = 0.3
    _clear_pause()


# ---------------- levels ----------------
func start_level(i: int, arena: bool = false, restart: bool = false) -> void:
    if level_root:
        level_root.process_mode = Node.PROCESS_MODE_DISABLED
        level_root.hide()
        level_root.queue_free()
    level_idx = i
    in_arena = arena
    transitioning = false
    if restart:
        GameState.pollution = cp_pollution
        GameState.stock = cp_stock.duplicate()
    else:
        cp_pollution = GameState.pollution
        cp_stock = GameState.stock.duplicate()
        GameState.save_game(i, arena)   # auto-save: every level start and before every boss
        if arena or i > 0:
            GameState.item_collected.emit(Loc.t("msg_saved"))
    GameState.running = not arena
    GameState.heat_timer = 0.0
    GameState.bins_done = 0
    GameState.bins_total = 0
    var d: Dictionary = levels[i]
    level_root = Node2D.new()
    add_child(level_root)

    var right_limit := 1280
    var spawn := Vector2(100, 560)
    if arena:
        for r in ARENA:
            _platform(r, true)
        _platform(Rect2(-40, -300, 40, 1200), false)
        _platform(Rect2(1280, -300, 40, 1200), false)
        var b := BossS.new()
        b.boss_id = d["boss"]
        b.position = Vector2(1000, 590)
        b.defeated.connect(_on_boss_defeated)
        level_root.add_child(b)
        spawn = Vector2(60, 600)
    else:
        for r in d["platforms"]:
            _platform(r, true)
        _platform(Rect2(-40, -300, 40, 1200), false)
        _platform(Rect2(d["end_x"] + 200.0, -300, 40, 1200), false)
        for e in d["enemies"]:
            var en := EnemyS.new()
            en.position = e
            level_root.add_child(en)
        for c in d["chests"]:
            var ch := ChestS.new()
            ch.position = c[0]
            ch.kind = c[1]
            level_root.add_child(ch)
        var gate := GateS.new()
        gate.boss_id = d["boss"]
        gate.position = Vector2(d["end_x"], 450)
        gate.total = d["bins"].size()
        gate.entered.connect(_on_gate_entered)
        level_root.add_child(gate)
        GameState.bins_total = d["bins"].size()
        for bd in d["bins"]:
            var bn := BinS.new()
            bn.position = bd[0]
            bn.type = bd[1]
            bn.need = bd[2]
            bn.activated.connect(gate.bin_done)
            level_root.add_child(bn)
        right_limit = int(d["end_x"]) + 240

    var p := PlayerS.new()
    p.spawn_pos = spawn
    p.position = spawn
    p.died.connect(_on_player_died)
    level_root.add_child(p)
    var cam := Camera2D.new()
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_bottom = 720
    cam.limit_right = right_limit
    cam.position_smoothing_enabled = true
    p.add_child(cam)
    cam.make_current()
    GameState.hp = GameState.max_hp
    GameState.changed.emit()


func _platform(r: Rect2, grass: bool) -> void:
    var pl := PlatformS.new()
    pl.position = r.position
    pl.size = r.size
    pl.grass = grass
    level_root.add_child(pl)


func _on_gate_entered() -> void:
    if not transitioning:
        transitioning = true
        call_deferred("start_level", level_idx, true)


func _on_boss_defeated() -> void:
    GameState.item_collected.emit(Loc.t("msg_boss_down"))
    call_deferred("_after_boss")


func _after_boss() -> void:
    if level_idx + 1 >= levels.size():
        _show_ending()
    else:
        start_level(level_idx + 1, false)   # auto-save happens here (after the boss)


func _on_player_died() -> void:
    GameState.item_collected.emit(Loc.t("msg_died"))
    call_deferred("start_level", level_idx, in_arena, true)


func _process(delta: float) -> void:
    # Sky turns sickly yellowish with pollution (brightness stays the same)
    var p := GameState.pollution / 100.0
    RenderingServer.set_default_clear_color(Color(0.55, 0.8, 0.95).lerp(Color(0.76, 0.7, 0.48), p))
    pause_block = maxf(0.0, pause_block - delta)
    if playing and pause_layer == null and not get_tree().paused and pause_block <= 0.0 and Input.is_action_just_pressed("ui_cancel"):
        _open_pause()


# ---------------- ending ----------------
func _show_ending() -> void:
    playing = false
    GameState.running = false
    GameState.delete_save()
    if level_root:
        level_root.queue_free()
        level_root = null
    hud.hide()
    bg_layer.hide()
    var clean := GameState.pollution < 50.0
    var slides: Array = CutsceneS.good_slides() if clean else CutsceneS.bad_slides()
    var title := Loc.t("end_clean") if clean else Loc.t("end_dirty")
    slides.append({"scene": "stats", "who": "", "raw": true, "text": Loc.t("end_stats", [title, GameState.trash_total, GameState.delivered_total, int(GameState.pollution)])})
    var cs := CutsceneS.new()
    cs.slides = slides
    cs.finished.connect(_on_ending_done)
    _put_overlay(cs)


func _on_ending_done() -> void:
    _clear_overlay()
    GameState.reset()
    _show_menu()
