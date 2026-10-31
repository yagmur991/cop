extends Area2D
# Geri dönüşüm kutusu: oyuncu taşıdığı çöpü içine girerek teslim eder.
# Dolunca "activated" sinyali gider, boss kapısının kilidi bir adım açılır.

signal activated

var need := 2
var have := 0
var done := false
var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(56, 50)
	cs.shape = r
	cs.position = Vector2(0, -25)
	add_child(cs)
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/PlasticRecycleBin-Sheet.png")
	sprite.scale = Vector2(0.4, 0.4)       # 128x160 -> ~51x64
	sprite.position = Vector2(0, -32)      # origin is bottom-middle
	add_child(sprite)


func _physics_process(_delta: float) -> void:
	if done or GameState.trash_stock <= 0:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			var n := mini(GameState.trash_stock, need - have)
			if n > 0:
				have += n
				GameState.deposit(n)
				queue_redraw()
				GameState.item_collected.emit("Geri dönüştürüldü! %d/%d (kirlilik düştü)" % [have, need])
				if have >= need:
					done = true
					sprite.modulate = Color(0.6, 1.0, 0.6)
					activated.emit()
			break


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-14, -70), "%d/%d" % [have, need], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(f, Vector2(-42, -88), "GERİ DÖNÜŞÜM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
