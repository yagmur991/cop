extends Node2D
# Main menu and pause menu (is_pause = true). Pages: main, difficulty, options, credits, howto.

signal new_game(difficulty: int)
signal continue_game
signal resume
signal quit_to_menu

const HowToS = preload("res://scripts/howto.gd")
const ArtS = preload("res://scripts/art.gd")

var is_pause := false
var page := "main"
var sel := 0
var diff_sel := 1
var opt_sel := 0
var t := 0.0
var delay := 0.25
var howto: Node2D
var last_mouse := Vector2(-1, -1)
var back_rect := Rect2(40, 650, 190, 46)


func _ready() -> void:
    if not is_pause and GameState.has_save():
        sel = 1


# ---------------- layout helpers ----------------
func _items() -> Array:
    if is_pause:
        return [["resume", "p_resume"], ["howto", "m_howto"], ["options", "m_options"], ["menu", "p_menu"]]
    return [["new", "m_new"], ["continue", "m_continue"], ["howto", "m_howto"], ["options", "m_options"], ["credits", "m_credits"], ["quit", "m_quit"]]


func _enabled(id: String) -> bool:
    if id == "continue":
        return GameState.has_save()
    return true


func _item_rect(i: int) -> Rect2:
    var y0 := 292.0 if not is_pause else 270.0
    return Rect2(450, y0 + i * 60.0, 380, 52)


func _card_rect(i: int) -> Rect2:
    return Rect2(100 + i * 370, 190, 330, 390)


func _opt_rect(i: int) -> Rect2:
    return Rect2(340, 230 + i * 100, 600, 70)


func _chip_rect(i: int) -> Rect2:
    return Rect2(1120 + i * 74, 18, 64, 34)


# ---------------- input ----------------
func _accept() -> bool:
    return Input.is_action_just_pressed("ui_accept")


func _cancel() -> bool:
    return Input.is_action_just_pressed("ui_cancel")


func _process(delta: float) -> void:
    t += delta
    delay -= delta
    if page == "howto":
        return
    _hover()
    if delay <= 0.0:
        match page:
            "main":
                _input_main()
            "difficulty":
                if Input.is_action_just_pressed("left"):
                    diff_sel = (diff_sel + 2) % 3
                if Input.is_action_just_pressed("right"):
                    diff_sel = (diff_sel + 1) % 3
                if _accept():
                    new_game.emit(diff_sel)
                if _cancel():
                    _to_main()
            "options":
                _input_options()
            "credits":
                if _accept() or _cancel():
                    _to_main()
    queue_redraw()


func _input_main() -> void:
    var items := _items()
    if Input.is_action_just_pressed("down"):
        sel = _next_enabled(sel, 1)
    if Input.is_action_just_pressed("up"):
        sel = _next_enabled(sel, -1)
    if _accept():
        _activate(items[sel][0])
    if is_pause and _cancel():
        resume.emit()


func _next_enabled(from: int, dir: int) -> int:
    var items := _items()
    var n := items.size()
    var i := from
    for k in n:
        i = (i + dir + n) % n
        if _enabled(items[i][0]):
            return i
    return from


func _input_options() -> void:
    if Input.is_action_just_pressed("down"):
        opt_sel = (opt_sel + 1) % 3
    if Input.is_action_just_pressed("up"):
        opt_sel = (opt_sel + 2) % 3
    var change := Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right") or _accept()
    if change:
        _options_toggle()
    if _cancel():
        _to_main()


func _options_toggle() -> void:
    match opt_sel:
        0:
            Loc.set_lang("tr" if Loc.lang == "en" else "en")
        1:
            Loc.set_fullscreen(not Loc.fullscreen)
        2:
            _to_main()


func _activate(id: String) -> void:
    match id:
        "new":
            page = "difficulty"
            diff_sel = 1
            delay = 0.15
        "continue":
            if GameState.has_save():
                continue_game.emit()
        "howto":
            _open_howto()
        "options":
            page = "options"
            opt_sel = 0
            delay = 0.15
        "credits":
            page = "credits"
            delay = 0.15
        "quit":
            get_tree().quit()
        "resume":
            resume.emit()
        "menu":
            quit_to_menu.emit()


func _to_main() -> void:
    page = "main"
    delay = 0.15


func _open_howto() -> void:
    howto = HowToS.new()
    howto.finished.connect(_close_howto)
    add_child(howto)
    page = "howto"


