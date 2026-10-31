extends CharacterBody2D
# Platformer boss. Oyuncunun saldırısı die() çağırır -> hasar alır.
# plastic: şişe atar + zıplayıp üstüne düşer | factory: üstüne hücum eder + moloz yağdırır

signal defeated

const ItemS = preload("res://scripts/item.gd")
const ProjS = preload("res://scripts/projectile.gd")
const MIN_HITS := 6   # boss en az bu kadar vuruşta ölür (hasar yükseltmeleri ne olursa olsun)

var boss_id := "plastic"
var max_hp := 12
var hp := 12
var t := 0.0
var state_t := 2.0
var hit_cd := 0.0
var flash := 0.0
var dead := false
var charging := false
var charge_t := 0.0
var charge_dir := 1.0
var jump_vx := 0.0
var hits := 0
var player: Node2D
var hurt_area: Area2D


func _ready() -> void:
    add_to_group("boss")
    collision_layer = 2
    collision_mask = 1
    max_hp = 12 if boss_id == "plastic" else 16
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

    if charging:
        charge_t -= delta
        velocity.x = charge_dir * 430.0
        if is_on_wall() or charge_t <= 0.0:
            charging = false
            state_t = 1.4
    else:
        if is_on_floor():
            jump_vx = 0.0
            velocity.x = to_p * 70.0
        else:
            velocity.x = jump_vx
        if state_t <= 0.0 and is_on_floor():
            _next_attack(to_p)

    move_and_slide()

    for b in hurt_area.get_overlapping_bodies():
        if b.is_in_group("player"):
            b.hurt(global_position.x)
    queue_redraw()


func _next_attack(to_p: float) -> void:
    state_t = 2.2
    var roll := randi() % 2
    if boss_id == "plastic":
        if roll == 0:
            _throw_bottles()
        else:
            velocity.y = -720.0
            jump_vx = to_p * 280.0
    else:
        if roll == 0:
            charging = true
            charge_t = 2.0
            charge_dir = to_p if to_p != 0.0 else 1.0
        else:
            _rain()


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
    for m in [0.7, 1.0, 1.3]:
        _spawn_proj(global_position + Vector2(0, -50), Vector2(dx * m, -480.0), 900.0, 10.0, Color(0.4, 0.8, 1.0))


func _rain() -> void:
    for i in 6:
        _spawn_proj(Vector2(randf_range(80.0, 1200.0), -20.0), Vector2(0, 240.0), 0.0, 14.0, Color(0.5, 0.5, 0.5))


func die() -> void:
    if hit_cd > 0.0 or dead:
        return
    hit_cd = 0.35
    flash = 0.2
    hits += 1
    hp -= mini(1 + int(GameState.upgrades["damage"]), ceili(float(max_hp) / MIN_HITS))
    if hits % 3 == 0:
        var it := ItemS.new()
        it.kind = "recycle" if randf() < 0.5 else "trash"
        it.position = position + Vector2(0, -90)
        get_parent().call_deferred("add_child", it)
    if hp <= 0:
        dead = true
        defeated.emit()
        queue_free()


func _draw() -> void:
    var white := flash > 0.0
    if boss_id == "plastic":
        var c := Color.WHITE if white else Color(0.3, 0.7, 0.9)
        draw_circle(Vector2(0, 0), 48.0, c)
        draw_rect(Rect2(-12, -66, 24, 18), c.darkened(0.25))
        draw_circle(Vector2(-16, -8), 11.0, Color.WHITE)
        draw_circle(Vector2(16, -8), 11.0, Color.WHITE)
        draw_circle(Vector2(-16, -6), 5.0, Color.BLACK)
        draw_circle(Vector2(16, -6), 5.0, Color.BLACK)
    else:
        var c2 := Color.WHITE if white else Color(0.4, 0.4, 0.42)
        draw_rect(Rect2(-45, -50, 90, 100), c2)
        draw_rect(Rect2(-35, -85, 18, 38), c2.darkened(0.25))
        draw_rect(Rect2(17, -85, 18, 38), c2.darkened(0.25))
        for i in 3:
            draw_circle(Vector2(-26 + sin(t * 2.0 + i) * 6.0, -100 - i * 16), 8.0 + i * 2.0, Color(0.3, 0.3, 0.3, 0.7))
        draw_rect(Rect2(-28, -15, 22, 10), Color(0.9, 0.1, 0.1))
        draw_rect(Rect2(6, -15, 22, 10), Color(0.9, 0.1, 0.1))
    draw_rect(Rect2(-60, 58, 120, 8), Color(0.2, 0.2, 0.2))
    draw_rect(Rect2(-60, 58, 120.0 * maxf(hp, 0) / max_hp, 8), Color(0.9, 0.2, 0.25))
