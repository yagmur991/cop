extends CharacterBody2D
# Platformer boss. Oyuncunun saldırısı die() çağırır -> hasar alır.
# Her saldırıdan önce kısa bir uyarı ("!") var. Canı yarıya inince 2. faza geçer.
# plastic: şişe yağmuru / zıplayıp ezme + şok dalgası / plastik dalga / mikroplastik yağmuru
# factory: hücum / moloz yağmuru / nişanlı duman topları / kenarlardan duman dalgası
# land (Landfill Titan, final boss, 3 phases): çöp dikenleri / yuvarlanan çöp kayaları / zehirli varil + birikinti / çöp kargaları / gölgeli çöp düşüşü

signal defeated

const ItemS = preload("res://scripts/item.gd")
const ProjS = preload("res://scripts/projectile.gd")
const HazardS = preload("res://scripts/hazard.gd")
const FontsS = preload("res://scripts/fonts.gd")
const MIN_HITS := 6   # boss en az bu kadar vuruşta ölür (hasar yükseltmeleri ne olursa olsun)

var boss_id := "plastic"
var max_hp := 22
var hp := 22
var t := 0.0
var state_t := 2.5
var hit_cd := 0.0
var flash := 0.0
var dead := false
var charging := false
var charge_t := 0.0
var charge_dir := 1.0
var jump_vx := 0.0
var hits := 0
var windup := 0.0
var pending := ""
var slam := false
var air_t := 0.0
var phase2 := false
var phase3 := false      # land boss only
var later_q: Array = []   # delayed actions: {t, fn, args}
var last_attack := ""
var player: Node2D
var hurt_area: Area2D


func _ready() -> void:
    add_to_group("boss")
    collision_layer = 2
    collision_mask = 1
    var base_hp: int = int({"plastic": 22, "factory": 28, "land": 44}.get(boss_id, 22))
    max_hp = int(round(float(base_hp) * GameState.diff_boss()))
    hp = max_hp
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(90, 80)
    cs.shape = r
    cs.position = Vector2(0, 10)
    if boss_id == "land":
        r.size = Vector2(120, 104)
        cs.position = Vector2(0, 6)
    add_child(cs)
    hurt_area = Area2D.new()
    hurt_area.collision_layer = 0
    hurt_area.collision_mask = 8
    var hs := CollisionShape2D.new()
    var hr := RectangleShape2D.new()
    hr.size = Vector2(98, 108)
    if boss_id == "land":
        hr.size = Vector2(134, 120)
    hs.shape = hr
    hurt_area.add_child(hs)
    add_child(hurt_area)


func _physics_process(delta: float) -> void:
    if dead:
        return
    _run_later(delta)
    t += delta
    hit_cd = maxf(0.0, hit_cd - delta)
    flash = maxf(0.0, flash - delta)
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
    var to_p := 0.0
    if player:
        to_p = signf(player.global_position.x - global_position.x)
    velocity.y += 1500.0 * delta
    state_t -= delta
    var spd := 95.0 if phase2 else 70.0
    if boss_id == "land":
        spd = 110.0 if phase3 else (85.0 if phase2 else 60.0)

    if windup > 0.0:
        windup -= delta
        velocity.x = 0.0
        if windup <= 0.0:
            _exec(pending, to_p)
    elif charging:
        charge_t -= delta
        velocity.x = charge_dir * (520.0 if phase2 else 430.0)
        if is_on_wall() or charge_t <= 0.0:
            charging = false
            state_t = 1.2
    else:
        if is_on_floor():
            jump_vx = 0.0
            velocity.x = to_p * spd
        else:
            velocity.x = jump_vx
        if state_t <= 0.0 and is_on_floor():
            _next_attack()

    move_and_slide()

    if is_on_floor():
        if slam and air_t > 0.2:
            slam = false
            GameState.shake.emit(8.0, 0.25)
            _ground_wave(false)
        air_t = 0.0
    else:
        air_t += delta

    for b in hurt_area.get_overlapping_bodies():
        if b.is_in_group("player"):
            b.hurt(global_position.x)
    queue_redraw()


