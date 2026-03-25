## Verlet Physics Engine - Direct port from Soldat's Parts.pas
## Original: Copyright (c) 2001-02 Michal Marcinkowski
##
## This is a faithful port of Soldat's Verlet integration particle system.
## The Verlet method stores current and previous positions instead of velocity,
## which gives natural momentum and stable constraint satisfaction.

class_name VerletPhysics

const NUM_PARTICLES := 16  # Reduced from Soldat's 560 - we only need player particles

var active: Array[bool] = []
var pos: Array[Vector2] = []
var old_pos: Array[Vector2] = []
var velocity: Array[Vector2] = []
var forces: Array[Vector2] = []
var one_over_mass: Array[float] = []

var time_step: float = 1.0
var gravity: float = 0.06
var v_damping: float = 0.99
var e_damping: float = 0.99

var constraints: Array[Dictionary] = []  # {active, part_a, part_b, rest_length}


func _init():
	for i in NUM_PARTICLES:
		active.append(false)
		pos.append(Vector2.ZERO)
		old_pos.append(Vector2.ZERO)
		velocity.append(Vector2.ZERO)
		forces.append(Vector2.ZERO)
		one_over_mass.append(1.0)


## Core Verlet integration - direct port from Parts.pas lines 126-147
## Formula: new_pos = (1 + damping) * pos - damping * old_pos + forces * dt^2
func verlet(i: int) -> void:
	# Accumulate gravity
	forces[i].y += gravity

	var temp_pos := pos[i]

	# Verlet integration with velocity damping
	# S1 = pos * (1 + VDamping), S2 = old_pos * VDamping
	var s1 := pos[i] * (1.0 + v_damping)
	var s2 := old_pos[i] * v_damping

	var d := s1 - s2
	var force_term := forces[i] * one_over_mass[i] * (time_step * time_step)

	pos[i] = d + force_term
	old_pos[i] = temp_pos

	# Derive velocity from position change (for collision response)
	velocity[i] = pos[i] - old_pos[i]

	# Clear forces
	forces[i] = Vector2.ZERO


func do_verlet_timestep() -> void:
	for i in NUM_PARTICLES:
		if active[i]:
			verlet(i)
	satisfy_constraints()


func do_verlet_timestep_for(i: int, j: int) -> void:
	verlet(i)
	satisfy_constraint_for(j)


## Constraint satisfaction - maintains rigid distances between particles
## Used for the player skeleton (gostek) bone structure
func satisfy_constraints() -> void:
	for c in constraints:
		if not c.active:
			continue

		var delta := pos[c.part_b] - pos[c.part_a]
		var delta_length := delta.length()
		var diff := 0.0

		if delta_length != 0.0:
			diff = (delta_length - c.rest_length) / delta_length

		if one_over_mass[c.part_a] > 0.0:
			pos[c.part_a] += delta * 0.5 * diff

		if one_over_mass[c.part_b] > 0.0:
			pos[c.part_b] -= delta * 0.5 * diff


func satisfy_constraint_for(idx: int) -> void:
	if idx < 0 or idx >= constraints.size():
		return
	var c = constraints[idx]
	var delta := pos[c.part_b] - pos[c.part_a]
	var delta_length := delta.length()
	var diff := 0.0

	if delta_length != 0.0:
		diff = (delta_length - c.rest_length) / delta_length

	if one_over_mass[c.part_a] > 0.0:
		pos[c.part_a] += delta * 0.5 * diff

	if one_over_mass[c.part_b] > 0.0:
		pos[c.part_b] -= delta * 0.5 * diff


func create_part(start: Vector2, vel: Vector2, mass: float, num: int) -> void:
	if num < 0 or num >= NUM_PARTICLES:
		return
	active[num] = true
	pos[num] = start
	velocity[num] = vel
	old_pos[num] = start
	one_over_mass[num] = 1.0 / mass


func make_constraint(part_a: int, part_b: int, rest_length: float) -> void:
	constraints.append({
		"active": true,
		"part_a": part_a,
		"part_b": part_b,
		"rest_length": rest_length,
	})


func stop_all_parts() -> void:
	for i in NUM_PARTICLES:
		if active[i]:
			velocity[i] = Vector2.ZERO
			old_pos[i] = pos[i]
