extends CharacterBody2D
class_name Player

@onready var left_ray := $LeftRay
@onready var right_ray := $RightRay
@onready var anim_player := $AnimationPlayer

const MAX_SPEED := 90.0
const RUN_ACCEL := 1000.0
const RUN_REDUCE := 400.0
const AIR_MULT := 0.65
const JUMP_VELOCITY := -105.0
const JUMP_H_BOOST := 40.0
const JUMP_TIMER := 0.2
const DASH_SPEED := 240.0
const END_DASH_SPEED := 160.0
const DASH_TIMER := .15
const DASH_COOLDOWN := .2
const MAX_STAMINA := 110.0
const CLIMB_STILL_COST := 10.0
const CLIMB_UP_COST := 100.0/2.2
const CLIMB_JUMP_COST := 27.5
const CLIMB_UP_SPEED := -45.0
const CLIMB_DOWN_SPEED := 80.0
const CLIMB_SLIP_SPEED := 30.0
const CLIMB_ACCEL := 900.0
const CLIMB_HOP := Vector2(100.0, -120.0)


const MAX_FALL := 160.0
const GRAVITY := 900.0
const HALF_GRAV_THRESH := 40.0


var jump_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var is_wall_climbing := false

var max_dashes: int = 1
var dashes: int = 1

var stamina := 110.0
var facing: float

var past_positions: Array[Vector2]
var collectible: Node2D

func _ready() -> void:
	past_positions.resize(15)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction.x:
		facing = direction.x
		print(facing)
	if not dash_timer and not is_wall_climbing:
		var move_x: int = sign(direction.x)
		var mult := 1.0 if is_on_floor() else AIR_MULT
		if abs(velocity.x) > MAX_SPEED and sign(velocity.x) == move_x:
			velocity.x = move_toward(velocity.x, move_x * MAX_SPEED, RUN_REDUCE * delta * mult)
		else:
			velocity.x = move_toward(velocity.x, move_x * MAX_SPEED, RUN_ACCEL * delta * mult)
		if is_on_floor() and direction.x:
			if facing > 0:
				anim_player.play("run_right")
			else:
				anim_player.play("run_left")
		elif is_on_floor():
			if facing > 0:
				anim_player.play("idle_right")
			else:
				anim_player.play("idle_left")
	var grav_mult = 0.5 if abs(velocity.y)  < HALF_GRAV_THRESH else 1.0
	# Add the gravity.
	if jump_timer:
		jump_timer -= delta
		velocity.y = JUMP_VELOCITY
		if jump_timer <= 0:
			jump_timer = 0.0
	if dash_timer:
		dash_timer -= delta
		if dash_timer <= 0:
			dash_timer = 0.0
			velocity.x = END_DASH_SPEED * direction.x
			if velocity.y < 0:
				velocity.y = END_DASH_SPEED * 0.75 * direction.y
	if is_wall_climbing:
		if direction.y < 0:
			velocity.y = move_toward(velocity.y, CLIMB_UP_SPEED, CLIMB_ACCEL * delta)
			stamina -= CLIMB_UP_COST * delta
		elif direction.y > 0:
			velocity.y = move_toward(velocity.y, CLIMB_DOWN_SPEED, CLIMB_ACCEL * delta)
		elif direction.y == 0:
			stamina -= CLIMB_STILL_COST * delta
			velocity.y = 0
		if stamina < 0 or not Input.is_action_pressed("grab") or not (left_ray.is_colliding() or right_ray.is_colliding()):
			print(Input.is_action_pressed("grab"))
			is_wall_climbing = false
		
	if not is_on_floor() and not jump_timer and not dash_timer and not is_wall_climbing:
		velocity.y = move_toward(velocity.y, MAX_FALL, GRAVITY * delta * grav_mult)
	elif is_on_floor() and not is_wall_climbing:
		dashes = max_dashes
		stamina = MAX_STAMINA
		
		
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and not is_wall_climbing:
			velocity.y = JUMP_VELOCITY
			jump_timer = JUMP_TIMER - delta
			if facing > 0:
				anim_player.play("jump_right")
			else:
				anim_player.play("jump_left")
		elif is_wall_climbing:
			velocity.y = CLIMB_HOP.y
			velocity.x = CLIMB_HOP.x * direction.x
			velocity.x *= 1 if left_ray.is_colliding() else -1
			jump_timer = JUMP_TIMER - delta
			is_wall_climbing = false
			if facing > 0:
				anim_player.play("jump_right")
			else:
				anim_player.play("jump_left")
	elif Input.is_action_just_pressed("dash") and dashes and not dash_cooldown:
		dashes -= 1
		dash_timer = DASH_TIMER
		get_tree().paused = true
		await get_tree().create_timer(0.05, true, false, true).timeout
		get_tree().paused = false
		if facing > 0:
			anim_player.play("dash_right")
		else:
			anim_player.play("dash_left")
		direction = Input.get_vector("left", "right", "up", "down")
		velocity = DASH_SPEED * direction
	elif Input.is_action_pressed("grab") and (left_ray.is_colliding() or right_ray.is_colliding()) and not is_wall_climbing and not jump_timer:
		is_wall_climbing = true
		if left_ray.is_colliding():
			position.x -= 1
		else:
			position.x += 1
		velocity = Vector2.ZERO
		if facing > 0:
			anim_player.play("climb_right")
		else:
			anim_player.play("climb_left")
	move_and_slide()
	
	# object carrying
	
	if collectible:
		if velocity:
			collectible.position = past_positions[0]
			past_positions.append(position)
			past_positions.pop_front()
		if is_on_floor():
			collectible.move_to_player(position)
