extends Node
# Global oyun durumu (autoload). Tüm sistemler buradan okur/yazar.

signal changed
signal item_collected(text: String)
signal heat_wave

var max_hp := 5
var hp := 5
var pollution := 0.0          # 0-100
var recycle_stock := 0        # Boss savaşında kullanılacak itemler
var trash_stock := 0
var recycled_total := 0
var trash_total := 0
var dirty_total := 0          # Boss'ta kullanılan çöp bombası sayısı
var upgrades := {"double_jump": false, "speed": 0, "damage": 0, "shield": 0}
var running := false          # true iken zamanla kirlilik/sıcaklık artar
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


func reset() -> void:
    max_hp = 5
    hp = 5
    pollution = 0.0
    recycle_stock = 0
    trash_stock = 0
    recycled_total = 0
    trash_total = 0
    dirty_total = 0
    upgrades = {"double_jump": false, "speed": 0, "damage": 0, "shield": 0}
    running = false
    heat_timer = 0.0
    bins_done = 0
    bins_total = 0
    changed.emit()


func add_pollution(amount: float) -> void:
    pollution = clampf(pollution + amount, 0.0, 100.0)
    changed.emit()


func apply_item(kind: String) -> void:
    var text := ""
    if kind == "recycle":
        recycled_total += 1
        recycle_stock += 1
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
        trash_stock += 1
        upgrades["damage"] += 1
        add_pollution(12.0)
        text = "ÇÖP: Hasar +1 ama kirlilik arttı!"
    changed.emit()
    item_collected.emit(text)


func _process(delta: float) -> void:
    if not running:
        return
    pollution = minf(100.0, pollution + 0.25 * delta)   # zamanla kirlilik artar
    if pollution >= 85.0:
        heat_timer += delta
        if heat_timer >= 6.0:
            heat_timer = 0.0
            heat_wave.emit()
    else:
        heat_timer = 0.0


func temperature() -> float:
    return 1.2 + pollution * 0.03   # küresel ısınma göstergesi (°C)


func deposit(n: int) -> void:
    trash_stock -= n
    add_pollution(-10.0 * n)
