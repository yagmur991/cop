extends Node2D

const FontsS = preload("res://scripts/fonts.gd")
const SpritesS = preload("res://scripts/sprites.gd")
# Overcooked tarzı anlatıcılı sinematik. Görseller kodla çizilir; ileride sprite ile değiştirilebilir.
# Enter: ilerle, Esc: sinematiği atla.

signal finished

var slides: Array = []
var idx := 0
var shown := 0.0
var t := 0.0
var delay := 0.3
var voice: AudioStreamPlayer
var blip_narr: AudioStream
var blip_gaia: AudioStream
var last_shown := 0
var voice_n := 0


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel art
    voice = AudioStreamPlayer.new()
    add_child(voice)
    if ResourceLoader.exists("res://assets/sfx/blip_narrator.wav"):
        blip_narr = load("res://assets/sfx/blip_narrator.wav")
    if ResourceLoader.exists("res://assets/sfx/blip_gaia.wav"):
        blip_gaia = load("res://assets/sfx/blip_gaia.wav")


func _voice_tick(txt: String) -> void:
    var n := int(shown)
    if n <= last_shown:
        return
    var who: String = slides[idx]["who"]
    for i in range(last_shown, mini(n, txt.length())):
        var ch := txt.substr(i, 1)
        if ch.to_lower() != ch.to_upper():   # only letters make a sound
            voice_n += 1
            if voice_n % 2 == 0:
                _blip(who == "who_gaia")
    last_shown = n


func _blip(gaia: bool) -> void:
    if voice == null or Loc.sfx_vol <= 0.001:
        return
    var snd: AudioStream = blip_gaia if gaia else blip_narr
    if snd == null:
        return
    voice.stream = snd
    voice.pitch_scale = randf_range(1.05, 1.65) if gaia else randf_range(0.7, 1.1)
    voice.volume_db = linear_to_db(Loc.sfx_vol) - 4.0
    voice.play()


static func intro_slides() -> Array:
    return [
        {"scene": "earth_good", "who": "who_narrator", "text": "intro_1"},
        {"scene": "earth_bad", "who": "who_narrator", "text": "intro_2"},
        {"scene": "ruins", "who": "who_narrator", "text": "intro_3"},
        {"scene": "ocean", "who": "who_narrator", "text": "intro_4"},
        {"scene": "mentor", "who": "who_gaia", "text": "intro_5"},
        {"scene": "who", "who": "", "text": ""},
    ]


static func good_slides() -> Array:
    return [
        {"scene": "world_good", "who": "who_narrator", "text": "good_1"},
        {"scene": "mentor_happy", "who": "who_gaia", "text": "good_2"},
    ]


static func bad_slides() -> Array:
    return [
        {"scene": "world_bad", "who": "who_narrator", "text": "bad_1"},
        {"scene": "grave", "who": "who_narrator", "text": "bad_2"},
    ]


func _text(s: Dictionary) -> String:
    if s.get("raw", false):
        return s["text"]
    if s["text"] == "":
        return ""
    return Loc.t(s["text"])


func _who_name(s: Dictionary) -> String:
    if s["who"] == "":
        return ""
    return Loc.t(s["who"])


func _process(delta: float) -> void:
    t += delta
    delay -= delta
    var txt := _text(slides[idx])
    shown = minf(shown + 45.0 * delta, float(txt.length()))
    _voice_tick(txt)
    if delay <= 0.0:
        if Input.is_action_just_pressed("ui_cancel"):
            Sfx.play("ui_back")
            set_process(false)
            finished.emit()
            return
        if Input.is_action_just_pressed("ui_accept"):
            if shown < float(txt.length()):
                shown = float(txt.length())
                last_shown = txt.length()
            else:
                idx += 1
                shown = 0.0
                last_shown = 0
                Sfx.play("ui_move")
                if idx >= slides.size():
                    set_process(false)
                    finished.emit()
                    return
    queue_redraw()


