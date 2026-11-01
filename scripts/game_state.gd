extends Node
# Global game state (autoload): stats, difficulty, save / load.

signal changed
signal item_collected(text: String)
signal heat_wave
signal shake(amount: float, time: float)              # camera shake
signal hitstop(time: float)                           # short freeze frame
signal burst(pos: Vector2, col: Color, n: int)        # particle burst

const SAVE_PATH := "user://savegame.json"

var trash_types := ["glass", "metal", "paper", "plastic"]
var trash_colors := {
    "glass": Color(0.25, 0.75, 0.4), "metal": Color(0.62, 0.66, 0.72),
    "paper": Color(0.35, 0.6, 0.95), "plastic": Color(0.98, 0.82, 0.2)}
var char_colors := [
    Color(0.3, 0.8, 0.4), Color(0.3, 0.55, 0.95), Color(0.95, 0.8, 0.25), Color(0.65, 0.4, 0.9), Color(0.95, 0.5, 0.7)]
var char_idx := 0

var difficulty := 1            # 0 easy, 1 normal, 2 hard
var max_hp := 5
var hp := 5
var pollution := 0.0           # 0-100
var pollution_rate := 0.25
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
var sel := 0                   # selected trash type (index into trash_types): what E drops into a bin
var trash_bag: Array = []      # shuffle bag: every type shows up evenly, in random order
var lv_stats := {}             # per-level numbers for the level summary card
var lv_upg_start := {}         # upgrades at the start of the level (to show what was gained)


func _ready() -> void:
    _add_action("left", [KEY_A, KEY_LEFT])
    _add_action("right", [KEY_D, KEY_RIGHT])
    _add_action("up", [KEY_W, KEY_UP])
    _add_action("down", [KEY_S, KEY_DOWN])
    _add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
    _add_action("attack", [KEY_J, KEY_X, KEY_Z])
    _add_action("inventory", [KEY_B])
    _add_action("deposit", [KEY_E])
    _add_action("cycle", [KEY_Q])
    reset_level_stats()


# Q cycles through the types you carry, 1-4 pick a type directly
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("cycle"):
        select_next()
    elif event is InputEventKey and event.pressed and not event.echo:
        var idx := int(event.physical_keycode) - int(KEY_1)
        if idx >= 0 and idx < 4:
            sel = idx
            changed.emit()


func select_next() -> void:
    for k in range(1, 5):
        var j := (sel + k) % 4
        if int(stock[trash_types[j]]) > 0:
            sel = j
            changed.emit()
            return
    sel = (sel + 1) % 4
    changed.emit()


# never keep an empty type selected while another one is carried
func fix_sel() -> void:
    if int(stock[trash_types[sel]]) > 0:
        return
    for k in range(1, 4):
        var j := (sel + k) % 4
        if int(stock[trash_types[j]]) > 0:
            sel = j
            return


func reset_level_stats() -> void:
    lv_stats = {"ok": 0, "wrong": 0, "kills": 0, "saplings": 0, "trash": 0, "deaths": 0, "bins": 0}
    lv_upg_start = upgrades.duplicate()


