extends StaticBody2D

var size := Vector2(100, 20)
var grass := true
var last_step := -1


func _ready() -> void:
    collision_layer = 1
    collision_mask = 0
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = size
    cs.shape = r
    cs.position = size / 2.0
    add_child(cs)


func _process(_delta: float) -> void:
    var step := int(GameState.pollution / 8.0)
    if step != last_step:
        last_step = step
        queue_redraw()


func _draw() -> void:
    var p := GameState.pollution / 100.0
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.26, 0.2).lerp(Color(0.27, 0.23, 0.2), p))
    if not grass:
        return
    draw_rect(Rect2(0, 0, size.x, 6), Color(0.3, 0.75, 0.35).lerp(Color(0.52, 0.44, 0.22), p))
    # kirlilik arttıkça yerlere çöp dolar
    var n := int(size.x / 50.0)
    for i in n:
        var h := (i * 7919 + int(position.x) * 31 + int(position.y) * 17) % 100
        if h < p * 100.0:
            var lx := (i + 0.5) * 50.0 + float((h * 13) % 24 - 12)
            var col: Color = GameState.trash_colors[GameState.trash_types[h % 4]]
            draw_rect(Rect2(lx, -7, 9, 7), col)
            draw_rect(Rect2(lx + 2, -10, 4, 3), col.lightened(0.3))