func _next_attack() -> void:
    if boss_id == "land":
        _next_land_attack()
        return
    var options: Array = ["throw", "jump", "wave", "rain"] if boss_id == "plastic" else ["charge", "rain", "smoke", "wave"]
    pending = options.pick_random()
    Sfx.play("warn")
    windup = 0.45 if phase2 else 0.65
    state_t = (1.4 if phase2 else 2.2) + windup


func _exec(attack: String, to_p: float) -> void:
    match attack:
        "throw":
            _throw_bottles()
        "jump":
            velocity.y = -720.0
            jump_vx = to_p * 280.0
            slam = true
        "wave":
            _ground_wave(boss_id == "factory")
        "rain":
            _rain()
        "charge":
            charging = true
            charge_t = 2.0
            charge_dir = to_p if to_p != 0.0 else 1.0
        "smoke":
            _smoke()
        "quake":
            _quake()
        "avalanche":
            _avalanche()
        "barrels":
            _barrels()
        "vultures":
            _vultures()
        "junkfall":
            _junkfall()


func _spawn_proj(pos: Vector2, v: Vector2, g: float, rad: float, col: Color) -> void:
    var p := ProjS.new()
    p.position = pos
    p.vel = v
    p.grav = g
    p.r = rad
    p.col = col
    get_parent().add_child(p)


func _throw_bottles() -> void:
    if player == null:
        return
    var dx := clampf(player.global_position.x - global_position.x, -500.0, 500.0)
    var mults: Array = [0.5, 0.75, 1.0, 1.25, 1.5] if phase2 else [0.7, 1.0, 1.3]
    for m in mults:
        _spawn_proj(global_position + Vector2(0, -50), Vector2(dx * m, -480.0), 900.0, 10.0, Color(0.4, 0.8, 1.0))


func _rain() -> void:
    var n := 9 if phase2 else 6
    var rad := 8.0 if boss_id == "plastic" else 14.0
    var col := Color(0.4, 0.8, 1.0) if boss_id == "plastic" else Color(0.5, 0.5, 0.5)
    for i in n:
        _spawn_proj(Vector2(randf_range(80.0, 1200.0), -20.0), Vector2(0, 260.0), 0.0, rad, col)


func _ground_wave(from_edges: bool) -> void:
    var sp := 380.0 if phase2 else 320.0
    if from_edges:
        _spawn_proj(Vector2(-20, 625), Vector2(sp, 0), 0.0, 16.0, Color(0.5, 0.5, 0.5))
        _spawn_proj(Vector2(1300, 625), Vector2(-sp, 0), 0.0, 16.0, Color(0.5, 0.5, 0.5))
    else:
        _spawn_proj(global_position + Vector2(-50, 30), Vector2(-sp, 0), 0.0, 14.0, Color(0.4, 0.8, 1.0))
        _spawn_proj(global_position + Vector2(50, 30), Vector2(sp, 0), 0.0, 14.0, Color(0.4, 0.8, 1.0))


func _smoke() -> void:
    if player == null:
        return
    var dir := (player.global_position - global_position).normalized()
    var angles: Array = [-0.45, -0.22, 0.0, 0.22, 0.45] if phase2 else [-0.25, 0.0, 0.25]
    for a in angles:
        _spawn_proj(global_position + Vector2(0, -20), dir.rotated(a) * 380.0, 0.0, 14.0, Color(0.5, 0.5, 0.5))


func _min_hits() -> int:
    return 9 if boss_id == "land" else MIN_HITS   # the final boss takes at least 9 hits


# ---------------- Landfill Titan (land boss) ----------------
func _lv() -> int:
    return 2 if phase3 else (1 if phase2 else 0)


func _sc() -> float:
    return 0.9 + 0.1 * float(GameState.difficulty)   # attack speed by difficulty


func _next_land_attack() -> void:
    var options: Array = ["quake", "avalanche", "barrels", "vultures", "junkfall"]
    options.erase(last_attack)
    pending = options.pick_random()
    last_attack = pending
    Sfx.play("warn")
    windup = 0.35 if phase3 else (0.45 if phase2 else 0.65)
    state_t = (0.8 if phase3 else (1.25 if phase2 else 1.8)) + windup


func _later(delay: float, fn: String, args: Array = []) -> void:
    later_q.append({"t": delay, "fn": fn, "args": args})


