extends Node2D
# Illustrated "How to Play" pages. Used from the menu, the pause menu and as the tutorial after the intro.

signal finished

const PAGES := 4
const ArtS = preload("res://scripts/art.gd")

var tutorial_mode := false
var page := 0
var t := 0.0
var delay := 0.25
var closed := false
var back_rect := Rect2(60, 648, 190, 46)
var next_rect := Rect2(1030, 648, 190, 46)


func _process(delta: float) -> void:
    t += delta
    delay -= delta
    if delay <= 0.0 and not closed:
        if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("ui_right"):
            page = mini(page + 1, PAGES - 1)
        if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("ui_left"):
            page = maxi(page - 1, 0)
        if Input.is_action_just_pressed("ui_accept"):
            _next()
        if Input.is_action_just_pressed("ui_cancel"):
            _finish()
    queue_redraw()


func _input(event: InputEvent) -> void:
    if delay > 0.0 or closed:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var m := get_local_mouse_position()
        if next_rect.has_point(m):
            _next()
        elif back_rect.has_point(m):
            page = maxi(page - 1, 0)


func _next() -> void:
    if page < PAGES - 1:
        page += 1
    else:
        _finish()


func _finish() -> void:
    if closed:
        return
    closed = true
    finished.emit()


func _key(p: Vector2, label: String) -> float:
    var f := ThemeDB.fallback_font
    var w := maxf(52.0, 24.0 + label.length() * 15.0)
    draw_rect(Rect2(p + Vector2(0, 5), Vector2(w, 48)), Color(0, 0, 0, 0.5))
    draw_rect(Rect2(p, Vector2(w, 48)), Color(0.85, 0.88, 0.9))
    draw_rect(Rect2(p + Vector2(4, 4), Vector2(w - 8, 36)), Color(0.97, 0.98, 1.0))
    draw_string(f, p + Vector2(0, 33), label, HORIZONTAL_ALIGNMENT_CENTER, w, 24, Color(0.1, 0.12, 0.15))
    return w


func _btn(r: Rect2, label: String, col: Color) -> void:
    var f := ThemeDB.fallback_font
    var hover := r.has_point(get_local_mouse_position())
    draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.45))
    draw_rect(r, col.lightened(0.15) if hover else col)
    draw_rect(r, Color(1, 1, 1, 0.8), false, 2.0)
    draw_string(f, r.position + Vector2(0, 31), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, Color.WHITE)