func _add_action(action_name: String, keys: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    for k in keys:
        var e := InputEventKey.new()
        e.physical_keycode = k
        InputMap.action_add_event(action_name, e)


# ---------------- difficulty ----------------
func diff_pollution() -> float:
    return [0.6, 1.0, 1.4][difficulty]


func diff_enemy() -> float:
    return [0.8, 1.0, 1.25][difficulty]


func diff_boss() -> float:
    return [0.75, 1.0, 1.3][difficulty]


func diff_hp() -> int:
    return [2, 0, -1][difficulty]


func diff_heat() -> float:
    return [95.0, 85.0, 70.0][difficulty]


# ---------------- names ----------------
func trash_name(type: String) -> String:
    return Loc.t("trash_" + type)


func char_name(i: int) -> String:
    return Loc.t("char_%d_name" % i)


func char_perk(i: int) -> String:
    return Loc.t("char_%d_perk" % i)


func player_color() -> Color:
    return char_colors[char_idx]


func apply_character() -> void:
    max_hp = 5 + diff_hp()
    attack_delay = 0.3
    pollution_rate = 0.25
    match char_idx:
        0:
            max_hp += 1
        1:
            upgrades["speed"] = int(upgrades["speed"]) + 1
        2:
            attack_delay = 0.2
        3:
            pollution_rate = 0.15
        4:
            upgrades["shield"] = int(upgrades["shield"]) + 1
    hp = max_hp
    changed.emit()


func reset() -> void:
    char_idx = 0
    difficulty = 1
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
    sel = 0
    trash_bag.clear()
    reset_level_stats()
    changed.emit()


func next_trash_type() -> String:
    if trash_bag.is_empty():
        trash_bag = trash_types.duplicate()
        trash_bag.shuffle()
    trash_cycle += 1
    return trash_bag.pop_back()


func add_pollution(amount: float) -> void:
    pollution = clampf(pollution + amount, 0.0, 100.0)
    changed.emit()


func apply_item(kind: String, trash_type: String = "") -> void:
    var text := ""
    if kind == "recycle":
        recycled_total += 1
        Sfx.play("pickup_clean")
        lv_stats["saplings"] += 1
        add_pollution(-8.0)
        var pool: Array = ["speed", "shield", "heal"]
        if not upgrades["double_jump"]:
            pool.append("double_jump")
            pool.append("double_jump")
        var pick: String = pool.pick_random()
        match pick:
            "double_jump":
                upgrades["double_jump"] = true
                text = Loc.t("msg_up_dj")
            "speed":
                upgrades["speed"] += 1
                text = Loc.t("msg_up_speed")
            "shield":
                upgrades["shield"] += 1
                text = Loc.t("msg_up_shield")
            "heal":
                hp = mini(hp + 1, max_hp)
                text = Loc.t("msg_up_heal")
    else:
        trash_total += 1
        Sfx.play("pickup_trash")
        lv_stats["trash"] += 1
        var had_sel := int(stock[trash_types[sel]]) > 0
        stock[trash_type] += 1
        if not had_sel:
            sel = trash_types.find(trash_type)
        upgrades["damage"] += 1
        add_pollution(12.0)
        text = Loc.t("msg_trash", [trash_name(trash_type)])
    changed.emit()
    item_collected.emit(text)


func deposit(trash_type: String, n: int) -> void:
    stock[trash_type] -= n
    delivered_total += n
    lv_stats["ok"] += n
    add_pollution(-10.0 * n)
    fix_sel()


# wrong bin: the item is spoiled and the pollution goes up
func contaminate(trash_type: String) -> void:
    stock[trash_type] -= 1
    lv_stats["wrong"] += 1
    add_pollution(8.0)
    fix_sel()


func _process(delta: float) -> void:
    if not running:
        return
    pollution = minf(100.0, pollution + pollution_rate * diff_pollution() * delta)
    if pollution >= diff_heat():
        heat_timer += delta
        if heat_timer >= 6.0:
            heat_timer = 0.0
            heat_wave.emit()
    else:
        heat_timer = 0.0


func temperature() -> float:
    return 1.2 + pollution * 0.03


# ---------------- save / load ----------------
func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)


func save_game(level_idx: int, arena: bool) -> void:
    var d := {
        "v": 1, "level": level_idx, "arena": arena, "difficulty": difficulty, "char": char_idx,
        "max_hp": max_hp, "pollution": pollution, "pollution_rate": pollution_rate, "attack_delay": attack_delay,
        "stock": stock, "trash_cycle": trash_cycle, "recycled_total": recycled_total,
        "trash_total": trash_total, "delivered_total": delivered_total, "upgrades": upgrades}
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(d))


func load_game() -> Dictionary:
    if not has_save():
        return {}
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return {}
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var d: Dictionary = parsed
    reset()
    difficulty = int(d.get("difficulty", 1))
    char_idx = int(d.get("char", 0))
    max_hp = int(d.get("max_hp", 5))
    pollution = float(d.get("pollution", 0.0))
    pollution_rate = float(d.get("pollution_rate", 0.25))
    attack_delay = float(d.get("attack_delay", 0.3))
    trash_cycle = int(d.get("trash_cycle", 0))
    recycled_total = int(d.get("recycled_total", 0))
    trash_total = int(d.get("trash_total", 0))
    delivered_total = int(d.get("delivered_total", 0))
    var st: Dictionary = d.get("stock", {})
    for k in trash_types:
        stock[k] = int(st.get(k, 0))
    var up: Dictionary = d.get("upgrades", {})
    upgrades = {"double_jump": bool(up.get("double_jump", false)), "speed": int(up.get("speed", 0)),
        "damage": int(up.get("damage", 0)), "shield": int(up.get("shield", 0))}
    hp = max_hp
    fix_sel()
    changed.emit()
    return {"level": int(d.get("level", 0)), "arena": bool(d.get("arena", false))}


func delete_save() -> void:
    if has_save():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