func _close_howto() -> void:
    if howto:
        howto.queue_free()
        howto = null
    page = "main"
    delay = 0.25


func _hover() -> void:
    var m := get_local_mouse_position()
    if m == last_mouse:
        return
    last_mouse = m
    match page:
        "main":
            var items := _items()
            for i in items.size():
                if _item_rect(i).has_point(m) and _enabled(items[i][0]):
                    sel = i
        "difficulty":
            for i in 3:
                if _card_rect(i).has_point(m):
                    diff_sel = i
        "options":
            for i in 3:
                if _opt_rect(i).has_point(m):
                    opt_sel = i


func _input(event: InputEvent) -> void:
    if page == "howto" or delay > 0.0:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _click(get_local_mouse_position())


func _click(m: Vector2) -> void:
    match page:
        "main":
            var items := _items()
            for i in items.size():
                if _item_rect(i).has_point(m):
                    sel = i
                    if _enabled(items[i][0]):
                        _activate(items[i][0])
                    return
            if not is_pause:
                if _chip_rect(0).has_point(m):
                    Loc.set_lang("en")
                elif _chip_rect(1).has_point(m):
                    Loc.set_lang("tr")
        "difficulty":
            for i in 3:
                if _card_rect(i).has_point(m):
                    diff_sel = i
                    new_game.emit(i)
                    return
            if back_rect.has_point(m):
                _to_main()
        "options":
            for i in 3:
                if _opt_rect(i).has_point(m):
                    opt_sel = i
                    _options_toggle()
                    return
            if back_rect.has_point(m):
                _to_main()
        "credits":
            _to_main()


# ---------------- drawing ----------------
func _draw() -> void:
    if page == "howto":
        return
    if is_pause:
        draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.72))
    else:
        _draw_background()
    match page:
        "main":
            _draw_main()
        "difficulty":
            _draw_difficulty()
        "options":
            _draw_options()
        "credits":
            _draw_credits()


func _outlined(text: String, pos: Vector2, width: float, size: int, col: Color, outline := 8) -> void:
    var f := ThemeDB.fallback_font
    draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline, Color(0.04, 0.1, 0.07))
    draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


func _draw_title(center_x: float, y: float, size: int) -> void:
    var f := ThemeDB.fallback_font
    var title := Loc.t("game_title")
    var total := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
    var x := center_x - total / 2.0
    var cols := [GameState.trash_colors["glass"], GameState.trash_colors["paper"], GameState.trash_colors["plastic"], GameState.trash_colors["metal"]]
    var ci := 0
    for i in title.length():
        var ch := title.substr(i, 1)
        var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
        if ch != " ":
            var pos := Vector2(x, y + sin(t * 2.0 + i * 0.6) * 6.0)
            draw_string(f, pos + Vector2(4, 7), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.45))
            draw_string_outline(f, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 14, Color(0.05, 0.15, 0.1))
            draw_string(f, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, cols[ci % 4])
            ci += 1
        x += w


func _btn(r: Rect2, label: String, col: Color, selected: bool, enabled: bool = true) -> void:
    var f := ThemeDB.fallback_font
    var rr := r
    if selected:
        rr = r.grow_individual(16, 3, 16, 3)
    var base := col if enabled else Color(0.35, 0.35, 0.38)
    draw_rect(Rect2(rr.position + Vector2(4, 5), rr.size), Color(0, 0, 0, 0.4))
    draw_rect(rr, base.darkened(0.1) if selected else base.darkened(0.35))
    draw_rect(Rect2(rr.position, Vector2(rr.size.x, 7)), base.lightened(0.25))
    draw_rect(rr, Color.WHITE if selected else Color(1, 1, 1, 0.25), false, 3.0 if selected else 2.0)
    var tcol := Color.WHITE if enabled else Color(0.7, 0.7, 0.72)
    draw_string_outline(f, rr.position + Vector2(0, 37), label, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 28, 6, Color(0, 0, 0, 0.8))
    draw_string(f, rr.position + Vector2(0, 37), label, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 28, tcol)
    if selected:
        ArtS.recycle(self, Vector2(rr.position.x + 28, rr.get_center().y), 13.0, t * 2.0, Color.WHITE)
        ArtS.recycle(self, Vector2(rr.end.x - 28, rr.get_center().y), 13.0, -t * 2.0, Color.WHITE)


