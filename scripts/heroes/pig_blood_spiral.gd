extends Node2D
class_name PigBloodSpiral

const BLOOD_SPIRAL_TEXTURE := preload("res://characters/pig/assets/blood spiral.png")

var orbit_radius: float = 28.0
var orbit_radius_growth: float = 34.0
var angular_speed: float = 1.8
var pulse_speed: float = 5.2
var start_angle: float = 0.0
var visual_scale: float = 0.8
var launch_duration: float = 0.32

var _time: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

@onready var _spiral: AnimatedSprite2D = $Spiral


func setup(config: Dictionary) -> PigBloodSpiral:
	orbit_radius = float(config.get("orbit_radius", orbit_radius))
	orbit_radius_growth = float(config.get("orbit_radius_growth", orbit_radius_growth))
	angular_speed = float(config.get("angular_speed", angular_speed))
	pulse_speed = float(config.get("pulse_speed", pulse_speed))
	start_angle = float(config.get("start_angle", start_angle))
	visual_scale = float(config.get("visual_scale", visual_scale))
	launch_duration = float(config.get("launch_duration", launch_duration))
	return self


func _ready() -> void:
	_build_frames_from_texture()
	_base_scale = Vector2.ONE * visual_scale
	modulate = Color(1.0, 0.42, 0.42, 0.9)
	if is_instance_valid(_spiral):
		_spiral.scale = _base_scale
		_spiral.play("spiral")
	_update_motion(0.0)


func _process(delta: float) -> void:
	_update_motion(delta)


func _build_frames_from_texture() -> void:
	if not is_instance_valid(_spiral) or BLOOD_SPIRAL_TEXTURE == null:
		return

	var frames := SpriteFrames.new()
	frames.add_animation("spiral")
	frames.set_animation_speed("spiral", 7.0)
	frames.set_animation_loop("spiral", true)

	var frame_width := int(BLOOD_SPIRAL_TEXTURE.get_width() / 2.0)
	var frame_height := BLOOD_SPIRAL_TEXTURE.get_height()
	if frame_width <= 0 or frame_height <= 0:
		return

	for i in range(2):
		var atlas := AtlasTexture.new()
		atlas.atlas = BLOOD_SPIRAL_TEXTURE
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("spiral", atlas)

	_spiral.sprite_frames = frames
	_spiral.centered = true


func _update_motion(delta: float) -> void:
	_time += delta
	var angle: float = start_angle + _time * angular_speed
	var launch_t: float = clampf(_time / maxf(launch_duration, 0.01), 0.0, 1.0)
	var launch_scale: float = 1.0 - pow(1.0 - launch_t, 3.0)
	var radius: float = (orbit_radius + sin(_time * 1.8 + start_angle) * orbit_radius_growth) * launch_scale
	position = Vector2(cos(angle), sin(angle)) * radius

	if is_instance_valid(_spiral):
		var pulse: float = 1.0 + sin(_time * pulse_speed + start_angle) * 0.08
		_spiral.scale = _base_scale * pulse * maxf(0.25, launch_scale)
		_spiral.rotation = sin(_time * 1.2 + start_angle) * 0.12
