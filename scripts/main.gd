extends Node2D

const PlayerS = preload("res://scripts/player.gd")
const EnemyS = preload("res://scripts/enemy.gd")
const ChestS = preload("res://scripts/chest.gd")
const PlatformS = preload("res://scripts/platform.gd")
const HudS = preload("res://scripts/hud.gd")
const BossS = preload("res://scripts/boss.gd")
const BinS = preload("res://scripts/recycle_bin.gd")
const GateS = preload("res://scripts/gate.gd")

const ARENA := [
    Rect2(0, 650, 1280, 70), Rect2(140, 530, 200, 20), Rect2(940, 530, 200, 20), Rect2(540, 410, 200, 20)]

# Level verisi: platformlar (x, y, w, h), düşmanlar (x, y), sandıklar [pos, tür]
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
        "chests": [[Vector2(430, 540), "recycle"], [Vector2(1250, 540), "trash"], [Vector2(2330, 430), "recycle"],
            [Vector2(2600, 650), "trash"], [Vector2(3400, 450), "recycle"]],
        "bins": [[Vector2(2000, 650), 2], [Vector2(3300, 650), 2], [Vector2(3800, 650), 2]],
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
        "bins": [[Vector2(1500, 650), 2], [Vector2(2800, 650), 2], [Vector2(3750, 650), 3]],
    },
]

var level_idx := 0
var in_arena := false
var level_root: Node2D
var canvas_mod: CanvasModulate
var hud: CanvasLayer
var transitioning := false
var cp_pollution := 0.0
var cp_trash := 0
var ending := false


func _ready() -> void:
    hud = HudS.new()
    add_child(hud)
    start_level(0, false)
    GameState.item_collected.emit("COP31: Çöpleri yen, sandıkları aç, seçimini yap!")


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
        GameState.trash_stock = cp_trash
    else:
        cp_pollution = GameState.pollution
        cp_trash = GameState.trash_stock
    GameState.running = not arena
    GameState.heat_timer = 0.0
    GameState.bins_done = 0
    GameState.bins_total = 0
    var d: Dictionary = levels[i]
    level_root = Node2D.new()
    add_child(level_root)
    canvas_mod = CanvasModulate.new()
    level_root.add_child(canvas_mod)

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
        gate.position = Vector2(d["end_x"], 450)
        gate.total = d["bins"].size()
        gate.entered.connect(_on_gate_entered)
        level_root.add_child(gate)
        GameState.bins_total = d["bins"].size()
        for bd in d["bins"]:
            var bn := BinS.new()
            bn.position = bd[0]
            bn.need = bd[1]
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
    GameState.item_collected.emit("BOSS YENİLDİ!")
    call_deferred("_after_boss")


func _after_boss() -> void:
    if level_idx + 1 >= levels.size():
        _show_ending()
    else:
        start_level(level_idx + 1, false)


func _on_player_died() -> void:
    GameState.item_collected.emit("Yenildin! Yeniden başlıyor...")
    call_deferred("start_level", level_idx, in_arena, true)


func _process(_delta: float) -> void:
    var p := GameState.pollution / 100.0
    RenderingServer.set_default_clear_color(Color(0.55, 0.8, 0.95).lerp(Color(0.5, 0.26, 0.2), p))
    if canvas_mod:
        canvas_mod.color = Color.WHITE.lerp(Color(0.65, 0.58, 0.5), p)
    if ending and Input.is_action_just_pressed("ui_accept"):
        GameState.reset()
        get_tree().reload_current_scene()


func _show_ending() -> void:
    ending = true
    GameState.running = false
    level_root.queue_free()
    hud.hide()
    var cl := CanvasLayer.new()
    cl.layer = 30
    var bg := ColorRect.new()
    bg.color = Color.BLACK
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    cl.add_child(bg)
    var l := Label.new()
    l.set_anchors_preset(Control.PRESET_FULL_RECT)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", 28)
    var clean := GameState.pollution < 50.0
    var title := "TEMİZ SON" if clean else "KİRLİ SON"
    var story := "Doğa nefes aldı. Seçimlerin dünyayı iyileştirdi." if clean else "Güçlü oldun ama dünya kirlendi. Başka bir yol vardı..."
    # NOT: Sunumdan önce bu bilgilerin kaynaklarını kontrol edin.
    var facts := [
        "Biliyor muydun? Alüminyum kutuyu geri dönüştürmek, sıfırdan üretime göre yaklaşık %95 daha az enerji harcar.",
        "Biliyor muydun? Cam, kalite kaybı olmadan tekrar tekrar geri dönüştürülebilir.",
        "Biliyor muydun? Plastik atıkların büyük bir kısmı doğada yüzyıllarca kalır."]
    l.text = "%s\n\n%s\n\nToplanan geri dönüşüm itemi: %d\nToplanan çöp itemi: %d\nKirlilik: %%%d\n\n%s\n\nYeniden oynamak için Enter" % [
        title, story, GameState.recycled_total, GameState.trash_total, int(GameState.pollution), facts.pick_random()]
    cl.add_child(l)
    add_child(cl)