func _btn_cols() -> Array:
    return [GameState.trash_colors["glass"], GameState.trash_colors["paper"], GameState.trash_colors["plastic"], GameState.trash_colors["metal"], GameState.trash_colors["glass"], GameState.trash_colors["paper"]]


func _draw_main() -> void:
    var f := ThemeDB.fallback_font
    if is_pause:
        draw_rect(Rect2(400, 130, 480, 520), Color(0.07, 0.14, 0.12, 0.95))
        draw_rect(Rect2(400, 130, 480, 520), Color(0.4, 0.9, 0.5), false, 3.0)
        _outlined(Loc.t("p_title"), Vector2(400, 220), 480.0, 54, Color.WHITE)
        draw_string(f, Vector2(410, 625), Loc.t("p_note"), HORIZONTAL_ALIGNMENT_CENTER, 460.0, 15, Color(0.7, 0.85, 0.75))
    else:
        _draw_title(640.0, 190.0, 118)
        _outlined(Loc.t("tagline"), Vector2(0, 252), 1280.0, 28, Color(1, 1, 0.9), 6)
        # language chips
        var cn := ["EN", "TR"]
        for i in 2:
            var r := _chip_rect(i)
            var on := (Loc.lang == "en" and i == 0) or (Loc.lang == "tr" and i == 1)
            draw_rect(r, Color(0.2, 0.6, 0.35) if on else Color(0, 0, 0, 0.45))
            draw_rect(r, Color.WHITE, false, 2.0)
            draw_string(f, r.position + Vector2(0, 25), cn[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, Color.WHITE)
        draw_string(f, Vector2(0, 710), "v0.1", HORIZONTAL_ALIGNMENT_RIGHT, 1262.0, 14, Color(1, 1, 1, 0.6))
    var items := _items()
    var cols := _btn_cols()
    for i in items.size():
        var id: String = items[i][0]
        _btn(_item_rect(i), Loc.t(items[i][1]), cols[i % cols.size()], i == sel, _enabled(id))
        if id == "continue" and not _enabled(id) and not is_pause:
            draw_string(f, _item_rect(i).position + Vector2(400, 33), Loc.t("m_nosave"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))


func _draw_back(hover_mouse: bool = true) -> void:
    var f := ThemeDB.fallback_font
    var hover := back_rect.has_point(get_local_mouse_position())
    draw_rect(back_rect, Color(0.25, 0.4, 0.5) if not hover else Color(0.35, 0.55, 0.65))
    draw_rect(back_rect, Color(1, 1, 1, 0.8), false, 2.0)
    draw_string(f, back_rect.position + Vector2(0, 31), Loc.t("o_back"), HORIZONTAL_ALIGNMENT_CENTER, back_rect.size.x, 24, Color.WHITE)


func _panel_bg() -> void:
    if not is_pause:
        draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.5))


