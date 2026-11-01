extends Area2D
# Hazards spawned by the Landfill Titan (land boss). Every hazard shows a warning first.
# spike:  trash spikes erupt from the floor (cracks glow on the ground before)
# barrel: a toxic barrel is lobbed, lands and leaves a toxic puddle for a few seconds
# sweep:  a boulder (floor) or a crow (any height) crosses the screen; a marker shows the edge + height first
# drop:   a heavy junk chunk falls where its shadow shows, then bursts into shards

const ProjS = preload("res://scripts/projectile.gd")
const GROUND_Y := 650.0

var kind := "spike"
var warn := 0.8            # telegraph time before the hazard becomes dangerous
var t := 0.0
var dir := 1.0             # sweep direction
var speed := 400.0         # sweep speed
var radius := 16.0         # sweep / drop radius
var style := "boulder"     # sweep look: boulder / bird
var height := 110.0        # spike
var width := 56.0          # spike
var target_x := 640.0      # barrel landing x
var fly_time := 0.95       # barrel flight time
var puddle_w := 150.0
var puddle_time := 5.0
var shards := 2            # drop: shards after impact
var state := "warn"        # warn / active / puddle
var x0 := 0.0
var y0 := 0.0
var spin := 0.0
var cs: CollisionShape2D


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    monitoring = false
    add_to_group("boss_hazard")
    cs = CollisionShape2D.new()
    add_child(cs)
    x0 = position.x
    y0 = position.y
    match kind:
        "spike":
            var r := RectangleShape2D.new()
            r.size = Vector2(width - 8.0, height)
            cs.shape = r
            cs.position = Vector2(0, -height / 2.0)
        "barrel":
            state = "active"
            _circle(15.0)
            monitoring = true
        "sweep":
            _circle(radius - 3.0)
        "drop":
            _circle(radius - 2.0)


func _circle(r: float) -> void:
    var c := CircleShape2D.new()
    c.radius = r
    cs.shape = c
    cs.position = Vector2.ZERO


func _hit_player() -> void:
    if not monitoring:
        return
    for b in get_overlapping_bodies():
        if b.is_in_group("player"):
            b.hurt(global_position.x)
            return


func _physics_process(delta: float) -> void:
    t += delta
    match kind:
        "spike":
            _step_spike()
        "barrel":
            _step_barrel(delta)
        "sweep":
            _step_sweep(delta)
        "drop":
            _step_drop(delta)
    queue_redraw()


func _step_spike() -> void:
    if state == "warn" and t >= warn:
        state = "active"
        monitoring = true
    if state == "active":
        _hit_player()
        if t >= warn + 0.6:
            queue_free()


func _step_barrel(delta: float) -> void:
    if state == "active":
        var u := clampf(t / fly_time, 0.0, 1.0)
        position.x = lerpf(x0, target_x, u)
        position.y = lerpf(y0, GROUND_Y - 16.0, u) - 4.0 * 260.0 * u * (1.0 - u)
        spin += delta * 9.0
        _hit_player()
        if u >= 1.0:
            _become_puddle()
    elif state == "puddle":
        _hit_player()
        if t >= puddle_time:
            queue_free()


func _become_puddle() -> void:
    state = "puddle"
    t = 0.0
    position = Vector2(target_x, GROUND_Y)
    var r := RectangleShape2D.new()
    r.size = Vector2(puddle_w, 14.0)
    cs.shape = r
    cs.position = Vector2(0, -7)
    add_to_group("puddle")
    var puddles := get_tree().get_nodes_in_group("puddle")
    if puddles.size() > 5:
        puddles[0].queue_free()


func _step_sweep(delta: float) -> void:
    if state == "warn" and t >= warn:
        state = "active"
        monitoring = true
    if state == "active":
        position.x += dir * speed * delta
        spin += dir * speed / maxf(radius, 1.0) * delta
        _hit_player()
        if position.x < -140.0 or position.x > 1420.0:
            queue_free()


func _step_drop(delta: float) -> void:
    if state == "warn" and t >= warn:
        state = "active"
        monitoring = true
    if state == "active":
        position.y += 950.0 * delta
        spin += delta * 3.0
        _hit_player()
        if position.y >= GROUND_Y - radius:
            _burst()
            queue_free()


