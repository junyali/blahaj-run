extends Node

# enemies :3
@export var djungelskog_scene: PackedScene = preload("res://characters/enemies/Djungelskog.tscn")
@export var picoling_scene: PackedScene = preload("res://characters/enemies/Picoling.tscn")
@export var pider_scene: PackedScene = preload("res://characters/enemies/Pider.tscn")

# pickups
@export var meatball_scene: PackedScene = preload("res://objects/Meatballs.tscn")
@export var hotdog_scene: PackedScene = preload("res://objects/Hotdog.tscn")

@export var spawn_distance: float = 600.0
@export var arena_size: Vector2 = Vector2(1200, 800)

var djungelskog_timer: Timer
var picoling_timer: Timer
var pider_timer: Timer
var pickup_timer: Timer

var player: CharacterBody2D
var game_time: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	create_timers()
	setup_timers()
	start_spawning()
	
func _process(delta: float) -> void:
	game_time += delta
	
func create_timers() -> void:
	djungelskog_timer = Timer.new()
	picoling_timer = Timer.new()
	pider_timer = Timer.new()
	pickup_timer = Timer.new()
	
	add_child(djungelskog_timer)
	add_child(picoling_timer)
	add_child(pider_timer)
	add_child(pickup_timer)

func setup_timers() -> void:
	djungelskog_timer.wait_time = randf_range(20.0, 30.0)
	djungelskog_timer.timeout.connect(_on_djungelskog_timer_timeout)
	
	picoling_timer.wait_time = randf_range(25.0, 35.0)
	picoling_timer.timeout.connect(_on_picoling_timer_timeout)
	
	pider_timer.wait_time = randf_range(120.0, 180.0)
	pider_timer.timeout.connect(_on_pider_timer_timeout)
	
	pickup_timer.wait_time = randf_range(15.0, 25.0)
	pickup_timer.timeout.connect(_on_pickup_timer_timeout)

func start_spawning() -> void:
	djungelskog_timer.start()
	picoling_timer.start()
	pider_timer.start()
	pickup_timer.start()

func get_difficulty_multiplier() -> float:
	return min(1.0 + (game_time / 300.0), 3.0)

func get_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var angle = randf() * TAU
	var distance = spawn_distance + randf_range(0, 200)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	spawn_pos.x = clamp(spawn_pos.x, -arena_size.x/2, arena_size.x/2)
	spawn_pos.y = clamp(spawn_pos.y, -arena_size.y/2, arena_size.y/2)
	
	return spawn_pos

func _on_djungelskog_timer_timeout() -> void:
	spawn_djungelskog_group()
	
	var base_time = randf_range(20.0, 30.0)
	var difficulty = get_difficulty_multiplier()
	djungelskog_timer.wait_time = max(base_time / difficulty, 8.0)
	djungelskog_timer.start()

func spawn_djungelskog_group() -> void:
	var group_size = 1
	var spawn_together = false
	
	var rand = randf()
	if rand < 0.5:
		group_size = 1
	elif rand < 0.8:
		group_size = 2 
		spawn_together = randf() < 0.6
	else:
		group_size = 3
	
	var base_position = get_spawn_position()
	
	for i in group_size:
		var djungelskog = djungelskog_scene.instantiate()
		
		if spawn_together and group_size > 1:
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			djungelskog.global_position = base_position + offset
		else:
			djungelskog.global_position = get_spawn_position()
		
		get_parent().add_child(djungelskog)

func _on_picoling_timer_timeout() -> void:
	spawn_picoling_swarm()
	
	var base_time = randf_range(25.0, 35.0)
	var difficulty = get_difficulty_multiplier()
	picoling_timer.wait_time = max(base_time / difficulty, 12.0)
	picoling_timer.start()

func spawn_picoling_swarm() -> void:
	var swarm_size = randi_range(3, 7)
	var center_position = get_spawn_position()
	
	for i in swarm_size:
		var picoling = picoling_scene.instantiate()
		
		var angle = (i * TAU) / swarm_size + randf_range(-1.5, 1.5)
		var distance = randf_range(30, 80)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		picoling.global_position = center_position + offset
		get_parent().add_child(picoling)

func _on_pider_timer_timeout() -> void:
	spawn_pider()
	
	var base_time = randf_range(120.0, 180.0)
	var difficulty = get_difficulty_multiplier()
	pider_timer.wait_time = max(base_time / difficulty, 60.0)
	pider_timer.start()

func spawn_pider() -> void:
	var pider = pider_scene.instantiate()
	pider.global_position = get_spawn_position()
	get_parent().add_child(pider)

func _on_pickup_timer_timeout() -> void:
	spawn_random_pickup()
	
	pickup_timer.wait_time = randf_range(15.0, 25.0)
	pickup_timer.start()

func spawn_random_pickup() -> void:
	var pickup_scene = hotdog_scene if randf() < 0.7 else meatball_scene
	var pickup = pickup_scene.instantiate()
	
	var spawn_pos = Vector2(
		randf_range(-arena_size.x/2, arena_size.x/2),
		randf_range(-arena_size.y/2, arena_size.y/2)
	)
	
	pickup.global_position = spawn_pos
	get_parent().add_child(pickup)
