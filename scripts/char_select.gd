extends Node2D

const FontsS = preload("res://scripts/fonts.gd")
# "Who are you?" character select. Each color gives a small perk.

signal finished

var sel := 0
var t := 0.0
var delay := 0.35


func _process(delta: float) -> void:
    t += delta
    delay -= delta
    var n: int = GameState.char_colors.size()
    if delay <= 0.0:
        if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("ui_right"):
            sel = (sel + 1) % n
        if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("ui_left"):
            sel = (sel + n - 1) % n
        if Input.is_action_just_pressed("ui_accept"):
            _confirm()
    queue_redraw()


func _confirm() -> void:
    GameState.char_idx = sel
    set_process(false)
    finished.emit()


func _x(i: int) -> float:
    return 640.0 + (i - (GameState.char_colors.size() - 1) / 2.0) * 220.0


func _input(event: InputEvent) -> void:
    if delay > 0.0:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var m := get_local_mouse_position()
        for i in GameState.char_colors.size():
            if Rect2(_x(i) - 100.0, 240.0, 200.0, 240.0).has_point(m):
                if sel == i:
                    _confirm()
                else:
                    sel = i
                return


func _char(p: Vector2, s: float, col: Color) -> void:
    draw_rect(Rect2(p + Vector2(-14, -22) * s, Vector2(28, 44) * s), col)
    draw_rect(Rect2(p + Vector2(-14, -22) * s, Vector2(28, 10) * s), col.darkened(0.2))
    draw_rect(Rect2(p + Vector2(3, -16) * s, Vector2(6, 6) * s), Color.WHITE)
    draw_rect(Rect2(p + Vector2(-5, 0) * s, Vector2(10, 10) * s), Color(0.2, 0.5, 0.9))


func _draw() -> void:
    var f: Font = FontsS.TEXT
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.06, 0.08, 0.16))
    draw_string(FontsS.TITLE, Vector2(0, 110), Loc.t("cs_title"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 60, Color.WHITE)
    draw_string(f, Vector2(0, 150), Loc.t("cs_sub"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 22, Color(0.7, 0.7, 0.8))
    var n: int = GameState.char_colors.size()
    for i in n:
        var x := _x(i)
        var base: Color = GameState.char_colors[i]
        if i == sel:
            draw_circle(Vector2(x, 350), 90.0, Color(1, 1, 1, 0.08))
            _char(Vector2(x, 350 + sin(t * 4.0) * 6.0), 2.8, base)
            draw_rect(Rect2(x - 60, 440, 120, 4), base)
        else:
            _char(Vector2(x, 360), 1.9, base.darkened(0.35))
    draw_string(FontsS.TITLE, Vector2(0, 530), GameState.char_name(sel), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 40, GameState.char_colors[sel])
    draw_string(FontsS.BTN, Vector2(0, 575), GameState.char_perk(sel), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 26, Color.WHITE)
    draw_string(f, Vector2(0, 660), Loc.t("cs_hint"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 20, Color(0.6, 0.6, 0.7))
