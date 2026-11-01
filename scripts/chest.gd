extends Area2D
# Sandık. Oyuncunun saldırısıyla açılır. Origin = alt orta nokta.

const ItemS = preload("res://scripts/item.gd")

var kind := "recycle"   # recycle = güvenli, az item | trash = riskli, çok item
var opened := false
var sprite: Sprite2D
var pending := 0       # saplings from this chest not yet picked up
var grown := false     # true once all saplings are picked up -> grown tree


func _ready() -> void:
    collision_layer = 4
    collision_mask = 0
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(40, 32)
    cs.shape = r
    cs.position = Vector2(0, -16)
    add_child(cs)
    if kind == "trash":
        sprite = Sprite2D.new()
        sprite.texture = preload("res://assets/Sprite-0001-Sheet.png")
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.scale = Vector2(0.6, 0.6)    # 64x64 -> ~38x38
        sprite.position = Vector2(0, -19)   # origin is bottom-middle
        add_child(sprite)


func open() -> void:
    if opened:
        return
    opened = true
    Sfx.play("chest")
    GameState.burst.emit(global_position + Vector2(0, -20), Color(0.75, 0.6, 0.4), 10)
    GameState.shake.emit(2.5, 0.12)
    if sprite:
        sprite.modulate = Color(0.5, 0.5, 0.5)
    queue_redraw()
    var n := 2 if kind == "recycle" else 3
    if kind == "recycle":
        pending = n
    for i in n:
        var it := ItemS.new()
        it.kind = kind
        if kind == "recycle":
            it.source = self
        else:
            it.trash_type = GameState.next_trash_type()
        it.position = position + Vector2((i - (n - 1) / 2.0) * 32.0, -48)
        get_parent().call_deferred("add_child", it)


func item_taken() -> void:
    pending -= 1
    if pending <= 0 and not grown:
        grown = true
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


func _sapling(base: Vector2, k: float, dim: float) -> void:
    # base = where the stem meets the soil, k = size, dim = 0.0 normal / 0.5 when opened
    draw_line(base, base + Vector2(0, -13.0 * k), Color(0.25, 0.5, 0.2).darkened(dim), 3.0 * k)
    _leaf(base + Vector2(0, -7.0 * k), -PI * 0.85, 13.0 * k, 5.0 * k, Color(0.2, 0.7, 0.3).darkened(dim))
    _leaf(base + Vector2(0, -10.0 * k), -PI * 0.15, 13.0 * k, 5.0 * k, Color(0.3, 0.85, 0.4).darkened(dim))
    _leaf(base + Vector2(0, -13.0 * k), -PI * 0.5, 12.0 * k, 4.0 * k, Color(0.4, 0.95, 0.5).darkened(dim))


func _draw() -> void:
    if kind == "trash":
        return   # drawn by the sprite
    if grown:
        _tree()
        return
    # recycle: a bunch of saplings on a soil bed
    var dim := 0.5 if opened else 0.0
    draw_rect(Rect2(-20, -6, 40, 6), Color(0.4, 0.28, 0.2).darkened(dim))
    _sapling(Vector2(-12, -5), 0.8, dim)
    _sapling(Vector2(12, -5), 0.9, dim)
    _sapling(Vector2(0, -5), 1.0, dim)


func _tree() -> void:
    draw_rect(Rect2(-14, -4, 28, 4), Color(0.4, 0.28, 0.2))
    draw_rect(Rect2(-6, -38, 12, 36), Color(0.42, 0.28, 0.18))
    draw_rect(Rect2(-6, -38, 4, 36), Color(0.34, 0.22, 0.14))
    draw_circle(Vector2(-17, -46), 16.0, Color(0.18, 0.55, 0.26))
    draw_circle(Vector2(17, -46), 16.0, Color(0.18, 0.55, 0.26))
    draw_circle(Vector2(0, -58), 22.0, Color(0.22, 0.65, 0.3))
    draw_circle(Vector2(-6, -64), 12.0, Color(0.32, 0.8, 0.4))