func _draw() -> void:
    var f := ThemeDB.fallback_font
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.07, 0.13, 0.14))
    for i in 7:
        ArtS.recycle(self, Vector2(100 + i * 190, 150 + (i % 3) * 230), 70.0, t * 0.2 + i, Color(1, 1, 1, 0.04))
    draw_rect(Rect2(0, 0, 1280, 92), Color(0.1, 0.3, 0.22))
    draw_rect(Rect2(0, 88, 1280, 6), Color(0.3, 0.8, 0.45))
    draw_string(f, Vector2(60, 62), Loc.t("h_title") + "  -  " + Loc.t("h_p%d" % (page + 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
    draw_string(f, Vector2(0, 62), Loc.t("h_page", [page + 1, PAGES]), HORIZONTAL_ALIGNMENT_RIGHT, 1220.0, 22, Color(0.8, 0.95, 0.85))
    match page:
        0:
            _page_controls()
        1:
            _page_mission()
        2:
            _page_items()
        _:
            _page_tips()
    if page > 0:
        _btn(back_rect, Loc.t("o_back"), Color(0.25, 0.4, 0.5))
    var last := page == PAGES - 1
    var nl := Loc.t("h_start") if (last and tutorial_mode) else (Loc.t("h_close") if last else Loc.t("h_next"))
    _btn(next_rect, nl, Color(0.2, 0.6, 0.35))
    var hint := Loc.t("h_hint_tut") if tutorial_mode else Loc.t("h_hint")
    draw_string(f, Vector2(0, 678), hint, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 18, Color(0.7, 0.8, 0.8))


func _page_controls() -> void:
    var f := ThemeDB.fallback_font
    var rows := [
        [["A", "D"], "h_move"], [["Space", "W"], "h_jump"], [["J", "X"], "h_attack"], [["B"], "h_inv"], [["Esc"], "h_pause"]]
    for i in rows.size():
        var y := 130.0 + i * 94.0
        var x := 70.0
        for k in rows[i][0]:
            x += _key(Vector2(x, y), k) + 10.0
        draw_string(f, Vector2(330, y + 34), Loc.t(rows[i][1]), HORIZONTAL_ALIGNMENT_LEFT, 560.0, 26, Color.WHITE)
    # little scene: the hero, a trash monster and a sapling
    var c := GameState.player_color()
    var p := Vector2(1030, 380 + sin(t * 3.0) * 6.0)
    draw_rect(Rect2(p + Vector2(-14, -22) * 3.0, Vector2(28, 44) * 3.0), c)
    draw_rect(Rect2(p + Vector2(-14, -22) * 3.0, Vector2(28, 10) * 3.0), c.darkened(0.2))
    draw_rect(Rect2(p + Vector2(3, -16) * 3.0, Vector2(6, 6) * 3.0), Color.WHITE)
    draw_rect(Rect2(p + Vector2(-5, 0) * 3.0, Vector2(10, 10) * 3.0), Color(0.2, 0.5, 0.9))
    draw_rect(Rect2(p + Vector2(50, -40), Vector2(60, 70)), Color(1, 1, 1, 0.35))
    ArtS.trash(self, "plastic", Vector2(1100, 600), 2.4)
    ArtS.sapling(self, Vector2(940, 610), 2.4)


func _page_mission() -> void:
    var f := ThemeDB.fallback_font
    var cols := [GameState.trash_colors["glass"], GameState.trash_colors["paper"], GameState.trash_colors["plastic"], GameState.trash_colors["metal"]]
    for i in 6:
        var y := 122.0 + i * 82.0
        var c: Color = cols[i % 4]
        draw_circle(Vector2(84, y + 24), 26.0, c.darkened(0.2))
        draw_arc(Vector2(84, y + 24), 26.0, 0, TAU, 24, Color.WHITE, 2.0)
        draw_string(f, Vector2(58, y + 35), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 52.0, 30, Color.WHITE)
        draw_multiline_string(f, Vector2(140, y + 22), Loc.t("h_m%d" % (i + 1)), HORIZONTAL_ALIGNMENT_LEFT, 1080.0, 24, 2, Color.WHITE)


func _page_items() -> void:
    var f := ThemeDB.fallback_font
    ArtS.sapling(self, Vector2(110, 170), 2.0)
    draw_multiline_string(f, Vector2(220, 168), Loc.t("h_i_sapling"), HORIZONTAL_ALIGNMENT_LEFT, 980.0, 26, 2, Color.WHITE)
    for i in 4:
        ArtS.trash(self, GameState.trash_types[i], Vector2(100 + i * 64, 275), 2.0)
    draw_multiline_string(f, Vector2(380, 272), Loc.t("h_i_trash"), HORIZONTAL_ALIGNMENT_LEFT, 820.0, 26, 2, Color.WHITE)
    for i in 4:
        ArtS.bin(self, GameState.trash_types[i], Vector2(100 + i * 74, 400), 1.2)
        draw_string(f, Vector2(70 + i * 74, 424), GameState.trash_name(GameState.trash_types[i]), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 14, Color.WHITE)
    draw_multiline_string(f, Vector2(420, 380), Loc.t("h_i_bin"), HORIZONTAL_ALIGNMENT_LEFT, 780.0, 26, 2, Color.WHITE)
    # gate icon
    draw_rect(Rect2(90, 460, 44, 80), Color(0.3, 0.3, 0.34))
    draw_rect(Rect2(90, 460, 44, 80), Color.WHITE, false, 2.0)
    draw_arc(Vector2(112, 492), 7.0, PI, TAU, 10, Color(0.85, 0.75, 0.3), 3.0)
    draw_rect(Rect2(103, 492, 18, 15), Color(0.85, 0.7, 0.2))
    draw_multiline_string(f, Vector2(220, 505), Loc.t("h_i_gate"), HORIZONTAL_ALIGNMENT_LEFT, 980.0, 26, 2, Color.WHITE)
    ArtS.shield(self, Vector2(112, 600), 2.0)
    draw_multiline_string(f, Vector2(220, 598), Loc.t("h_i_up"), HORIZONTAL_ALIGNMENT_LEFT, 980.0, 26, 2, Color.WHITE)


func _page_tips() -> void:
    var f := ThemeDB.fallback_font
    for i in 5:
        var y := 140.0 + i * 100.0
        draw_circle(Vector2(76, y + 18), 10.0, Color(0.4, 0.9, 0.5))
        draw_multiline_string(f, Vector2(104, y + 26), Loc.t("h_t%d" % (i + 1)), HORIZONTAL_ALIGNMENT_LEFT, 700.0, 25, 3, Color.WHITE)
    # boss illustration: warning ! and a ground wave
    var b := Vector2(1010, 330)
    draw_circle(b, 70.0, Color(0.3, 0.7, 0.9))
    draw_rect(Rect2(b + Vector2(-16, -96), Vector2(32, 26)), Color(0.22, 0.55, 0.72))
    draw_circle(b + Vector2(-24, -10), 16.0, Color.WHITE)
    draw_circle(b + Vector2(24, -10), 16.0, Color.WHITE)
    draw_circle(b + Vector2(-24, -7), 7.0, Color.BLACK)
    draw_circle(b + Vector2(24, -7), 7.0, Color.BLACK)
    if int(t * 3.0) % 2 == 0:
        draw_string(ThemeDB.fallback_font, b + Vector2(-14, -110), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 70, Color(1.0, 0.2, 0.2))
    draw_rect(Rect2(820, 440, 380, 6), Color(0.4, 0.3, 0.25))
    var wx := 820.0 + fposmod(t * 160.0, 380.0)
    draw_circle(Vector2(wx, 432), 12.0, Color(0.4, 0.8, 1.0))
    ArtS.sapling(self, Vector2(900, 520), 2.6)
    ArtS.bin(self, "glass", Vector2(1010, 530), 1.8)
    ArtS.bin(self, "plastic", Vector2(1110, 530), 1.8)
