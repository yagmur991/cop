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
const LevelCardS = preload("res://scripts/level_card.gd")
const SummaryCardS = preload("res://scripts/summary_card.gd")
const BossBarS = preload("res://scripts/boss_bar.gd")
const BurstS = preload("res://scripts/burst.gd")

const ARENA := [
    Rect2(0, 650, 1280, 70), Rect2(140, 530, 200, 20), Rect2(940, 530, 200, 20), Rect2(540, 410, 200, 20)]

# Level verisi: platformlar, düşmanlar, sandıklar [pos, tür], kutular [pos, çöp türü, ihtiyaç]
var levels := [
    {
        "end_x": 4000.0, "boss": "plastic", "theme": "sea",
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
        "end_x": 4000.0, "boss": "factory", "theme": "air",
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
    {
        "end_x": 4600.0, "boss": "land", "theme": "land",
        "platforms": [
            Rect2(0, 650, 700, 70), Rect2(870, 650, 380, 70), Rect2(1420, 650, 330, 70), Rect2(1920, 650, 300, 70),
            Rect2(2390, 650, 500, 70), Rect2(3070, 650, 300, 70), Rect2(3540, 650, 1260, 70),
            Rect2(300, 540, 160, 20), Rect2(520, 450, 160, 20),
            Rect2(980, 540, 160, 20), Rect2(1130, 450, 160, 20),
            Rect2(1480, 540, 160, 20), Rect2(1650, 450, 160, 20), Rect2(1830, 360, 160, 20),
            Rect2(2000, 540, 160, 20), Rect2(2170, 450, 160, 20),
            Rect2(2600, 540, 180, 20), Rect2(2800, 450, 180, 20), Rect2(2990, 540, 120, 20), Rect2(3150, 450, 160, 20),
            Rect2(3640, 540, 180, 20), Rect2(3860, 450, 180, 20), Rect2(4080, 360, 180, 20),
            Rect2(4300, 450, 180, 20), Rect2(4500, 540, 160, 20),
        ],
        "enemies": [
            Vector2(450, 630), Vector2(600, 430), Vector2(1060, 630), Vector2(1585, 630),
            Vector2(2070, 630), Vector2(2640, 630), Vector2(2890, 430), Vector2(3220, 630),
            Vector2(3900, 630), Vector2(3950, 430), Vector2(4390, 430), Vector2(4400, 630),
        ],
        "chests": [
            [Vector2(380, 540), "recycle"], [Vector2(1060, 540), "trash"], [Vector2(1210, 450), "recycle"],
            [Vector2(1730, 450), "trash"], [Vector2(1910, 360), "trash"], [Vector2(2080, 540), "recycle"],
            [Vector2(2250, 450), "trash"], [Vector2(2690, 540), "recycle"], [Vector2(3230, 450), "trash"],
            [Vector2(3730, 540), "recycle"], [Vector2(4170, 360), "trash"],
        ],
        "bins": [[Vector2(1500, 650), "glass", 2], [Vector2(2150, 650), "metal", 2],
            [Vector2(2800, 650), "paper", 2], [Vector2(4250, 650), "plastic", 2]],
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
var bg_node: Node2D
var cur_theme := "sea"          # sea / air / land (set per level)
var card_layer: CanvasLayer
var card_pending := false       # a level card is (about to be) showing
var pending_msgs: Array = []    # HUD messages held back until the card closes
var boss_layer: CanvasLayer
var summary_layer: CanvasLayer
var cam_node: Camera2D
var shake_t := 0.0
var shake_amp := 0.0
var hitstop_on := false
var boss_down := false          # the boss just fell; the summary card is coming
var cp_stats := {}


func _ready() -> void:
    bg_layer = CanvasLayer.new()
    bg_layer.layer = -1
    bg_node = BackgroundS.new()
    bg_layer.add_child(bg_node)
    bg_layer.hide()
    add_child(bg_layer)
    hud = HudS.new()
    hud.hide()
    add_child(hud)
    boss_layer = CanvasLayer.new()
    boss_layer.layer = 7
    boss_layer.add_child(BossBarS.new())
    add_child(boss_layer)
    GameState.shake.connect(_on_shake)
    GameState.hitstop.connect(_on_hitstop)
    GameState.burst.connect(_on_burst)
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
    card_pending = false
    pending_msgs.clear()
    boss_down = false
    Engine.time_scale = 1.0
    hitstop_on = false
    if summary_layer:
        summary_layer.queue_free()
        summary_layer = null
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
        _say(Loc.t("msg_intro"))


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
    var d: Dictionary = levels[i]
    cur_theme = str(d.get("theme", "land"))
    bg_node.theme = cur_theme
    card_pending = not arena and not restart
    boss_down = false
    if restart:
        GameState.pollution = cp_pollution
        GameState.stock = cp_stock.duplicate()
        var deaths := int(GameState.lv_stats["deaths"])
        GameState.lv_stats = cp_stats.duplicate()
        GameState.lv_stats["deaths"] = deaths
        GameState.fix_sel()
    else:
        if not arena:
            GameState.reset_level_stats()
        cp_pollution = GameState.pollution
        cp_stock = GameState.stock.duplicate()
        cp_stats = GameState.lv_stats.duplicate()
        GameState.save_game(i, arena)   # auto-save: every level start and before every boss
        if arena or i > 0:
            _say(Loc.t("msg_saved"))
    GameState.running = not arena
    GameState.heat_timer = 0.0
    GameState.bins_done = 0
    GameState.bins_total = 0
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
            en.theme = cur_theme
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
        GameState.bins_total = maxi(1, d["bins"].size() - 1)   # the gate needs all bins but one
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
    cam_node = cam
    GameState.hp = GameState.max_hp
    GameState.changed.emit()
    if card_pending:
        _show_level_card(i)


func _platform(r: Rect2, grass: bool) -> void:
    var pl := PlatformS.new()
    pl.position = r.position
    pl.size = r.size
    pl.grass = grass
    pl.theme = cur_theme
    level_root.add_child(pl)


func _on_gate_entered() -> void:
    if not transitioning:
        transitioning = true
        call_deferred("start_level", level_idx, true)


func _on_boss_defeated() -> void:
    boss_down = true
    GameState.item_collected.emit(Loc.t("msg_boss_down"))
    get_tree().create_timer(1.8).timeout.connect(_after_boss)   # let the player enjoy the explosion


func _after_boss() -> void:
    if not playing or not boss_down or summary_layer != null:
        return
    if pause_layer != null:   # pause menu is open: try again a bit later
        get_tree().create_timer(0.5).timeout.connect(_after_boss)
        return
    _show_summary()


func _upgrades_text() -> String:
    var u: Dictionary = GameState.upgrades
    var u0: Dictionary = GameState.lv_upg_start
    var parts := PackedStringArray()
    var dmg := int(u["damage"]) - int(u0.get("damage", 0))
    var spd := int(u["speed"]) - int(u0.get("speed", 0))
    var shd := int(u["shield"]) - int(u0.get("shield", 0))
    if dmg > 0:
        parts.append("+%d %s" % [dmg, Loc.t("up_damage")])
    if spd > 0:
        parts.append("+%d %s" % [spd, Loc.t("up_speed")])
    if shd > 0:
        parts.append("+%d %s" % [shd, Loc.t("up_shield")])
    if bool(u["double_jump"]) and not bool(u0.get("double_jump", false)):
        parts.append(Loc.t("up_double"))
    return ", ".join(parts) if parts.size() > 0 else Loc.t("sum_none")


func _show_summary() -> void:
    var st: Dictionary = GameState.lv_stats.duplicate()
    st["pollution"] = GameState.pollution
    var dd: Dictionary = levels[level_idx]
    st["bins_all"] = dd["bins"].size()
    var ok := int(st["ok"])
    var wrong := int(st["wrong"])
    var acc := 1.0 if ok + wrong == 0 else float(ok) / float(ok + wrong)
    var card := SummaryCardS.new()
    card.level_no = level_idx + 1
    card.theme = cur_theme
    card.stats = st
    card.stars = [acc >= 0.8, GameState.pollution < 50.0, int(st["deaths"]) == 0]
    card.upgrades_text = _upgrades_text()
    card.fact_key = "boss_" + cur_theme
    card.last = level_idx + 1 >= levels.size()
    card.finished.connect(_on_summary_done)
    summary_layer = CanvasLayer.new()
    summary_layer.layer = 45
    summary_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    summary_layer.add_child(card)
    add_child(summary_layer)
    get_tree().paused = true


func _on_summary_done() -> void:
    get_tree().paused = false
    pause_block = 0.4
    boss_down = false
    if summary_layer:
        summary_layer.queue_free()
        summary_layer = null
    if level_idx + 1 >= levels.size():
        _show_ending()
    else:
        start_level(level_idx + 1, false)   # auto-save happens here (after the boss)


func _on_player_died() -> void:
    if boss_down:
        return
    GameState.lv_stats["deaths"] += 1
    GameState.item_collected.emit(Loc.t("msg_died"))
    call_deferred("start_level", level_idx, in_arena, true)


func _process(delta: float) -> void:
    # Sky turns sickly yellowish with pollution (brightness stays the same)
    var p := GameState.pollution / 100.0
    if playing:
        RenderingServer.set_default_clear_color(_sky(p))
    else:
        RenderingServer.set_default_clear_color(Color(0.16, 0.12, 0.1))   # menu / cutscenes: warm letterbox
    pause_block = maxf(0.0, pause_block - delta)
    if shake_t > 0.0 and is_instance_valid(cam_node):
        shake_t -= delta
        if shake_t <= 0.0:
            shake_amp = 0.0
            cam_node.offset = Vector2.ZERO
        else:
            cam_node.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amp * clampf(shake_t / 0.3, 0.0, 1.0)
    if playing and pause_layer == null and not get_tree().paused and pause_block <= 0.0 and Input.is_action_just_pressed("ui_cancel"):
        _open_pause()


# ---------------- game feel: shake, freeze frame, particles ----------------
func _on_shake(amount: float, time: float) -> void:
    shake_amp = maxf(shake_amp, amount)
    shake_t = maxf(shake_t, time)


func _on_hitstop(time: float) -> void:
    if hitstop_on or not playing:
        return
    hitstop_on = true
    Engine.time_scale = 0.06
    get_tree().create_timer(time, true, false, true).timeout.connect(_end_hitstop)   # ignores time scale


func _end_hitstop() -> void:
    Engine.time_scale = 1.0
    hitstop_on = false


func _on_burst(pos: Vector2, col: Color, n: int) -> void:
    if not is_instance_valid(level_root):
        return
    var b := BurstS.new()
    b.position = pos
    b.col = col
    b.n = n
    level_root.add_child(b)


# ---------------- level themes + intro card ----------------
func _sky(p: float) -> Color:
    var clean := Color(0.55, 0.8, 0.95)
    var dirty := Color(0.76, 0.7, 0.48)
    if cur_theme == "sea":
        clean = Color(0.6, 0.83, 0.94)
        dirty = Color(0.66, 0.68, 0.5)
    elif cur_theme == "air":
        clean = Color(0.58, 0.78, 0.94)
        dirty = Color(0.72, 0.62, 0.46)
    elif cur_theme == "land":
        clean = Color(0.64, 0.82, 0.92)
        dirty = Color(0.74, 0.64, 0.46)
    return clean.lerp(dirty, p)


# HUD messages wait while the level card is up, so the player actually sees them
func _say(text: String) -> void:
    if card_pending:
        pending_msgs.append(text)
    else:
        GameState.item_collected.emit(text)


func _show_level_card(i: int) -> void:
    var card := LevelCardS.new()
    card.level_no = i + 1
    card.theme = cur_theme
    card.finished.connect(_on_card_done)
    card_layer = CanvasLayer.new()
    card_layer.layer = 45
    card_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    card_layer.add_child(card)
    add_child(card_layer)
    get_tree().paused = true


func _on_card_done() -> void:
    get_tree().paused = false
    pause_block = 0.4
    card_pending = false
    if card_layer:
        card_layer.queue_free()
        card_layer = null
    for m in pending_msgs:
        GameState.item_collected.emit(m)
    pending_msgs.clear()


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