func _run_later(delta: float) -> void:
    var i := 0
    while i < later_q.size():
        var q: Dictionary = later_q[i]
        q["t"] = float(q["t"]) - delta
        if float(q["t"]) <= 0.0:
            later_q.remove_at(i)
            callv(String(q["fn"]), q["args"])
        else:
            i += 1


func _hazard(kind: String, pos: Vector2, props: Dictionary) -> void:
    var h := HazardS.new()
    h.kind = kind
    h.position = pos
    for k in props:
        h.set(k, props[k])
    get_parent().add_child(h)


# 1) QUAKE: pounds the ground; trash spikes erupt in both directions (+1 aimed at you from phase 2)
func _quake() -> void:
    var lv := _lv()
    GameState.shake.emit(10.0, 0.35)
    var per_side := 3 + lv
    var gap: float = [150.0, 125.0, 108.0][lv]
    for side in [-1.0, 1.0]:
        for k in range(1, per_side + 1):
            var x: float = global_position.x + float(side) * gap * float(k)
            if x < 30.0 or x > 1250.0:
                continue
            _hazard("spike", Vector2(x, 650.0), {"warn": 0.75 + 0.14 * float(k), "width": 56.0, "height": 112.0})
    if lv >= 1 and is_instance_valid(player):
        _hazard("spike", Vector2(player.global_position.x, 650.0), {"warn": 1.0, "width": 60.0, "height": 120.0})


# 2) AVALANCHE: big trash boulders roll in from alternating edges - jump them
func _avalanche() -> void:
    var lv := _lv()
    var spd: float = [300.0, 340.0, 390.0][lv] * _sc()
    var from_left := randf() < 0.5
    for i in 2 + lv:
        _later(0.9 * float(i) * (0.8 if lv == 2 else 1.0), "_boulder", [1.0 if from_left else -1.0, spd])
        from_left = not from_left


func _boulder(d: float, spd: float) -> void:
    _hazard("sweep", Vector2(-50.0 if d > 0.0 else 1330.0, 620.0), {"dir": d, "speed": spd, "radius": 30.0, "style": "boulder", "warn": 0.6})


# 3) BARRELS: lobs toxic barrels; each leaves a toxic puddle on the floor for a few seconds
func _barrels() -> void:
    for i in 2 + _lv():
        _later(0.35 * float(i), "_lob_barrel", [])


func _lob_barrel() -> void:
    var px := 640.0
    if is_instance_valid(player):
        px = player.global_position.x
    var tx := clampf(px + randf_range(-170.0, 170.0), 70.0, 1210.0)
    _hazard("barrel", global_position + Vector2(0, -60), {"target_x": tx, "fly_time": 0.95, "puddle_w": 150.0 + 20.0 * float(_lv()), "puddle_time": 5.0 + float(_lv())})


# 4) VULTURES: crows sweep across the screen at different heights (the first one aims at your height)
func _vultures() -> void:
    var lv := _lv()
    var ys: Array = [615.0, 560.0, 505.0, 450.0, 395.0]
    var from_left := randf() < 0.5
    for i in 3 + lv:
        var y: float = ys.pick_random()
        if i == 0 and is_instance_valid(player):
            y = clampf(player.global_position.y, 380.0, 630.0)
        _later(0.45 * float(i), "_bird", [1.0 if from_left else -1.0, y])
        from_left = not from_left


func _bird(d: float, y: float) -> void:
    var sp: float = [470.0, 520.0, 580.0][_lv()] * _sc()
    _hazard("sweep", Vector2(-50.0 if d > 0.0 else 1330.0, y), {"dir": d, "speed": sp, "radius": 16.0, "style": "bird", "warn": 0.7})


# 5) JUNKFALL: heavy junk falls where the shadows are, then bursts into shards along the floor
func _junkfall() -> void:
    var lv := _lv()
    var n: int = [3, 4, 6][lv]
    for i in n:
        var x := 640.0
        if is_instance_valid(player):
            x = player.global_position.x
        if i > 0:
            x += randf_range(-340.0, 340.0)
        x = clampf(x, 60.0, 1220.0)
        _hazard("drop", Vector2(x, -70.0), {"warn": 0.85 + 0.2 * float(i), "radius": 27.0, "shards": 2 + lv})


