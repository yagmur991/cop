extends Node2D
# Level backgrounds. theme: "sea" / "air" / "land".
# Pollution (0..1) makes each one sickly; cleaning it up brings the healthy version back.

const PERIOD := 1700.0
const TREE_PERIOD := 1820.0
const FontBold: Font = preload("res://assets/fonts/Lora-Bold.ttf")

var theme := "sea"
var t := 0.0
var buildings: Array = []


func _ready() -> void:
	var x := 0.0
	var i := 0
	while x < PERIOD - 120.0:
		var w := 70.0 + float((i * 37) % 60)
		var h := 90.0 + float((i * 61) % 170)
		buildings.append(Rect2(x, 560.0 - h, w, h))
		x += w + 12.0
		i += 1


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


# ---------------- helpers ----------------
func _hills(off: float, base: float, amp: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= 1280.0:
		pts.append(Vector2(x, base + sin((x + off) * 0.004) * amp))
		x += 40.0
	pts.append(Vector2(1280, 720))
	pts.append(Vector2(0, 720))
	draw_colored_polygon(pts, col)


func _wrap(x: float, off: float, factor: float, period: float, margin: float) -> float:
	return fposmod(x - off * factor, period) - margin


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 18:
		var a := float(k) / 18.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _sun(p: float) -> void:
	draw_circle(Vector2(1050, 110), 46.0, Color(1.0, 0.95, 0.5).lerp(Color(0.95, 0.62, 0.32), p))


func _draw() -> void:
	var p := GameState.pollution / 100.0
	var cam := get_viewport().get_camera_2d()
	var off := 0.0
	if cam:
		off = cam.get_screen_center_position().x
	if theme == "air":
		_draw_air(p, off)
	elif theme == "land":
		_draw_land(p, off)
	else:
		_draw_sea(p, off)


# ---------------- shared pieces (city, trees, smog) ----------------
func _city(off: float, p: float) -> void:
	var bcol := Color(0.62, 0.72, 0.82).lerp(Color(0.46, 0.43, 0.4), p)
	var shift := fposmod(off * 0.25, PERIOD)
	for k in 2:
		for bi in buildings.size():
			var r: Rect2 = buildings[bi]
			var rr := Rect2(r.position + Vector2(float(k) * PERIOD - shift, 0), r.size)
			if rr.end.x < 0.0 or rr.position.x > 1280.0:
				continue
			draw_rect(rr, bcol)
			if bi % 4 == 0:
				draw_rect(Rect2(rr.position.x + rr.size.x * 0.6, rr.position.y - 28, 12, 28), bcol.darkened(0.2))
				if p > 0.1:
					for j in 5:
						var sp := Vector2(rr.position.x + rr.size.x * 0.6 + 6.0 + sin(t + float(j)) * 8.0 + float(j) * 6.0,
							rr.position.y - 34.0 - float(j) * 24.0 - fposmod(t * 30.0 + float(j) * 18.0, 36.0))
						draw_circle(sp, 10.0 + float(j) * 3.0, Color(0.4, 0.37, 0.32, 0.65 * p))


func _trees(off: float, p: float) -> void:
	var tshift := fposmod(off * 0.45, TREE_PERIOD)
	var crown_r := lerpf(34.0, 0.0, clampf((p - 0.35) / 0.4, 0.0, 1.0))
	var crown_col := Color(0.25, 0.65, 0.3).lerp(Color(0.5, 0.45, 0.2), p)
	for k in 2:
		for i in 7:
			var tx := float(i) * 260.0 + float(k) * TREE_PERIOD - tshift
			if tx < -60.0 or tx > 1340.0:
				continue
			var trunk := Color(0.38, 0.26, 0.16).lerp(Color(0.25, 0.2, 0.17), p)
			draw_rect(Rect2(tx - 5, 540, 10, 60), trunk)
			if crown_r > 2.0:
				draw_circle(Vector2(tx, 524), crown_r, crown_col)
				draw_circle(Vector2(tx - 14, 536), crown_r * 0.7, crown_col)
				draw_circle(Vector2(tx + 14, 536), crown_r * 0.7, crown_col)
			else:
				draw_line(Vector2(tx, 560), Vector2(tx - 22, 520), trunk, 4.0)
				draw_line(Vector2(tx, 552), Vector2(tx + 24, 512), trunk, 4.0)
				draw_line(Vector2(tx, 540), Vector2(tx - 10, 500), trunk, 3.0)


func _smog(off: float, p: float) -> void:
	if p <= 0.05:
		return
	for i in 8:
		var cx := fposmod(float(i) * 260.0 + t * (10.0 + float(i) * 3.0) - off * 0.2, 1500.0) - 100.0
		var cy := 120.0 + float(i % 4) * 90.0 + sin(t * 0.3 + float(i)) * 12.0
		var rad := 70.0 + float(i % 3) * 20.0
		draw_circle(Vector2(cx, cy), rad, Color(0.5, 0.45, 0.28, 0.32 * p))
		draw_circle(Vector2(cx + rad * 0.6, cy + 10.0), rad * 0.7, Color(0.5, 0.45, 0.28, 0.28 * p))
	draw_rect(Rect2(0, 420, 1280, 300), Color(0.5, 0.42, 0.25, 0.15 * p))


# ---------------- SEA: ocean + plastic pollution ----------------
func _fish(pos: Vector2, a: float, dir: float) -> void:
	var body := Color(1.0, 0.62, 0.3, a)
	_ellipse(pos, 14.0, 7.0, body)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-12.0 * dir, 0.0), pos + Vector2(-24.0 * dir, -8.0), pos + Vector2(-24.0 * dir, 8.0)]), body)
	draw_circle(pos + Vector2(7.0 * dir, -2.0), 1.8, Color(0.1, 0.1, 0.12, a))


