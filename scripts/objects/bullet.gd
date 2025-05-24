extends Area2D

@export var speed: float = 500.0
@export var damage: int = 25
@export var lifetime: float = 3.0

var direction: Vector2

func _ready() -> void:
	print("Bullet created at position: ", global_position)
	get_tree().create_timer(lifetime).timeout.connect(_on_timeout)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

func _on_timeout() -> void:
	queue_free()

func set_direction_and_rotation(target_direction: Vector2) -> void:
	direction = target_direction
	rotation = direction.angle()
