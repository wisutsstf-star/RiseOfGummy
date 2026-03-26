extends Area2D
class_name PigBloodCourier

const BLOOD_SPIRAL_TEXTURE := preload("res://characters/pig/assets/blood spiral.png")

@export var debug_mode := false

var heal_amount: int = 0
var move_speed: float = 240.0
var arrive_distance: float = 14.0
var target_node: Node2D = null
var target_position: Vector2 = Vector2.ZERO
var on_arrive: Callable = Callable()
var hp_drained: float = 0.0
var hp_threshold: float = 0.0
var is_delivering: bool = false
var target: Node = null

var _is_finished: bool = false
var _hit_texture: Texture2D = null
var _fly_sprite: AnimatedSprite2D = null
var _collision_warmup: float = 0.12


func setup(config: Dictionary) -> PigBloodCourier:
	heal_amount = maxi(0, int(config.get("heal_amount", heal_amount)))
	move_speed = maxf(1.0, float(config.get("move_speed", move_speed)))
	arrive_distance = maxf(4.0, float(config.get("arrive_distance", arrive_distance)))
	target_node = config.get("target_node", null)
	target_position = Vector2(config.get("target_position", target_position))
	on_arrive = config.get("on_arrive", Callable())
	_hit_texture = config.get("hit_texture", null)
	hp_threshold = maxf(0.0, float(config.get("hp_threshold", hp_threshold)))
	hp_drained = float(config.get("hp_drained", heal_amount))
	target = target_node

	var start_position := Vector2(config.get("start_position", global_position))
	global_position = start_position
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_visuals(config.get("fly_frames", null))
	is_delivering = true
	return self


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 1
	collision_mask = 0
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	set_process(true)
	set_physics_process(true)
	if debug_mode:
		print_debug_info("Ready")


func _physics_process(delta: float) -> void:
	if _is_finished:
		return
	if not is_delivering:
		return

	if _collision_warmup > 0.0:
		_collision_warmup = maxf(0.0, _collision_warmup - delta)
		if _collision_warmup <= 0.0:
			monitoring = true
			collision_mask = 2147483647

	var destination := _resolve_target_position()
	var to_target := destination - global_position
	var distance := to_target.length()
	if distance <= arrive_distance:
		_complete_delivery(destination)
		return

	var direction := to_target / maxf(distance, 0.001)
	global_position += direction * move_speed * delta
	if is_instance_valid(_fly_sprite):
		_fly_sprite.flip_h = direction.x < 0.0


func _build_visuals(fly_frames: SpriteFrames) -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)

	_fly_sprite = AnimatedSprite2D.new()
	_fly_sprite.visible = true
	var resolved_frames: SpriteFrames = fly_frames if fly_frames != null else _make_default_fly_frames()
	if resolved_frames != null:
		_fly_sprite.sprite_frames = resolved_frames
		if _fly_sprite.sprite_frames.has_animation(&"fly"):
			_fly_sprite.animation = &"fly"
			_fly_sprite.play(&"fly")
		else:
			var animation_list := _fly_sprite.sprite_frames.get_animation_names()
			if not animation_list.is_empty():
				_fly_sprite.animation = StringName(animation_list[0])
				_fly_sprite.play()
			elif debug_mode:
				print_debug_info("Missing fly animation")
	elif debug_mode:
		print_debug_info("Missing blood_fly frames")
	_fly_sprite.scale = Vector2.ONE * 0.8
	_fly_sprite.z_index = 141
	add_child(_fly_sprite)


func _resolve_target_position() -> Vector2:
	if is_instance_valid(target_node):
		return target_node.global_position
	return target_position


func start_delivery(hp: float) -> void:
	hp_drained = hp
	if hp_drained < hp_threshold:
		if debug_mode:
			print_debug_info("HP too low - not spawning")
		queue_free()
		return
	target = _find_delivery_target()
	if target == null and target_position != Vector2.ZERO:
		target = self
	if target != null:
		is_delivering = true
		if debug_mode:
			print_debug_info("Starting delivery")


func _find_delivery_target() -> Node:
	if is_instance_valid(target_node):
		return target_node
	return null


func print_debug_info(stage: String) -> void:
	print("[Courier Debug] Stage:", stage)
	print("  Drained HP:", hp_drained)
	print("  Threshold:", hp_threshold)
	print("  Target:", String(target.name) if target != null else "None")


func _on_body_entered(body: Node) -> void:
	if _is_finished:
		return
	if body != null and body.is_in_group("enemies"):
		_fail_delivery()


func _on_area_entered(area: Area2D) -> void:
	if _is_finished:
		return
	if area == null:
		return
	if area.is_in_group("enemy_projectiles"):
		if is_instance_valid(area):
			area.queue_free()
		_fail_delivery()


func _complete_delivery(hit_position: Vector2) -> void:
	if _is_finished:
		return
	_is_finished = true
	_spawn_hit_effect(hit_position)
	if on_arrive.is_valid():
		on_arrive.call(heal_amount)
	queue_free()


func _fail_delivery() -> void:
	if _is_finished:
		return
	_is_finished = true
	_spawn_hit_effect(global_position)
	queue_free()


func _spawn_hit_effect(world_pos: Vector2) -> void:
	if _hit_texture == null or get_tree().current_scene == null:
		return

	var splash := Sprite2D.new()
	splash.texture = _make_hit_frame_texture(_hit_texture)
	splash.global_position = world_pos
	splash.z_index = 145
	splash.scale = Vector2.ONE * 0.85
	get_tree().current_scene.add_child(splash)

	var tween := splash.create_tween().set_parallel(true)
	tween.tween_property(splash, "scale", Vector2.ONE * 1.25, 0.16)
	tween.tween_property(splash, "modulate:a", 0.0, 0.16)
	tween.tween_callback(splash.queue_free)


func _make_hit_frame_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var width := texture.get_width()
	var height := texture.get_height()
	if width <= height:
		return texture
	var frame_width := width / 2.0
	if frame_width <= 0:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, frame_width, height)
	return atlas


func _make_default_fly_frames() -> SpriteFrames:
	if BLOOD_SPIRAL_TEXTURE == null:
		return null
	var frame_width := float(BLOOD_SPIRAL_TEXTURE.get_width()) / 2.0
	var frame_height := BLOOD_SPIRAL_TEXTURE.get_height()
	if frame_width <= 0 or frame_height <= 0:
		return null

	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", 7.0)
	frames.set_animation_loop("fly", true)
	for i in range(2):
		var atlas := AtlasTexture.new()
		atlas.atlas = BLOOD_SPIRAL_TEXTURE
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("fly", atlas)
	return frames
