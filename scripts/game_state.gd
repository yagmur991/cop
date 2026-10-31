extends Node
# Global oyun durumu (autoload).

signal changed
signal item_collected(text: String)
signal heat_wave

var trash_types := ["glass", "metal", "paper", "plastic"]
var trash_names := {"glass": "Cam", "metal": "Metal", "paper": "Kağıt", "plastic": "Plastik"}
var trash_colors := {
    "glass": Color(0.25, 0.75, 0.4), "metal": Color(0.62, 0.66, 0.72),
    "paper": Color(0.35, 0.6, 0.95), "plastic": Color(0.98, 0.82, 0.2)}

# Karakterler: her birinin küçük bir perk'ü var
var characters := [
    {"name": "Yeşil", "color": Color(0.3, 0.8, 0.4), "perk": "Doğa Dostu: +1 can ile başlar"},
    {"name": "Mavi", "color": Color(0.3, 0.55, 0.95), "perk": "Rüzgâr: biraz daha hızlı koşar"},
    {"name": "Sarı", "color": Color(0.95, 0.8, 0.25), "perk": "Işık: saldırı daha seri"},
    {"name": "Mor", "color": Color(0.65, 0.4, 0.9), "perk": "Sakin: kirlilik daha yavaş artar"},
    {"name": "Pembe", "color": Color(0.95, 0.5, 0.7), "perk": "Koruyucu: kalkanla başlar"},
]
var char_idx := 0

var max_hp := 5
var hp := 5
var pollution := 0.0          # 0-100
var pollution_rate := 0.25    # zamanla artış hızı
var attack_delay := 0.3
var stock := {"glass": 0, "metal": 0, "paper": 0, "plastic": 0}
var trash_cycle := 0
var recycled_total := 0
var trash_total := 0
var delivered_total := 0
var upgrades := {"double_jump": false, "speed": 0, "damage": 0, "shield": 0}
var running := false
var heat_timer := 0.0
var bins_done := 0
var bins_total := 0


func _ready() -> void:
    _add_action("left", [KEY_A, KEY_LEFT])
    _add_action("right", [KEY_D, KEY_RIGHT])
    _add_action("up", [KEY_W, KEY_UP])
    _add_action("down", [KEY_S, KEY_DOWN])
    _add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
    _add_action("attack", [KEY_J, KEY_X, KEY_Z])
    _add_action("inventory", [KEY_B])


func _add_action(action_name: String, keys: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    for k in keys:
        var e := InputEventKey.new()
        e.physical_keycode = k
        InputMap.action_add_event(action_name, e)


func player_color() -> Color:
    return characters[char_idx]["color"]


func apply_character() -> void:
    match char_idx:
        0:
            max_hp = 6
        1:
            upgrades["speed"] = 1
        2:
            attack_delay = 0.2
        3:
            pollution_rate = 0.15
        4:
            upgrades["shield"] = 1
    hp = max_hp
    changed.emit()


func reset() -> void:
    char_idx = 0
    max_hp = 5
    hp = 5
    pollution = 0.0
    pollution_rate = 0.25
    attack_delay = 0.3
    stock = {"glass": 0, "metal": 0, "paper": 0, "plastic": 0}
    trash_cycle = 0
    recycled_total = 0
    trash_total = 0
    delivered_total = 0
    upgrades = {"double_jump": false, "speed": 0, "damage": 0, "shield": 0}
    running = false
    heat_timer = 0.0
    bins_done = 0
    bins_total = 0
    changed.emit()


func next_trash_type() -> String:
    var t: String = trash_types[trash_cycle % 4]
    trash_cycle += 1
    return t


func add_pollution(amount: float) -> void:
    pollution = clampf(pollution + amount, 0.0, 100.0)
    changed.emit()


func apply_item(kind: String, trash_type: String = "") -> void:
    var text := ""
    if kind == "recycle":
        recycled_total += 1
        add_pollution(-8.0)
        var pool: Array = ["speed", "shield", "heal"]
        if not upgrades["double_jump"]:
            pool.append("double_jump")
            pool.append("double_jump")
        var pick: String = pool.pick_random()
        match pick:
            "double_jump":
                upgrades["double_jump"] = true
                text = "Fidan dikildi: Çift zıplama!"
            "speed":
                upgrades["speed"] += 1
                text = "Fidan dikildi: Hız artışı!"
            "shield":
                upgrades["shield"] += 1
                text = "Fidan dikildi: Kalkan (1 hasarı emer)!"
            "heal":
                hp = mini(hp + 1, max_hp)
                text = "Fidan dikildi: +1 can!"
    else:
        trash_total += 1
        stock[trash_type] += 1
        upgrades["damage"] += 1
        add_pollution(12.0)
        text = "%s atığı! Hasar +1 ama kirlilik arttı. Doğru kutuya götür!" % trash_names[trash_type]
    changed.emit()
    item_collected.emit(text)


func deposit(trash_type: String, n: int) -> void:
    stock[trash_type] -= n
    delivered_total += n
    add_pollution(-10.0 * n)


func _process(delta: float) -> void:
    if not running:
        return
    pollution = minf(100.0, pollution + pollution_rate * delta)
    if pollution >= 85.0:
        heat_timer += delta
        if heat_timer >= 6.0:
            heat_timer = 0.0
            heat_wave.emit()
    else:
        heat_timer = 0.0


func temperature() -> float:
    return 1.2 + pollution * 0.03
