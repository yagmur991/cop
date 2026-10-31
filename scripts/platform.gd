extends StaticBody2D

var size := Vector2(100, 20)
var grass := true


func _ready() -> void:
    collision_layer = 1
    collision_mask = 0
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = size
    cs.shape = r
    cs.position = size / 2.0
    add_child(cs)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.26, 0.2))
    if grass:
        draw_rect(Rect2(0, 0, size.x, 6), Color(0.3, 0.75, 0.35))
