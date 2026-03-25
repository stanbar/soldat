## Climb Timer - Manages timer, checkpoints, death tracking
extends Node

signal timer_started
signal timer_stopped(time: float)
signal checkpoint_hit(index: int)
signal death_counted(total: int)

var running: bool = false
var elapsed: float = 0.0
var death_count: int = 0
var checkpoints_hit := []
var best_time: float = INF


func _process(delta: float) -> void:
	if running:
		elapsed += delta


func start_timer() -> void:
	if not running:
		running = true
		elapsed = 0.0
		death_count = 0
		checkpoints_hit.clear()
		timer_started.emit()


func stop_timer() -> void:
	if running:
		running = false
		if elapsed < best_time:
			best_time = elapsed
		timer_stopped.emit(elapsed)


func hit_checkpoint(index: int) -> void:
	if index not in checkpoints_hit:
		checkpoints_hit.append(index)
		checkpoint_hit.emit(index)


func add_death() -> void:
	death_count += 1
	death_counted.emit(death_count)


func reset() -> void:
	running = false
	elapsed = 0.0
	death_count = 0
	checkpoints_hit.clear()


func get_time_string() -> String:
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	var millis := int((elapsed - int(elapsed)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]


func get_best_time_string() -> String:
	if best_time == INF:
		return "--:--.---"
	var minutes := int(best_time) / 60
	var seconds := int(best_time) % 60
	var millis := int((best_time - int(best_time)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]
