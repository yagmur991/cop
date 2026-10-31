extends CanvasLayer

var stats: Label
var bar_fill: ColorRect
var msg: Label
var msg_t := 0.0


func _ready() -> void:
    layer = 5
    stats = _label(Vector2(20, 12), 20)
    add_child(stats)
    var bg := ColorRect.new()
    bg.position = Vector2(20, 122)
    bg.size = Vector2(220, 16)
    bg.color = Color(0, 0, 0, 0.5)
    add_child(bg)
    bar_fill = ColorRect.new()
    bar_fill.position = Vector2(20, 122)
    bar_fill.size = Vector2(0, 16)
    add_child(bar_fill)
    var l := _label(Vector2(250, 118), 16)
    l.text = "Kirlilik"
    add_child(l)
    msg = _label(Vector2(240, 620), 26)
    msg.size = Vector2(800, 40)
    msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(msg)
    var hint := _label(Vector2(20, 686), 15)
    hint.text = "A/D: hareket   Boşluk/W: zıpla   J/X: saldır   Çöpleri mavi kutulara götür!"
    add_child(hint)
    GameState.item_collected.connect(show_msg)


func _label(pos: Vector2, font_size: int) -> Label:
    var l := Label.new()
    l.position = pos
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 6)
    return l


func show_msg(text: String) -> void:
    msg.text = text
    msg_t = 2.5


func _process(delta: float) -> void:
    var u: Dictionary = GameState.upgrades
    var lock_txt := "Boss arenası"
    if GameState.bins_total > 0:
        lock_txt = "Kilit: %d/%d kutu" % [GameState.bins_done, GameState.bins_total]
    stats.text = "CAN %d/%d    Kalkan: %d\nHız +%d    Hasar +%d    Çift zıplama: %s\nTaşınan çöp: %d    %s\nSıcaklık: +%.1f°C" % [
        GameState.hp, GameState.max_hp, u["shield"], u["speed"], u["damage"],
        "VAR" if u["double_jump"] else "yok", GameState.trash_stock, lock_txt, GameState.temperature()]
    var p := GameState.pollution / 100.0
    bar_fill.size.x = 220.0 * p
    bar_fill.color = Color(0.3, 0.8, 0.4).lerp(Color(0.8, 0.2, 0.15), p)
    msg_t -= delta
    if msg_t <= 0.0:
        msg.text = ""
