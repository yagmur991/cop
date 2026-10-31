extends Area2D
# Düşen upgrade itemi. kind: "recycle" veya "trash"

var kind := "recycle"
var t := 0.0


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
        queue_free()


func _process(delta: float) -> void:
    t += delta
    queue_redraw()


func _draw() -> void:
    var bob := sin(t * 4.0) * 4.0
    var col := Color(0.2, 0.8, 0.5) if kind == "recycle" else Color(0.5, 0.4, 0.3)
    draw_circle(Vector2(0, bob), 14.0, col)
    draw_arc(Vector2(0, bob), 14.0, 0, TAU, 24, Color.WHITE, 2.0)
    var letter := "R" if kind == "recycle" else "Ç"
    draw_string(ThemeDB.fallback_font, Vector2(-6, 6 + bob), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
