extends CharacterBody2D
# Platformer boss. Oyuncunun saldırısı die() çağırır -> hasar alır.
# Her saldırıdan önce kısa bir uyarı ("!") var. Canı yarıya inince 2. faza geçer.
# plastic: şişe yağmuru / zıplayıp ezme + şok dalgası / plastik dalga / mikroplastik yağmuru
# factory: hücum / moloz yağmuru / nişanlı duman topları / kenarlardan duman dalgası

signal defeated

const ItemS = preload("res://scripts/item.gd")
const ProjS = preload("res://scripts/projectile.gd")
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
var player: Node2D
var hurt_area: Area2D


func _ready() -> void:
    add_to_group("boss")
    collision_layer = 2
    collision_mask = 1
    var base_hp := 22 if boss_id == "plastic" else 28
    max_hp = int(round(float(base_hp) * GameState.diff_boss()))
    hp = max_hp
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(90, 80)
    cs.shape = r
    cs.position = Vector2(0, 10)
    add_child(cs)
    hurt_area = Area2D.new()
    hurt_area.collision_layer = 0
    hurt_area.collision_mask = 8
    var hs := CollisionShape2D.new()
    var hr := RectangleShape2D.new()
    hr.size = Vector2(98, 108)
    hs.shape = hr
    hurt_area.add_child(hs)
    add_child(hurt_area)


func _physics_process(delta: float) -> void:
    if dead:
        return
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
            _ground_wave(false)
        air_t = 0.0
    else:
        air_t += delta

    for b in hurt_area.get_overlapping_bodies():
        if b.is_in_group("player"):
            b.hurt(global_position.x)
    queue_redraw()


func _next_attack() -> void:
    var options: Array = ["throw", "jump", "wave", "rain"] if boss_id == "plastic" else ["charge", "rain", "smoke", "wave"]
    pending = options.pick_random()
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


func die() -> void:
    if hit_cd > 0.0 or dead:
        return
    hit_cd = 0.35
    flash = 0.2
    hits += 1
    hp -= mini(1 + int(GameState.upgrades["damage"]), ceili(float(max_hp) / MIN_HITS))
    if not phase2 and hp <= max_hp / 2.0 and hp > 0:
        phase2 = true
        GameState.item_collected.emit(Loc.t("msg_enraged"))
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
    else:
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
    if windup > 0.0:
        draw_string(ThemeDB.fallback_font, Vector2(-10, -110), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color(1.0, 0.2, 0.2))
    draw_rect(Rect2(-60, 58, 120, 8), Color(0.2, 0.2, 0.2))
    draw_rect(Rect2(-60, 58, 120.0 * maxf(hp, 0) / max_hp, 8), Color(0.9, 0.2, 0.25))