func die() -> void:
    if hit_cd > 0.0 or dead:
        return
    hit_cd = 0.35
    flash = 0.2
    hits += 1
    Sfx.play("boss_hit")
    GameState.burst.emit(global_position + Vector2(0, -20), Color(1.0, 0.95, 0.8), 10)
    GameState.shake.emit(5.0, 0.18)
    GameState.hitstop.emit(0.05)
    hp -= mini(1 + int(GameState.upgrades["damage"]), ceili(float(max_hp) / float(_min_hits())))
    if not phase2 and hp <= max_hp / 2.0 and hp > 0:
        phase2 = true
        GameState.item_collected.emit(Loc.t("msg_enraged"))
    if boss_id == "land" and not phase3 and hp <= max_hp * 0.25 and hp > 0:
        phase3 = true
        GameState.item_collected.emit(Loc.t("msg_fury"))
    if hits % 3 == 0:
        var it := ItemS.new()
        if randf() < 0.5:
            it.kind = "trash"
            it.trash_type = GameState.next_trash_type()
        else:
            it.kind = "recycle"
        it.position = position + Vector2(0, -90)
        get_parent().call_deferred("add_child", it)
    if hp <= 0:
        dead = true
        Sfx.play("boss_down")
        GameState.shake.emit(14.0, 0.6)
        GameState.hitstop.emit(0.18)
        for k in 4:
            GameState.burst.emit(global_position + Vector2(float(k - 2) * 30.0, -30.0), GameState.trash_colors[GameState.trash_types[k]], 14)
        later_q.clear()
        for h in get_tree().get_nodes_in_group("boss_hazard"):
            h.queue_free()
        defeated.emit()
        queue_free()