func _draw() -> void:
    var s: Dictionary = slides[idx]
    var f: Font = FontsS.TEXT
    var sc: String = s["scene"]
    _draw_scene(sc)
    var txt := _text(s)
    var part := txt.substr(0, int(shown))
    if sc == "stats":
        draw_multiline_string(FontsS.BTN, Vector2(0, 230), part, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 32)
    elif sc != "who":
        draw_rect(Rect2(60, 510, 1160, 170), Color(0, 0, 0, 0.72))
        draw_rect(Rect2(60, 510, 1160, 170), Color(1, 1, 1, 0.8), false, 2.0)
        draw_string(FontsS.BTN, Vector2(90, 548), _who_name(s), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.95, 0.82, 0.5))
        draw_multiline_string(f, Vector2(90, 590), part, HORIZONTAL_ALIGNMENT_LEFT, 1100.0, 26)
    if (sc == "who" or shown >= float(txt.length())) and int(t * 2.0) % 2 == 0:
        draw_string(FontsS.BTN, Vector2(1090, 668), Loc.t("cs_next"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    draw_string(f, Vector2(1130, 28), Loc.t("cs_skip"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.6))


func _draw_scene(sc: String) -> void:
    match sc:
        "earth_good":
            _earth(0.0)
        "earth_bad":
            _earth(1.0)
        "ruins":
            _ruins()
        "ocean":
            _ocean()
        "mentor":
            _mentor_room(0)
        "mentor_happy":
            _mentor_room(1)
        "who":
            _who()
        "world_good":
            _world(true)
        "world_bad":
            _world(false)
        "grave":
            _grave()
        _:
            draw_rect(Rect2(0, 0, 1280, 720), Color(0.05, 0.05, 0.08))


func _earth(sick: float) -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.03, 0.03, 0.1))
    for i in 60:
        var sp := Vector2(fposmod(i * 197.0, 1280.0), fposmod(i * 89.0, 500.0))
        draw_circle(sp, 1.5 + (i % 3) * 0.5, Color(1, 1, 1, 0.5 + 0.3 * sin(t * 2.0 + i)))
    var c := Vector2(640, 260)
    if sick > 0.5:
        draw_circle(c, 178.0 + sin(t * 3.0) * 4.0, Color(1.0, 0.3, 0.1, 0.25))
    var ocean := Color(0.2, 0.5, 0.9).lerp(Color(0.5, 0.35, 0.22), sick)
    var land := Color(0.3, 0.72, 0.35).lerp(Color(0.42, 0.32, 0.2), sick)
    draw_circle(c, 150.0, ocean)
    draw_circle(c + Vector2(-50, -30), 42.0, land)
    draw_circle(c + Vector2(-20, -45), 32.0, land)
    draw_circle(c + Vector2(55, 25), 48.0, land)
    draw_circle(c + Vector2(-70, 60), 30.0, land)
    if sick > 0.5:
        for i in 6:
            draw_circle(c + Vector2(-110 + i * 45, -140 - sin(t + i) * 10.0 - (i % 2) * 20), 30.0, Color(0.25, 0.25, 0.25, 0.7))
        var level := minf(0.35 + t * 0.2, 0.95)
        draw_rect(Rect2(930, 120, 26, 280), Color.WHITE)
        draw_rect(Rect2(934, 124 + (1.0 - level) * 272.0, 18, level * 272.0), Color(0.9, 0.15, 0.1))
        draw_circle(Vector2(943, 415), 28.0, Color(0.9, 0.15, 0.1))
    else:
        for i in 3:
            draw_circle(c + Vector2(-90 + i * 80, -60 + i * 30), 22.0, Color(1, 1, 1, 0.35))


func _ruins() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.55, 0.32, 0.2))
    draw_rect(Rect2(0, 0, 1280, 180), Color(0.42, 0.26, 0.18))
    draw_circle(Vector2(1000, 150), 60.0, Color(0.9, 0.35, 0.15))
    var xs := [60, 190, 330, 470, 620, 780, 910, 1060, 1180]
    for i in xs.size():
        var x: float = xs[i]
        var w := 100.0 + (i % 3) * 20.0
        var top := 500.0 - (160.0 + float((i * 53) % 150))
        var col := Color(0.22, 0.2, 0.2)
        draw_rect(Rect2(x, top, w, 500.0 - top), col)
        draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + w * 0.3, top - 25), Vector2(x + w * 0.5, top)]), col)
        draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.5, top), Vector2(x + w * 0.75, top - 18), Vector2(x + w, top)]), col)
        for j in 3:
            draw_rect(Rect2(x + 14, top + 20 + j * 40, 14, 18), Color(0.1, 0.08, 0.08))
            draw_rect(Rect2(x + w - 30, top + 20 + j * 40, 14, 18), Color(0.1, 0.08, 0.08))
        if i % 2 == 0:
            for j in 4:
                draw_circle(Vector2(x + w * 0.5 + sin(t + j) * 8.0, top - 30 - j * 28 - fposmod(t * 25.0 + j * 15.0, 30.0)), 12.0 + j * 3.0, Color(0.25, 0.22, 0.2, 0.6))
    draw_rect(Rect2(0, 500, 1280, 220), Color(0.18, 0.14, 0.12))


