## Main Game Scene - Orchestrates the Climb game
extends Node2D

const MC = MovementConstants

@onready var player: Node2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var timer_label: Label = $HUD/TimerLabel
@onready var death_label: Label = $HUD/DeathLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var map_name_label: Label = $HUD/MapNameLabel
@onready var restart_button: Button = $HUD/RestartButton

var touch_controls: Node  # TouchControls instance
var climb_timer: Node  # ClimbTimer instance
var ghost: Node2D  # GhostReplay instance

var poly_map: PolyMap
var current_map_data: Dictionary = {}
var checkpoint_zones: Array[Rect2] = []
var finish_zone: Rect2 = Rect2()
var start_triggered: bool = false

# Polygon colors for rendering
var poly_colors := {
	MC.POLY_TYPE_NORMAL: Color(0.35, 0.30, 0.25),
	MC.POLY_TYPE_ICE: Color(0.6, 0.85, 0.95),
	MC.POLY_TYPE_BOUNCY: Color(0.2, 0.7, 0.3),
	MC.POLY_TYPE_DEADLY: Color(0.8, 0.15, 0.1),
	MC.POLY_TYPE_BLOODY_DEADLY: Color(0.7, 0.1, 0.05),
	MC.POLY_TYPE_LAVA: Color(0.9, 0.3, 0.05),
	MC.POLY_TYPE_HURTS: Color(0.7, 0.5, 0.2),
}


func _ready() -> void:
	# Create subsystems
	climb_timer = preload("res://scripts/climb_timer.gd").new()
	add_child(climb_timer)

	ghost = preload("res://scripts/ghost_replay.gd").new()
	add_child(ghost)

	# Connect signals
	player.died.connect(_on_player_died)
	restart_button.pressed.connect(_on_restart)

	# Load default map
	load_map(MapData.create_jump_course())


func _physics_process(_delta: float) -> void:
	# Update camera to follow player
	camera.position = player.position

	# Update HUD
	timer_label.text = climb_timer.get_time_string()
	death_label.text = "Deaths: %d" % climb_timer.death_count
	best_label.text = "Best: %s" % climb_timer.get_best_time_string()

	# Record ghost
	if climb_timer.running:
		ghost.record_frame(player.position)

	# Check zones
	_check_zones()

	# Pass aim_x from screen to world space for player
	# On desktop: mouse position
	var mouse_screen := get_viewport().get_mouse_position()
	var mouse_world := camera.position + (mouse_screen - get_viewport_rect().size / 2)
	player.aim_x = mouse_world.x

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Keyboard controls (desktop testing)
	if event is InputEventKey or event is InputEventMouseButton:
		player.control_left = Input.is_action_pressed("move_left")
		player.control_right = Input.is_action_pressed("move_right")
		player.control_up = Input.is_action_pressed("jump")
		player.control_down = Input.is_action_pressed("crouch")


func load_map(map_data: Dictionary) -> void:
	current_map_data = map_data
	poly_map = PolyMap.new()

	# Load polygons
	for p in map_data.polygons:
		poly_map.add_polygon(p.v1, p.v2, p.v3, p.type, p.bounciness)
	poly_map.finalize()

	# Set player's map reference
	player.map = poly_map

	# Set spawn, checkpoints, finish
	player.position = map_data.spawn
	player.last_checkpoint = map_data.spawn
	player.physics.pos[player.particle_idx] = map_data.spawn
	player.physics.old_pos[player.particle_idx] = map_data.spawn

	checkpoint_zones.clear()
	for cp in map_data.get("checkpoints", []):
		checkpoint_zones.append(cp)

	finish_zone = map_data.get("finish", Rect2())

	# Reset timer
	climb_timer.reset()
	start_triggered = false
	ghost.stop_playback()
	ghost.stop_recording() if ghost.recording else null

	map_name_label.text = map_data.get("name", "Unknown Map")

	queue_redraw()


func _check_zones() -> void:
	var ppos := player.position

	# Start timer on first movement
	if not start_triggered and not climb_timer.running:
		if player.control_left or player.control_right or player.control_up:
			start_triggered = true
			climb_timer.start_timer()
			ghost.start_recording()

	# Checkpoints
	for i in checkpoint_zones.size():
		if checkpoint_zones[i].has_point(ppos):
			player.set_checkpoint(ppos)
			climb_timer.hit_checkpoint(i)

	# Finish
	if finish_zone.has_point(ppos) and climb_timer.running:
		climb_timer.stop_timer()
		ghost.stop_recording(climb_timer.elapsed)

		# Start ghost playback for next attempt
		ghost.start_playback()

	# Out of bounds death
	if ppos.y > 500 or ppos.y < -1500 or ppos.x < -600 or ppos.x > 2500:
		player._die()


func _on_player_died() -> void:
	climb_timer.add_death()


func _on_restart() -> void:
	player._respawn()
	climb_timer.reset()
	start_triggered = false
	ghost.stop_recording(INF) if ghost.recording else null
	ghost.start_playback()
	player.position = current_map_data.spawn
	player.physics.pos[player.particle_idx] = current_map_data.spawn
	player.physics.old_pos[player.particle_idx] = current_map_data.spawn
	player.last_checkpoint = current_map_data.spawn


func _draw() -> void:
	# Draw all map polygons
	if poly_map:
		for poly in poly_map.polygons:
			var color: Color = poly_colors.get(poly.poly_type, Color(0.4, 0.35, 0.3))
			var points := PackedVector2Array(poly.vertices)
			var colors := PackedColorArray([color, color, color])
			draw_polygon(points, colors)

	# Draw checkpoint zones
	for i in checkpoint_zones.size():
		var cp := checkpoint_zones[i]
		var hit := i in climb_timer.checkpoints_hit
		var color := Color(0, 1, 0, 0.3) if hit else Color(1, 1, 0, 0.2)
		draw_rect(cp, color)

	# Draw finish zone
	if finish_zone.size != Vector2.ZERO:
		draw_rect(finish_zone, Color(1, 0.8, 0, 0.3))
		# Draw "FINISH" text would go here with a font
