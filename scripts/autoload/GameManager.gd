extends Node

var current_score: int = 0
var enemies_killed: int = 0
var survival_time: float = 0.0
var game_start_time: float = 0.0

var enemy_scores: Dictionary = {
	"djungelskog": 50,
	"picoling": 10
}

var time_score_multiplier: float = 5.0

signal score_changed(new_score: int)
signal enemy_killed(enemy_type: String, total_kills: int)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game() -> void:
	current_score = 0
	enemies_killed = 0
	survival_time = 0.0
	game_start_time = Time.get_ticks_msec() / 1000.0
	score_changed.emit(current_score)

func add_enemy_kill(enemy_type: String) -> void:
	enemies_killed += 1
	
	var points = enemy_scores.get(enemy_type, 25)
	current_score += points
	
	score_changed.emit(current_score)
	enemy_killed.emit(enemy_type, enemies_killed)

func update_survival_time() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	survival_time = current_time - game_start_time
	
	var time_score = int(survival_time * time_score_multiplier)

func calculate_final_score() -> Dictionary:
	update_survival_time()
	
	var time_bonus: int = int(survival_time * time_score_multiplier)
	var total_score: int = current_score + time_bonus
	
	return {
		"total_score": total_score,
		"enemy_score": current_score,
		"time_bonus": time_bonus,
		"enemies_killed": enemies_killed,
		"survival_time": survival_time
	}

func format_time(time_seconds: float) -> String:
	var minutes: int = int(time_seconds) / 60
	var seconds: int = int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]
