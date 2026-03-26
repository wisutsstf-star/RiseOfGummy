extends BaseProjectile

const DAMAGE_COOLDOWN_META_KEY := "lion_wave_last_damage_time"
var hit_jelly_sound = load("res://characters/lion/assets/audio/jelly swords clashing.wav")
var _last_hit_sound_time: float = -1.0

@export var push_force: float = 300.0
@export var damage_multiplier: float = 2.5
@export var destroy_on_hit: bool = false
@export var slow_pct: float = 0.0
@export var slow_duration: float = 0.0
@export var collision_stun_duration: float = 0.0
@export var collision_stun_radius: float = 42.0
@export var width_multiplier: float = 1.0
@export var travel_distance_multiplier: float = 1.0
@export var travel_speed_multiplier: float = 1.0
@export var movement_drag: float = 0.97
@export var auto_fade_delay: float = -1.0
@export var fade_speed: float = 2.0
@export var lifetime_seconds: float = -1.0
@export var damage_hit_cooldown: float = 0.0
@export var repeat_hit_while_overlapping: bool = false
@export var overlap_hit_interval: float = 0.3
@export var enable_chain_collision_damage: bool = false
@export var chain_collision_check_interval: float = 0.08

# สกิลชนทะลุศัตรู เก็บตัวที่โดนไปแล้ว
var _hit_enemies = []
# Gradual slowdown and fade
var _is_fading: bool = false
var _fade_alpha: float = 1.0
var _active_pushed_enemies: Dictionary = {}
var _chain_collision_pair_times: Dictionary = {}
var _chain_collision_timer: float = 0.0
var _overlap_hit_timer: float = 0.0
var _lifetime_elapsed: float = 0.0


func _ready() -> void:
	super._ready()
	max_distance *= travel_distance_multiplier
	speed *= travel_speed_multiplier
	scale.x *= width_multiplier
	scale.y *= width_multiplier
	if auto_fade_delay >= 0.0:
		_start_auto_fade()
	if repeat_hit_while_overlapping:
		_overlap_hit_timer = overlap_hit_interval


func _start_auto_fade() -> void:
	await get_tree().create_timer(auto_fade_delay).timeout
	if not is_inside_tree() or _is_fading:
		return
	_is_fading = true


func _physics_process(delta: float) -> void:
	if not is_moving:
		return

	if enable_chain_collision_damage:
		_chain_collision_timer -= delta
		if _chain_collision_timer <= 0.0:
			_chain_collision_timer = chain_collision_check_interval
			_process_chain_collisions()

	if repeat_hit_while_overlapping:
		_overlap_hit_timer -= delta
		if _overlap_hit_timer <= 0.0:
			_overlap_hit_timer = overlap_hit_interval
			_process_overlap_hits()

	_lifetime_elapsed += delta
	if lifetime_seconds > 0.0 and _lifetime_elapsed >= lifetime_seconds:
		queue_free()
		return

	speed *= movement_drag

	if _is_fading:
		_fade_alpha -= fade_speed * delta
		_fade_alpha = max(_fade_alpha, 0.0)
		if sprite:
			sprite.modulate.a = _fade_alpha
		if _fade_alpha <= 0.0:
			queue_free()

	position += direction * speed * delta

	if lifetime_seconds <= 0.0 and global_position.distance_to(start_pos) > max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not is_moving:
		return

	if body.is_in_group("enemies") and body not in _hit_enemies:
		_hit_enemies.append(body)
		if destroy_on_hit and not _is_fading:
			_is_fading = true
		_on_hit_enemy(body)


func _on_hit_enemy(body: Node2D) -> void:
	if not _can_apply_damage_to(body):
		return
	_apply_wave_effects(body, true)
	_play_hit_sound()

	if destroy_on_hit:
		_play_hit_effect()


func _apply_wave_effects(body: Node2D, apply_slow_effects: bool) -> void:
	var atk = damage_data["amount"] if damage_data.has("amount") else damage
	atk = int(round(float(atk) * damage_multiplier))
	var crit = damage_data["is_crit"] if damage_data.has("is_crit") else false

	if body.has_method("take_damage"):
		if body.get_method_argument_count("take_damage") >= 4:
			body.take_damage(atk, "death_slash", direction, crit)
		else:
			body.take_damage(atk)
		_record_damage_hit(body)

	if body.has_method("apply_knockback"):
		var applied_push_force := minf(push_force, 160.0) if repeat_hit_while_overlapping else push_force
		body.apply_knockback(direction * applied_push_force)

	if enable_chain_collision_damage and is_instance_valid(body):
		_active_pushed_enemies[body.get_instance_id()] = body

	if collision_stun_duration > 0.0:
		if body.has_method("apply_stun"):
			body.apply_stun(collision_stun_duration)
		_try_apply_collision_stun(body)

	if apply_slow_effects and slow_pct > 0.0 and slow_duration > 0.0 and body.has_method("apply_slow"):
		body.apply_slow(1.0 - slow_pct, slow_duration)


