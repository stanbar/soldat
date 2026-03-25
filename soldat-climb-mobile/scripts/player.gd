## Player - Port of Soldat's Control.pas movement state machine + Sprites.pas ground detection
## This is the core of the Soldat movement feel.
extends Node2D


# Animation state IDs (simplified from Soldat's full animation system)
enum Anim {
	STAND, RUN, RUN_BACK, JUMP, JUMP_SIDE, FALL,
	CROUCH, CROUCH_RUN, CROUCH_RUN_BACK,
	ROLL, ROLL_BACK,  # Roll = forward roll, RollBack = backflip
	GET_UP,
}

# Animation frame counts (from Soldat's animation data)
# Can't use enum keys in const dict, so use static var
static var ANIM_FRAMES := {
	Anim.STAND: 1,
	Anim.RUN: 32,
	Anim.RUN_BACK: 32,
	Anim.JUMP: 14,
	Anim.JUMP_SIDE: 11,
	Anim.FALL: 1,
	Anim.CROUCH: 15,
	Anim.CROUCH_RUN: 15,
	Anim.CROUCH_RUN_BACK: 15,
	Anim.ROLL: 14,
	Anim.ROLL_BACK: 14,
	Anim.GET_UP: 24,
}

# Verlet physics for the player particle
var physics: VerletPhysics
var particle_idx: int = 0  # index in physics system

# State
var direction: int = 1  # 1 = facing right, -1 = facing left
var on_ground: bool = false
var on_ground_last_frame: bool = false
var on_ground_permanent: bool = false

# Animation state
var legs_anim: Anim = Anim.STAND
var legs_frame: int = 1
var legs_num_frames: int = 1
var body_anim: Anim = Anim.STAND

# Input state
var control_left: bool = false
var control_right: bool = false
var control_up: bool = false
var control_down: bool = false
var aim_x: float = 0.0  # world-space aim X position (from mouse or touch)

# Map reference
var map: PolyMap

# Climb mode
var is_dead: bool = false
var death_count: int = 0
var last_checkpoint: Vector2 = Vector2.ZERO

signal died
signal checkpoint_reached(pos: Vector2)
signal finished(time: float)


func _ready() -> void:
	physics = VerletPhysics.new()
	physics.gravity = MovementConstants.PLAYER_GRAVITY
	physics.v_damping = MovementConstants.V_DAMPING
	physics.time_step = MovementConstants.PHYSICS_TIMESTEP
	physics.create_part(position, Vector2.ZERO, 1.0, particle_idx)
	last_checkpoint = position


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	# Update direction from aim (port of Sprites.pas line 553-556)
	if aim_x >= physics.pos[particle_idx].x:
		direction = 1
	else:
		direction = -1

	# Run the movement state machine (port of Control.pas)
	_process_movement()

	# Verlet physics step
	physics.do_verlet_timestep()

	# Clamp velocity (port of Sprites.pas MAX_VELOCITY)
	var vel: Vector2 = physics.velocity[particle_idx]
	if vel.length() > MovementConstants.MAX_VELOCITY:
		vel = vel.normalized() * MovementConstants.MAX_VELOCITY
		physics.pos[particle_idx] = physics.old_pos[particle_idx] + vel

	# Ground detection (port of Sprites.pas lines 856-876)
	_check_ground()

	# Update position for rendering
	position = physics.pos[particle_idx]

	# Update animation frame
	_advance_animation()

	queue_redraw()


func _draw() -> void:
	# Simple gostek representation - colored rectangle + direction indicator
	var color := Color.CORNFLOWER_BLUE
	if legs_anim == Anim.CROUCH or legs_anim == Anim.CROUCH_RUN or legs_anim == Anim.CROUCH_RUN_BACK:
		draw_rect(Rect2(-5, -6, 10, 12), color)
	elif legs_anim == Anim.ROLL or legs_anim == Anim.ROLL_BACK:
		draw_circle(Vector2.ZERO, 6, color)
	else:
		draw_rect(Rect2(-4, -12, 8, 18), color)

	# Direction indicator (eyes)
	var eye_x := 2.0 * direction
	draw_circle(Vector2(eye_x, -8), 1.5, Color.WHITE)

	# Ground indicator
	if on_ground:
		draw_circle(Vector2(0, 8), 1, Color.GREEN)