func _burst() -> void:
    var n := maxi(shards, 2)
    for i in n:
        var side := -1.0 if i % 2 == 0 else 1.0
        var p := ProjS.new()
        p.position = Vector2(position.x, GROUND_Y - 12.0)
        p.vel = Vector2(side * (230.0 + 35.0 * float(i)), 0.0)
        p.grav = 0.0
        p.r = 9.0
        p.col = Color(0.62, 0.42, 0.26)
        get_parent().add_child(p)


# ---------------- drawing ----------------
func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
    var pts := PackedVector2Array()
    for k in 18:
        var a := float(k) / 18.0 * TAU
        pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
    draw_colored_polygon(pts, col)


func _draw() -> void:
    match kind:
        "spike":
            _draw_spike()
        "barrel":
            _draw_barrel()
        "sweep":
            _draw_sweep()
        "drop":
            _draw_drop()


func _draw_spike() -> void:
    var hw := width / 2.0
    if state == "warn":
        var k := clampf(t / warn, 0.0, 1.0)
        var blink := 1.0 if int(t * 12.0) % 2 == 0 else 0.55
        var col := Color(0.95, 0.55, 0.2, (0.35 + 0.45 * k) * blink)
        draw_line(Vector2(-hw, 0), Vector2(-hw * 0.4, -5), col, 3.0)
        draw_line(Vector2(-hw * 0.4, -5), Vector2(0, 1), col, 3.0)
        draw_line(Vector2(0, 1), Vector2(hw * 0.5, -6), col, 3.0)
        draw_line(Vector2(hw * 0.5, -6), Vector2(hw, 0), col, 3.0)
        for i in 3:
            draw_circle(Vector2(float(i - 1) * 14.0, -6.0 - fposmod(t * 40.0 + float(i) * 9.0, 18.0)), 3.0, Color(0.7, 0.6, 0.5, 0.45 * k))
        return
    var life_t := t - warn
    var grow := clampf(life_t / 0.07, 0.0, 1.0)
    var shrink := clampf((0.6 - life_t) / 0.18, 0.0, 1.0)
    var h := height * minf(grow, shrink)
    if h < 4.0:
        return
    var rust := Color(0.52, 0.33, 0.2)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-hw, 0), Vector2(-hw * 0.55, -h * 0.55), Vector2(-hw * 0.2, -h * 0.45), Vector2(0, -h),
        Vector2(hw * 0.25, -h * 0.5), Vector2(hw * 0.6, -h * 0.62), Vector2(hw, 0)]), rust)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-hw * 0.4, 0), Vector2(0, -h * 0.9), Vector2(hw * 0.3, 0)]), rust.lightened(0.18))
    draw_rect(Rect2(-hw * 0.7, -h * 0.3, 9, 6), Color(0.45, 0.78, 0.5))
    draw_rect(Rect2(hw * 0.2, -h * 0.22, 10, 6), Color(0.85, 0.8, 0.3))
    draw_rect(Rect2(-4, -h * 0.65, 8, 8), Color(0.72, 0.74, 0.78))


func _draw_barrel() -> void:
    if state == "active":
        draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
        draw_rect(Rect2(-11, -15, 22, 30), Color(0.35, 0.55, 0.25))
        draw_rect(Rect2(-11, -8, 22, 4), Color(0.2, 0.3, 0.15))
        draw_rect(Rect2(-11, 4, 22, 4), Color(0.2, 0.3, 0.15))
        draw_circle(Vector2.ZERO, 4.0, Color(0.85, 0.95, 0.3))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        return
    var fade := clampf((puddle_time - t) / 1.0, 0.0, 1.0)
    var blink := 1.0 if (fade > 0.99 or int(t * 10.0) % 2 == 0) else 0.6
    var hw := puddle_w / 2.0
    var pts := PackedVector2Array()
    pts.append(Vector2(-hw, 0))
    for k in range(1, 12):
        var u := float(k) / 12.0
        pts.append(Vector2(-hw + u * puddle_w, -sin(u * PI) * 12.0))
    pts.append(Vector2(hw, 0))
    draw_colored_polygon(pts, Color(0.42, 0.8, 0.2, 0.85 * fade * blink))
    for i in 4:
        draw_circle(Vector2(-hw * 0.6 + float(i) * hw * 0.4, -5.0 - fposmod(t * 14.0 + float(i) * 7.0, 12.0)), 2.5, Color(0.8, 1.0, 0.5, 0.7 * fade))