func _draw_difficulty() -> void:
    var f := ThemeDB.fallback_font
    _panel_bg()
    _outlined(Loc.t("d_title"), Vector2(0, 130), 1280.0, 56, Color.WHITE)
    var cols := [GameState.trash_colors["glass"], GameState.trash_colors["plastic"], Color(0.85, 0.25, 0.2)]
    var names := ["d_easy", "d_normal", "d_hard"]
    var descs := ["d_easy_desc", "d_normal_desc", "d_hard_desc"]
    for i in 3:
        var r := _card_rect(i)
        var on := i == diff_sel
        if on:
            r = r.grow(12)
            r.position.y += sin(t * 4.0) * 4.0
        var c: Color = cols[i]
        draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.45))
        draw_rect(r, c.darkened(0.55))
        draw_rect(Rect2(r.position, Vector2(r.size.x, 64)), c.darkened(0.1))
        draw_rect(r, Color.WHITE if on else Color(1, 1, 1, 0.3), false, 4.0 if on else 2.0)
        draw_string_outline(f, r.position + Vector2(0, 46), Loc.t(names[i]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40, 6, Color(0, 0, 0, 0.7))
        draw_string(f, r.position + Vector2(0, 46), Loc.t(names[i]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40, Color.WHITE)
        # thermometer
        var tc := Vector2(r.get_center().x, r.position.y + 210)
        draw_rect(Rect2(tc + Vector2(-9, -90), Vector2(18, 110)), Color(0.95, 0.95, 0.95))
        var lvl := (i + 1) / 3.0
        draw_rect(Rect2(tc + Vector2(-5, 16 - 106.0 * lvl), Vector2(10, 106.0 * lvl)), c.lightened(0.2))
        draw_circle(tc + Vector2(0, 30), 17.0, c.lightened(0.1))
        draw_circle(tc + Vector2(0, 30), 17.0, Color.WHITE, false, 2.0)
        draw_multiline_string(f, r.position + Vector2(24, 290), Loc.t(descs[i]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 48.0, 20, 4, Color.WHITE)
    draw_string(f, Vector2(0, 626), Loc.t("nav_hint_lr"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 18, Color(0.85, 0.9, 0.9))
    _draw_back()


func _draw_options() -> void:
    var f := ThemeDB.fallback_font
    _panel_bg()
    _outlined(Loc.t("o_title"), Vector2(0, 150), 1280.0, 56, Color.WHITE)
    var cols := _btn_cols()
    var labels := [Loc.t("o_language"), Loc.t("o_fullscreen"), Loc.t("o_back")]
    var vals := ["<  %s  >" % ("English" if Loc.lang == "en" else "Türkçe"), "<  %s  >" % (Loc.t("o_on") if Loc.fullscreen else Loc.t("o_off")), ""]
    for i in 3:
        var r := _opt_rect(i)
        var on := i == opt_sel
        if on:
            r = r.grow_individual(14, 3, 14, 3)
        var c: Color = cols[i]
        draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.4))
        draw_rect(r, c.darkened(0.1) if on else c.darkened(0.4))
        draw_rect(Rect2(r.position, Vector2(r.size.x, 7)), c.lightened(0.25))
        draw_rect(r, Color.WHITE if on else Color(1, 1, 1, 0.25), false, 3.0 if on else 2.0)
        if i < 2:
            draw_string(f, r.position + Vector2(24, 46), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
            draw_string(f, r.position + Vector2(0, 46), vals[i], HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 24.0, 28, Color.WHITE)
        else:
            draw_string(f, r.position + Vector2(0, 46), labels[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 28, Color.WHITE)
        if on:
            ArtS.recycle(self, Vector2(r.position.x - 28, r.get_center().y), 13.0, t * 2.0, Color.WHITE)
    draw_string(f, Vector2(0, 626), Loc.t("nav_hint"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 18, Color(0.85, 0.9, 0.9))
    _draw_back()


func _draw_credits() -> void:
    _panel_bg()
    _outlined(Loc.t("c_title"), Vector2(0, 150), 1280.0, 56, Color.WHITE)
    for i in 4:
        _outlined(Loc.t("c_%d" % (i + 1)), Vector2(0, 270 + i * 70), 1280.0, 28, Color(1, 1, 0.9), 6)
    for i in 4:
        ArtS.trash(self, GameState.trash_types[i], Vector2(500 + i * 90, 560 + sin(t * 2.0 + i) * 6.0), 2.0)
    _draw_back()


func _draw_background() -> void:
    # sky: polluted on the left, clean on the right
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.66, 0.52, 0.34))
    draw_rect(Rect2(0, 0, 1280, 260), Color(0.58, 0.44, 0.3, 0.5))
    draw_colored_polygon(PackedVector2Array([Vector2(700, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(470, 720)]), Color(0.5, 0.78, 0.95))
    draw_colored_polygon(PackedVector2Array([Vector2(640, 0), Vector2(700, 0), Vector2(470, 720), Vector2(410, 720)]), Color(0.6, 0.65, 0.6, 0.55))
    # dim red sun (left) and bright sun (right)
    draw_circle(Vector2(150, 130), 46.0, Color(0.85, 0.35, 0.2, 0.9))
    draw_circle(Vector2(1090, 110), 80.0, Color(1, 0.95, 0.6, 0.25))
    draw_circle(Vector2(1090, 110), 52.0, Color(1.0, 0.95, 0.5))
    # hills
    var lp := PackedVector2Array()
    var x := 0.0
    while x <= 720.0:
        lp.append(Vector2(x, 470.0 + sin(x * 0.006) * 25.0))
        x += 40.0
    lp.append(Vector2(720, 720))
    lp.append(Vector2(0, 720))
    draw_colored_polygon(lp, Color(0.42, 0.35, 0.26))
    var rp := PackedVector2Array([Vector2(470, 720)])
    x = 566.0
    while x <= 1280.0:
        rp.append(Vector2(x, 450.0 + sin(x * 0.005 + 1.0) * 30.0))
        x += 40.0
    rp.append(Vector2(1280, 720))
    draw_colored_polygon(rp, Color(0.38, 0.7, 0.4))
    # polluted skyline with chimneys + smoke (left)
    for i in 7:
        var bx := 10.0 + i * 70.0
        var bw := 56.0 + (i % 3) * 8.0
        var bh := 120.0 + float((i * 47) % 110)
        draw_rect(Rect2(bx, 560.0 - bh, bw, bh), Color(0.28, 0.25, 0.24))
        for j in 3:
            draw_rect(Rect2(bx + 8, 560.0 - bh + 14 + j * 30, 8, 12), Color(0.12, 0.1, 0.1))
            draw_rect(Rect2(bx + bw - 18, 560.0 - bh + 14 + j * 30, 8, 12), Color(0.12, 0.1, 0.1))
        if i % 3 == 0:
            draw_rect(Rect2(bx + bw * 0.6, 560.0 - bh - 44, 12, 44), Color(0.22, 0.2, 0.2))
            for j in 5:
                draw_circle(Vector2(bx + bw * 0.6 + 6.0 + sin(t + j + i) * 8.0, 560.0 - bh - 52.0 - j * 24.0 - fposmod(t * 26.0 + j * 12.0, 24.0)), 11.0 + j * 3.0, Color(0.3, 0.27, 0.24, 0.6))
    # dead trees (left) and living trees + wind turbines (right)
    for tx in [440.0, 520.0]:
        draw_rect(Rect2(tx - 4, 470, 8, 90), Color(0.22, 0.18, 0.16))
        draw_line(Vector2(tx, 500), Vector2(tx - 22, 462), Color(0.22, 0.18, 0.16), 4.0)
        draw_line(Vector2(tx, 490), Vector2(tx + 24, 456), Color(0.22, 0.18, 0.16), 4.0)
    for tx in [760.0, 900.0, 1020.0, 1190.0]:
        draw_rect(Rect2(tx - 5, 500, 10, 70), Color(0.4, 0.27, 0.16))
        draw_circle(Vector2(tx, 486), 36.0, Color(0.25, 0.68, 0.3))
        draw_circle(Vector2(tx - 20, 504), 26.0, Color(0.3, 0.74, 0.35))
        draw_circle(Vector2(tx + 20, 504), 26.0, Color(0.3, 0.74, 0.35))
    for wx in [830.0, 1110.0]:
        draw_line(Vector2(wx, 570), Vector2(wx, 380), Color.WHITE, 5.0)
        draw_circle(Vector2(wx, 380), 6.0, Color.WHITE)
        for k in 3:
            var a := t * 1.2 + k * TAU / 3.0
            draw_line(Vector2(wx, 380), Vector2(wx, 380) + Vector2.from_angle(a) * 62.0, Color.WHITE, 4.0)
    # smog drifting over the polluted half
    for i in 5:
        var cx := fposmod(i * 170.0 + t * 12.0, 760.0) - 60.0
        draw_circle(Vector2(cx, 90.0 + (i % 3) * 70.0), 80.0, Color(0.5, 0.42, 0.26, 0.3))
    # ground: dirty on the left with litter, grass on the right
    draw_rect(Rect2(0, 640, 1280, 80), Color(0.3, 0.24, 0.2))
    draw_colored_polygon(PackedVector2Array([Vector2(520, 640), Vector2(1280, 640), Vector2(1280, 720), Vector2(470, 720)]), Color(0.3, 0.7, 0.35))
    var tc := [GameState.trash_colors["glass"], GameState.trash_colors["paper"], GameState.trash_colors["plastic"], GameState.trash_colors["metal"]]
    for i in 12:
        draw_rect(Rect2(24 + i * 38, 636 + (i % 3) * 8, 10, 8), tc[i % 4])
    # floating items drifting up
    for i in 10:
        var pos := Vector2(80.0 + i * 120.0 + sin(t * 0.8 + i) * 24.0, 760.0 - fposmod(t * (22.0 + (i % 3) * 8.0) + i * 83.0, 860.0))
        draw_set_transform(pos, t * 0.6 + i, Vector2.ONE)
        ArtS.trash(self, GameState.trash_types[i % 4], Vector2.ZERO, 1.3)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