func _dead_fish(pos: Vector2, a: float) -> void:
	var body := Color(0.82, 0.82, 0.76, a)
	var ink := Color(0.2, 0.2, 0.2, a)
	_ellipse(pos, 14.0, 6.0, body)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(12, 0), pos + Vector2(24, -7), pos + Vector2(24, 7)]), body)
	draw_line(pos + Vector2(-9, -3), pos + Vector2(-5, 1), ink, 2.0)
	draw_line(pos + Vector2(-5, -3), pos + Vector2(-9, 1), ink, 2.0)


func _debris(kind: int, pos: Vector2, s: float, rot: float) -> void:
	draw_set_transform(pos, rot, Vector2(s, s))
	match kind:
		0:
			draw_rect(Rect2(-6, -14, 12, 28), Color(0.7, 0.88, 0.95, 0.9))
			draw_rect(Rect2(-3, -22, 6, 8), Color(0.7, 0.88, 0.95, 0.9))
			draw_rect(Rect2(-4, -26, 8, 4), Color(0.95, 0.95, 0.95))
		1:
			draw_colored_polygon(PackedVector2Array([Vector2(-12, -8), Vector2(12, -8), Vector2(16, 6), Vector2(0, 14), Vector2(-16, 6)]), Color(0.96, 0.96, 1.0, 0.65))
			draw_line(Vector2(-6, -8), Vector2(-9, -16), Color(0.96, 0.96, 1.0, 0.8), 2.0)
			draw_line(Vector2(6, -8), Vector2(9, -16), Color(0.96, 0.96, 1.0, 0.8), 2.0)
		2:
			draw_rect(Rect2(-7, -10, 14, 20), Color(0.72, 0.74, 0.78))
			draw_rect(Rect2(-7, -10, 14, 4), Color(0.85, 0.86, 0.9))
		_:
			draw_arc(Vector2(-8, 0), 7.0, 0.0, TAU, 12, Color(0.85, 0.92, 0.96), 2.5)
			draw_arc(Vector2(8, 0), 7.0, 0.0, TAU, 12, Color(0.85, 0.92, 0.96), 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sea(p: float, off: float) -> void:
	_sun(p)
	var horizon := 438.0
	# drifting clouds
	var cc := Color(1.0, 1.0, 1.0, 0.75).lerp(Color(0.62, 0.56, 0.42, 0.7), p)
	for i in 4:
		var cx := fposmod(float(i) * 340.0 + t * 8.0 - off * 0.05, 1500.0) - 110.0
		var cy := 70.0 + float(i % 3) * 46.0
		draw_circle(Vector2(cx, cy), 34.0, cc)
		draw_circle(Vector2(cx + 34.0, cy + 6.0), 28.0, cc)
		draw_circle(Vector2(cx - 32.0, cy + 8.0), 24.0, cc)
	# far coast + offshore oil rig (its flare burns when pollution is high)
	_hills(off * 0.04, 408.0, 16.0, Color(0.56, 0.72, 0.64).lerp(Color(0.5, 0.47, 0.38), p))
	var rx := _wrap(300.0, off, 0.06, 1500.0, 100.0)
	var rig := Color(0.32, 0.34, 0.38)
	draw_rect(Rect2(rx, 392.0, 50.0, 6.0), rig)
	draw_rect(Rect2(rx + 20.0, 360.0, 6.0, 32.0), rig)
	draw_line(Vector2(rx + 6.0, 398.0), Vector2(rx + 2.0, horizon + 4.0), rig, 3.0)
	draw_line(Vector2(rx + 44.0, 398.0), Vector2(rx + 48.0, horizon + 4.0), rig, 3.0)
	if p > 0.15:
		var fl := 3.0 + 5.0 * p + sin(t * 9.0) * 1.5
		draw_circle(Vector2(rx + 23.0, 354.0), fl + 3.0, Color(1.0, 0.55, 0.15, 0.35))
		draw_circle(Vector2(rx + 23.0, 354.0), fl, Color(1.0, 0.7, 0.25, 0.9))
		for j in 4:
			draw_circle(Vector2(rx + 23.0 + float(j) * 5.0, 340.0 - fposmod(t * 20.0 + float(j) * 14.0, 56.0)), 6.0 + float(j) * 2.0, Color(0.25, 0.23, 0.22, 0.4 * p))
	# water: clean blue -> murky green-brown
	var top_c := Color(0.36, 0.7, 0.86).lerp(Color(0.5, 0.52, 0.34), p)
	var bot_c := Color(0.2, 0.5, 0.74).lerp(Color(0.34, 0.33, 0.24), p)
	for k in 7:
		draw_rect(Rect2(0, horizon + float(k) * 40.5, 1280, 42), top_c.lerp(bot_c, float(k) / 6.0))
	for row in 5:
		var pts := PackedVector2Array()
		var wy := horizon + 22.0 + float(row) * 52.0
		var amp := 3.0 + float(row) * 1.2
		for k in 33:
			var x := float(k) * 40.0
			pts.append(Vector2(x, wy + sin((x + off * (0.2 + 0.1 * float(row))) * 0.02 + t * (1.0 + 0.2 * float(row)) + float(row)) * amp))
		draw_polyline(pts, Color(1, 1, 1, 0.22 * (1.0 - p * 0.6)), 2.0)
	# sea life: alive when clean, belly-up when polluted
	var alive := clampf(1.0 - (p - 0.25) / 0.3, 0.0, 1.0)
	var dead := clampf((p - 0.45) / 0.3, 0.0, 1.0)
	if alive > 0.02:
		for i in 5:
			var fx := _wrap(float(i) * 260.0, off, 0.5, 1500.0, 110.0) + sin(t * 0.8 + float(i)) * 20.0
			var fy := horizon + 90.0 + float((i * 53) % 170)
			_fish(Vector2(fx, fy), alive, 1.0 if i % 2 == 0 else -1.0)
	if dead > 0.02:
		for i in 4:
			var dx := _wrap(float(i) * 330.0 + 120.0, off, 0.4, 1500.0, 110.0)
			var dy := horizon + 26.0 + float((i * 37) % 70) + sin(t + float(i)) * 2.0
			_dead_fish(Vector2(dx, dy), dead)
	# floating plastic: more of it the dirtier the sea gets
	var count := 3 + int(p * 15.0)
	for i in count:
		var by := horizon + 24.0 + float((i * 71) % 240)
		var s := 0.7 + (by - horizon) / 320.0
		var bx := _wrap(float(i) * 197.0 + 60.0, off, 0.3 + (by - horizon) / 900.0, 1500.0, 110.0)
		_debris(i % 4, Vector2(bx, by + sin(t * 1.3 + float(i)) * 4.0), s, sin(t * 0.9 + float(i)) * 0.45)
	# oil sheen
	if p > 0.35:
		var a := clampf((p - 0.35) / 0.5, 0.0, 1.0) * 0.35
		for i in 4:
			var ox := _wrap(float(i) * 400.0, off, 0.3, 1600.0, 200.0)
			var oy := horizon + 70.0 + float(i) * 55.0
			_ellipse(Vector2(ox, oy), 180.0, 16.0, Color(0.1, 0.08, 0.12, a))
			_ellipse(Vector2(ox + 20.0, oy - 2.0), 120.0, 8.0, Color(0.35, 0.2, 0.5, a * 0.7))
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.55, 0.5, 0.3, 0.14 * p))