## Port of Control.pas lines 1590-1984 — the full movement state machine
func _process_movement() -> void:
	var num := particle_idx

	# Active roll/backflip handling (highest priority, from lines 1590-1620)
	if body_anim == Anim.ROLL or body_anim == Anim.ROLL_BACK:
		if legs_anim == Anim.ROLL:
			if on_ground:
				physics.forces[num].x = direction * MovementConstants.ROLLSPEED
			else:
				physics.forces[num].x = direction * 2 * MovementConstants.FLYSPEED
		elif legs_anim == Anim.ROLL_BACK:
			if on_ground:
				physics.forces[num].x = -direction * MovementConstants.ROLLSPEED
			else:
				physics.forces[num].x = -direction * 2 * MovementConstants.FLYSPEED

			# Backflip jump boost (lines 1608-1618) — THE core Climb trick
			if legs_frame > MovementConstants.BACKFLIP_BOOST_START_FRAME and \
					legs_frame < MovementConstants.BACKFLIP_BOOST_END_FRAME:
				if control_up:
					physics.forces[num].y -= MovementConstants.BACKFLIP_JUMP_BOOST
					physics.forces[num].x *= MovementConstants.BACKFLIP_X_DAMPEN
					physics.velocity[num].x *= MovementConstants.BACKFLIP_VEL_X_DAMPEN

		# Handle roll/backflip completion (lines 2028-2075)
		if legs_frame >= _get_num_frames(legs_anim):
			if on_ground:
				if control_down:
					if control_left or control_right:
						if body_anim == Anim.ROLL:
							_set_legs_anim(Anim.CROUCH_RUN)
						else:
							_set_legs_anim(Anim.CROUCH_RUN_BACK)
					else:
						_set_legs_anim(Anim.CROUCH)
			elif body_anim == Anim.ROLL_BACK and control_up:
				if control_left or control_right:
					if (direction == 1) != control_left:
						_set_legs_anim(Anim.RUN)
					else:
						_set_legs_anim(Anim.RUN_BACK)
				else:
					_set_legs_anim(Anim.FALL)
			elif control_down:
				if control_left or control_right:
					if body_anim == Anim.ROLL:
						_set_legs_anim(Anim.CROUCH_RUN)
					else:
						_set_legs_anim(Anim.CROUCH_RUN_BACK)
				else:
					_set_legs_anim(Anim.CROUCH)
			body_anim = Anim.STAND
		return  # Roll/backflip takes priority over other movement

	# Down+Right: roll or crouch-run (lines 1622-1676)
	if control_right and control_down:
		if on_ground:
			if legs_anim == Anim.RUN or legs_anim == Anim.RUN_BACK or legs_anim == Anim.FALL:
				# Direction determines Roll vs RollBack
				if direction == 1:
					_set_anim(Anim.ROLL)
				else:
					_set_anim(Anim.ROLL_BACK)
			else:
				if direction == 1:
					_set_legs_anim(Anim.CROUCH_RUN)
				else:
					_set_legs_anim(Anim.CROUCH_RUN_BACK)

			if legs_anim == Anim.CROUCH_RUN or legs_anim == Anim.CROUCH_RUN_BACK:
				physics.forces[num].x = MovementConstants.CROUCHRUNSPEED
			elif legs_anim == Anim.ROLL or legs_anim == Anim.ROLL_BACK:
				physics.forces[num].x = 2 * MovementConstants.CROUCHRUNSPEED

	# Down+Left: roll or crouch-run (lines 1678-1730)
	elif control_left and control_down:
		if on_ground:
			if legs_anim == Anim.RUN or legs_anim == Anim.RUN_BACK or legs_anim == Anim.FALL:
				if direction == 1:
					_set_anim(Anim.ROLL_BACK)
				else:
					_set_anim(Anim.ROLL)
			else:
				if direction == 1:
					_set_legs_anim(Anim.CROUCH_RUN_BACK)
				else:
					_set_legs_anim(Anim.CROUCH_RUN)

			if legs_anim == Anim.CROUCH_RUN or legs_anim == Anim.CROUCH_RUN_BACK:
				physics.forces[num].x = -MovementConstants.CROUCHRUNSPEED
			elif legs_anim == Anim.ROLL or legs_anim == Anim.ROLL_BACK:
				physics.forces[num].x = -2 * MovementConstants.CROUCHRUNSPEED

	# Right+Up: side jump right (lines 1777-1822)
	elif control_right and control_up:
		if on_ground:
			if legs_anim == Anim.RUN or legs_anim == Anim.RUN_BACK or legs_anim == Anim.STAND \
					or legs_anim == Anim.CROUCH or legs_anim == Anim.CROUCH_RUN \
					or legs_anim == Anim.CROUCH_RUN_BACK:
				_set_legs_anim(Anim.JUMP_SIDE)
			if legs_frame >= _get_num_frames(legs_anim):
				_set_legs_anim(Anim.RUN)
		elif legs_anim == Anim.ROLL or legs_anim == Anim.ROLL_BACK:
			if direction == 1:
				_set_legs_anim(Anim.RUN)
			else:
				_set_legs_anim(Anim.RUN_BACK)

		# Jump→JumpSide conversion mid-air (line 1807-1812)
		if legs_anim == Anim.JUMP:
			if legs_frame < 10:
				_set_legs_anim(Anim.JUMP_SIDE)

		# Side jump forces (lines 1815-1822)
		if legs_anim == Anim.JUMP_SIDE:
			if legs_frame > MovementConstants.SIDEJUMP_FORCE_START_FRAME and \
					legs_frame < MovementConstants.SIDEJUMP_FORCE_END_FRAME:
				physics.forces[num].x = MovementConstants.JUMPDIRSPEED
				physics.forces[num].y = -MovementConstants.JUMPDIRSPEED / 1.2

	# Left+Up: side jump left (lines 1825-1870)
	elif control_left and control_up:
		if on_ground:
			if legs_anim == Anim.RUN or legs_anim == Anim.RUN_BACK or legs_anim == Anim.STAND \
					or legs_anim == Anim.CROUCH or legs_anim == Anim.CROUCH_RUN \
					or legs_anim == Anim.CROUCH_RUN_BACK:
				_set_legs_anim(Anim.JUMP_SIDE)
			if legs_frame >= _get_num_frames(legs_anim):
				_set_legs_anim(Anim.RUN)
		elif legs_anim == Anim.ROLL or legs_anim == Anim.ROLL_BACK:
			if direction == -1:
				_set_legs_anim(Anim.RUN)
			else:
				_set_legs_anim(Anim.RUN_BACK)

		if legs_anim == Anim.JUMP:
			if legs_frame < 10:
				_set_legs_anim(Anim.JUMP_SIDE)

		if legs_anim == Anim.JUMP_SIDE:
			if legs_frame > MovementConstants.SIDEJUMP_FORCE_START_FRAME and \
					legs_frame < MovementConstants.SIDEJUMP_FORCE_END_FRAME:
				physics.forces[num].x = -MovementConstants.JUMPDIRSPEED
				physics.forces[num].y = -MovementConstants.JUMPDIRSPEED / 1.2

	# Up only: vertical jump (lines 1873-1898)
	elif control_up:
		if on_ground:
			if legs_anim != Anim.JUMP:
				_set_legs_anim(Anim.JUMP)
			if legs_frame >= _get_num_frames(legs_anim):
				_set_legs_anim(Anim.STAND)

		if legs_anim == Anim.JUMP:
			if legs_frame > MovementConstants.JUMP_FORCE_START_FRAME and \
					legs_frame < MovementConstants.JUMP_FORCE_END_FRAME:
				physics.forces[num].y = -MovementConstants.JUMPSPEED
			if legs_frame >= _get_num_frames(legs_anim):
				_set_legs_anim(Anim.FALL)

	# Down only: crouch (lines 1901-1913)
	elif control_down:
		if on_ground:
			_set_legs_anim(Anim.CROUCH)

	# Right only: run (lines 1916-1940)
	elif control_right:
		if direction == 1:
			_set_legs_anim(Anim.RUN)
		else:
			_set_legs_anim(Anim.RUN_BACK)

		if on_ground:
			physics.forces[num].x = MovementConstants.RUNSPEED
			physics.forces[num].y = -MovementConstants.RUNSPEEDUP
		else:
			physics.forces[num].x = MovementConstants.FLYSPEED

	# Left only: run (lines 1943-1967)
	elif control_left:
		if direction == -1:
			_set_legs_anim(Anim.RUN)
		else:
			_set_legs_anim(Anim.RUN_BACK)

		if on_ground:
			physics.forces[num].x = -MovementConstants.RUNSPEED
			physics.forces[num].y = -MovementConstants.RUNSPEEDUP
		else:
			physics.forces[num].x = -MovementConstants.FLYSPEED

	# No input (lines 1970-1983)
	else:
		if on_ground:
			_set_legs_anim(Anim.STAND)
		else:
			_set_legs_anim(Anim.FALL)


