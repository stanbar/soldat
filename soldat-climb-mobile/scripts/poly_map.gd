## Polygon Map - Direct port from Soldat's PolyMap.pas

class_name PolyMap
extends RefCounted


class MapPolygon:
	extends RefCounted
	var vertices := []  # 3 Vector2s
	var normals := []  # 3 Vector2s
	var poly_type: int = 0
	var bounciness: float = 0.0

	func setup(v1: Vector2, v2: Vector2, v3: Vector2, type: int = 0, bounce: float = 0.0) -> void:
		vertices = [v1, v2, v3]
		poly_type = type
		bounciness = bounce
		_compute_normals()

	func _compute_normals() -> void:
		normals.clear()
		for i in 3:
			var j := (i + 1) % 3
			var edge: Vector2 = vertices[j] - vertices[i]
			var perp := Vector2(-edge.y, edge.x).normalized()
			normals.append(perp)


var polygons := []
var sectors_division: float = 100.0
var sectors_num: int = 25
var sectors := {}


func point_in_poly(p: Vector2, poly: MapPolygon) -> bool:
	var a: Vector2 = poly.vertices[0]
	var b: Vector2 = poly.vertices[1]
	var c: Vector2 = poly.vertices[2]
	var ap_x := p.x - a.x
	var ap_y := p.y - a.y
	var p_ab := (b.x - a.x) * ap_y - (b.y - a.y) * ap_x > 0
	var p_ac := (c.x - a.x) * ap_y - (c.y - a.y) * ap_x > 0
	if p_ac == p_ab:
		return false
	if ((c.x - b.x) * (p.y - b.y) - (c.y - b.y) * (p.x - b.x) > 0) != p_ab:
		return false
	return true


func closest_perpendicular(poly_idx: int, pos: Vector2) -> Dictionary:
	var poly: MapPolygon = polygons[poly_idx]
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


func collision_test(pos: Vector2) -> Dictionary:
	var sx := roundi(pos.x / sectors_division)
	var sy := roundi(pos.y / sectors_division)
	var key := Vector2i(sx, sy)
	if not sectors.has(key):
		return {"collided": false}

	var sector_polys: Array = sectors[key]
	for poly_idx in sector_polys:
		var poly: MapPolygon = polygons[poly_idx]
		if poly.poly_type == MovementConstants.POLY_TYPE_DOESNT_COLLIDE:
			continue
		if poly.poly_type == MovementConstants.POLY_TYPE_ONLY_BULLETS:
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


func build_sectors() -> void:
	sectors.clear()
	for i in polygons.size():
		var poly: MapPolygon = polygons[i]
		var min_v: Vector2 = poly.vertices[0]
		var max_v: Vector2 = poly.vertices[0]
		for v in poly.vertices:
			min_v.x = min(min_v.x, v.x)
			min_v.y = min(min_v.y, v.y)
			max_v.x = max(max_v.x, v.x)
			max_v.y = max(max_v.y, v.y)
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


func _point_line_distance(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t := clampf(ab.dot(ap) / len_sq, 0.0, 1.0)
	var closest := a + ab * t
	return p.distance_to(closest)


func add_polygon(v1: Vector2, v2: Vector2, v3: Vector2,
		type: int = 0, bounce: float = 0.0) -> void:
	var poly := MapPolygon.new()
	poly.setup(v1, v2, v3, type, bounce)
	polygons.append(poly)


func finalize() -> void:
	build_sectors()
