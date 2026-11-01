extends Node2D
# "LEVEL 1 - Save the Sea" card shown before each level. Runs while the game is paused.

signal finished

const FontTitle: Font = preload("res://assets/fonts/YoungSerif-Regular.ttf")
const FontBtn: Font = preload("res://assets/fonts/Lora-Bold.ttf")
const FontText: Font = preload("res://assets/fonts/Lora-Regular.ttf")
const CREAM := Color(1.0, 0.96, 0.86)
const OUTLINE := Color(0.24, 0.17, 0.13)

const MIN_WAIT := 0.6   # Enter is ignored for a moment so it can't be skipped by accident
const FADE := 0.45

var level_no := 1
var theme := "sea"
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


# The card stays until the player presses Enter
func _input(event: InputEvent) -> void:
    if t < MIN_WAIT or leaving:
        return
    if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
        leaving = true
        get_viewport().set_input_as_handled()


func _outlined(text: String, pos: Vector2, size: int, col: Color, outline: int, f: Font) -> void:
    draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, size, outline, OUTLINE)
    draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, size, col)


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

    var bob := sin(t * 2.0) * 4.0
    var c := Vector2(640.0, 170.0 + bob)
    match theme:
        "air":
            _icon_air(c)
        "land":
            _icon_land(c)
        _:
            _icon_sea(c)

    var rise := (1.0 - clampf(t / 0.6, 0.0, 1.0)) * 24.0
    _outlined(Loc.t("lv_num", [level_no]), Vector2(0, 300.0 + rise), 30, Color(CREAM, 0.92), 6, FontBtn)
    _outlined(Loc.t("lv_" + theme), Vector2(0, 400.0 + rise), 96, CREAM, 12, FontTitle)
    draw_line(Vector2(560, 424.0 + rise), Vector2(720, 424.0 + rise), Color(CREAM, 0.55), 3.0)
    _outlined(Loc.t("lv_" + theme + "_sub"), Vector2(0, 470.0 + rise), 26, Color(CREAM, 0.95), 5, FontBtn)
    if t >= MIN_WAIT:
        draw_string(FontText, Vector2(0, 650), Loc.t("lv_continue"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 20, Color(CREAM, 0.6 + 0.3 * sin(t * 4.0)))


func _icon_sea(c: Vector2) -> void:
    var glass := Color(0.78, 0.92, 0.96, 0.95)
    draw_set_transform(c, 0.35, Vector2.ONE)
    draw_rect(Rect2(-14, -40, 28, 56), glass)
    draw_rect(Rect2(-6, -58, 12, 18), glass)
    draw_rect(Rect2(-8, -64, 16, 8), Color(0.96, 0.96, 0.96))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    for row in 2:
        var pts := PackedVector2Array()
        for k in 19:
            var x := -90.0 + float(k) * 10.0
            pts.append(c + Vector2(x, 26.0 + float(row) * 13.0 + sin(t * 2.0 + float(k) * 0.7 + float(row)) * 3.0))
        draw_polyline(pts, Color(CREAM, 0.7), 3.0)


func _icon_air(c: Vector2) -> void:
    var smoke := Color(0.35, 0.34, 0.34, 0.85)
    draw_rect(Rect2(c.x - 70.0, c.y - 10.0, 22.0, 62.0), Color(0.3, 0.32, 0.36))
    draw_rect(Rect2(c.x - 70.0, c.y - 10.0, 22.0, 8.0), Color(0.75, 0.3, 0.25))
    for j in 4:
        draw_circle(Vector2(c.x - 59.0 + sin(t + float(j)) * 6.0, c.y - 22.0 - float(j) * 18.0 - fposmod(t * 20.0, 18.0)), 10.0 + float(j) * 4.0, Color(smoke, 0.8 - float(j) * 0.15))
    draw_circle(c + Vector2(10, 0), 30.0, smoke)
    draw_circle(c + Vector2(44, 8), 24.0, smoke)
    draw_circle(c + Vector2(-16, 10), 22.0, smoke)
    draw_string(FontBtn, c + Vector2(-14, 12), "CO2", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(CREAM, 0.9))


func _icon_land(c: Vector2) -> void:
    var dirt := Color(0.42, 0.33, 0.25)
    draw_colored_polygon(PackedVector2Array([c + Vector2(-110, 50), c + Vector2(-50, -8), c + Vector2(0, -22), c + Vector2(60, -4), c + Vector2(110, 50)]), dirt)
    var bits: Array = [Color(0.5, 0.7, 0.55), Color(0.9, 0.82, 0.45), Color(0.55, 0.65, 0.85), Color(0.75, 0.76, 0.8)]
    for i in 8:
        var bc: Color = bits[i % 4]
        draw_rect(Rect2(c.x - 70.0 + float((i * 37) % 120), c.y + 6.0 + float((i * 23) % 34), 10.0, 7.0), bc)
    # a small sapling growing out of the heap
    var sway := sin(t * 1.5) * 3.0
    draw_line(c + Vector2(0, -22), c + Vector2(sway, -56), Color(0.45, 0.65, 0.4), 4.0)
    draw_circle(c + Vector2(sway - 8.0, -58), 9.0, Color(0.55, 0.78, 0.5))
    draw_circle(c + Vector2(sway + 8.0, -64), 9.0, Color(0.6, 0.82, 0.55))
