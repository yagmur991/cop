extends CharacterBody2D

signal died

const GRAVITY := 1500.0
const ArtS = preload("res://scripts/art.gd")
const JUMP_V := -620.0

var jumps_left := 1
var facing := 1
var attack_cd := 0.0
var attack_vis := 0.0
var invuln := 0.0
var knock := 0.0
var spawn_pos := Vector2(100, 560)
var hitbox: Area2D
var _dead := false


func _ready() -> void:
    add_to_group("player")
    GameState.heat_wave.connect(_on_heat)
    collision_layer = 8
    collision_mask = 1
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(28, 44)
    cs.shape = r
    add_child(cs)

    hitbox = Area2D.new()
    hitbox.collision_layer = 0
    hitbox.collision_mask = 6   # düşman (2) + sandık (4)
    hitbox.monitoring = false
    var hs := CollisionShape2D.new()
    var hr := RectangleShape2D.new()
    hr.size = Vector2(44, 40)
    hs.shape = hr
    hitbox.add_child(hs)
    hitbox.position = Vector2(34, 0)
    hitbox.body_entered.connect(_on_hit_body)
    hitbox.area_entered.connect(_on_hit_area)
    add_child(hitbox)


func _on_hit_body(body: Node) -> void:
    if body.has_method("die"):
        body.die()


func _on_hit_area(area: Node) -> void:
    if area.has_method("open"):
        area.open()


func _physics_process(delta: float) -> void:
    attack_cd = maxf(0.0, attack_cd - delta)
    invuln = maxf(0.0, invuln - delta)
    knock = maxf(0.0, knock - delta)
    if attack_vis > 0.0:
        attack_vis -= delta
        if attack_vis <= 0.0:
            hitbox.set_deferred("monitoring", false)

    var dir := Input.get_axis("left", "right")
    if knock <= 0.0:
        velocity.x = dir * (280.0 + 50.0 * int(GameState.upgrades["speed"]))
    if dir != 0.0:
        facing = 1 if dir > 0.0 else -1
        hitbox.position.x = 34.0 * facing

    var max_jumps := 2 if GameState.upgrades["double_jump"] else 1
    if is_on_floor():
        jumps_left = max_jumps
    else:
        velocity.y += GRAVITY * delta
        jumps_left = mini(jumps_left, max_jumps - 1)

    if Input.is_action_just_pressed("jump") and jumps_left > 0:
        velocity.y = JUMP_V
        jumps_left -= 1
    if Input.is_action_just_released("jump") and velocity.y < -250.0:
        velocity.y *= 0.5

    if Input.is_action_just_pressed("attack") and attack_cd <= 0.0:
        attack_cd = GameState.attack_delay
        attack_vis = 0.15
        hitbox.monitoring = true

    move_and_slide()

    if position.y > 900.0:
        _lose_hp()
        if not _dead:
            position = spawn_pos
            velocity = Vector2.ZERO

    modulate.a = 0.4 if (invuln > 0.0 and int(invuln * 20.0) % 2 == 0) else 1.0
    queue_redraw()


func hurt(from_x: float) -> void:
    if invuln > 0.0 or _dead:
        return
    invuln = 1.0
    knock = 0.2
    var side := 1.0 if global_position.x >= from_x else -1.0
    velocity = Vector2(side * 320.0, -250.0)
    GameState.shake.emit(8.0, 0.25)
    GameState.hitstop.emit(0.07)
    GameState.burst.emit(global_position, Color(0.85, 0.3, 0.25), 8)
    if int(GameState.upgrades["shield"]) > 0:
        GameState.upgrades["shield"] -= 1
        GameState.changed.emit()
        GameState.item_collected.emit(Loc.t("msg_shield"))
        return
    _lose_hp()


func _lose_hp() -> void:
    GameState.hp -= 1
    GameState.changed.emit()
    if GameState.hp <= 0 and not _dead:
        _dead = true
        died.emit()


func _draw() -> void:
    var col: Color = GameState.player_color()
    draw_rect(Rect2(-14, -22, 28, 44), col)
    draw_rect(Rect2(-14, -22, 28, 10), col.darkened(0.2))
    draw_rect(Rect2(facing * 6 - 3, -16, 6, 6), Color.WHITE)
    draw_rect(Rect2(-5, 0, 10, 10), Color(0.2, 0.5, 0.9))  # geri dönüşüm rozeti
    # the trash type E would drop right now, floating above the head
    var held: String = GameState.trash_types[GameState.sel]
    if int(GameState.stock[held]) > 0:
        ArtS.trash(self, held, Vector2(0, -40.0 + sin(Time.get_ticks_msec() * 0.005) * 2.0), 0.8)
    if attack_vis > 0.0:
        var x := 14.0 if facing > 0 else -58.0
        draw_rect(Rect2(x, -20, 44, 40), Color(1, 1, 1, 0.45))


func _on_heat() -> void:
    if _dead or invuln > 0.0:
        return
    invuln = 1.0
    GameState.item_collected.emit(Loc.t("msg_heat"))
    _lose_hp()