func _draw() -> void:
    var white := flash > 0.0
    var rage := Color(0.9, 0.2, 0.2)
    if boss_id == "plastic":
        var c := Color(0.3, 0.7, 0.9)
        if phase2:
            c = c.lerp(rage, 0.35)
        if white:
            c = Color.WHITE
        draw_circle(Vector2(0, 0), 48.0, c)
        draw_rect(Rect2(-12, -66, 24, 18), c.darkened(0.25))
        draw_circle(Vector2(-16, -8), 11.0, Color.WHITE)
        draw_circle(Vector2(16, -8), 11.0, Color.WHITE)
        draw_circle(Vector2(-16, -6), 5.0, Color.BLACK)
        draw_circle(Vector2(16, -6), 5.0, Color.BLACK)
    elif boss_id == "factory":
        var c2 := Color(0.4, 0.4, 0.42)
        if phase2:
            c2 = c2.lerp(rage, 0.3)
        if white:
            c2 = Color.WHITE
        draw_rect(Rect2(-45, -50, 90, 100), c2)
        draw_rect(Rect2(-35, -85, 18, 38), c2.darkened(0.25))
        draw_rect(Rect2(17, -85, 18, 38), c2.darkened(0.25))
        for i in 3:
            draw_circle(Vector2(-26 + sin(t * 2.0 + i) * 6.0, -100 - i * 16), 8.0 + i * 2.0, Color(0.3, 0.3, 0.3, 0.7))
        draw_rect(Rect2(-28, -15, 22, 10), Color(0.9, 0.1, 0.1))
        draw_rect(Rect2(6, -15, 22, 10), Color(0.9, 0.1, 0.1))
    else:
        _draw_land(white, rage)
    var is_land := boss_id == "land"
    if windup > 0.0:
        draw_string(FontsS.BTN, Vector2(-10, -150.0 if is_land else -110.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color(1.0, 0.2, 0.2))


func _draw_land(white: bool, rage: Color) -> void:
    var wob := sin(t * 2.0) * 2.0
    var base := Color(0.38, 0.32, 0.27)
    if phase2:
        base = base.lerp(rage, 0.18)
    if phase3:
        base = base.lerp(rage, 0.35)
    if white:
        base = Color.WHITE
    # mound body
    draw_colored_polygon(PackedVector2Array([Vector2(-66, 58), Vector2(-74, 18), Vector2(-60, -28), Vector2(-34, -50), Vector2(0, -56), Vector2(36, -48), Vector2(62, -24), Vector2(76, 18), Vector2(68, 58)]), base)
    draw_line(Vector2(-70, 8), Vector2(72, 14), base.darkened(0.25), 4.0)
    draw_line(Vector2(-64, 34), Vector2(66, 38), base.darkened(0.25), 4.0)
    for i in 16:
        var px := -58.0 + float((i * 37) % 112)
        var py := -44.0 + float((i * 53) % 96)
        if pow(px / 70.0, 2.0) + pow((py - 4.0) / 56.0, 2.0) < 0.82:
            var jc: Color = GameState.trash_colors[GameState.trash_types[i % 4]]
            draw_rect(Rect2(px, py, 10, 7), Color.WHITE if white else jc.darkened(0.15))
    for tx in [-58.0, 58.0]:
        draw_circle(Vector2(tx, 36), 17.0, Color(0.1, 0.1, 0.11))
        draw_circle(Vector2(tx, 36), 8.0, Color(0.3, 0.3, 0.32))
    # arms swinging
    var sw := sin(t * 3.0) * 8.0
    draw_line(Vector2(-66, -8), Vector2(-92, 22 + sw), base.darkened(0.15), 22.0)
    draw_line(Vector2(66, -8), Vector2(92, 22 - sw), base.darkened(0.15), 22.0)
    draw_circle(Vector2(-94, 26 + sw), 15.0, base.lightened(0.1))
    draw_circle(Vector2(94, 26 - sw), 15.0, base.lightened(0.1))
    # head with a crown of glass bottles
    var head := Color.WHITE if white else Color(0.5, 0.42, 0.35)
    draw_rect(Rect2(-30, -98 + wob, 60, 48), head)
    draw_rect(Rect2(-30, -98 + wob, 60, 8), head.darkened(0.2))
    for i in 4:
        var bx := -24.0 + float(i) * 16.0
        draw_colored_polygon(PackedVector2Array([Vector2(bx - 6.0, -98.0 + wob), Vector2(bx + 6.0, -98.0 + wob), Vector2(bx, -122.0 + wob - float(i % 2) * 8.0)]), Color.WHITE if white else Color(0.35, 0.75, 0.45))
    # glowing toxic eyes + core
    var glow := 0.6 + 0.4 * sin(t * 6.0)
    var ec := Color(1.0, 0.45, 0.2) if phase3 else Color(0.55, 1.0, 0.3)
    for ex in [-13.0, 13.0]:
        draw_circle(Vector2(ex, -74.0 + wob), 11.0, Color(ec, 0.25 * glow))
        draw_circle(Vector2(ex, -74.0 + wob), 6.0, ec)
    draw_line(Vector2(-24, -88.0 + wob), Vector2(-5, -80.0 + wob), Color(0.1, 0.07, 0.05), 4.0)
    draw_line(Vector2(24, -88.0 + wob), Vector2(5, -80.0 + wob), Color(0.1, 0.07, 0.05), 4.0)
    draw_rect(Rect2(-18, -62.0 + wob, 36, 8), Color(0.12, 0.08, 0.06))
    for i in 5:
        draw_rect(Rect2(-16.0 + float(i) * 7.0, -62.0 + wob, 4, 6), Color(0.85, 0.85, 0.8))
    var pulse := 0.5 + 0.5 * sin(t * (9.0 if phase3 else 5.0))
    draw_circle(Vector2(0, 16), 20.0, Color(ec, 0.15 + 0.15 * pulse))
    draw_circle(Vector2(0, 16), 11.0 + 2.0 * pulse, ec)
    # crows circling (more of them as it gets angrier)
    var crows := 2 + (2 if phase2 else 0) + (2 if phase3 else 0)
    for i in crows:
        var a := t * (1.4 + 0.2 * float(i)) + float(i) * TAU / float(crows)
        var cp := Vector2(cos(a) * 95.0, -112.0 + sin(a) * 26.0)
        var fl := sin(t * 14.0 + float(i)) * 5.0
        draw_line(cp + Vector2(-8, -fl), cp, Color(0.08, 0.08, 0.1), 3.0)
        draw_line(cp, cp + Vector2(8, -fl), Color(0.08, 0.08, 0.1), 3.0)
