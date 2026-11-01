extends CharacterBody2D
# Çöp canavarı: devriye gezer, tek vuruşta ölür, item düşürür.

const ItemS = preload("res://scripts/item.gd")
const SpritesS = preload("res://scripts/sprites.gd")

var origin_x := 0.0
var range_x := 70.0
var dir := 1
var t := 0.0
var dead := false
var hurt_area: Area2D
var theme := "land"   # level theme (sea / air / land) - only used for the death particle colour now
var sprite: Sprite2D


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
    # 32x40 monster sprite, standing on the bottom of the collision box
    sprite = SpritesS.make(SpritesS.ENEMY, 1.0)
    sprite.position = Vector2(0, 14)
    add_child(sprite)


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
    sprite.flip_h = dir < 0
    sprite.scale.y = 1.0 + sin(t * 8.0) * 0.04   # little squash, anchored at the feet


func die() -> void:
    if dead:
        return
    dead = true
    Sfx.play("enemy_pop")
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
