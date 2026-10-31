extends Node2D
# "Kimsin sen?" karakter seçim ekranı. Her renk küçük bir perk verir.

signal finished

var sel := 0
var t := 0.0
var delay := 0.35


func _process(delta: float) -> void:
    t += delta
    delay -= delta
    var n: int = GameState.characters.size()
    if delay <= 0.0:
        if Input.is_action_just_pressed("ui_right"):
            sel = (sel + 1) % n
        if Input.is_action_just_pressed("ui_left"):
            sel = (sel + n - 1) % n
        if Input.is_action_just_pressed("ui_accept"):
            GameState.char_idx = sel
            set_process(false)
            finished.emit()
    queue_redraw()


func _char(p: Vector2, s: float, col: Color) -> void:
    draw_rect(Rect2(p + Vector2(-14, -22) * s, Vector2(28, 44) * s), col)
    draw_rect(Rect2(p + Vector2(-14, -22) * s, Vector2(28, 10) * s), col.darkened(0.2))
    draw_rect(Rect2(p + Vector2(3, -16) * s, Vector2(6, 6) * s), Color.WHITE)
    draw_rect(Rect2(p + Vector2(-5, 0) * s, Vector2(10, 10) * s), Color(0.2, 0.5, 0.9))


func _draw() -> void:
    var f := ThemeDB.fallback_font
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.06, 0.08, 0.16))
    draw_string(f, Vector2(0, 110), "KİMSİN SEN?", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 60, Color.WHITE)
    draw_string(f, Vector2(0, 150), "Karakterini seç", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 22, Color(0.7, 0.7, 0.8))
    var n: int = GameState.characters.size()
    for i in n:
        var c: Dictionary = GameState.characters[i]
        var x := 640.0 + (i - (n - 1) / 2.0) * 220.0
        var base := Color(c["color"])
        if i == sel:
            draw_circle(Vector2(x, 350), 90.0, Color(1, 1, 1, 0.08))
            _char(Vector2(x, 350 + sin(t * 4.0) * 6.0), 2.8, base)
            draw_rect(Rect2(x - 60, 440, 120, 4), base)
        else:
            _char(Vector2(x, 360), 1.9, base.darkened(0.35))
    var cur: Dictionary = GameState.characters[sel]
    draw_string(f, Vector2(0, 530), cur["name"], HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 40, cur["color"])
    draw_string(f, Vector2(0, 575), cur["perk"], HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 26, Color.WHITE)
    draw_string(f, Vector2(0, 660), "← → seç     Enter onayla", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 20, Color(0.6, 0.6, 0.7))
