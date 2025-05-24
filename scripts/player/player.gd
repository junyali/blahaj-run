extends CharacterBody2D

## Scenes
@export var bullet_scene: PackedScene = preload("res://objects/bullet.tscn")

## Character Variables
@export var max_speed: float = 300.0
@export var acceleration: float = 500.0
@export var friction: float = 1500.0
@export var dash_force: float = 800.0
@export var dash_duration: float = 0.3
@export var dash_damage: int = 50
@export var dash_cooldown: float = 2.0

## Character Stats
@export var max_health: float = 100.0
@export var iframe_duration: float = 0.1
@export var shoot_cooldown: float = 0.3

## Node References
@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var camera: Camera2D = $Camera
@onready var health_bar: ProgressBar = $HealthBar
@onready var iframe_timer: Timer = $IframeTimer
@onready var shoot_timer: Timer = $ShootTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var dash_area: Area2D = $DashArea

var current_health: float = max_health
var is_invulnerable: bool = false
var can_shoot: bool = true
var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2

func _ready() -> void:
	add_to_group("player")
	setup_health()
	setup_vulnerability()
	setup_shooting()
	setup_dash()

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_shooting()
	handle_dash()
	move_and_slide()
	
func _process(delta: float) -> void:
	update_health_bar()

func handle_movement(delta: float) -> void:
	var h_dir: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var v_dir: float = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var input_dir: Vector2 = Vector2(h_dir, v_dir).normalized()
	
	# Allows diagonal movement T-T
	if input_dir != Vector2.ZERO:
		velocity = velocity.lerp(input_dir * max_speed, acceleration * delta / 100.0)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta / 100.0)
		
func handle_shooting() -> void:
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()
		
func handle_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()
		
func start_dash() -> void:
	is_dashing = true
	can_dash = false
	
	if velocity.length() > 0:
		dash_direction = velocity.normalized()
	else:
		dash_direction = (get_global_mouse_position() - global_position).normalized()
	
	velocity = dash_direction * dash_force	

	dash_area.set_collision_mask_value(1, true)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate", Color.CYAN, 0.1)
	tween.tween_property(sprite, "rotation", sprite.rotation + (PI * 4), dash_duration)
	
	dash_timer.start()
		
func shoot() -> void:
	if not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	bullet.global_position = global_position + shoot_direction * 32
	bullet.set_direction_and_rotation(shoot_direction)
	
	can_shoot = false
	shoot_timer.start()
		
func setup_health() -> void:
	current_health = max_health
	update_health_bar()
	
func setup_vulnerability() -> void:
	iframe_timer.wait_time = iframe_duration
	iframe_timer.one_shot = true
	
func setup_shooting() -> void:
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = true
	
func setup_dash() -> void:
	dash_timer.wait_time = dash_duration
	dash_timer.one_shot = true
	
	# Dash cooldown timer
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	
	dash_area.set_collision_mask_value(1, false)
	
func take_damage(damage: float) -> void:
	if is_invulnerable:
		return
		
	current_health -= damage
	current_health = max(current_health, 0)

	flash_sprite(Color.RED, 0.1)
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
		
func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func heal(amount: int) -> void:
	current_health += amount
	current_health = min(current_health, max_health)
	update_health_bar()
	
func die() -> void:
	var final_stats = GameManager.calculate_final_score()
	print("Game Over!")
	print("Final Score: ", final_stats.total_score)
	print("Enemies Killed: ", final_stats.enemies_killed)
	print("Time Survived: ", GameManager.format_time(final_stats.survival_time))
	pass # death logic goes here X_X

func _on_iframe_timer_timeout() -> void:
	is_invulnerable = false
	sprite.modulate = Color.WHITE

func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	dash_area.set_collision_mask_value(1, false)
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	dash_cooldown_timer.start()

func _on_dash_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self and not body.is_in_group("player") and body.is_in_group("enemies"):
		body.take_damage(dash_damage)
		if body.has_method("apply_knockback"):
			body.apply_knockback(dash_direction * 300)

func _on_dash_area_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(dash_damage)
