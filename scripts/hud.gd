extends CanvasLayer

var stats: Label
var bar_fill: ColorRect
var msg: Label
var msg_t := 0.0

var inv_root: Control
var inv_label: Label


func _ready() -> void:
    layer = 5
    process_mode = Node.PROCESS_MODE_ALWAYS   # oyun durunca da B çalışsın

    # --- Sade ana HUD: sadece can, kirlilik barı, sıcaklık ---
    stats = _label(Vector2(20, 12), 20)
    add_child(stats)
    var bg := ColorRect.new()
    bg.position = Vector2(20, 44)
    bg.size = Vector2(220, 16)
    bg.color = Color(0, 0, 0, 0.5)
    add_child(bg)
    bar_fill = ColorRect.new()
    bar_fill.position = Vector2(20, 44)
    bar_fill.size = Vector2(0, 16)
    add_child(bar_fill)
    var l := _label(Vector2(250, 40), 16)
    l.text = "Kirlilik"
    add_child(l)

    msg = _label(Vector2(240, 620), 26)
    msg.size = Vector2(800, 40)
    msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(msg)

    var hint := _label(Vector2(20, 686), 15)
    hint.text = "B: Envanter   J/X: Saldır   Boşluk/W: Zıpla   Çöpü doğru türdeki kutuya götür!"
    add_child(hint)

    _build_inventory()
    GameState.item_collected.connect(show_msg)


func _build_inventory() -> void:
    inv_root = Control.new()
    inv_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    inv_root.visible = false
    add_child(inv_root)

    var dim := ColorRect.new()
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0, 0, 0, 0.6)
    inv_root.add_child(dim)

    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    inv_root.add_child(panel)

    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 24)
    panel.add_child(margin)

    inv_label = Label.new()
    inv_label.add_theme_font_size_override("font_size", 22)
    inv_label.custom_minimum_size = Vector2(420, 0)
    margin.add_child(inv_label)


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


func _input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("inventory"):
        _toggle_inventory()


func _toggle_inventory() -> void:
    inv_root.visible = not inv_root.visible
    get_tree().paused = inv_root.visible   # envanter açıkken oyun dursun


func _process(delta: float) -> void:
    stats.text = "CAN %d/%d    Sıcaklık: +%.1f°C" % [
        GameState.hp, GameState.max_hp, GameState.temperature()]
    var p := GameState.pollution / 100.0
    bar_fill.size.x = 220.0 * p
    bar_fill.color = Color(0.3, 0.8, 0.4).lerp(Color(0.8, 0.2, 0.15), p)

    msg_t -= delta
    if msg_t <= 0.0:
        msg.text = ""

    if inv_root.visible:
        _update_inventory()


func _update_inventory() -> void:
    var u: Dictionary = GameState.upgrades
    var st: Dictionary = GameState.stock
    var lock_txt := "Boss arenası"
    if GameState.bins_total > 0:
        lock_txt = "%d/%d kutu" % [GameState.bins_done, GameState.bins_total]
    inv_label.text = "ENVANTER  (kapatmak için B)\n\n" \
        + "Taşınan çöp: Cam %d | Metal %d | Kağıt %d | Plastik %d\n" % [st["glass"], st["metal"], st["paper"], st["plastic"]] \
        + "Kalkan: %d\n" % u["shield"] \
        + "Hız: +%d\n" % u["speed"] \
        + "Hasar: +%d\n" % u["damage"] \
        + "Çift zıplama: %s\n\n" % ("VAR" if u["double_jump"] else "yok") \
        + "Toplanan geri dönüşüm: %d\n" % GameState.recycled_total \
        + "Toplanan çöp: %d\n" % GameState.trash_total \
        + "Kilit durumu: %s\n" % lock_txt \
        + "Kirlilik: %%%d" % int(GameState.pollution)