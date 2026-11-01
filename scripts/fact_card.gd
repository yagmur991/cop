extends Node2D
# "Did you know?" card: short eco facts that slide in under the pollution bar. Never pauses the game.
# Triggered with GameState.fact.emit("bin_glass") -> shows Loc key "fact_bin_glass".

const FontsS = preload("res://scripts/fonts.gd")
const CREAM := Color(1.0, 0.96, 0.86)
const BUTTER := Color(0.95, 0.82, 0.5)
const SHOW_TIME := 7.0

var cur := ""
var queue: Array = []
var t := 0.0


func _ready() -> void:
    GameState.fact.connect(_on_fact)


func _on_fact(key: String) -> void:
    if key == cur or key in queue:
        return
    if cur == "":
        cur = key
        t = 0.0
    elif queue.size() < 3:
        queue.append(key)


func clear() -> void:
    cur = ""
    queue.clear()
    queue_redraw()


func _process(delta: float) -> void:
    if cur == "":
        return
    t += delta
    if t >= SHOW_TIME:
        cur = ""
        if not queue.is_empty():
            cur = queue.pop_front()
            t = 0.0
    queue_redraw()


func _draw() -> void:
    if cur == "":
        return
    var fade_in := clampf(t / 0.4, 0.0, 1.0)
    var a := minf(fade_in, clampf((SHOW_TIME - t) / 0.5, 0.0, 1.0))
    var r := Rect2(20.0 - (1.0 - fade_in) * 40.0, 86.0, 440.0, 122.0)
    draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0.1, 0.06, 0.04, 0.35 * a))
    draw_rect(r, Color(0.17, 0.13, 0.1, 0.9 * a))
    draw_rect(r, Color(BUTTER, 0.85 * a), false, 2.0)
    draw_string(FontsS.TITLE, r.position + Vector2(16, 30), Loc.t("fact_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(BUTTER, a))
    draw_multiline_string(FontsS.TEXT, r.position + Vector2(16, 58), Loc.t("fact_" + cur), HORIZONTAL_ALIGNMENT_LEFT, 408.0, 17, 4, Color(CREAM, a))
