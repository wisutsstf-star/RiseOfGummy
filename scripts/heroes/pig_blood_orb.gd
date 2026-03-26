extends Area2D
class_name PigBloodOrb

const ORB_TEXTURE_PATH := "res://characters/pig/assets/red_sphere.png"
const ORB_BASE_SCALE := Vector2(0.16, 0.16)
const ORB_ROTATION_SPEED := 2.0
const ORBIT_SPARK_TEXTURE_PATHS := [
	"res://characters/pig/assets/orbit_spark (1).png",
	"res://characters/pig/assets/orbit_spark (2).png",
	"res://characters/pig/assets/orbit_spark (3).png",
	"res://characters/pig/assets/orbit_spark (4).png",
	"res://characters/pig/assets/orbit_spark (5).png",
]

signal orb_finished(orb)
signal orb_reached_center(orb)

@export var move_speed: float = 80.0
@export var retarget_interval_min: float = 0.3
@export var retarget_interval_max: float = 0.6
@export var explosion_radius: float = 56.0

var owner_hero: Node = null
var anchor_node: Node2D = null
var orbit_center: Vector2 = Vector2.ZERO
var move_radius: float = 130.0
var orb_duration: float = 6.0
var orb_drain_damage: int = 6
var orb_drain_percent: float = 5.0
var drain_interval: float = 0.8
var orb_drain_cap: int = 15
var converge_only: bool = false

var _life_remaining: float = 0.0
var _retarget_timer: float = 0.0
var _drain_cooldowns: Dictionary = {}
var _is_finishing: bool = false
var _target_enemy: Node2D = null
var _target_position: Vector2 = Vector2.ZERO
var _has_target_position: bool = false
var _orb_texture: Texture2D = null
var _initial_target_enemy: Node2D = null
var _orbit_spark_textures: Array[Texture2D] = []

@onready var _orb_sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var _orbit_spark: AnimatedSprite2D = get_node_or_null("OrbitSpark") as AnimatedSprite2D


func setup(config: Dictionary) -> PigBloodOrb:
	owner_hero = config.get("owner_hero", owner_hero)
	anchor_node = config.get("anchor_node", anchor_node)
	orbit_center = Vector2(config.get("orbit_center", orbit_center))
	move_radius = float(config.get("move_radius", move_radius))
	orb_duration = float(config.get("orb_duration", orb_duration))
	orb_drain_damage = int(config.get("orb_drain_damage", orb_drain_damage))
	orb_drain_percent = float(config.get("orb_drain_percent", orb_drain_percent))
	drain_interval = float(config.get("drain_interval", drain_interval))
	orb_drain_cap = int(config.get("orb_drain_cap", orb_drain_cap))
	converge_only = bool(config.get("converge_only", converge_only))
	_initial_target_enemy = config.get("initial_target_enemy", _initial_target_enemy)
	if config.has("target_position"):
		_target_position = Vector2(config["target_position"])
		_has_target_position = true
	if config.has("move_speed"):
		move_speed = float(config["move_speed"])
	return self


func _ready() -> void:
	monitoring = not converge_only
	add_to_group("pig_blood_orbs")
	_orb_texture = _load_orb_texture()
	if _orb_sprite == null:
		_orb_sprite = Sprite2D.new()
		_orb_sprite.name = "Sprite2D"
		_orb_sprite.scale = ORB_BASE_SCALE
		_orb_sprite.modulate = Color(1.0, 0.45, 0.45, 0.95)
		add_child(_orb_sprite)
	if _orb_texture != null:
		_orb_sprite.texture = _orb_texture
	if _orb_sprite.scale == Vector2.ZERO:
		_orb_sprite.scale = ORB_BASE_SCALE
	_orb_sprite.visible = true
	_setup_orbit_spark()
	z_index = 120
	_life_remaining = maxf(orb_duration, 0.2)
	if is_instance_valid(anchor_node):
		orbit_center = anchor_node.global_position
	if not converge_only and _is_valid_enemy(_initial_target_enemy):
		_target_enemy = _initial_target_enemy
	_acquire_target_enemy(true)


