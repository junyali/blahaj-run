extends Area2D

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 1.0)
	tween.tween_property(self, "position:y", position.y + 5, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.heal(15)
		queue_free()
