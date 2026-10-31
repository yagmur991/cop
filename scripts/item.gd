extends Area2D
# Düşen upgrade itemi. kind: "recycle" veya "trash"

var kind := "recycle"
var t := 0.0
var source: Node = null   # chest that dropped this sapling (optional)
var variant := randi() % 2   # trash look: 0 = crushed cola can, 1 = crumpled paper


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    var cs := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 16.0
    cs.shape = c
    add_child(cs)
    body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
    if body.is_in_group("player"):
        GameState.apply_item(kind)
        if is_instance_valid(source) and source.has_method("item_taken"):
            source.item_taken()
        queue_free()


func _process(delta: float) -> void:
    t += delta
    queue_redraw()


func _leaf(base: Vector2, ang: float, length: float, wid: float, col: Color) -> void:
    var dir := Vector2.from_angle(ang)
    var nor := dir.orthogonal()
    var pts := PackedVector2Array()
    for i in range(0, 9):
        var u := i / 8.0
        pts.append(base + dir * length * u + nor * wid * sin(u * PI))
    for i in range(7, 0, -1):
        var u := i / 8.0
        pts.append(base + dir * length * u - nor * wid * sin(u * PI))
    draw_colored_polygon(pts, col)


func _draw() -> void:
    var bob := sin(t * 4.0) * 4.0
    if kind == "recycle":
        # Sapling: soft glow, soil, stem, three leaves
        draw_circle(Vector2(0, bob), 16.0, Color(0.6, 1.0, 0.7, 0.22))
        draw_rect(Rect2(-8, 10 + bob, 16, 4), Color(0.4, 0.28, 0.2))
        draw_line(Vector2(0, 11 + bob), Vector2(0, -2 + bob), Color(0.25, 0.5, 0.2), 3.0)
        _leaf(Vector2(0, 4 + bob), -PI * 0.85, 13.0, 5.0, Color(0.2, 0.7, 0.3))
        _leaf(Vector2(0, 1 + bob), -PI * 0.15, 13.0, 5.0, Color(0.3, 0.85, 0.4))
        _leaf(Vector2(0, -2 + bob), -PI * 0.5, 12.0, 4.0, Color(0.4, 0.95, 0.5))
        return
    draw_circle(Vector2(0, bob), 16.0, Color(1.0, 0.9, 0.7, 0.18))
    if variant == 0:
        _draw_can(bob)
    else:
        _draw_paper(bob)


func _draw_can(bob: float) -> void:
    draw_set_transform(Vector2(0, bob), -0.45, Vector2.ONE)
    var body := PackedVector2Array([
        Vector2(-8, -12), Vector2(8, -12), Vector2(9, -5), Vector2(5, 0), Vector2(9, 6),
        Vector2(8, 12), Vector2(-8, 12), Vector2(-10, 5), Vector2(-6, 0), Vector2(-9, -4)])
    draw_colored_polygon(body, Color(0.8, 0.12, 0.12))
    draw_polyline(PackedVector2Array([Vector2(-8, -4), Vector2(-3, -7), Vector2(2, -2), Vector2(7, -5)]), Color.WHITE, 3.0)
    draw_polyline(PackedVector2Array([Vector2(-8, 6), Vector2(-3, 3), Vector2(2, 8), Vector2(7, 5)]), Color.WHITE, 3.0)
    draw_line(Vector2(-6, 0), Vector2(5, 0), Color(0.45, 0.05, 0.05), 2.0)
    draw_rect(Rect2(-8, -14, 16, 3), Color(0.8, 0.8, 0.84))
    draw_rect(Rect2(-8, 11, 16, 2), Color(0.65, 0.65, 0.7))
    draw_circle(Vector2(1, -13), 2.0, Color(0.55, 0.55, 0.6))
    draw_polyline(body + PackedVector2Array([body[0]]), Color(0.35, 0.04, 0.04), 1.5)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_paper(bob: float) -> void:
    draw_set_transform(Vector2(0, bob), 0.3, Vector2.ONE)
    var radii := [12.0, 9.5, 13.0, 10.0, 12.5, 9.0, 13.0, 10.5, 12.0, 9.5]
    var pts := PackedVector2Array()
    for i in 10:
        pts.append(Vector2.from_angle(i * TAU / 10.0) * radii[i])
    draw_colored_polygon(pts, Color(0.94, 0.93, 0.86))
    draw_colored_polygon(PackedVector2Array([Vector2(2, -1), Vector2(6, 6), Vector2(-4, 7)]), Color(0.8, 0.78, 0.7))
    draw_colored_polygon(PackedVector2Array([Vector2(-7, -3), Vector2(-2, -8), Vector2(2, -1)]), Color(0.86, 0.85, 0.78))
    var fold := Color(0.5, 0.48, 0.42)
    draw_line(Vector2(-6, -3), Vector2(2, -1), fold, 1.2)
    draw_line(Vector2(2, -1), Vector2(7, -7), fold, 1.2)
    draw_line(Vector2(-2, -1), Vector2(-4, 7), fold, 1.2)
    draw_line(Vector2(2, -1), Vector2(5, 6), fold, 1.2)
    draw_line(Vector2(-8, 3), Vector2(-1, 2), fold, 1.2)
    draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.43, 0.38), 1.5)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
