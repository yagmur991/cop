extends Node2D
# Small one-shot particle burst (squares + dots). Spawned through GameState.burst -> main.gd.

const LIFE := 0.6

var col := Color.WHITE
var n := 10
var spd := 260.0
var t := 0.0
var pp := PackedVector2Array()
var vv := PackedVector2Array()
var rr := PackedFloat32Array()
var sq: Array = []
var cc: Array = []


func _ready() -> void:
    z_index = 20
    for i in n:
        var s := randf_range(0.35, 1.0) * spd
        pp.append(Vector2.ZERO)
        vv.append(Vector2.from_angle(randf() * TAU) * s + Vector2(0.0, -spd * 0.25))
        rr.append(randf_range(2.5, 5.5))
        sq.append(randf() < 0.5)
        cc.append(col.lerp(Color.WHITE, randf() * 0.4))


func _process(delta: float) -> void:
    t += delta
    if t >= LIFE:
        queue_free()
        return
    for i in pp.size():
        vv[i] = vv[i] + Vector2(0.0, 700.0 * delta)
        pp[i] = pp[i] + vv[i] * delta
    queue_redraw()


func _draw() -> void:
    var a := clampf(1.0 - t / LIFE, 0.0, 1.0)
    for i in pp.size():
        var c: Color = cc[i]
        c.a = a
        if sq[i]:
            draw_rect(Rect2(pp[i] - Vector2(rr[i], rr[i]) * 0.5, Vector2(rr[i], rr[i])), c)
        else:
            draw_circle(pp[i], rr[i] * 0.6, c)
