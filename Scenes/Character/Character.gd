extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var attack_hit_box: Area2D = $AttackHitBox


enum STATE {
	IDLE,
	MOVE,
	ATTACK,
}

var dir_dict : Dictionary = {
	"Left": Vector2.LEFT,
	"Right": Vector2.RIGHT,
	"Up": Vector2.UP,
	"Down": Vector2.DOWN,
}
var speed = 300.0

var state : int = STATE.IDLE :
	get = get_state,
	set = set_state 

var moving_direction := Vector2.ZERO :
	get = get_moving_direction,
	set = set_moving_direction

var facing_direction := Vector2.DOWN :
	get = get_facing_direction,
	set = set_facing_direction

signal state_changed
signal facing_direction_changed
signal moving_direction_changed

#### ACCESSORS ####

func set_state(value : int) -> void:
	if value != state:
		state = value
		emit_signal("state_changed")

func get_state() -> int:
	return state

func set_facing_direction(value: Vector2) ->void:
	if facing_direction != value:
		facing_direction = value
		emit_signal("facing_direction_changed")

func get_facing_direction() -> Vector2:
	return facing_direction

func set_moving_direction(value: Vector2) -> void:
	if value != moving_direction:
		moving_direction = value
		emit_signal("moving_direction_changed")

func get_moving_direction() -> Vector2:
	return moving_direction

#### BUILT-IN ####

func _process(_delta: float) -> void:
	velocity = moving_direction * speed
	_update_animation()
	move_and_slide()

func _input(_event: InputEvent) -> void:
	var dir = Vector2(
		int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
		int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		)
	
	set_moving_direction(dir.normalized())
	
	if Input.is_action_just_pressed("ui_accept"):
		set_state(STATE.ATTACK)
	
	if state != STATE.ATTACK:
		# Idle animation
		if moving_direction == Vector2.ZERO:
			set_state(STATE.IDLE)
		# Move Animation
		else:
			set_state(STATE.MOVE)

#### LOGIC ####

func _update_animation() -> void:
	var dir_name = _find_dir_name(facing_direction)
	var state_name = ""
	
	match(state):
		STATE.IDLE: state_name = "Idle"
		STATE.ATTACK: state_name = "Attack"
		STATE.MOVE: state_name = "Move"
	
	animated_sprite.play(state_name + dir_name)

func _update_attack_hitbox_direction() -> void:
	var angle = facing_direction.angle()
	attack_hit_box.set_rotation_degrees(rad_to_deg(angle) - 90)

func _find_dir_name(dir: Vector2) -> String:
	var dir_values_array = dir_dict.values()
	var dir_index = dir_values_array.find(dir)
	if dir_index == -1:
		return ""
	var dir_keys_array = dir_dict.keys()
	var dir_key = dir_keys_array[dir_index]
	
	return dir_key

#### SIGNAL RESPONSES ####

func _on_animated_sprite_animation_finished() -> void:
	if "Attack".is_subsequence_of(animated_sprite.animation):
		_update_animation()

func _on_state_changed() -> void:
	_update_animation()

func _on_facing_direction_changed() -> void:
	_update_animation()
	_update_attack_hitbox_direction()

func _on_moving_direction_changed() -> void:
	if moving_direction == Vector2.ZERO or moving_direction == facing_direction:
		return
	
	var sign_dir = Vector2(sign(moving_direction.x), sign(moving_direction.y))
	
	if sign_dir == moving_direction:
		set_facing_direction(moving_direction)
	else:
		if sign_dir.x == facing_direction.x:
			set_facing_direction(Vector2(0, sign_dir.y))
		else:
			set_facing_direction(Vector2(sign_dir.x, 0))
