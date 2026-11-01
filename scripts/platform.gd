extends StaticBody2D

var size := Vector2(100, 20)
var grass := true
var theme := "land"   # sea: sand, air: concrete, land: soil
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


func _colors(p: float) -> Array:
    if theme == "sea":
        return [Color(0.74, 0.64, 0.44).lerp(Color(0.42, 0.38, 0.3), p), Color(0.9, 0.82, 0.6).lerp(Color(0.52, 0.47, 0.34), p)]
    if theme == "air":
        return [Color(0.38, 0.4, 0.44).lerp(Color(0.24, 0.24, 0.26), p), Color(0.55, 0.57, 0.62).lerp(Color(0.34, 0.34, 0.34), p)]
    return [Color(0.36, 0.26, 0.2).lerp(Color(0.27, 0.23, 0.2), p), Color(0.3, 0.75, 0.35).lerp(Color(0.52, 0.44, 0.22), p)]


func _draw() -> void:
    var p := GameState.pollution / 100.0
    var cols := _colors(p)
    var body: Color = cols[0]
    var top: Color = cols[1]
    draw_rect(Rect2(Vector2.ZERO, size), body)
    if not grass:
        return
    draw_rect(Rect2(0, 0, size.x, 6), top)
    if theme == "sea":
        for i in int(size.x / 60.0):
            draw_rect(Rect2(float(i) * 60.0 + 14.0, 11.0, 12.0, 3.0), body.darkened(0.12))
    elif theme == "air":
        for i in int(size.x / 40.0):
            draw_rect(Rect2(float(i) * 40.0 + 10.0, 2.0, 18.0, 2.0), Color(0.9, 0.8, 0.3, 0.7))
    # kirlilik arttıkça yerlere çöp dolar
    var n := int(size.x / 50.0)
    for i in n:
        var h := (i * 7919 + int(position.x) * 31 + int(position.y) * 17) % 100
        if h < p * 100.0:
            var lx := (i + 0.5) * 50.0 + float((h * 13) % 24 - 12)
            var col: Color = GameState.trash_colors[GameState.trash_types[h % 4]]
            draw_rect(Rect2(lx, -7, 9, 7), col)
            draw_rect(Rect2(lx + 2, -10, 4, 3), col.lightened(0.3))
