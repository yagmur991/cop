extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$HUD/Label.text = "Score: " + str(Global.score)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Char":
		Global.score = max(0, Global.score - 1) # Subtracts 1 point from the total score
		get_tree().call_deferred("reload_current_scene")
