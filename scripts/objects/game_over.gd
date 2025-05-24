extends Control

@onready var background: ColorRect = $ColorRect
@onready var skull_icon: TextureRect = $Container/Skull
@onready var game_over_label: Label = $Container/GameOverLabel
@onready var score_label: Label = $Container/Score

func _ready() -> void:
	visible = false

	setup_styling()

func setup_styling() -> void:
	background.color = Color(0.35, 0.35, 0.35, 0.8)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var container = $Container

	game_over_label.text = "GAME OVER"

func show_game_over() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	var final_score = GameManager.calculate_final_score()
	score_label.text = "Final Score: " + str(final_score.total_score)
	
	visible = true

	modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
func _input(event: InputEvent) -> void:
	if visible and event.is_pressed():
		restart_game()

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	