func _ocean() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.5, 0.5, 0.44))
    for i in 5:
        draw_circle(Vector2(150 + i * 270, 90 + (i % 2) * 40), 80.0, Color(0.38, 0.36, 0.32, 0.8))
    draw_rect(Rect2(0, 300, 1280, 220), Color(0.25, 0.36, 0.36))
    for row in 4:
        var pts := PackedVector2Array()
        for k in 33:
            pts.append(Vector2(k * 40.0, 330.0 + row * 45.0 + sin(t * 1.5 + k * 0.7 + row) * 6.0))
        draw_polyline(pts, Color(0.4, 0.5, 0.5), 3.0)
    draw_colored_polygon(PackedVector2Array([Vector2(160, 300), Vector2(250, 150), Vector2(340, 300)]), Color(0.9, 0.95, 1.0))
    draw_colored_polygon(PackedVector2Array([Vector2(900, 300), Vector2(960, 200), Vector2(1030, 300)]), Color(0.9, 0.95, 1.0))
    for i in 4:
        draw_circle(Vector2(230 + i * 30, 300 + fposmod(t * 50.0 + i * 25.0, 70.0)), 3.0, Color(0.5, 0.7, 1.0))
    var cols := [Color(0.3, 0.6, 0.95), Color(0.98, 0.82, 0.2), Color(0.25, 0.75, 0.4), Color(0.6, 0.66, 0.72)]
    for i in 9:
        var p := Vector2(120 + i * 135.0, 380.0 + (i % 3) * 40.0 + sin(t * 1.5 + i) * 6.0)
        draw_rect(Rect2(p + Vector2(-7, -9), Vector2(14, 20)), cols[i % 4])
        draw_rect(Rect2(p + Vector2(-3, -15), Vector2(6, 7)), cols[i % 4].lightened(0.3))


func _mentor(p: Vector2, sc: float, mood: int) -> void:
    # p = horizontal centre / top of the sprite; sc = scale of the 128x160 PNG
    var tex: Texture2D = SpritesS.GAIA[clampi(mood, 0, 1)]
    var sz := Vector2(tex.get_width(), tex.get_height()) * sc
    draw_texture_rect(tex, Rect2(p - Vector2(sz.x / 2.0, 0.0), sz), false)


func _mentor_room(mood: int) -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.25, 0.3, 0.4))
    draw_rect(Rect2(0, 440, 1280, 280), Color(0.18, 0.2, 0.28))
    var win := Rect2(840, 70, 300, 240)
    if mood == 1:
        draw_rect(win, Color(0.55, 0.8, 0.95))
        draw_circle(Vector2(1060, 130), 30.0, Color(1.0, 0.95, 0.5))
        draw_rect(Rect2(840, 250, 300, 60), Color(0.4, 0.75, 0.4))
    else:
        draw_rect(win, Color(0.6, 0.38, 0.25))
        draw_circle(Vector2(1060, 130), 30.0, Color(0.9, 0.35, 0.15))
        draw_rect(Rect2(840, 250, 300, 60), Color(0.3, 0.22, 0.18))
        draw_circle(Vector2(950, 200 - fposmod(t * 20.0, 40.0)), 22.0, Color(0.3, 0.28, 0.25, 0.7))
    draw_rect(win, Color(0.9, 0.9, 0.95), false, 6.0)
    _mentor(Vector2(430, 96), 2.6, mood)   # feet end right at the dialogue box
    if mood == 1:
        for i in 40:
            var cp := Vector2(fposmod(i * 97.0, 1280.0), fposmod(i * 53.0 + t * 120.0, 500.0))
            draw_rect(Rect2(cp, Vector2(8, 12)), Color.from_hsv(fposmod(i * 0.13, 1.0), 0.8, 1.0))


func _who() -> void:
    var f: Font = FontsS.TEXT
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.03, 0.03, 0.06))
    var p := Vector2(640, 380)
    draw_rect(Rect2(p + Vector2(-14, -22) * 4.0, Vector2(28, 44) * 4.0), Color(0.12, 0.12, 0.16))
    draw_string(f, p + Vector2(-30, 25), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 110, Color(0.4, 0.4, 0.5))
    draw_string(FontsS.TITLE, Vector2(0, 150), Loc.t("cs_title"), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 72, Color(1.0, 0.96, 0.86))