func _physics_process(delta: float) -> void:
	if _is_finishing:
		return

	_life_remaining -= delta
	if _life_remaining <= 0.0:
		_finish(false)
		return

	_tick_contact_cooldowns(delta)
	rotation += ORB_ROTATION_SPEED * delta
	if is_instance_valid(_orbit_spark):
		_orbit_spark.global_position = global_position
		_orbit_spark.global_rotation = 0.0

	if converge_only:
		_move_toward_target(delta)
		return

	_acquire_target_enemy()
	_move_toward_target(delta)
	_drain_overlapping_enemies()


func on_pig_skill_overlap() -> void:
	if _is_finishing:
		return

	if converge_only:
		_finish(true)
		return

	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not _is_valid_enemy(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > explosion_radius:
			continue

		var dir: Vector2 = (enemy.global_position - global_position).normalized()
		enemy.take_damage(_get_drain_amount(enemy), "death_explode", dir)

	_finish(true)


func on_pig_existing_skill_hit() -> void:
	if _is_finishing:
		return
	_finish(true)


func _acquire_target_enemy(force: bool = false) -> void:
	if converge_only:
		return

	_retarget_timer -= get_physics_process_delta_time()
	if force and _is_valid_enemy(_initial_target_enemy):
		_target_enemy = _initial_target_enemy
		_retarget_timer = randf_range(retarget_interval_min, retarget_interval_max)
		return
	if not force and _retarget_timer > 0.0 and _is_valid_enemy(_target_enemy):
		return

	_target_enemy = _find_nearest_enemy()
	_retarget_timer = randf_range(retarget_interval_min, retarget_interval_max)


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func _move_toward_target(delta: float) -> void:
	if _has_target_position:
		var to_target: Vector2 = _target_position - global_position
		if to_target.length() > 5.0:
			global_position += to_target.normalized() * move_speed * delta
		else:
			_on_reached_target_position()
		return

	var destination := _get_idle_anchor_position()
	if _is_valid_enemy(_target_enemy):
		destination = _target_enemy.global_position

	var to_dest: Vector2 = destination - global_position
	if to_dest.length() > 2.0:
		global_position += to_dest.normalized() * move_speed * delta

	if not _is_valid_enemy(_target_enemy):
		var current_center := _get_orbit_center()
		var offset: Vector2 = global_position - current_center
		if offset.length() > move_radius:
			global_position = current_center + offset.normalized() * move_radius


func _on_reached_target_position() -> void:
	_is_finishing = true
	set_physics_process(false)
	orb_reached_center.emit(self)

	var fade_tween := create_tween().set_parallel(true)
	fade_tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	fade_tween.tween_callback(_finish_and_free)


func _get_idle_anchor_position() -> Vector2:
	if is_instance_valid(owner_hero) and owner_hero is Node2D:
		return (owner_hero as Node2D).global_position + Vector2(0.0, -28.0)
	return _get_orbit_center()


func _get_orbit_center() -> Vector2:
	if is_instance_valid(anchor_node):
		orbit_center = anchor_node.global_position
	return orbit_center


func _tick_contact_cooldowns(delta: float) -> void:
	for key in _drain_cooldowns.keys():
		_drain_cooldowns[key] = maxf(0.0, float(_drain_cooldowns[key]) - delta)


func _drain_overlapping_enemies() -> void:
	if converge_only or _is_finishing or not monitoring:
		return

	for body in get_overlapping_bodies():
		if not _is_valid_enemy(body):
			continue

		var body_id: int = body.get_instance_id()
		if float(_drain_cooldowns.get(body_id, 0.0)) > 0.0:
			continue

		var drain_amount: int = _get_drain_amount(body)
		if drain_amount <= 0:
			continue

		body.take_damage(drain_amount)
		if body.has_method("apply_slow"):
			body.apply_slow(0.4, 1.2) # 40% slow for 1.2s
		_send_blood_to_pig(body.global_position, drain_amount)
		_drain_cooldowns[body_id] = drain_interval


func _get_drain_amount(enemy: Node) -> int:
	if enemy == null or not is_instance_valid(enemy):
		return 0

	var drain_amount: int = orb_drain_damage
	if "current_hp" in enemy:
		drain_amount = maxi(1, int(round(float(enemy.current_hp) * orb_drain_percent * 0.01)))
	if orb_drain_cap > 0:
		drain_amount = mini(drain_amount, orb_drain_cap)
	return maxi(0, drain_amount)


func _send_blood_to_pig(start_position: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	if is_instance_valid(owner_hero) and owner_hero.has_method("spawn_orb_blood_fly_to_pig"):
		owner_hero.spawn_orb_blood_fly_to_pig(start_position, amount)


func _is_valid_enemy(body: Node) -> bool:
	if not (is_instance_valid(body) and body.is_in_group("enemies") and body.has_method("take_damage")):
		return false
	if "is_dead" in body and bool(body.is_dead):
		return false
	return true


func _finish(triggered_by_skill: bool) -> void:
	if _is_finishing:
		return

	_is_finishing = true
	monitoring = false
	set_physics_process(false)
	if is_instance_valid(_orbit_spark):
		_orbit_spark.visible = false
	_spawn_finish_burst()

	var tween: Tween = create_tween().set_parallel(true)
	if triggered_by_skill:
		tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.12)
		tween.tween_property(self, "modulate:a", 0.0, 0.12)
	else:
		tween.tween_property(self, "scale", Vector2.ZERO, 0.16)
		tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(_finish_and_free)


func _spawn_finish_burst() -> void:
	if _orb_texture == null:
		return

	var burst := Sprite2D.new()
	burst.texture = _orb_texture
	burst.global_position = global_position
	burst.scale = Vector2(0.22, 0.22)
	burst.modulate = Color(1.0, 0.35, 0.35, 0.95)

	var parent := get_parent()
	if parent == null:
		return
	parent.add_child(burst)

	var burst_tween := burst.create_tween().set_parallel(true)
	burst_tween.tween_property(burst, "scale", Vector2(0.8, 0.8), 0.18)
	burst_tween.tween_property(burst, "modulate:a", 0.0, 0.18)
	burst_tween.tween_callback(burst.queue_free)


func _finish_and_free() -> void:
	orb_finished.emit(self)
	queue_free()


func _load_orb_texture() -> Texture2D:
	return load(ORB_TEXTURE_PATH) as Texture2D


func _setup_orbit_spark() -> void:
	_orbit_spark_textures.clear()
	for texture_path in ORBIT_SPARK_TEXTURE_PATHS:
		var texture := load(texture_path) as Texture2D
		if texture != null:
			_orbit_spark_textures.append(texture)

	if _orbit_spark == null:
		_orbit_spark = AnimatedSprite2D.new()
		_orbit_spark.name = "OrbitSpark"
		add_child(_orbit_spark)

	if _orbit_spark_textures.is_empty():
		_orbit_spark.visible = false
		return

	var frames := SpriteFrames.new()
	frames.add_animation("spark")
	frames.set_animation_speed("spark", 10.0)
	frames.set_animation_loop("spark", true)
	for texture in _orbit_spark_textures:
		frames.add_frame("spark", texture)

	_orbit_spark.sprite_frames = frames
	_orbit_spark.animation = "spark"
	_orbit_spark.top_level = true
	_orbit_spark.position = Vector2.ZERO
	var spark_scale := ORB_BASE_SCALE
	if _orb_texture != null and not _orbit_spark_textures.is_empty():
		var orb_size := _orb_texture.get_size()
		var spark_size := _orbit_spark_textures[0].get_size()
		if spark_size.x > 0.0 and spark_size.y > 0.0:
			spark_scale = Vector2(
				ORB_BASE_SCALE.x * (orb_size.x / spark_size.x),
				ORB_BASE_SCALE.y * (orb_size.y / spark_size.y)
			)
	_orbit_spark.scale = spark_scale
	_orbit_spark.z_index = 121
	_orbit_spark.visible = true
	_orbit_spark.global_position = global_position
	_orbit_spark.global_rotation = 0.0
	_orbit_spark.play("spark")
