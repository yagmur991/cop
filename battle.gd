extends Node2D
# Omori tarzı boss savaşı: sıra tabanlı menü + kutu içinde kurşun kaçma.

signal finished(won: bool)

enum S { TEXT, MENU, DODGE }
const BOX := Rect2(440, 340, 400, 180)
const MAX_HP := 6

var boss_id := "plastic"
var boss_name := ""
var boss_hp := 28
var boss_max := 28
var state := S.TEXT
var after: Callable
var timer := 0.0
var msg := ""
var sel := 0
var player_hp := MAX_HP
var soul := Vector2.ZERO
var bullets: Array = []
var dodge_t := 0.0
var dodge_len := 6.0
var spawn_t := 0.0
var invuln := 0.0
var flash := 0.0
var t := 0.0
var dirty_used := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
    rng.randomize()
    if boss_id == "plastic":
        boss_name = "PLASTİK CANAVAR"
        boss_max = 28
        dodge_len = 6.0
    else:
        boss_name = "FABRİKA DEV"
        boss_max = 40
        dodge_len = 7.0
    boss_hp = boss_max
    _say("%s yolunu kesti!" % boss_name, _to_menu)


func _say(text: String, cb: Callable) -> void:
    msg = text
    after = cb
    timer = 1.6
    state = S.TEXT


func _to_menu() -> void:
    state = S.MENU


func _process(delta: float) -> void:
    t += delta
    flash = maxf(0.0, flash - delta)
    invuln = maxf(0.0, invuln - delta)
    match state:
        S.TEXT:
            timer -= delta
            if timer <= 0.0 or Input.is_action_just_pressed("ui_accept"):
                after.call()
        S.MENU:
            if Input.is_action_just_pressed("ui_down"):
                sel = (sel + 1) % 3
            if Input.is_action_just_pressed("ui_up"):
                sel = (sel + 2) % 3
            if Input.is_action_just_pressed("ui_accept"):
                _confirm()
        S.DODGE:
            _update_dodge(delta)
    queue_redraw()


func _hit_boss(d: int) -> void:
    boss_hp = maxi(0, boss_hp - d)
    flash = 0.3


func _confirm() -> void:
    match sel:
        0:
            var d := 3 + int(GameState.upgrades["damage"])
            _hit_boss(d)
            _say("Sert bir darbe! %d hasar." % d, _after_player)
        1:
            if GameState.recycle_stock <= 0:
                _say("Geri dönüşüm itemin kalmadı! Sandıklardan topla.", _to_menu)
                return
            GameState.recycle_stock -= 1
            GameState.add_pollution(-5.0)
            _hit_boss(6)
            player_hp = mini(player_hp + 1, MAX_HP)
            _say("Geri dönüşüm dalgası! 6 hasar, +1 HP, hava temizlendi.", _after_player)
        2:
            if GameState.trash_stock <= 0:
                _say("Çöp itemin kalmadı!", _to_menu)
                return
            GameState.trash_stock -= 1
            GameState.add_pollution(15.0)
            GameState.dirty_total += 1
            dirty_used = true
            _hit_boss(11)
            _say("Çöp bombası! 11 hasar ama kirlilik arttı...", _after_player)


func _after_player() -> void:
    if boss_hp <= 0:
        var txt := "%s yenildi! " % boss_name
        txt += "Çöp bombaları havayı kirletti..." if dirty_used else "Temiz zafer! Doğa nefes aldı."
        _say(txt, _emit_win)
    else:
        _start_dodge()


func _emit_win() -> void:
    set_process(false)
    finished.emit(true)


func _emit_lose() -> void:
    set_process(false)
    finished.emit(false)


func _start_dodge() -> void:
    state = S.DODGE
    dodge_t = 0.0
    bullets.clear()
    soul = BOX.get_center()
    spawn_t = 0.4


func _update_dodge(delta: float) -> void:
    dodge_t += delta
    var dir := Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
    if dir.length() > 0.0:
        soul += dir.normalized() * 240.0 * delta
    soul.x = clampf(soul.x, BOX.position.x + 8.0, BOX.end.x - 8.0)
    soul.y = clampf(soul.y, BOX.position.y + 8.0, BOX.end.y - 8.0)
    spawn_t -= delta
    if spawn_t <= 0.0:
        _spawn_bullet()
        spawn_t = 0.38 if boss_id == "plastic" else 0.3
    var spd_mul := 1.0 + GameState.pollution / 200.0
    for i in range(bullets.size() - 1, -1, -1):
        var b: Dictionary = bullets[i]
        b["pos"] += b["vel"] * delta * spd_mul
        if invuln <= 0.0 and soul.distance_to(b["pos"]) < b["r"] + 6.0:
            bullets.remove_at(i)
            _hurt()
            if state != S.DODGE:
                return
            continue
        if not Rect2(-60, -60, 1400, 840).has_point(b["pos"]):
            bullets.remove_at(i)
    if dodge_t >= dodge_len:
        bullets.clear()
        _to_menu()


