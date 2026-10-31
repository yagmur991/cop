extends Area2D
# Boss gate, themed per boss. Locked until every recycling bin is full. Origin = top-left of the 80x200 door.
# plastic: ocean / plastic-waste gate    factory: gloomy grey steel factory gate

signal entered

var boss_id := "plastic"
var total := 4
var done := 0
var fired := false
var msg_cd := 0.0
var t := 0.0
var open_t := 0.0


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(80, 200)
    cs.shape = r
    cs.position = Vector2(40, 100)
    add_child(cs)


func unlocked() -> bool:
    return done >= total


func bin_done() -> void:
    done += 1
    GameState.bins_done = done
    if unlocked():
        GameState.item_collected.emit(Loc.t("msg_gate_open"))


func _process(delta: float) -> void:
    t += delta
    open_t = move_toward(open_t, 1.0 if unlocked() else 0.0, delta * 1.5)
    queue_redraw()


func _physics_process(delta: float) -> void:
    msg_cd = maxf(0.0, msg_cd - delta)
    for b in get_overlapping_bodies():
        if b.is_in_group("player"):
            if unlocked():
                if not fired:
                    fired = true
                    entered.emit()
            elif msg_cd <= 0.0:
                msg_cd = 2.5
                GameState.item_collected.emit(Loc.t("msg_gate_locked", [done, total]))


func _draw() -> void:
    if boss_id == "factory":
        _draw_factory()
    else:
        _draw_plastic()
    _draw_lock()


func _draw_lock() -> void:
    var f := ThemeDB.fallback_font
    if unlocked():
        draw_rect(Rect2(-10, -14, 100, 214), Color(0.4, 1.0, 0.5, 0.25 + 0.15 * sin(t * 4.0)), false, 4.0)
        return
    draw_line(Vector2(0, 40), Vector2(80, 150), Color(0.7, 0.7, 0.75), 5.0)
    draw_line(Vector2(80, 40), Vector2(0, 150), Color(0.7, 0.7, 0.75), 5.0)
    draw_arc(Vector2(40, 88), 10.0, PI, TAU, 12, Color(0.85, 0.75, 0.3), 4.0)
    draw_rect(Rect2(27, 88, 26, 22), Color(0.85, 0.7, 0.2))
    draw_circle(Vector2(40, 99), 3.0, Color(0.2, 0.15, 0.05))
    draw_string_outline(f, Vector2(0, 134), "%d/%d" % [done, total], HORIZONTAL_ALIGNMENT_CENTER, 80.0, 22, 6, Color.BLACK)
    draw_string(f, Vector2(0, 134), "%d/%d" % [done, total], HORIZONTAL_ALIGNMENT_CENTER, 80.0, 22, Color.WHITE)


func _draw_plastic() -> void:
    # frame
    draw_rect(Rect2(-10, -14, 100, 214), Color(0.06, 0.24, 0.3))
    draw_rect(Rect2(-14, -26, 108, 16), Color(0.1, 0.35, 0.4))
    for i in 3:
        draw_arc(Vector2(14 + i * 26, -18), 8.0, 0, TAU, 14, Color(0.8, 0.92, 0.96), 3.0)   # six-pack rings
    # glowing interior (visible when open)
    draw_rect(Rect2(0, 0, 80, 200), Color(0.3, 0.9, 0.85, 0.9))
    # door panel: wave bands, slides open
    var w := 80.0 * (1.0 - open_t * 0.85)
    for y in range(0, 200, 20):
        var c := Color(0.2, 0.55, 0.7).lerp(Color(0.35, 0.75, 0.85), 0.5 + 0.5 * sin(t * 1.5 + y * 0.2))
        draw_rect(Rect2(0, y, w, 20), c)
    for row in 4:
        var pts := PackedVector2Array()
        for k in 9:
            pts.append(Vector2(k * w / 8.0, 30.0 + row * 45.0 + sin(t * 2.0 + k * 0.9 + row) * 5.0))
        draw_polyline(pts, Color(0.85, 0.97, 1.0, 0.7), 2.0)
    # plastic bottles stuck in the frame
    draw_rect(Rect2(-8, 70, 8, 18), Color(0.5, 0.8, 1.0))
    draw_rect(Rect2(-6, 64, 4, 7), Color(0.9, 0.9, 0.95))
    draw_rect(Rect2(80, 130, 8, 18), Color(0.98, 0.82, 0.2))
    draw_rect(Rect2(82, 124, 4, 7), Color(0.9, 0.9, 0.95))
    # hanging plastic bag
    var sway := sin(t * 1.4) * 5.0
    draw_colored_polygon(PackedVector2Array([Vector2(60, -10), Vector2(88, -10), Vector2(94 + sway, 26), Vector2(74 + sway * 1.4, 44), Vector2(56 + sway, 22)]), Color(0.95, 0.95, 1.0, 0.6))
    # bubbles
    for i in 5:
        draw_circle(Vector2(8 + i * 16 + sin(t + i) * 3.0, 190 - fposmod(t * 25.0 + i * 37.0, 190.0)), 2.5 + (i % 2), Color(1, 1, 1, 0.5))
    # waves at the base
    var base := PackedVector2Array()
    for k in 13:
        base.append(Vector2(-10 + k * 8.5, 198 + sin(t * 2.0 + k) * 3.0))
    draw_polyline(base, Color(0.7, 0.95, 1.0), 3.0)


