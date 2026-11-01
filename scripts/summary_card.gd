extends Node2D
# Level summary shown after a boss falls: sorting accuracy, kills, pollution, upgrades, 0-3 saplings, a fact.
# Stays until the player presses Enter. Runs while the game is paused.

signal finished

const ArtS = preload("res://scripts/art.gd")
const FontsS = preload("res://scripts/fonts.gd")
const CREAM := Color(1.0, 0.96, 0.86)
const BUTTER := Color(0.95, 0.82, 0.5)
const OUTLINE := Color(0.24, 0.17, 0.13)
const MIN_WAIT := 0.8
const FADE := 0.45

var level_no := 1
var theme := "sea"
var stats: Dictionary = {}      # ok, wrong, kills, saplings, trash, deaths, pollution
var stars: Array = [false, false, false]
var upgrades_text := ""
var fact_key := ""
var last := false
var t := 0.0
var leaving := false
var leave_t := 0.0
var done := false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
    t += delta
    var a := clampf(t / FADE, 0.0, 1.0)
    if leaving:
        leave_t += delta
        a *= clampf(1.0 - leave_t / FADE, 0.0, 1.0)
        if leave_t >= FADE and not done:
            done = true
            finished.emit()
    modulate.a = a
    queue_redraw()


func _input(event: InputEvent) -> void:
    if t < MIN_WAIT or leaving:
        return
    if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
        leaving = true
        get_viewport().set_input_as_handled()


func _outlined(text: String, pos: Vector2, width: float, size: int, col: Color, outline: int, f: Font) -> void:
    draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline, OUTLINE)
    draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


func _row(x: float, y: float, w: float, label: String, value: String) -> void:
    draw_string(FontsS.BTN, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, w - 90.0, 22, Color(CREAM, 0.92))
    draw_string(FontsS.TITLE, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_RIGHT, w, 26, BUTTER)
    draw_line(Vector2(x, y + 10.0), Vector2(x + w, y + 10.0), Color(CREAM, 0.18), 1.0)


func _draw() -> void:
    var top := Color(0.58, 0.78, 0.8)
    var bot := Color(0.26, 0.46, 0.56)
    if theme == "air":
        top = Color(0.76, 0.73, 0.66)
        bot = Color(0.42, 0.45, 0.52)
    elif theme == "land":
        top = Color(0.8, 0.72, 0.52)
        bot = Color(0.34, 0.29, 0.21)
    draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)]), PackedColorArray([top, top, bot, bot]))
    draw_rect(Rect2(140, 0, 1000, 720), Color(0.15, 0.1, 0.07, 0.35))

    _outlined(Loc.t("sum_title"), Vector2(0, 92), 1280.0, 60, CREAM, 10, FontsS.TITLE)
    _outlined(Loc.t("sum_" + theme), Vector2(0, 134), 1280.0, 24, Color(CREAM, 0.95), 5, FontsS.BTN)

    # 0-3 saplings
    var labels := [Loc.t("sum_star_acc"), Loc.t("sum_star_poll"), Loc.t("sum_star_death")]
    for i in 3:
        var cx := 400.0 + float(i) * 240.0
        var got: bool = stars[i]
        if got:
            ArtS.sapling(self, Vector2(cx, 196.0 + sin(t * 3.0 + float(i)) * 3.0), 2.4)
        else:
            draw_circle(Vector2(cx, 192.0), 22.0, Color(0.1, 0.07, 0.05, 0.4))
            draw_arc(Vector2(cx, 192.0), 22.0, 0.0, TAU, 20, Color(CREAM, 0.35), 2.0)
        draw_string(FontsS.TEXT, Vector2(cx - 110.0, 248.0), labels[i], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 16, Color(CREAM, 1.0 if got else 0.55))

    # numbers
    var ok := int(stats.get("ok", 0))
    var wrong := int(stats.get("wrong", 0))
    var acc := "-" if ok + wrong == 0 else "%d%%" % int(round(100.0 * float(ok) / float(ok + wrong)))
    _row(200.0, 305.0, 400.0, Loc.t("sum_ok"), str(ok))
    _row(200.0, 351.0, 400.0, Loc.t("sum_wrong"), str(wrong))
    _row(200.0, 397.0, 400.0, Loc.t("sum_acc"), acc)
    _row(200.0, 443.0, 400.0, Loc.t("sum_kills"), str(int(stats.get("kills", 0))))
    _row(680.0, 305.0, 400.0, Loc.t("sum_bins"), "%d/%d" % [int(stats.get("bins", 0)), int(stats.get("bins_all", 0))])
    _row(680.0, 351.0, 400.0, Loc.t("sum_saplings"), str(int(stats.get("saplings", 0))))
    _row(680.0, 397.0, 400.0, Loc.t("sum_poll"), "%d%%" % int(stats.get("pollution", 0)))
    _row(680.0, 443.0, 400.0, Loc.t("sum_deaths"), str(int(stats.get("deaths", 0))))
    draw_string(FontsS.BTN, Vector2(200.0, 500.0), Loc.t("sum_upg") + ": ", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(CREAM, 0.92))
    draw_string(FontsS.TEXT, Vector2(200.0, 528.0), upgrades_text, HORIZONTAL_ALIGNMENT_LEFT, 880.0, 20, BUTTER)

    # did-you-know box
    var r := Rect2(200.0, 556.0, 880.0, 88.0)
    draw_rect(r, Color(0.17, 0.13, 0.1, 0.8))
    draw_rect(r, Color(BUTTER, 0.8), false, 2.0)
    draw_string(FontsS.TITLE, r.position + Vector2(16, 28), Loc.t("fact_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, BUTTER)
    draw_multiline_string(FontsS.TEXT, r.position + Vector2(16, 54), Loc.t("fact_" + fact_key), HORIZONTAL_ALIGNMENT_LEFT, 848.0, 18, 2, CREAM)

    if t >= MIN_WAIT:
        var hint := Loc.t("sum_continue_last") if last else Loc.t("sum_continue")
        draw_string(FontsS.TEXT, Vector2(0, 690), hint, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 20, Color(CREAM, 0.6 + 0.3 * sin(t * 4.0)))