func _tree(p: Vector2, alive: bool) -> void:
    var trunk := Color(0.38, 0.26, 0.16) if alive else Color(0.22, 0.18, 0.16)
    draw_rect(Rect2(p + Vector2(-6, -70), Vector2(12, 70)), trunk)
    if alive:
        draw_circle(p + Vector2(0, -90), 36.0, Color(0.25, 0.68, 0.3))
        draw_circle(p + Vector2(-20, -72), 26.0, Color(0.3, 0.72, 0.35))
        draw_circle(p + Vector2(20, -72), 26.0, Color(0.3, 0.72, 0.35))
    else:
        draw_line(p + Vector2(0, -60), p + Vector2(-26, -100), trunk, 4.0)
        draw_line(p + Vector2(0, -50), p + Vector2(28, -92), trunk, 4.0)


func _world(good: bool) -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.55, 0.8, 0.95) if good else Color(0.45, 0.35, 0.25))
    var sun_col := Color(1.0, 0.95, 0.5) if good else Color(0.85, 0.3, 0.15)
    draw_circle(Vector2(1000, 120), 55.0, sun_col)
    var pts := PackedVector2Array()
    var x := 0.0
    while x <= 1280.0:
        pts.append(Vector2(x, 380.0 + sin(x * 0.005) * 30.0))
        x += 40.0
    pts.append(Vector2(1280, 500))
    pts.append(Vector2(0, 500))
    draw_colored_polygon(pts, Color(0.35, 0.75, 0.4) if good else Color(0.4, 0.32, 0.22))
    draw_rect(Rect2(0, 440, 1280, 80), Color(0.3, 0.6, 0.95) if good else Color(0.3, 0.28, 0.2))
    draw_rect(Rect2(0, 0, 1280, 500), Color(0, 0, 0, 0) if good else Color(0.45, 0.4, 0.2, 0.25))
    for i in 5:
        _tree(Vector2(100 + i * 230, 470), good)
    if good:
        for i in 3:
            var b := Vector2(300 + i * 330, 330)
            draw_line(b, b + Vector2(0, 100), Color.WHITE, 5.0)
            for k in 3:
                var a := t * 2.0 + k * TAU / 3.0
                draw_line(b, b + Vector2(cos(a), sin(a)) * 50.0, Color.WHITE, 4.0)
    else:
        for i in 4:
            for j in 5:
                draw_circle(Vector2(180 + i * 300 + sin(t + j) * 8.0, 400 - j * 40 - fposmod(t * 25.0 + j * 10.0, 30.0)), 18.0 + j * 4.0, Color(0.25, 0.23, 0.2, 0.55))


func _grave() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.22, 0.18, 0.28))
    draw_circle(Vector2(240, 110), 40.0, Color(0.85, 0.85, 0.75))
    draw_rect(Rect2(0, 430, 1280, 290), Color(0.15, 0.14, 0.16))
    for i in 5:
        _tree(Vector2(100 + i * 260, 440), false)
    draw_rect(Rect2(570, 270, 140, 190), Color(0.55, 0.55, 0.58))
    draw_circle(Vector2(640, 270), 70.0, Color(0.55, 0.55, 0.58))
    var f: Font = FontsS.TEXT
    draw_string(FontsS.BTN, Vector2(570, 300), "PROF.", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 22, Color(0.2, 0.2, 0.22))
    draw_string(FontsS.BTN, Vector2(570, 330), "GAIA", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 26, Color(0.2, 0.2, 0.22))
    draw_arc(Vector2(745, 455), 12.0, 0, TAU, 16, Color(0.1, 0.1, 0.1), 3.0)
    draw_arc(Vector2(775, 455), 12.0, 0, TAU, 16, Color(0.1, 0.1, 0.1), 3.0)
    draw_line(Vector2(757, 455), Vector2(763, 455), Color(0.1, 0.1, 0.1), 3.0)
    draw_line(Vector2(520, 460), Vector2(520, 425), Color(0.3, 0.4, 0.2), 3.0)
    draw_circle(Vector2(520, 420), 6.0, Color(0.5, 0.3, 0.35))
    for i in 10:
        draw_circle(Vector2(fposmod(i * 131.0 + t * 40.0, 1280.0), 380.0 + (i % 5) * 20.0), 3.0, Color(0.5, 0.45, 0.4, 0.5))
