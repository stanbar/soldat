## Ghost Replay - Records and plays back player position each physics frame
extends Node2D

var recording: bool = false
var playing: bool = false
var frames: PackedVector2Array = PackedVector2Array()
var playback_index: int = 0
var ghost_color := Color(0.3, 0.8, 1.0, 0.3)

# Best run ghost
var best_frames: PackedVector2Array = PackedVector2Array()
var best_time: float = INF


func start_recording() -> void:
	recording = true
	playing = false
	frames.clear()
	playback_index = 0


func record_frame(pos: Vector2) -> void:
	if recording:
		frames.append(pos)


func stop_recording(time: float) -> void:
	recording = false
	if time < best_time and frames.size() > 0:
		best_time = time
		best_frames = frames.duplicate()


func start_playback() -> void:
	if best_frames.size() == 0:
		return
	playing = true
	playback_index = 0


func stop_playback() -> void:
	playing = false
	playback_index = 0


func _physics_process(_delta: float) -> void:
	if playing and best_frames.size() > 0:
		if playback_index < best_frames.size():
			position = best_frames[playback_index]
			playback_index += 1
			queue_redraw()
		else:
			stop_playback()


func _draw() -> void:
	if playing:
		# Draw ghost as semi-transparent rectangle
		draw_rect(Rect2(-4, -12, 8, 18), ghost_color)