## Port of Sprites.pas lines 856-876 — Ground detection
func _check_ground() -> void:
	if not map:
		return

	var p: Vector2 = physics.pos[particle_idx]
	var vel: Vector2 = physics.velocity[particle_idx]
	on_ground = false

	# Leg collision check at (x+2, y+2) and (x-2, y+2)
	# Port of Sprites.pas lines 858-862
	var check_pos := p + vel
	var result := _check_map_collision(check_pos.x + 2, check_pos.y + 2)
	if not result.collided:
		result = _check_map_collision(check_pos.x - 2, check_pos.y + 2)

	if result.collided:
		on_ground = true

	# Vertex collision check within radius 3 (line 868-870)
	if not on_ground:
		var r := map.collision_test(check_pos)
		if r.collided and r.distance < 3.0:
			on_ground = true

	# OnGroundPermanent: stable over 2 frames (line 873-874)
	if not (on_ground != on_ground_last_frame):
		on_ground_permanent = on_ground
	on_ground_last_frame = on_ground


## Port of Sprites.pas CheckMapCollision (line 2573)
## Handles collision response, surface friction, bouncy/ice/deadly polygons
func _check_map_collision(x: float, y: float) -> Dictionary:
	if not map:
		return {"collided": false}

	var num := particle_idx
	var p := Vector2(x, y)
	var vel: Vector2 = physics.velocity[num]
	var test_pos := p + vel

	var result := map.collision_test(test_pos)
	if not result.collided:
		return {"collided": false}

	var poly_type: int = result.poly_type
	var step_normal: Vector2 = result.normal

	# Handle special polygon types
	if poly_type == MovementConstants.POLY_TYPE_DEADLY or poly_type == MovementConstants.POLY_TYPE_BLOODY_DEADLY:
		_die()
		return result
	if poly_type == MovementConstants.POLY_TYPE_LAVA:
		_die()
		return result

	# Collision response (lines 2718-2750)
	var perp: Vector2 = result.normal
	var d: float = result.distance
	perp = perp.normalized() * d

	var vel_len := vel.length()
	if perp.length() > vel_len:
		perp = perp.normalized() * vel_len

	physics.old_pos[num] = physics.pos[num]
	physics.pos[num] -= perp

	if poly_type == MovementConstants.POLY_TYPE_BOUNCY:
		perp = perp.normalized() * result.bounciness * vel_len

	physics.velocity[num] -= perp
	# Update velocity from position change
	physics.velocity[num] = physics.pos[num] - physics.old_pos[num]

	# Surface friction (lines 2753-2822)
	# Only apply when the step normal points upward (standing surface)
	if step_normal.y > MovementConstants.SLIDELIMIT:
		if poly_type != MovementConstants.POLY_TYPE_ICE and poly_type != MovementConstants.POLY_TYPE_BOUNCY:
			if legs_anim == Anim.STAND or legs_anim == Anim.FALL or legs_anim == Anim.CROUCH:
				# Standing friction: instant stop
				physics.velocity[num].x *= MovementConstants.STANDSURFACECOEFX
				physics.velocity[num].y *= MovementConstants.STANDSURFACECOEFY
				physics.forces[num].x -= physics.velocity[num].x
			else:
				# Moving friction
				physics.velocity[num].x *= MovementConstants.SURFACECOEFX
				physics.velocity[num].y *= MovementConstants.SURFACECOEFY

		# Cancel gravity when standing still on flat ground (lines 2768-2771)
		if legs_anim == Anim.STAND or legs_anim == Anim.CROUCH or legs_anim == Anim.FALL:
			if abs(physics.velocity[num].x) < MovementConstants.SLIDELIMIT and \
					step_normal.y > MovementConstants.SLIDELIMIT:
				physics.pos[num] = physics.old_pos[num]
				physics.forces[num].y -= MovementConstants.PLAYER_GRAVITY

	return result


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	death_count += 1
	died.emit()

	# Respawn at last checkpoint after a short delay
	get_tree().create_timer(0.5).timeout.connect(_respawn)


