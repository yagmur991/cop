extends Area2D
# Type-specific recycling bin (glass / metal / paper / plastic).
# Stand inside it and press E: the SELECTED trash goes in.
#   right bin -> counts toward the gate lock, pollution drops
#   wrong bin -> the item is spoiled and pollution rises (you learn which trash goes where)
# Sprite: res://assets/Recycle bin <type>.png (64x64), looked up in sprites.gd.

signal activated

const ArtS = preload("res://scripts/art.gd")
const SpritesS = preload("res://scripts/sprites.gd")
const FontsS = preload("res://scripts/fonts.gd")
const CREAM := Color(1.0, 0.96, 0.86)
const COCOA := Color(0.27, 0.18, 0.13)

var type := "glass"
var need := 2
var have := 0
var done := false
var sprite: Sprite2D
var inside := false
var flash := 0.0
var t := 0.0


func _ready() -> void:
    collision_layer = 0
    collision_mask = 8
    add_to_group("bin")
    var cs := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(60, 56)
    cs.shape = r
    cs.position = Vector2(0, -28)
    add_child(cs)
    sprite = SpritesS.make(SpritesS.BINS[type], 1.0)   # 64x64, origin = bottom middle
    add_child(sprite)


func _physics_process(delta: float) -> void:
    t += delta
    flash = maxf(0.0, flash - delta)
    var was := inside
    inside = false
    if not done:
        for b in get_overlapping_bodies():
            if b.is_in_group("player"):
                inside = true
                break
    if inside and Input.is_action_just_pressed("deposit"):
        _try_deposit()
    if inside or was or flash > 0.0:
        queue_redraw()


func _try_deposit() -> void:
    var held: String = GameState.trash_types[GameState.sel]
    if int(GameState.stock[held]) <= 0:
        GameState.item_collected.emit(Loc.t("msg_nohold"))
        return
    var at := global_position + Vector2(0, -34)
    if held == type:
        have += 1
        GameState.deposit(type, 1)
        Sfx.play("deposit")
        GameState.burst.emit(at, GameState.trash_colors[type], 14)
        GameState.item_collected.emit(Loc.t("msg_bin", [GameState.trash_name(type), have, need]))
        if have >= need:
            done = true
            Sfx.play("bin_full")
            if sprite:
                sprite.modulate = Color(0.6, 1.0, 0.6)
            activated.emit()
    else:
        GameState.contaminate(held)
        flash = 0.5
        GameState.burst.emit(at, Color(0.85, 0.3, 0.25), 12)
        GameState.shake.emit(4.0, 0.2)
        GameState.item_collected.emit(Loc.t("msg_wrong", [GameState.trash_name(held), GameState.trash_name(type)]))
    queue_redraw()


func _draw_prompt() -> void:
    var held: String = GameState.trash_types[GameState.sel]
    var has := int(GameState.stock[held]) > 0
    var c := Vector2(0, -116.0 + sin(t * 5.0) * 3.0)
    draw_rect(Rect2(c + Vector2(-46, -20), Vector2(92, 40)), Color(0.15, 0.1, 0.07, 0.88))
    draw_rect(Rect2(c + Vector2(-46, -20), Vector2(92, 40)), Color(CREAM, 0.8), false, 2.0)
    draw_rect(Rect2(c + Vector2(-40, -13), Vector2(26, 26)), CREAM)
    draw_string(FontsS.BTN, c + Vector2(-40, 7), "E", HORIZONTAL_ALIGNMENT_CENTER, 26.0, 20, COCOA)
    if has:
        ArtS.trash(self, held, c + Vector2(16, 0), 0.9)
    else:
        draw_string(FontsS.BTN, c + Vector2(-8, 8), "?", HORIZONTAL_ALIGNMENT_CENTER, 48.0, 22, Color(CREAM, 0.7))


func _draw() -> void:
    draw_string(FontsS.BTN, Vector2(-40, -70), "%d/%d" % [have, need], HORIZONTAL_ALIGNMENT_CENTER, 80.0, 20, CREAM)
    if flash > 0.0:
        draw_rect(Rect2(-32, -64, 64, 64), Color(0.9, 0.2, 0.15, flash * 0.6))
    if inside and not done:
        _draw_prompt()
