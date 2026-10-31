extends Area2D
# Tür-bazlı geri dönüşüm kutusu (cam / metal / kağıt / plastik).
# Oyuncu eşleşen türde çöp taşıyorsa içine girerek teslim eder.
# Sprite: res://assets/<Tür>RecycleBin-Sheet.png (Plastic, Glass, Metal, Paper).
# Dosya yoksa kutu kodla çizilir; dosyayı assets/ içine koymak yeterli.

signal activated

var type := "glass"
var need := 2
var have := 0
var done := false
var sprite: Sprite2D


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(60, 56)
    cs.shape = r
    cs.position = Vector2(0, -28)
    add_child(cs)
    var path := "res://assets/%sRecycleBin-Sheet.png" % type.capitalize()
    if ResourceLoader.exists(path):
        sprite = Sprite2D.new()
        sprite.texture = load(path)
        sprite.scale = Vector2(0.4, 0.4)       # 128x160 -> ~51x64
        sprite.position = Vector2(0, -32)      # origin = alt orta
        add_child(sprite)


func _physics_process(_delta: float) -> void:
    if done or int(GameState.stock[type]) <= 0:
        return
    for b in get_overlapping_bodies():
        if b.is_in_group("player"):
            var n := mini(int(GameState.stock[type]), need - have)
            if n > 0:
                have += n
                GameState.deposit(type, n)
                queue_redraw()
                GameState.item_collected.emit(Loc.t("msg_bin", [GameState.trash_name(type), have, need]))
                if have >= need:
                    done = true
                    if sprite:
                        sprite.modulate = Color(0.6, 1.0, 0.6)
                    activated.emit()
            break


func _draw() -> void:
    var col: Color = GameState.trash_colors[type]
    var f := ThemeDB.fallback_font
    if sprite:
        draw_string(f, Vector2(-40, -70), "%d/%d" % [have, need], HORIZONTAL_ALIGNMENT_CENTER, 80.0, 20, Color.WHITE)
        return
    var body := col.darkened(0.15) if not done else col.lightened(0.15)
    draw_rect(Rect2(-28, -52, 56, 52), body)
    draw_rect(Rect2(-32, -60, 64, 9), body.lightened(0.2))
    draw_rect(Rect2(-24, -46, 48, 5), body.darkened(0.2))
    draw_arc(Vector2(0, -26), 10.0, 0.3, 4.4, 14, Color.WHITE, 3.0)
    draw_colored_polygon(PackedVector2Array([Vector2(7, -37), Vector2(14, -28), Vector2(3, -28)]), Color.WHITE)
    draw_string(f, Vector2(-40, -70), GameState.trash_name(type), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 14, Color.WHITE)
    var label := Loc.t("done") if done else "%d/%d" % [have, need]
    draw_string(f, Vector2(-40, -8), label, HORIZONTAL_ALIGNMENT_CENTER, 80.0, 16, Color.WHITE)
