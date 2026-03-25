## Polygon Map - Direct port from Soldat's PolyMap.pas
## Handles polygon collision detection with sector-based spatial partitioning.

class_name PolyMap
extends RefCounted

const MC = MovementConstants

# Map polygon structure
class MapPolygon:
	var vertices: Array[Vector2] = []  # 3 vertices
	var normals: Array[Vector2] = []  # 3 edge normals (perpendiculars)
	var poly_type: int = 0
	var bounciness: float = 0.0

	func _init(v1: Vector2 = Vector2.ZERO, v2: Vector2 = Vector2.ZERO,
			v3: Vector2 = Vector2.ZERO, type: int = 0, bounce: float = 0.0):
		vertices = [v1, v2, v3]
		poly_type = type
		bounciness = bounce
		_compute_normals()

	func _compute_normals() -> void:
		# Compute edge perpendicular normals (inward-pointing)
		normals.clear()
		for i in 3:
			var j := (i + 1) % 3
			var edge := vertices[j] - vertices[i]
			# Perpendicular (rotated 90 degrees) - inward pointing
			var perp := Vector2(-edge.y, edge.x).normalized()
			normals.append(perp)


# Map data
var polygons: Array[MapPolygon] = []
var sectors_division: float = 100.0
var sectors_num: int = 25
var sectors: Dictionary = {}  # Key: Vector2i(sx, sy), Value: Array[int] (polygon indices)

# Spawnpoints and zones
var spawn_point: Vector2 = Vector2.ZERO
var checkpoints: Array[Rect2] = []
var finish_zone: Rect2 = Rect2()


## Port of PolyMap.pas PointInPoly (line 410)
## Uses cross-product winding test
func point_in_poly(p: Vector2, poly: MapPolygon) -> bool:
	var a := poly.vertices[0]
	var b := poly.vertices[1]
	var c := poly.vertices[2]

	var ap_x := p.x - a.x
	var ap_y := p.y - a.y

	var p_ab := (b.x - a.x) * ap_y - (b.y - a.y) * ap_x > 0
	var p_ac := (c.x - a.x) * ap_y - (c.y - a.y) * ap_x > 0

	if p_ac == p_ab:
		return false

	if ((c.x - b.x) * (p.y - b.y) - (c.y - b.y) * (p.x - b.x) > 0) != p_ab:
		return false

	return true


## Port of PolyMap.pas PointInPolyEdges (line 382)
## Half-plane test using precomputed perpendiculars
func point_in_poly_edges(p: Vector2, poly_idx: int) -> bool:
	var poly := polygons[poly_idx]
	for i in 3:
		var u := p - poly.vertices[i]
		var d := poly.normals[i].dot(u)
		if d < 0:
			return false
	return true


## Port of PolyMap.pas ClosestPerpendicular (line 457)
## Returns the perpendicular normal of the closest edge and the distance
func closest_perpendicular(poly_idx: int, pos: Vector2) -> Dictionary:
	var poly := polygons[poly_idx]
	var min_dist := INF
	var best_edge := 0

	for i in 3:
		var j := (i + 1) % 3
		var d := _point_line_distance(poly.vertices[i], poly.vertices[j], pos)
		if d < min_dist:
			min_dist = d
			best_edge = i

	return {
		"normal": poly.normals[best_edge],
		"distance": min_dist,
		"edge": best_edge,
	}


## Port of PolyMap.pas CollisionTest (line 536)
## Sector-based collision test with perpendicular response vector
func collision_test(pos: Vector2) -> Dictionary:
	var sx := roundi(pos.x / sectors_division)
	var sy := roundi(pos.y / sectors_division)

	var key := Vector2i(sx, sy)
	if not sectors.has(key):
		return {"collided": false}

	var sector_polys: Array = sectors[key]
	for poly_idx in sector_polys:
		var poly := polygons[poly_idx]

		# Skip non-colliding types
		if poly.poly_type == MC.POLY_TYPE_DOESNT_COLLIDE:
			continue
		if poly.poly_type == MC.POLY_TYPE_ONLY_BULLETS:
			continue

		if point_in_poly(pos, poly):
			var perp_data := closest_perpendicular(poly_idx, pos)
			var perp_vec: Vector2 = perp_data.normal * 1.5 * perp_data.distance

			return {
				"collided": true,
				"perp_vec": perp_vec,
				"poly_type": poly.poly_type,
				"poly_idx": poly_idx,
				"bounciness": poly.bounciness,
				"normal": perp_data.normal,
				"distance": perp_data.distance,
			}

	return {"collided": false}


## Build sector spatial partitioning from polygons
func build_sectors() -> void:
	sectors.clear()
	for i in polygons.size():
		var poly := polygons[i]
		# Find bounding box of polygon
		var min_v := poly.vertices[0]
		var max_v := poly.vertices[0]
		for v in poly.vertices:
			min_v.x = min(min_v.x, v.x)
			min_v.y = min(min_v.y, v.y)
			max_v.x = max(max_v.x, v.x)
			max_v.y = max(max_v.y, v.y)

		# Add polygon to all sectors it overlaps
		var sx_min := floori(min_v.x / sectors_division) - 1
		var sx_max := ceili(max_v.x / sectors_division) + 1
		var sy_min := floori(min_v.y / sectors_division) - 1
		var sy_max := ceili(max_v.y / sectors_division) + 1

		for sx in range(sx_min, sx_max + 1):
			for sy in range(sy_min, sy_max + 1):
				var key := Vector2i(sx, sy)
				if not sectors.has(key):
					sectors[key] = []
				sectors[key].append(i)


## Helper: point-to-line-segment distance
func _point_line_distance(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ab.dot(ap) / ab.length_squared(), 0.0, 1.0)
	var closest := a + ab * t
	return p.distance_to(closest)


## Add a polygon to the map
func add_polygon(v1: Vector2, v2: Vector2, v3: Vector2,
		type: int = 0, bounce: float = 0.0) -> void:
	var poly := MapPolygon.new(v1, v2, v3, type, bounce)
	polygons.append(poly)


## Rebuild after adding polygons
func finalize() -> void:
	build_sectors()