func _respawn() -> void:
	physics.pos[particle_idx] = last_checkpoint
	physics.old_pos[particle_idx] = last_checkpoint
	physics.velocity[particle_idx] = Vector2.ZERO
	physics.forces[particle_idx] = Vector2.ZERO
	position = last_checkpoint
	is_dead = false
	legs_anim = Anim.STAND
	legs_frame = 1
	body_anim = Anim.STAND


func set_checkpoint(cp: Vector2) -> void:
	last_checkpoint = cp
	checkpoint_reached.emit(cp)


func _set_legs_anim(anim: Anim) -> void:
	if legs_anim != anim:
		legs_anim = anim
		legs_frame = 1
		legs_num_frames = _get_num_frames(anim)


func _set_anim(anim: Anim) -> void:
	_set_legs_anim(anim)
	body_anim = anim
	legs_frame = 1


func _get_num_frames(anim: Anim) -> int:
	return ANIM_FRAMES.get(anim, 1)


func _advance_animation() -> void:
	legs_frame += 1
	if legs_frame > legs_num_frames:
		# Some animations loop, others transition
		match legs_anim:
			Anim.RUN, Anim.RUN_BACK, Anim.CROUCH_RUN, Anim.CROUCH_RUN_BACK:
				legs_frame = 1  # loop
			Anim.STAND, Anim.FALL, Anim.CROUCH:
				legs_frame = legs_num_frames  # hold last frame
			_:
				pass  # Let state machine handle transitions
