extends Node
# Background music with crossfades. Autoload "Music". Tracks live in res://assets/music/.

const TRACKS := {
    "menu": "res://assets/music/menu.ogg",
    "intro": "res://assets/music/intro.ogg",
    "level1": "res://assets/music/level1.ogg",
    "level2": "res://assets/music/level2.ogg",
    "level3": "res://assets/music/level3.ogg",
    "boss_plastic": "res://assets/music/boss_plastic.ogg",
    "boss_factory": "res://assets/music/boss_factory.ogg",
    "boss_land": "res://assets/music/boss_land.ogg",
    "ending_good": "res://assets/music/ending_good.ogg",
    "ending_bad": "res://assets/music/ending_bad.ogg",
}

var players: Array = []
var active := 0
var current := ""
var tween: Tween


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS   # keeps playing while the game is paused
    for i in 2:
        var p := AudioStreamPlayer.new()
        p.volume_db = -80.0
        add_child(p)
        players.append(p)
    Loc.volume_changed.connect(_on_volume)


func _target_db() -> float:
    if Loc.music_vol <= 0.001:
        return -80.0
    return linear_to_db(Loc.music_vol)


func _on_volume() -> void:
    var p: AudioStreamPlayer = players[active]
    if p.playing:
        p.volume_db = _target_db()


func play(track: String, fade: float = 1.0) -> void:
    if track == current:
        return
    current = track
    var path: String = TRACKS.get(track, "")
    var old: AudioStreamPlayer = players[active]
    var stream: AudioStream = null
    if path != "" and ResourceLoader.exists(path):
        stream = load(path)
    if tween:
        tween.kill()
    tween = create_tween().set_parallel(true)
    tween.tween_property(old, "volume_db", -60.0, fade)
    if stream:
        var ogg := stream as AudioStreamOggVorbis
        if ogg:
            ogg.loop = true
        active = 1 - active
        var nw: AudioStreamPlayer = players[active]
        nw.stream = stream
        nw.volume_db = -60.0
        nw.play()
        tween.tween_property(nw, "volume_db", _target_db(), fade)
    tween.chain().tween_callback(old.stop)