func _draw_factory() -> void:
    var steel := Color(0.26, 0.27, 0.29)
    # smokestacks + smoke
    draw_rect(Rect2(-6, -74, 20, 60), steel.darkened(0.25))
    draw_rect(Rect2(66, -96, 20, 82), steel.darkened(0.25))
    draw_rect(Rect2(-6, -74, 20, 6), Color(0.7, 0.2, 0.15))
    draw_rect(Rect2(66, -96, 20, 6), Color(0.7, 0.2, 0.15))
    for i in 6:
        var yy := -80.0 - i * 18.0 - fposmod(t * 28.0 + i * 12.0, 30.0)
        draw_circle(Vector2(4 + sin(t + i) * 7.0 + i * 3.0, yy), 9.0 + i * 2.5, Color(0.3, 0.3, 0.32, 0.6))
        draw_circle(Vector2(76 + sin(t * 1.2 + i) * 7.0 + i * 3.0, yy - 20.0), 10.0 + i * 2.5, Color(0.28, 0.28, 0.3, 0.55))
    # frame + pipes
    draw_rect(Rect2(-10, -14, 100, 214), steel)
    draw_rect(Rect2(-22, 20, 9, 180), steel.lightened(0.1))
    draw_rect(Rect2(93, 40, 9, 160), steel.lightened(0.1))
    for y in [50, 110, 170]:
        draw_rect(Rect2(-24, y, 13, 6), steel.darkened(0.3))
        draw_rect(Rect2(91, y, 13, 6), steel.darkened(0.3))
    # dark interior with ember glow (visible when open)
    draw_rect(Rect2(0, 0, 80, 200), Color(0.12, 0.05, 0.04))
    draw_rect(Rect2(0, 150, 80, 50), Color(0.9, 0.35, 0.1, 0.55))
    # door panel: slides up like a shutter
    var h := 200.0 * (1.0 - open_t * 0.9)
    draw_rect(Rect2(0, 0, 80, h), steel.lightened(0.05))
    for y in range(24, int(h), 26):
        draw_rect(Rect2(0, y, 80, 3), steel.darkened(0.35))
    # hazard stripes
    if h > 20.0:
        draw_rect(Rect2(0, 0, 80, 16), Color(0.9, 0.75, 0.1))
        for i in 6:
            var x0 := i * 16.0
            draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 8, 0), Vector2(x0 - 4, 16), Vector2(x0 - 12, 16)]), Color(0.1, 0.1, 0.1))
    # gear + rivets
    if h > 130.0:
        var c := Vector2(40, 100)
        draw_circle(c, 22.0, Color(0.18, 0.18, 0.2))
        for k in 8:
            var d := Vector2.from_angle(t * 0.8 + k * TAU / 8.0)
            draw_line(c + d * 18.0, c + d * 29.0, Color(0.18, 0.18, 0.2), 7.0)
        draw_circle(c, 7.0, steel)
        for p in [Vector2(6, 26), Vector2(74, 26), Vector2(6, 176), Vector2(74, 176)]:
            draw_circle(p, 3.0, steel.darkened(0.4))
    # warning light
    var lit := unlocked() or sin(t * 6.0) > 0.0
    var lc := Color(0.3, 0.95, 0.4) if unlocked() else Color(0.95, 0.2, 0.15)
    draw_circle(Vector2(40, -26), 9.0, lc if lit else lc.darkened(0.6))
    draw_arc(Vector2(40, -26), 9.0, 0, TAU, 14, Color(0.1, 0.1, 0.1), 2.0)
