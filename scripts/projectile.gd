extends Area2D
# Boss mermisi (şişe, moloz). Oyuncuya değince hasar verir.

var vel := Vector2.ZERO
var grav := 0.0
var r := 10.0
var col := Color(0.4, 0.8, 1.0)


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    var cs := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = r
    cs.shape = c
    add_child(cs)
    body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
    if body.is_in_group("player"):
        body.hurt(global_position.x)
        queue_free()


func _physics_process(delta: float) -> void:
    vel.y += grav * delta
    position += vel * delta
    if position.y > 900.0 or position.x < -100.0 or position.x > 1400.0:
        queue_free()


func _draw() -> void:
    draw_circle(Vector2.ZERO, r, col)
    draw_arc(Vector2.ZERO, r, 0, TAU, 20, Color.WHITE, 2.0)
