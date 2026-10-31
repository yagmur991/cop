extends CharacterBody2D
# Çöp canavarı: devriye gezer, tek vuruşta ölür, item düşürür.

const ItemS = preload("res://scripts/item.gd")

var origin_x := 0.0
var range_x := 70.0
var dir := 1
var t := 0.0
var dead := false
var hurt_area: Area2D


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
    var it := ItemS.new()
    if randf() < 0.6:
        it.kind = "trash"
        it.trash_type = GameState.next_trash_type()
    else:
        it.kind = "recycle"
    it.position = position + Vector2(0, -10)
    get_parent().call_deferred("add_child", it)
    queue_free()


func _draw() -> void:
    var squash := sin(t * 8.0) * 2.0
    draw_rect(Rect2(-15, -14 + squash, 30, 28 - squash), Color(0.45, 0.38, 0.3))
    draw_rect(Rect2(-8, -20 + squash, 16, 8), Color(0.6, 0.7, 0.75))  # şişe boynu
    draw_rect(Rect2(-9, -6, 6, 6), Color.WHITE)
    draw_rect(Rect2(3, -6, 6, 6), Color.WHITE)
    draw_rect(Rect2(-7, -4, 3, 3), Color.BLACK)
    draw_rect(Rect2(5, -4, 3, 3), Color.BLACK)
