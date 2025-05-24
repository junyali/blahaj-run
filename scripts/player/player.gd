extends CharacterBody2D

## Character Variables
@export var max_speed: float = 300.0
@export var acceleration: float = 500.0
@export var friction: float = 1500.0

## Character Stats
@export var max_health: float = 100.0
@export var iframe_duration: float = 1.0

var current_health: float = max_health

## Node References
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $Collision
@onready var camera: Camera2D = $Camera
@onready var health_bar: ProgressBar = $HealthBar
@onready var iframe_timer: Timer = $IframeTimer

var is_invulnerable: bool = true

func _ready() -> void:
	setup_health()
	setup_vulnerability()

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	move_and_slide()
	
func _process(delta: float) -> void:
	update_health_bar()

func handle_movement(delta: float) -> void:
	var h_dir: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var v_dir: float = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var input_dir: Vector2 = Vector2(h_dir, v_dir).normalized()
	
	# Allows diagonal movement T-T
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
func setup_health() -> void:
	current_health = max_health
	update_health_bar()
	
func setup_vulnerability() -> void:
	iframe_timer.wait_time = iframe_duration
	iframe_timer.one_shot = true
	
func take_damage(damage: float) -> void:
	if is_invulnerable:
		return
		
	current_health -= damage
	current_health = max(current_health, 0)

	flash_sprite(Color.RED)
	update_health_bar()
	
	start_invulnerability()
	
	if current_health <= 0:
		die()
	
func flash_sprite(colour: Color, duration: float = 1.0) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", colour, duration)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	
func start_invulnerability() -> void:
	is_invulnerable = true
	iframe_timer.start()

func update_health_bar() -> void:
	if health_bar:
		var health_percentage: float = float(current_health) / float(max_health)
		health_bar.value = health_percentage * 100
		

func heal(amount: int) -> void:
	current_health += amount
	current_health = min(current_health, max_health)
	update_health_bar()
	
func die() -> void:
	pass # death logic goes here X_X

func _on_iframe_timer_timeout() -> void:
	is_invulnerable = false
	sprite.modulate = Color.WHITE
