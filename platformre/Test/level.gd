extends Node2D

@onready var player := $Player
@onready var player_spawn := $"Player Spawn"
@onready var finish := $Finish
@onready var camera := $Camera2D

var screen_top_corner := Vector2.ZERO
var screen_size := Vector2(320, 180)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.global_position = player_spawn.global_position
	finish.connect("level_finished", level_end)
	SignalBus.reset.connect(level_reset)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var bounds = Rect2(screen_top_corner, screen_size)
	if not bounds.has_point(player.position):
		screen_top_corner = Vector2(floor(player.position.x / screen_size.x) * screen_size.x, floor(player.position.y / screen_size.y) * screen_size.y)
		print("aiudsfhsakjfksjadnfkjasdnfkjadsf", screen_top_corner)
		var tween = create_tween()
		tween.tween_property(camera, "position", screen_top_corner, 0.4).set_trans(Tween.TRANS_SINE)
func level_end():
	pass

func level_reset():
	player.global_position = player_spawn.global_position
	player.velocity = Vector2.ZERO