# ---------------- AIR: factories, carbon, smoke ----------------
func _factories(off: float, p: float) -> void:
	var steel := Color(0.36, 0.4, 0.46).lerp(Color(0.22, 0.2, 0.19), p)
	for i in 4:
		var fx := _wrap(float(i) * 400.0 + 30.0, off, 0.45, 1600.0, 220.0)
		var w := 170.0 + float((i * 41) % 50)
		var h := 80.0 + float((i * 23) % 40)
		draw_rect(Rect2(fx, 650.0 - h, w, h), steel)
		for s in 4:
			var sx := fx + float(s) * w / 4.0
			draw_colored_polygon(PackedVector2Array([Vector2(sx, 650.0 - h), Vector2(sx, 650.0 - h - 22.0), Vector2(sx + w / 4.0, 650.0 - h)]), steel.darkened(0.12))
		for c in 2:
			var cx := fx + w * (0.22 + 0.5 * float(c))
			var ctop := 650.0 - h - 150.0
			draw_rect(Rect2(cx - 9.0, ctop, 18.0, 150.0), steel.darkened(0.2))
			draw_rect(Rect2(cx - 9.0, ctop, 18.0, 8.0), Color(0.75, 0.25, 0.2))
			draw_rect(Rect2(cx - 9.0, ctop + 24.0, 18.0, 6.0), Color(0.75, 0.25, 0.2))
			var amt := 0.12 + 0.55 * p
			for j in 6:
				var u := fposmod(t * 0.25 + float(j) / 6.0 + float(i * 2 + c) * 0.17, 1.0)
				var py := ctop - u * 190.0
				var px := cx + sin(t * 0.8 + float(j)) * 10.0 + u * 40.0
				draw_circle(Vector2(px, py), 10.0 + u * 26.0, Color(0.34, 0.33, 0.33, amt * (1.0 - u * 0.6)))
			if p > 0.1:
				var u2 := fposmod(t * 0.2 + float(i * 2 + c) * 0.3, 1.0)
				var lab := Vector2(cx + 8.0 + u2 * 50.0, ctop - 30.0 - u2 * 170.0)
				draw_string(FontBold, lab, "CO2", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.14, 0.13, 0.12, (1.0 - u2) * (0.35 + 0.5 * p)))