func _draw_sweep() -> void:
    if state == "warn":
        var k := clampf(t / warn, 0.0, 1.0)
        var blink := 1.0 if int(t * 10.0) % 2 == 0 else 0.5
        var ex := dir * 90.0   # the marker sits just inside the screen edge
        draw_dashed_line(Vector2(ex, 0), Vector2(dir * 1240.0, 0), Color(1.0, 0.3, 0.25, 0.2 + 0.2 * k), 3.0, 14.0)
        draw_colored_polygon(PackedVector2Array([Vector2(ex - 22.0, 18.0), Vector2(ex + 22.0, 18.0), Vector2(ex, -22.0)]), Color(1.0, 0.25, 0.2, 0.9 * blink))
        draw_string(ThemeDB.fallback_font, Vector2(ex - 6.0, 12.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
        return
    if style == "boulder":
        draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
        draw_circle(Vector2.ZERO, radius, Color(0.4, 0.33, 0.28))
        draw_circle(Vector2.ZERO, radius * 0.82, Color(0.46, 0.38, 0.32))
        var cols: Array = [Color(0.45, 0.78, 0.5), Color(0.85, 0.8, 0.3), Color(0.5, 0.65, 0.9), Color(0.72, 0.74, 0.78)]
        for i in 8:
            var a := float(i) / 8.0 * TAU
            var c: Color = cols[i % 4]
            draw_rect(Rect2(Vector2.from_angle(a) * radius * 0.6 - Vector2(5.0, 3.5), Vector2(10.0, 7.0)), c)
        draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.15, 0.1, 0.08), 3.0)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    else:
        var flap := sin(t * 22.0)
        var body := Color(0.12, 0.12, 0.15)
        draw_circle(Vector2.ZERO, radius * 0.8, body)
        draw_line(Vector2.ZERO, Vector2(-dir * 12.0, -16.0 - 12.0 * flap), body, 7.0)
        draw_line(Vector2.ZERO, Vector2(-dir * 12.0, 16.0 + 12.0 * flap), body, 7.0)
        draw_colored_polygon(PackedVector2Array([Vector2(dir * radius * 0.7, -3.0), Vector2(dir * radius * 0.7, 4.0), Vector2(dir * (radius + 10.0), 1.0)]), Color(0.85, 0.65, 0.2))
        draw_circle(Vector2(dir * 5.0, -3.0), 2.5, Color(1.0, 0.3, 0.2))


func _draw_drop() -> void:
    if state == "warn":
        var k := clampf(t / warn, 0.0, 1.0)
        var blink := 1.0 if int(t * 12.0) % 2 == 0 else 0.6
        var rx := lerpf(8.0, radius + 12.0, k)
        var gy := GROUND_Y - position.y   # the floor, in local coordinates
        _ellipse(Vector2(0, gy - 2.0), rx, rx * 0.28, Color(0.1, 0.05, 0.03, (0.35 + 0.35 * k) * blink))
        return
    draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-radius, -4.0), Vector2(-radius * 0.6, -radius), Vector2(radius * 0.3, -radius * 0.9),
        Vector2(radius, -radius * 0.2), Vector2(radius * 0.8, radius * 0.8), Vector2(-radius * 0.3, radius),
        Vector2(-radius * 0.9, radius * 0.5)]), Color(0.38, 0.3, 0.26))
    draw_rect(Rect2(-8, -8, 10, 7), Color(0.85, 0.8, 0.3))
    draw_rect(Rect2(2, 4, 10, 7), Color(0.5, 0.65, 0.9))
    draw_rect(Rect2(-14, 6, 9, 6), Color(0.45, 0.78, 0.5))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    for i in 3:
        draw_line(Vector2(float(i - 1) * 12.0, -radius - 6.0), Vector2(float(i - 1) * 12.0, -radius - 34.0 - float(i) * 8.0), Color(1, 1, 1, 0.25), 3.0)
