extends Node2D
# HUD, top right: the four trash types you carry. The highlighted one is what E drops into a bin.

const ArtS = preload("res://scripts/art.gd")
const FontsS = preload("res://scripts/fonts.gd")
const CREAM := Color(1.0, 0.96, 0.86)
const OUTLINE := Color(0.24, 0.17, 0.13)


func _process(_delta: float) -> void:
    queue_redraw()


func _soft(c: Color) -> Color:
    return Color.from_hsv(c.h, c.s * 0.5, lerpf(c.v, 0.88, 0.35))


func _draw() -> void:
    var x0 := 950.0
    for i in 4:
        var type: String = GameState.trash_types[i]
        var n := int(GameState.stock[type])
        var col: Color = GameState.trash_colors[type]
        var on := i == GameState.sel
        var r := Rect2(x0 + float(i) * 74.0, 10.0, 68.0, 68.0)
        draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0.1, 0.06, 0.04, 0.35))
        draw_rect(r, Color(0.16, 0.12, 0.1, 0.8))
        draw_rect(Rect2(r.position.x, r.end.y - 6.0, r.size.x, 6.0), _soft(col))
        ArtS.trash(self, type, r.get_center() + Vector2(0, -4), 1.3)
        if n <= 0:
            draw_rect(r, Color(0.1, 0.07, 0.05, 0.6))
        draw_rect(r, CREAM if on else Color(CREAM, 0.3), false, 3.0 if on else 1.5)
        draw_string(FontsS.BTN, r.position + Vector2(6, 18), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(CREAM, 0.8))
        draw_string_outline(FontsS.BTN, Vector2(r.position.x, r.end.y - 12.0), "x%d" % n, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6.0, 18, 5, OUTLINE)
        draw_string(FontsS.BTN, Vector2(r.position.x, r.end.y - 12.0), "x%d" % n, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6.0, 18, CREAM)
    var hint := Loc.t("carry_hint")
    draw_string_outline(FontsS.TEXT, Vector2(0, 98), hint, HORIZONTAL_ALIGNMENT_RIGHT, 1262.0, 14, 4, OUTLINE)
    draw_string(FontsS.TEXT, Vector2(0, 98), hint, HORIZONTAL_ALIGNMENT_RIGHT, 1262.0, 14, Color(CREAM, 0.9))