func _smoke_ceiling(off: float, p: float) -> void:
	if p <= 0.03:
		return
	draw_rect(Rect2(0, 0, 1280, 280), Color(0.45, 0.38, 0.24, 0.3 * p))
	for i in 9:
		var cx := fposmod(float(i) * 190.0 + t * (8.0 + float(i % 3) * 3.0) - off * 0.12, 1500.0) - 110.0
		var cy := 40.0 + float((i * 37) % 120) + sin(t * 0.4 + float(i)) * 8.0
		var rad := 60.0 + float((i * 17) % 40)
		draw_circle(Vector2(cx, cy), rad, Color(0.32, 0.29, 0.27, 0.5 * p))
		draw_circle(Vector2(cx + rad * 0.6, cy + 12.0), rad * 0.7, Color(0.36, 0.33, 0.3, 0.42 * p))
	draw_rect(Rect2(0, 420, 1280, 300), Color(0.5, 0.42, 0.25, 0.14 * p))


func _draw_air(p: float, off: float) -> void:
	_sun(p)
	# distant wind turbines: clean energy keeps spinning above the smog
	var wcol := Color(0.93, 0.96, 0.98).lerp(Color(0.66, 0.62, 0.55), p)
	for i in 4:
		var wx := _wrap(float(i) * 410.0 + 140.0, off, 0.06, 1640.0, 120.0)
		var hub := Vector2(wx, 345.0 + float((i * 29) % 40))
		draw_line(Vector2(wx, 470.0), hub, wcol, 4.0)
		draw_circle(hub, 5.0, wcol)
		for k in 3:
			var a := t * (1.1 - 0.5 * p) + float(k) * TAU / 3.0 + float(i)
			draw_line(hub, hub + Vector2.from_angle(a) * 52.0, wcol, 3.0)
	_hills(off * 0.1, 478.0, 22.0, Color(0.5, 0.72, 0.5).lerp(Color(0.5, 0.46, 0.34), p))
	_city(off, p)
	_factories(off, p)
	_smoke_ceiling(off, p)


