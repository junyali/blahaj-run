extends Area2D

@export var speed: float = 200.0
@export var lifetime: float = 5.0

var direction: Vector2
var damage: float

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func set_direction_and_damage(new_direction: Vector2, new_damage: float) -> void:
	direction = new_direction
	damage = new_damage
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
