extends Node2D
# Arka plan: kirlilik arttıkça ortam pisleşir (parlaklık düşmez; renk, duman ve ağaçlar değişir).

const PERIOD := 1700.0
const TREE_PERIOD := 1820.0

var t := 0.0
var buildings: Array = []


func _ready() -> void:
    var x := 0.0
    var i := 0
    while x < PERIOD - 120.0:
        var w := 70.0 + float((i * 37) % 60)
        var h := 90.0 + float((i * 61) % 170)
        buildings.append(Rect2(x, 560.0 - h, w, h))
        x += w + 12.0
        i += 1


func _process(delta: float) -> void:
    t += delta
    queue_redraw()


func _hills(off: float, base: float, amp: float, col: Color) -> void:
    var pts := PackedVector2Array()
    var x := 0.0
    while x <= 1280.0:
        pts.append(Vector2(x, base + sin((x + off) * 0.004) * amp))
        x += 40.0
    pts.append(Vector2(1280, 720))
    pts.append(Vector2(0, 720))
    draw_colored_polygon(pts, col)


func _draw() -> void:
    var p := GameState.pollution / 100.0
    var cam := get_viewport().get_camera_2d()
    var off := 0.0
    if cam:
        off = cam.get_screen_center_position().x

    # güneş: temizken sarı, kirliyken soluk turuncu
    draw_circle(Vector2(1050, 110), 46.0, Color(1.0, 0.95, 0.5).lerp(Color(0.95, 0.62, 0.32), p))

    _hills(off * 0.1, 470.0, 28.0, Color(0.45, 0.75, 0.45).lerp(Color(0.54, 0.48, 0.34), p))

    # şehir silueti + fabrika bacaları
    var bcol := Color(0.62, 0.72, 0.82).lerp(Color(0.46, 0.43, 0.4), p)
    var shift := fposmod(off * 0.25, PERIOD)
    for k in 2:
        for bi in buildings.size():
            var r: Rect2 = buildings[bi]
            var rr := Rect2(r.position + Vector2(k * PERIOD - shift, 0), r.size)
            if rr.end.x < 0.0 or rr.position.x > 1280.0:
                continue
            draw_rect(rr, bcol)
            if bi % 4 == 0:
                draw_rect(Rect2(rr.position.x + rr.size.x * 0.6, rr.position.y - 28, 12, 28), bcol.darkened(0.2))
                if p > 0.1:
                    for j in 5:
                        var sp := Vector2(rr.position.x + rr.size.x * 0.6 + 6 + sin(t + j) * 8.0 + j * 6.0,
                            rr.position.y - 34 - j * 24 - fposmod(t * 30.0 + j * 18.0, 36.0))
                        draw_circle(sp, 10.0 + j * 3.0, Color(0.4, 0.37, 0.32, 0.65 * p))

    # ağaçlar: temizken yaprak dolu, kirliyken kuru dallar
    var tshift := fposmod(off * 0.45, TREE_PERIOD)
    var crown_r := lerpf(34.0, 0.0, clampf((p - 0.35) / 0.4, 0.0, 1.0))
    var crown_col := Color(0.25, 0.65, 0.3).lerp(Color(0.5, 0.45, 0.2), p)
    for k in 2:
        for i in 7:
            var tx := i * 260.0 + k * TREE_PERIOD - tshift
            if tx < -60.0 or tx > 1340.0:
                continue
            var trunk := Color(0.38, 0.26, 0.16).lerp(Color(0.25, 0.2, 0.17), p)
            draw_rect(Rect2(tx - 5, 540, 10, 60), trunk)
            if crown_r > 2.0:
                draw_circle(Vector2(tx, 524), crown_r, crown_col)
                draw_circle(Vector2(tx - 14, 536), crown_r * 0.7, crown_col)
                draw_circle(Vector2(tx + 14, 536), crown_r * 0.7, crown_col)
            else:
                draw_line(Vector2(tx, 560), Vector2(tx - 22, 520), trunk, 4.0)
                draw_line(Vector2(tx, 552), Vector2(tx + 24, 512), trunk, 4.0)
                draw_line(Vector2(tx, 540), Vector2(tx - 10, 500), trunk, 3.0)

    # duman/smog bulutları
    if p > 0.05:
        for i in 8:
            var cx := fposmod(i * 260.0 + t * (10.0 + i * 3.0) - off * 0.2, 1500.0) - 100.0
            var cy := 120.0 + (i % 4) * 90.0 + sin(t * 0.3 + i) * 12.0
            var rad := 70.0 + (i % 3) * 20.0
            draw_circle(Vector2(cx, cy), rad, Color(0.5, 0.45, 0.28, 0.32 * p))
            draw_circle(Vector2(cx + rad * 0.6, cy + 10.0), rad * 0.7, Color(0.5, 0.45, 0.28, 0.28 * p))
        draw_rect(Rect2(0, 420, 1280, 300), Color(0.5, 0.42, 0.25, 0.15 * p))