# ---------------- LAND: farmland vs. landfill ----------------
func _draw_land(p: float, off: float) -> void:
	_sun(p)
	_hills(off * 0.05, 420.0, 40.0, Color(0.55, 0.68, 0.62).lerp(Color(0.52, 0.47, 0.4), p))
	_hills(off * 0.12, 482.0, 24.0, Color(0.55, 0.78, 0.4).lerp(Color(0.55, 0.45, 0.28), p))
	for k in 6:
		draw_line(Vector2(0, 522.0 + float(k) * 20.0), Vector2(1280, 522.0 + float(k) * 20.0), Color(0, 0, 0, 0.05), 3.0)
	# farm windmill
	var wmx := _wrap(880.0, off, 0.2, 1600.0, 120.0)
	var wcol := Color(0.9, 0.86, 0.78).lerp(Color(0.5, 0.45, 0.4), p)
	draw_colored_polygon(PackedVector2Array([Vector2(wmx - 16.0, 520.0), Vector2(wmx + 16.0, 520.0), Vector2(wmx + 9.0, 440.0), Vector2(wmx - 9.0, 440.0)]), wcol)
	var hub := Vector2(wmx, 436.0)
	for k in 4:
		var a := t * (0.8 - 0.5 * p) + float(k) * TAU / 4.0
		draw_line(hub, hub + Vector2.from_angle(a) * 46.0, wcol.darkened(0.15), 5.0)
	draw_circle(hub, 5.0, wcol.darkened(0.3))
	# landfill mounds: small when clean, mountains of trash when polluted
	var mcol := Color(0.45, 0.4, 0.34).lerp(Color(0.34, 0.3, 0.26), p)
	var flock := 1 + int(p * 3.0)
	for i in 3:
		var mx := _wrap(float(i) * 560.0 + 200.0, off, 0.3, 1680.0, 260.0)
		var mh := 50.0 + float((i * 47) % 40) + 120.0 * p
		var mw := 230.0 + float((i * 31) % 60)
		draw_colored_polygon(PackedVector2Array([Vector2(mx - mw * 0.5, 650.0), Vector2(mx - mw * 0.2, 650.0 - mh * 0.85), Vector2(mx, 650.0 - mh), Vector2(mx + mw * 0.25, 650.0 - mh * 0.8), Vector2(mx + mw * 0.5, 650.0)]), mcol)
		for j in 10:
			var bc: Color = GameState.trash_colors[GameState.trash_types[j % 4]]
			var bx := mx - mw * 0.28 + float((j * 37) % int(mw * 0.56))
			var by := 650.0 - 8.0 - float((j * 29) % int(mh * 0.5))
			draw_rect(Rect2(bx, by, 9, 6), Color(bc, 0.45 + 0.5 * p))
		if i == 0:
			var yel := Color(0.85, 0.72, 0.35)
			draw_rect(Rect2(mx - 24.0, 650.0 - mh - 14.0, 40.0, 14.0), yel)
			draw_rect(Rect2(mx - 10.0, 650.0 - mh - 28.0, 18.0, 14.0), yel.darkened(0.15))
			draw_line(Vector2(mx - 24.0, 650.0 - mh - 8.0), Vector2(mx - 38.0, 650.0 - mh - 2.0), Color(0.3, 0.3, 0.32), 4.0)
		if p > 0.45:
			draw_circle(Vector2(mx + mw * 0.1, 650.0 - mh - 2.0), 5.0 + 3.0 * sin(t * 8.0 + float(i)), Color(1.0, 0.55, 0.2, 0.85))
			for j in 3:
				draw_circle(Vector2(mx + mw * 0.1 + sin(t + float(j)) * 6.0, 650.0 - mh - 14.0 - fposmod(t * 22.0 + float(j) * 14.0, 44.0)), 7.0 + float(j) * 3.0, Color(0.25, 0.23, 0.22, 0.4 * p))
		for j in flock:
			var ang := t * 0.7 + float(j) * 2.1 + float(i)
			var bp := Vector2(mx + cos(ang) * (80.0 + float(j) * 14.0), 650.0 - mh - 48.0 + sin(ang * 1.3) * 20.0)
			var fl := sin(t * 12.0 + float(j)) * 4.0
			draw_line(bp + Vector2(-7, -fl), bp, Color(0.1, 0.1, 0.12), 2.5)
			draw_line(bp, bp + Vector2(7, -fl), Color(0.1, 0.1, 0.12), 2.5)
	_trees(off, p)
	_smog(off, p)
