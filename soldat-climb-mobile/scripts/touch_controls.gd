## Touch Controls with Input Buffering
## Handles mobile touch input and keyboard fallback.
## Right zone: aim zone (touch position = facing direction) + tap=jump, swipe down=crouch
## Left zone: d-pad for left/right movement
extends CanvasLayer

signal input_changed(left: bool, right: bool, up: bool, down: bool, aim_x: float)

# Touch zones (fractions of screen width)
const LEFT_ZONE_WIDTH := 0.4  # Left 40% for d-pad
const DPAD_BUTTON_SIZE := 80.0
const ACTION_BUTTON_SIZE := 80.0
const BUTTON_MARGIN := 20.0

# Input buffering (5 frames at 60fps = ~83ms)
const BUFFER_FRAMES := 5

# State
var control_left := false
var control_right := false
var control_up := false
var control_down := false
var aim_x := 0.0  # World-space X for facing direction

# Touch tracking
var _left_touch_id := -1
var _right_touch_id := -1
var _right_touch_start := Vector2.ZERO
var _right_touch_current := Vector2.ZERO

# Input buffer for jump (allows slightly early presses to register)
var _jump_buffer: int = 0
var _crouch_buffer: int = 0

# Reference to player for aim-relative-to-player calculation
var player_screen_x: float = 480.0  # Updated each frame by main scene


func _ready() -> void:
	layer = 10  # Render above game


func _process(_delta: float) -> void:
	# Keyboard fallback (for desktop testing)
	if not _has_active_touches():
		control_left = Input.is_action_pressed("move_left")
		control_right = Input.is_action_pressed("move_right")
		control_up = Input.is_action_pressed("jump")
		control_down = Input.is_action_pressed("crouch")

		# Mouse for aim direction (desktop)
		aim_x = get_viewport().get_mouse_position().x

	# Tick down input buffers
	if _jump_buffer > 0:
		_jump_buffer -= 1
		control_up = true

	if _crouch_buffer > 0:
		_crouch_buffer -= 1
		control_down = true

	input_changed.emit(control_left, control_right, control_up, control_down, aim_x)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var screen_width := get_viewport().get_visible_rect().size.x
	var screen_height := get_viewport().get_visible_rect().size.y
	var zone_boundary := screen_width * LEFT_ZONE_WIDTH

	if event.pressed:
		if event.position.x < zone_boundary:
			# Left zone: d-pad
			_left_touch_id = event.index
			_update_dpad(event.position, screen_height)
		else:
			# Right zone: aim + actions
			_right_touch_id = event.index
			_right_touch_start = event.position
			_right_touch_current = event.position

			# Aim direction from touch position relative to player
			aim_x = event.position.x  # Will be converted to world space by main scene

			# Tap = jump (buffer it)
			_jump_buffer = BUFFER_FRAMES
	else:
		if event.index == _left_touch_id:
			_left_touch_id = -1
			control_left = false
			control_right = false
		elif event.index == _right_touch_id:
			_right_touch_id = -1
			# Check for swipe down on release
			var swipe := _right_touch_current - _right_touch_start
			if swipe.y > 40 and abs(swipe.x) < abs(swipe.y):
				_crouch_buffer = BUFFER_FRAMES


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	var screen_height := get_viewport().get_visible_rect().size.y

	if event.index == _left_touch_id:
		_update_dpad(event.position, screen_height)
	elif event.index == _right_touch_id:
		_right_touch_current = event.position
		# Continuous aim tracking
		aim_x = event.position.x


func _update_dpad(pos: Vector2, screen_height: float) -> void:
	# Simple left/right based on position in left zone
	var screen_width := get_viewport().get_visible_rect().size.x
	var zone_center_x := screen_width * LEFT_ZONE_WIDTH * 0.5

	control_left = pos.x < zone_center_x
	control_right = pos.x >= zone_center_x


func _has_active_touches() -> bool:
	return _left_touch_id >= 0 or _right_touch_id >= 0


func _draw() -> void:
	# Draw touch control overlay (semi-transparent)
	var screen := get_viewport().get_visible_rect().size
	var zone_x := screen.x * LEFT_ZONE_WIDTH

	# Left zone background
	draw_rect(Rect2(0, screen.y * 0.5, zone_x, screen.y * 0.5),
		Color(1, 1, 1, 0.05))

	# D-pad buttons
	var btn_y := screen.y - DPAD_BUTTON_SIZE - BUTTON_MARGIN
	var left_btn := Rect2(BUTTON_MARGIN, btn_y, DPAD_BUTTON_SIZE, DPAD_BUTTON_SIZE)
	var right_btn := Rect2(BUTTON_MARGIN + DPAD_BUTTON_SIZE + 10, btn_y,
		DPAD_BUTTON_SIZE, DPAD_BUTTON_SIZE)

	var left_color := Color(1, 1, 1, 0.3) if control_left else Color(1, 1, 1, 0.1)
	var right_color := Color(1, 1, 1, 0.3) if control_right else Color(1, 1, 1, 0.1)

	draw_rect(left_btn, left_color)
	draw_rect(right_btn, right_color)

	# Right zone - jump and aim indicator
	var jump_btn := Rect2(screen.x - BUTTON_MARGIN - ACTION_BUTTON_SIZE,
		btn_y - ACTION_BUTTON_SIZE - 10, ACTION_BUTTON_SIZE, ACTION_BUTTON_SIZE)
	var crouch_btn := Rect2(screen.x - BUTTON_MARGIN - ACTION_BUTTON_SIZE,
		btn_y, ACTION_BUTTON_SIZE, ACTION_BUTTON_SIZE)

	var jump_color := Color(0.3, 1, 0.3, 0.3) if control_up else Color(0.3, 1, 0.3, 0.1)
	var crouch_color := Color(1, 0.5, 0.3, 0.3) if control_down else Color(1, 0.5, 0.3, 0.1)

	draw_rect(jump_btn, jump_color)
	draw_rect(crouch_btn, crouch_color)

	queue_redraw()
