extends RefCounted
# Shared drawing helpers (icons). Call from inside a CanvasItem's _draw().


static func trash(ci: CanvasItem, type: String, p: Vector2, s: float = 1.0) -> void:
    var col: Color = GameState.trash_colors[type]
    match type:
        "glass":
            ci.draw_rect(Rect2(p + Vector2(-7, -6) * s, Vector2(14, 18) * s), col)
            ci.draw_rect(Rect2(p + Vector2(-3, -16) * s, Vector2(6, 11) * s), col)
            ci.draw_rect(Rect2(p + Vector2(-4, -4) * s, Vector2(3, 12) * s), Color(1, 1, 1, 0.45))
        "metal":
            ci.draw_rect(Rect2(p + Vector2(-9, -11) * s, Vector2(18, 22) * s), Color(0.8, 0.14, 0.14))
            ci.draw_rect(Rect2(p + Vector2(-9, -11) * s, Vector2(18, 4) * s), col.lightened(0.3))
            ci.draw_rect(Rect2(p + Vector2(-9, 7) * s, Vector2(18, 4) * s), col.darkened(0.2))
            ci.draw_rect(Rect2(p + Vector2(-5, -3) * s, Vector2(10, 6) * s), Color(1, 1, 1, 0.55))
        "paper":
            ci.draw_colored_polygon(PackedVector2Array([
                p + Vector2(-11, -6) * s, p + Vector2(-4, -13) * s, p + Vector2(7, -11) * s, p + Vector2(12, -2) * s,
                p + Vector2(8, 9) * s, p + Vector2(-3, 12) * s, p + Vector2(-12, 6) * s]), Color(0.95, 0.95, 0.92))
            ci.draw_line(p + Vector2(-7, -3) * s, p + Vector2(6, -5) * s, col, 2.0)
            ci.draw_line(p + Vector2(-6, 2) * s, p + Vector2(7, 1) * s, col, 2.0)
        _:
            ci.draw_rect(Rect2(p + Vector2(-7, -8) * s, Vector2(14, 20) * s), col)
            ci.draw_rect(Rect2(p + Vector2(-4, -14) * s, Vector2(8, 7) * s), Color(0.9, 0.9, 0.95))
            ci.draw_rect(Rect2(p + Vector2(-5, -15) * s, Vector2(10, 3) * s), Color(0.2, 0.4, 0.9))
            ci.draw_rect(Rect2(p + Vector2(-7, 0) * s, Vector2(14, 3) * s), col.darkened(0.25))


static func sapling(ci: CanvasItem, p: Vector2, s: float = 1.0) -> void:
    ci.draw_circle(p + Vector2(0, 2) * s, 14.0 * s, Color(0.3, 0.8, 0.4, 0.25))
    ci.draw_rect(Rect2(p + Vector2(-9, 4) * s, Vector2(18, 6) * s), Color(0.4, 0.28, 0.18))
    ci.draw_line(p + Vector2(0, 4) * s, p + Vector2(0, -10) * s, Color(0.25, 0.6, 0.25), 3.0 * s)
    ci.draw_circle(p + Vector2(-6, -11) * s, 6.0 * s, Color(0.35, 0.8, 0.4))
    ci.draw_circle(p + Vector2(6, -14) * s, 6.0 * s, Color(0.45, 0.88, 0.45))


static func bin(ci: CanvasItem, type: String, p: Vector2, s: float = 1.0) -> void:
    var col: Color = GameState.trash_colors[type]
    ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, -44) * s, p + Vector2(20, -44) * s, p + Vector2(24, 0), p + Vector2(-24, 0)]), col.darkened(0.15))
    ci.draw_rect(Rect2(p + Vector2(-25, -52) * s, Vector2(50, 9) * s), col.lightened(0.2))
    recycle(ci, p + Vector2(0, -22) * s, 9.0 * s, 0.0, Color.WHITE)


static func recycle(ci: CanvasItem, c: Vector2, r: float, rot: float, col: Color) -> void:
    for k in 3:
        var a0 := rot + k * TAU / 3.0
        var a1 := a0 + 1.7
        ci.draw_arc(c, r, a0, a1, 12, col, 3.0)
        var tip := c + Vector2.from_angle(a1) * r
        var tang := Vector2.from_angle(a1 + PI / 2.0)
        var rad := Vector2.from_angle(a1)
        ci.draw_colored_polygon(PackedVector2Array([tip + tang * 6.0, tip + rad * 5.0, tip - rad * 5.0]), col)


static func shield(ci: CanvasItem, p: Vector2, s: float = 1.0) -> void:
    ci.draw_colored_polygon(PackedVector2Array([
        p + Vector2(-11, -13) * s, p + Vector2(11, -13) * s, p + Vector2(11, 2) * s, p + Vector2(0, 14) * s, p + Vector2(-11, 2) * s]), Color(0.4, 0.7, 1.0))
    ci.draw_line(p + Vector2(0, -10) * s, p + Vector2(0, 9) * s, Color.WHITE, 2.0)
