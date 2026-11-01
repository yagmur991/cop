extends Node
# Short UI + gameplay sound effects. Autoload "Sfx". Usage: Sfx.play("ui_select")
# Sounds live in res://assets/sfx/<name>.wav.

const NAMES := [
    "ui_move", "ui_select", "ui_back", "card_start", "jump", "attack", "hurt", "pickup_clean", "pickup_trash",
    "chest", "deposit", "bin_full", "unlock", "enemy_pop", "boss_hit", "boss_down", "warn"]

var streams := {}
var players: Array = []
var next := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS   # menu clicks must work while the game is paused
    for n in NAMES:
        var path := "res://assets/sfx/%s.wav" % n
        if ResourceLoader.exists(path):
            streams[n] = load(path)
    for i in 10:
        var p := AudioStreamPlayer.new()
        add_child(p)
        players.append(p)


func play(sound: String, pitch: float = 1.0) -> void:
    if Loc.sfx_vol <= 0.001 or not streams.has(sound):
        return
    var p: AudioStreamPlayer = players[next]
    next = (next + 1) % players.size()
    p.stream = streams[sound]
    p.pitch_scale = pitch
    p.volume_db = linear_to_db(Loc.sfx_vol) - 3.0
    p.play()