func _hurt() -> void:
    if int(GameState.upgrades["shield"]) > 0:
        GameState.upgrades["shield"] -= 1
        GameState.changed.emit()
        invuln = 0.7
        return
    player_hp -= 1
    invuln = 1.0
    if player_hp <= 0:
        bullets.clear()
        _say("Yenildin... Geri dönüşümü unutma!", _emit_lose)


func _spawn_bullet() -> void:
    var b := {}
    if boss_id == "plastic" or rng.randf() < 0.35:
        b = {
            "pos": Vector2(rng.randf_range(BOX.position.x, BOX.end.x), BOX.position.y - 20.0),
            "vel": Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(190.0, 270.0)),
            "r": 9.0, "c": Color(0.4, 0.8, 1.0)}
    else:
        var from_left := rng.randf() < 0.5
        var sp := rng.randf_range(170.0, 240.0)
        b = {
            "pos": Vector2(BOX.position.x - 20.0 if from_left else BOX.end.x + 20.0, rng.randf_range(BOX.position.y, BOX.end.y)),
            "vel": Vector2(sp if from_left else -sp, rng.randf_range(-30.0, 30.0)),
            "r": 13.0, "c": Color(0.55, 0.55, 0.55)}
    bullets.append(b)


func _draw_boss() -> void:
    var shake := Vector2(sin(t * 90.0) * 6.0, 0) if flash > 0.0 else Vector2.ZERO
    var base := Vector2(640, 170 + sin(t * 2.0) * 6.0) + shake
    if boss_id == "plastic":
        var c := Color.WHITE if flash > 0.0 else Color(0.3, 0.7, 0.9)
        draw_circle(base, 75.0, c)
        for i in 5:
            draw_rect(Rect2(base.x - 100 + i * 42, base.y + 40, 20, 55), c.darkened(0.2))
            draw_rect(Rect2(base.x - 96 + i * 42, base.y + 30, 12, 12), c.darkened(0.2))
        draw_circle(base + Vector2(-26, -10), 14.0, Color.WHITE)
        draw_circle(base + Vector2(26, -10), 14.0, Color.WHITE)
        draw_circle(base + Vector2(-26, -8), 6.0, Color.BLACK)
        draw_circle(base + Vector2(26, -8), 6.0, Color.BLACK)
    else:
        var c2 := Color.WHITE if flash > 0.0 else Color(0.4, 0.4, 0.42)
        draw_rect(Rect2(base.x - 120, base.y - 60, 240, 150), c2)
        draw_rect(Rect2(base.x - 90, base.y - 130, 32, 75), c2.darkened(0.2))
        draw_rect(Rect2(base.x + 55, base.y - 130, 32, 75), c2.darkened(0.2))
        for i in 3:
            draw_circle(base + Vector2(-74 + sin(t * 2.0 + i) * 10.0, -150 - i * 28), 14.0 + i * 3.0, Color(0.3, 0.3, 0.3, 0.7))
        draw_rect(Rect2(base.x - 60, base.y - 20, 40, 14), Color(0.9, 0.1, 0.1))
        draw_rect(Rect2(base.x + 20, base.y - 20, 40, 14), Color(0.9, 0.1, 0.1))


func _draw() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)
    _draw_boss()
    draw_rect(Rect2(440, 34, 400, 14), Color(0.25, 0.25, 0.25))
    draw_rect(Rect2(440, 34, 400.0 * boss_hp / boss_max, 14), Color(0.9, 0.2, 0.25))
    draw_string(font, Vector2(440, 28), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    draw_rect(BOX, Color.WHITE, false, 3.0)
    match state:
        S.TEXT:
            draw_multiline_string(font, BOX.position + Vector2(20, 40), msg, HORIZONTAL_ALIGNMENT_LEFT, BOX.size.x - 40.0, 20)
        S.MENU:
            var opts := ["Saldır", "Geri Dönüştür (x%d)" % GameState.recycle_stock, "Çöp Bombası (x%d)" % GameState.trash_stock]
            for i in 3:
                var col := Color.WHITE
                if (i == 1 and GameState.recycle_stock <= 0) or (i == 2 and GameState.trash_stock <= 0):
                    col = Color(0.5, 0.5, 0.5)
                var prefix := "> " if i == sel else "   "
                draw_string(font, BOX.position + Vector2(40, 50 + i * 45), prefix + opts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)
        S.DODGE:
            for b in bullets:
                draw_circle(b["pos"], b["r"], b["c"])
            if not (invuln > 0.0 and int(invuln * 20.0) % 2 == 0):
                draw_rect(Rect2(soul - Vector2(6, 6), Vector2(12, 12)), Color(0.3, 1.0, 0.5))
    var info := "CAN %d/%d    Kalkan %d    Kirlilik %d%%" % [player_hp, MAX_HP, GameState.upgrades["shield"], int(GameState.pollution)]
    draw_string(font, Vector2(440, 565), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    draw_string(font, Vector2(440, 600), "Yön tuşları / Enter: seç", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.6))
