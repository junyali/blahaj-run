extends CharacterBody2D

## Enemy Stats
@export var max_health: float = 30.0
@export var speed: float = 160.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 0.25

## Node References
@onready var sprite: Sprite2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar

var current_health: float
var player: CharacterBody2D
var can_attack: bool = true

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	
	player = get_tree().get_first_node_in_group("player")
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
		
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	move_and_slide()
	
	if can_attack and global_position.distance_to(player.global_position) <= attack_range:
		attack_player()

func _process(delta: float) -> void:
	update_healthbar()

func update_healthbar() -> void:
	if health_bar:
		var health_percentage: float = current_health / max_health
		health_bar.value = health_percentage * 100

		health_bar.visible = health_percentage < 1.0

func attack_player() -> void:
	if not player or not can_attack:
		return
	
	can_attack = false
	
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.ORANGE, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_attack:
		attack_player()

func take_damage(damage: float) -> void:
	current_health -= damage
	current_health = max(current_health, 0)
	
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)
	
	if current_health <= 0:
		die()

func apply_knockback(force: Vector2) -> void:
	velocity += force * 1.5

func die() -> void:
	GameManager.add_enemy_kill("picoling")
	queue_free()
