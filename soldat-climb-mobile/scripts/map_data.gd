## Map Data - Hand-built test maps for the Climb prototype

class_name MapData
extends RefCounted


static func create_basic_test() -> Dictionary:
	return {
		"name": "Basic Test",
		"polygons": [
			_poly(-500, 200, 1500, 200, 1500, 250),
			_poly(-500, 200, 1500, 250, -500, 250),
			_poly(-500, -400, -480, -400, -480, 200),
			_poly(-500, -400, -480, 200, -500, 200),
			_poly(100, 100, 250, 100, 250, 115),
			_poly(100, 100, 250, 115, 100, 115),
			_poly(350, 0, 500, 0, 500, 15),
			_poly(350, 0, 500, 15, 350, 15),
			_poly(600, -100, 750, -100, 750, -85),
			_poly(600, -100, 750, -85, 600, -85),
		],
		"spawn": Vector2(0, 180),
		"checkpoints": [],
		"finish": Rect2(700, -130, 50, 30),
	}


static func create_jump_course() -> Dictionary:
	return {
		"name": "Jump Course",
		"polygons": [
			_poly(-100, 200, 100, 200, 100, 250),
			_poly(-100, 200, 100, 250, -100, 250),
			_poly(200, 200, 350, 200, 350, 250),
			_poly(200, 200, 350, 250, 200, 250),
			_poly(450, 100, 600, 100, 600, 150),
			_poly(450, 100, 600, 150, 450, 150),
			_poly_typed(650, -100, 670, -100, 670, 150, 18, 1.5),
			_poly_typed(650, -100, 670, 150, 650, 150, 18, 1.5),
			_poly(700, -50, 900, -50, 900, -35),
			_poly(700, -50, 900, -35, 700, -35),
			_poly_typed(1000, -50, 1200, -50, 1200, -35, 4),
			_poly_typed(1000, -50, 1200, -35, 1000, -35, 4),
			_poly(1300, -150, 1380, -150, 1380, -135),
			_poly(1300, -150, 1380, -135, 1300, -135),
			_poly(1450, -250, 1600, -250, 1600, -235),
			_poly(1450, -250, 1600, -235, 1450, -235),
			_poly_typed(-200, 400, 1800, 400, 1800, 450, 5),
			_poly_typed(-200, 400, 1800, 450, -200, 450, 5),
		],
		"spawn": Vector2(0, 180),
		"checkpoints": [
			Rect2(500, 60, 50, 40),
			Rect2(800, -90, 50, 40),
			Rect2(1350, -190, 30, 40),
		],
		"finish": Rect2(1500, -290, 50, 40),
	}


static func create_climb_tower() -> Dictionary:
	var polys := []
	polys.append(_poly(-200, 300, 400, 300, 400, 350))
	polys.append(_poly(-200, 300, 400, 350, -200, 350))

	var heights := [200, 100, 0, -100, -200, -300, -400, -500, -600, -700]
	for i in heights.size():
		var x_offset: float = 0.0 if i % 2 == 0 else 200.0
		var y: float = heights[i]
		polys.append(_poly(x_offset, y, x_offset + 150, y, x_offset + 150, y + 15))
		polys.append(_poly(x_offset, y, x_offset + 150, y + 15, x_offset, y + 15))

	polys.append(_poly(-220, -800, -200, -800, -200, 300))
	polys.append(_poly(-220, -800, -200, 300, -220, 300))
	polys.append(_poly(400, -800, 420, -800, 420, 300))
	polys.append(_poly(400, -800, 420, 300, 400, 300))
	polys.append(_poly_typed(-220, 350, 420, 350, 420, 400, 9))
	polys.append(_poly_typed(-220, 350, 420, 400, -220, 400, 9))
	polys.append(_poly_typed(-220, -820, 420, -820, 420, -800, 18, 2.0))
	polys.append(_poly_typed(-220, -820, 420, -800, -220, -800, 18, 2.0))

	var checkpoints := []
	for i in range(2, heights.size(), 3):
		var x_offset: float = 0.0 if i % 2 == 0 else 200.0
		checkpoints.append(Rect2(x_offset + 50, heights[i] - 40, 50, 40))

	return {
		"name": "Climb Tower",
		"polygons": polys,
		"spawn": Vector2(50, 280),
		"checkpoints": checkpoints,
		"finish": Rect2(250, -740, 50, 40),
	}


static func _poly(x1: float, y1: float, x2: float, y2: float,
		x3: float, y3: float) -> Dictionary:
	return {
		"v1": Vector2(x1, y1),
		"v2": Vector2(x2, y2),
		"v3": Vector2(x3, y3),
		"type": 0,
		"bounciness": 0.0,
	}


static func _poly_typed(x1: float, y1: float, x2: float, y2: float,
		x3: float, y3: float, type: int, bounce: float = 0.0) -> Dictionary:
	return {
		"v1": Vector2(x1, y1),
		"v2": Vector2(x2, y2),
		"v3": Vector2(x3, y3),
		"type": type,
		"bounciness": bounce,
	}
