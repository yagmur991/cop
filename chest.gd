extends Area2D
# Sandık. Oyuncunun saldırısıyla açılır. Origin = alt orta nokta.

const ItemS = preload("res://scripts/item.gd")

var kind := "recycle"   # recycle = güvenli, az item | trash = riskli, çok item
var opened := false


func _ready() -> void:
    collision_layer = 4
    collision_mask = 0
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(40, 32)
    cs.shape = r
    cs.position = Vector2(0, -16)
    add_child(cs)


func open() -> void:
    if opened:
        return
    opened = true
    queue_redraw()
    var n := 2 if kind == "recycle" else 3
    for i in n:
        var it := ItemS.new()
        it.kind = kind
        it.position = position + Vector2((i - (n - 1) / 2.0) * 32.0, -48)
        get_parent().call_deferred("add_child", it)


func _draw() -> void:
    var col := Color(0.2, 0.5, 0.9) if kind == "recycle" else Color(0.4, 0.4, 0.42)
    if opened:
        col = col.darkened(0.5)
    draw_rect(Rect2(-20, -32, 40, 32), col)
    draw_rect(Rect2(-22, -36, 44, 8), col.lightened(0.2))
    var label := "R" if kind == "recycle" else "Ç"
    draw_string(ThemeDB.fallback_font, Vector2(-6, -9), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
