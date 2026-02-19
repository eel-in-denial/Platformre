extends Area2D
class_name Orange

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collectible = self
		for i in range(15):
			body.past_positions[i] = position
		set_deferred("monitoring", false)
			
func move_to_player(player_pos):
	position = position.lerp(player_pos, 0.1)
	if position.distance_to(player_pos) < 1:
		queue_free()
