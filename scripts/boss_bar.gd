extends Node2D
# Boss HUD: a name banner when the fight starts + a fixed health bar (with the boss name) at the top.

const FontsS = preload("res://scripts/fonts.gd")
const CREAM := Color(1.0, 0.96, 0.86)
const BUTTER := Color(0.95, 0.82, 0.5)
const OUTLINE := Color(0.24, 0.17, 0.13)
const INTRO := 3.2

var boss: Node = null
var intro_t := 99.0
var lag := 1.0


func _process(delta: float) -> void:
    var b := get_tree().get_first_node_in_group("boss")
    if b != boss:
        boss = b
        if b != null:
            intro_t = 0.0
            lag = 1.0
    if boss != null and is_instance_valid(boss):
        intro_t += delta
        var ratio := clampf(float(boss.hp) / float(maxi(int(boss.max_hp), 1)), 0.0, 1.0)
        lag = ratio if ratio > lag else move_toward(lag, ratio, delta * 0.3)
    queue_redraw()


func _outlined(text: String, pos: Vector2, width: float, size: int, col: Color, outline: int, f: Font) -> void:
    draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline, Color(OUTLINE, col.a))
    draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


func _draw() -> void:
    if boss == null or not is_instance_valid(boss) or boss.dead:
        return
    var bname := Loc.t("boss_" + str(boss.boss_id))
    var ratio := clampf(float(boss.hp) / float(maxi(int(boss.max_hp), 1)), 0.0, 1.0)
    # health bar
    var bx := 380.0
    var bw := 520.0
    var by := 50.0
    _outlined(bname, Vector2(bx, by - 8.0), bw, 24, CREAM, 6, FontsS.TITLE)
    draw_rect(Rect2(bx - 3.0, by - 3.0, bw + 6.0, 22.0), Color(0.12, 0.08, 0.06, 0.88))
    draw_rect(Rect2(bx, by, bw * lag, 16.0), Color(1.0, 0.95, 0.8, 0.8))
    draw_rect(Rect2(bx, by, bw * ratio, 16.0), Color(0.82, 0.4, 0.34))
    draw_line(Vector2(bx + bw * 0.5, by), Vector2(bx + bw * 0.5, by + 16.0), Color(CREAM, 0.8), 2.0)
    if str(boss.boss_id) == "land":
        draw_line(Vector2(bx + bw * 0.25, by), Vector2(bx + bw * 0.25, by + 16.0), Color(CREAM, 0.8), 2.0)
    draw_rect(Rect2(bx - 3.0, by - 3.0, bw + 6.0, 22.0), Color(CREAM, 0.7), false, 2.0)
    # intro banner
    if intro_t < INTRO:
        var a := minf(clampf(intro_t / 0.4, 0.0, 1.0), clampf((INTRO - intro_t) / 0.6, 0.0, 1.0))
        draw_rect(Rect2(0, 250, 1280, 150), Color(0.12, 0.08, 0.06, 0.62 * a))
        draw_string(FontsS.BTN, Vector2(0, 292), Loc.t("boss_label"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 26, Color(BUTTER, a))
        _outlined(bname, Vector2(0, 372), 1280.0, 84, Color(CREAM, a), 12, FontsS.TITLE)
