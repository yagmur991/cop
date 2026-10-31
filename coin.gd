extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Char":
		Global.score += 1
		print("Score: ", Global.score) # This displays your score in the debugger panel at the bottom!# (Optional) Add to a global score counter here
		queue_free() # Deletes the coin from the map