func _can_apply_damage_to(body: Node2D) -> bool:
	if damage_hit_cooldown <= 0.0:
		return true
	if not body.has_meta(DAMAGE_COOLDOWN_META_KEY):
		return true
	var last_hit_time := float(body.get_meta(DAMAGE_COOLDOWN_META_KEY, -INF))
	return _get_time_seconds() - last_hit_time >= damage_hit_cooldown


func _record_damage_hit(body: Node2D) -> void:
	if damage_hit_cooldown <= 0.0:
		return
	body.set_meta(DAMAGE_COOLDOWN_META_KEY, _get_time_seconds())


func _get_time_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _process_overlap_hits() -> void:
	for body in get_overlapping_bodies():
		if not (body is Node2D):
			continue
		if not body.is_in_group("enemies"):
			continue
		if "is_dead" in body and body.is_dead:
			continue
		_on_hit_enemy(body)


func _process_chain_collisions() -> void:
	if _active_pushed_enemies.is_empty():
		return

	var enemies := get_tree().get_nodes_in_group("enemies")
	var active_ids := _active_pushed_enemies.keys()
	for active_id in active_ids:
		var active_enemy: Node2D = _active_pushed_enemies.get(active_id)
		if not is_instance_valid(active_enemy) or ("is_dead" in active_enemy and active_enemy.is_dead):
			_active_pushed_enemies.erase(active_id)
			continue

		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if enemy == active_enemy:
				continue
			if "is_dead" in enemy and enemy.is_dead:
				continue
			if not _are_bodies_colliding(active_enemy, enemy):
				continue

			var pair_key := _make_collision_pair_key(active_enemy, enemy)
			var now := _get_time_seconds()
			var last_pair_time := float(_chain_collision_pair_times.get(pair_key, -INF))
			if now - last_pair_time < chain_collision_check_interval:
				continue

			_chain_collision_pair_times[pair_key] = now
			_apply_wave_effects(enemy, false)


func _are_bodies_colliding(a: Node2D, b: Node2D) -> bool:
	var distance := a.global_position.distance_to(b.global_position)
	return distance <= _get_collision_reach(a) + _get_collision_reach(b)


func _make_collision_pair_key(a: Node2D, b: Node2D) -> String:
	var id_a := a.get_instance_id()
	var id_b := b.get_instance_id()
	return "%s:%s" % [min(id_a, id_b), max(id_a, id_b)]


func _get_collision_reach(body: Node2D) -> float:
	for child in body.get_children():
		var collision_shape := child as CollisionShape2D
		if collision_shape == null or collision_shape.shape == null:
			continue

		var shape_scale := collision_shape.global_scale.abs()
		if collision_shape.shape is CircleShape2D:
			var circle := collision_shape.shape as CircleShape2D
			return circle.radius * max(shape_scale.x, shape_scale.y)
		if collision_shape.shape is RectangleShape2D:
			var rectangle := collision_shape.shape as RectangleShape2D
			return rectangle.size.length() * 0.5 * max(shape_scale.x, shape_scale.y)

	return 24.0


func _try_apply_collision_stun(primary_target: Node2D) -> void:
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(primary_target):
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == primary_target or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("apply_stun"):
			continue
		if primary_target.global_position.distance_to(enemy.global_position) <= collision_stun_radius:
			enemy.apply_stun(collision_stun_duration)
			break


func _play_hit_effect() -> void:
	is_moving = false
	queue_free()

func _play_hit_sound() -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now - _last_hit_sound_time < 0.08: # 80ms throttle
		return
	_last_hit_sound_time = now
	
	var player = AudioStreamPlayer2D.new()
	player.global_position = global_position
	get_tree().current_scene.add_child(player)
	player.stream = hit_jelly_sound
	player.bus = "SFX"
	player.max_distance = 2000
	player.volume_db = -10.0
	player.pitch_scale = 0.75
	player.play()
	player.finished.connect(player.queue_free)
