extends CharacterBody2D

## Enemy Stats
@export var max_health: float = 300.0
@export var speed: float = 60.0
@export var melee_damage: float = 40.0
@export var ranged_damage: float = 30.0
@export var melee_range: float = 60.0
@export var shooting_range: float = 400.0
@export var melee_cooldown: float = 2.0
@export var shoot_cooldown: float = 1.5

## Scenes
@export var bulletkey_scene: PackedScene = preload("res://objects/bulletkey.tscn")

## Node References
@onready var sprite: Sprite2D = $Sprite
@onready var melee_area: Area2D = $AttackArea
@onready var shoot_timer: Timer = $ShootTimer
@onready var melee_timer: Timer = $MeleeTimer
@onready var health_bar: ProgressBar = $HealthBar

var current_health: float
var player: CharacterBody2D
var can_shoot: bool = true
var can_melee: bool = true

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	
	player = get_tree().get_first_node_in_group("player")
	
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = true
	
	melee_timer.wait_time = melee_cooldown
	melee_timer.one_shot = true
	
	update_healthbar()

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction_to_player = (player.global_position - global_position).normalized()
	
	if distance_to_player > shooting_range:
		velocity = direction_to_player * speed
	elif distance_to_player < melee_range * 1.5:
		velocity = -direction_to_player * (speed * 0.5)
	else:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
	
	move_and_slide()
	
	if direction_to_player.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	if distance_to_player <= melee_range and can_melee:
		melee_attack()
	elif distance_to_player <= shooting_range and can_shoot:
		ranged_attack()

func melee_attack() -> void:
	if not can_melee:
		return
	
	can_melee = false
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)
	
	if player and player.has_method("take_damage"):
		player.take_damage(melee_damage)
	
	melee_timer.start()

func ranged_attack() -> void:
	if not can_shoot or not bulletkey_scene:
		return
	
	can_shoot = false
	
	var bulletkey = bulletkey_scene.instantiate()
	get_parent().add_child(bulletkey)
	
	bulletkey.global_position = global_position
	var shoot_direction = (player.global_position - global_position).normalized()
	bulletkey.set_direction_and_damage(shoot_direction, ranged_damage)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_melee_timer_timeout() -> void:
	can_melee = true

func update_healthbar() -> void:
	if health_bar:
		var health_percentage = current_health / max_health
		health_bar.value = health_percentage * 100
		health_bar.visible = health_percentage < 1.0

func take_damage(damage: float) -> void:
	current_health -= damage
	current_health = max(current_health, 0)
	
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	update_healthbar()
	
	if current_health <= 0:
		die()

func apply_knockback(force: Vector2) -> void:
	velocity += force * 0.5

func die() -> void:
	GameManager.add_enemy_kill("pider")
	queue_free()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_melee:
		melee_attack()
