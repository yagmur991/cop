extends Area2D
# Boss kapısı. Tüm geri dönüşüm kutuları dolunca kilit açılır. Origin = sol üst.

signal entered

var total := 3
var done := 0
var fired := false
var msg_cd := 0.0


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(80, 200)
    cs.shape = r
    cs.position = Vector2(40, 100)
    add_child(cs)


func unlocked() -> bool:
    return done >= total


func bin_done() -> void:
    done += 1
    GameState.bins_done = done
    queue_redraw()
    if unlocked():
        GameState.item_collected.emit("KİLİT AÇILDI! Boss kapısı seni bekliyor.")


func _physics_process(delta: float) -> void:
    msg_cd = maxf(0.0, msg_cd - delta)
    for b in get_overlapping_bodies():
        if b.is_in_group("player"):
            if unlocked():
                if not fired:
                    fired = true
                    entered.emit()
            elif msg_cd <= 0.0:
                msg_cd = 2.5
                GameState.item_collected.emit("Kapı kilitli! Çöpleri geri dönüşüm kutularına götür (%d/%d)" % [done, total])


func _draw() -> void:
    var col := Color(0.6, 0.1, 0.15, 0.85) if unlocked() else Color(0.35, 0.35, 0.4, 0.9)
    draw_rect(Rect2(0, 0, 80, 200), col)
    var f := ThemeDB.fallback_font
    if unlocked():
        draw_string(f, Vector2(14, 105), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    else:
        draw_string(f, Vector2(8, 95), "KİLİTLİ", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
        draw_string(f, Vector2(24, 125), "%d/%d" % [done, total], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
