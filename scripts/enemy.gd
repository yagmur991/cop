extends CharacterBody2D
# Çöp canavarı: devriye gezer, tek vuruşta ölür, item düşürür.

const ItemS = preload("res://scripts/item.gd")

var origin_x := 0.0
var range_x := 70.0
var dir := 1
var t := 0.0
var dead := false
var hurt_area: Area2D
var theme := "land"   # sea: plastic-bag jellyfish, air: smog puff, land: tire monster


func _ready() -> void:
    add_to_group("enemy")
    collision_layer = 2
    collision_mask = 1
    origin_x = position.x
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(30, 28)
    cs.shape = r
    add_child(cs)
    hurt_area = Area2D.new()
    hurt_area.collision_layer = 0
    hurt_area.collision_mask = 8
    var hs := CollisionShape2D.new()
    var hr := RectangleShape2D.new()
    hr.size = Vector2(32, 30)
    hs.shape = hr
    hurt_area.add_child(hs)
    add_child(hurt_area)


func _physics_process(delta: float) -> void:
    t += delta
    velocity.y += 1500.0 * delta
    velocity.x = dir * 60.0 * (1.0 + GameState.pollution / 100.0) * GameState.diff_enemy()
    move_and_slide()
    if position.x > origin_x + range_x:
        dir = -1
    elif position.x < origin_x - range_x:
        dir = 1
    if is_on_wall():
        dir *= -1
    for b in hurt_area.get_overlapping_bodies():
        if b.is_in_group("player"):
            b.hurt(global_position.x)
    queue_redraw()


func die() -> void:
    if dead:
        return
    dead = true
    GameState.lv_stats["kills"] += 1
    GameState.burst.emit(global_position, _body_color(), 9)
    GameState.shake.emit(2.0, 0.1)
    GameState.hitstop.emit(0.03)
    var it := ItemS.new()
    if randf() < 0.6:
        it.kind = "trash"
        it.trash_type = GameState.next_trash_type()
    else:
        it.kind = "recycle"
    it.position = position + Vector2(0, -10)
    get_parent().call_deferred("add_child", it)
    queue_free()


func _body_color() -> Color:
    if theme == "sea":
        return Color(0.85, 0.92, 1.0)
    if theme == "air":
        return Color(0.5, 0.5, 0.55)
    return Color(0.3, 0.3, 0.33)


func _eyes(y: float, glow: Color) -> void:
    draw_circle(Vector2(-6, y), 4.0, Color.WHITE)
    draw_circle(Vector2(6, y), 4.0, Color.WHITE)
    draw_circle(Vector2(-6 + dir * 1.5, y + 0.5), 2.0, glow)
    draw_circle(Vector2(6 + dir * 1.5, y + 0.5), 2.0, glow)


func _draw_bag(sq: float) -> void:
    var body := Color(0.94, 0.96, 1.0, 0.88)
    var edge := Color(0.55, 0.72, 0.85)
    var pts := PackedVector2Array([Vector2(-13, -12 + sq), Vector2(13, -12 + sq), Vector2(16, 2), Vector2(9, 13), Vector2(-9, 13), Vector2(-16, 2)])
    draw_colored_polygon(pts, body)
    draw_polyline(pts + PackedVector2Array([pts[0]]), edge, 2.0)
    draw_arc(Vector2(-6, -12 + sq), 5.0, PI, TAU, 8, edge, 2.0)
    draw_arc(Vector2(6, -12 + sq), 5.0, PI, TAU, 8, edge, 2.0)
    for i in 3:
        var x := -7.0 + float(i) * 7.0
        draw_line(Vector2(x, 13), Vector2(x + sin(t * 6.0 + float(i)) * 3.0, 21), edge, 2.0)
    _eyes(-2.0, Color(0.1, 0.15, 0.3))


func _draw_smog(sq: float) -> void:
    var c := Color(0.38, 0.37, 0.4)
    draw_circle(Vector2(-8, 2), 10.0, c)
    draw_circle(Vector2(8, 2), 10.0, c)
    draw_circle(Vector2(0, -4 + sq), 12.0, c.lightened(0.08))
    draw_circle(Vector2(0, 6), 10.0, c.darkened(0.1))
    for i in 3:
        draw_circle(Vector2(sin(t * 3.0 + float(i)) * 6.0, -17.0 - fposmod(t * 20.0 + float(i) * 8.0, 16.0)), 3.0 + float(i), Color(0.42, 0.42, 0.45, 0.5))
    _eyes(-3.0, Color(0.9, 0.15, 0.1))


func _draw_tire(sq: float) -> void:
    var cy := sq * 0.4
    draw_circle(Vector2(0, cy), 14.0, Color(0.1, 0.1, 0.11))
    draw_circle(Vector2(0, cy), 7.0, Color(0.33, 0.33, 0.36))
    for i in 8:
        var a := t * 3.0 * float(dir) + float(i) * TAU / 8.0
        draw_line(Vector2.from_angle(a) * 11.0 + Vector2(0, cy), Vector2.from_angle(a) * 14.5 + Vector2(0, cy), Color(0.32, 0.32, 0.35), 2.5)
    _eyes(-3.0 + cy, Color(0.1, 0.1, 0.1))


func _draw() -> void:
    var squash := sin(t * 8.0) * 2.0
    if theme == "sea":
        _draw_bag(squash)
        return
    if theme == "air":
        _draw_smog(squash)
        return
    if theme == "land":
        _draw_tire(squash)
        return
    draw_rect(Rect2(-15, -14 + squash, 30, 28 - squash), Color(0.45, 0.38, 0.3))
    draw_rect(Rect2(-8, -20 + squash, 16, 8), Color(0.6, 0.7, 0.75))  # şişe boynu
    draw_rect(Rect2(-9, -6, 6, 6), Color.WHITE)
    draw_rect(Rect2(3, -6, 6, 6), Color.WHITE)
    draw_rect(Rect2(-7, -4, 3, 3), Color.BLACK)
    draw_rect(Rect2(5, -4, 3, 3), Color.BLACK)
