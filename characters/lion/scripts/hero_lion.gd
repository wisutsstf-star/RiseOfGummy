extends HeroBase

enum MarkerZone {CENTER, LEFT, RIGHT}

# Frames (1-indexed) of attack_ground where the spin deals damage.
const SPIN_ATTACK_FRAMES := [3, 4, 6, 10, 11, 12, 13, 14]
const BASE_SWORD_WAVE_CONFIG := {
	"level": 0,
	"proc_chance": 0.0,
	"damage_multiplier": 1.0,
	"active_damage_multiplier": 1.0,
	"range_multiplier": 1.0,
	"width_multiplier": 1.5,
	"knockback_force": 260.0,
	"slow_pct": 0.0,
	"slow_duration": 0.0,
	"active_charge_time": 0.0,
	"active_pierce": true,
	"collision_stun_duration": 0.0,
	"pull_duration": 0.0,
	"pull_radius": 160.0,
	"pull_force": 650.0,
	"travel_speed_multiplier": 0.6,
}
@export var marker_zone: MarkerZone = MarkerZone.CENTER
@export_range(0.03, 0.05, 0.005) var hit_stop_duration: float = 0.035
@export_range(0.04, 0.07, 0.005) var heavy_hit_stop_duration: float = 0.05
@export_range(0.0, 24.0, 1.0) var contact_engage_buffer: float = 6.0
@export_range(0.0, 1000.0, 10.0) var assist_range: float = 400.0
@export_range(0.0, 1000.0, 10.0) var defense_range: float = 400.0

var shot_frames: Array[int] = [3, 6]
var frames_fired: Array[int] = []
var is_attacking: bool = false
var is_using_skill: bool = false
var skill_projectile_scene: PackedScene
var mini_wave_projectile_scene: PackedScene
var slash_sound = preload("res://characters/lion/assets/audio/Sharp sword.wav")
var ult_sound = preload("res://characters/lion/assets/audio/Sharp energy sword wave.wav")
var hit_jelly_sound = load("res://characters/lion/assets/audio/jelly swords clashing.wav")

func get_hero_id() -> String:
	return "lion"

var _contact_attack_target: Node2D = null
var _walk_target: Node2D = null  # Lock target while walking to prevent jitter

# Tracks which targets were already damaged on the current active frame.
var hit_targets: Dictionary = {}
var _hit_pause_triggered: bool = false
var _swing_hit_count: int = 0
var _active_damage_frame: int = -1
var _normal_wave_proc_checked: bool = false
var _last_wave_frame: int = -1
var _custom_sword_skill_active: bool = false
var _is_berserk_active: bool = false
var _berserk_timer: float = 0.0
var _berserk_wave_timer: float = 0.0
var _berserk_waves_released: int = 0

# The actual melee hit radius for distance-based damage detection.
var _spin_radius: float = 45.0

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var spin_hitbox_shape: CollisionShape2D = $AttackHitbox/SpinHitbox


func _die() -> void:
	super._die()
	is_using_skill = false
	_custom_sword_skill_active = false
	_is_berserk_active = false
	_berserk_timer = 0.0
	_berserk_wave_timer = 0.0
	_berserk_waves_released = 0
	is_attacking = false
	ground_is_attacking = false
	_contact_attack_target = null
	_walk_target = null
	_reset_attack_cycle_state()


func _ready() -> void:
	super._ready()
	_restore_lion_visual_state()
	attack_hitbox.monitoring = false
	spin_hitbox_shape.disabled = true
	_update_attack_visual_direction()
	sprite.frame_changed.connect(_on_frame_changed_for_skill)
	sprite.animation_finished.connect(_on_lion_animation_finished)

	if spin_hitbox_shape and spin_hitbox_shape.shape is CircleShape2D:
		_spin_radius = (spin_hitbox_shape.shape as CircleShape2D).radius

	skill_projectile_scene = load("res://characters/lion/scenes/LionSkillProjectile.tscn")
	mini_wave_projectile_scene = load("res://characters/lion/scenes/LionMiniWaveProjectile.tscn")


func toggle_ground_mode(slot_index: int = 0) -> void:
	set_ground_mode(!is_ground_mode, slot_index)


func set_ground_mode(_enabled: bool, slot_index: int = 0) -> void:
	super.set_ground_mode(_enabled, slot_index)


# ─── Helper: is current attack_ground frame a damage frame? ───
func _is_current_frame_active() -> bool:
	if sprite.animation != "attack_ground":
		return false
	# sprite.frame is 0-indexed; SPIN_ATTACK_FRAMES is 1-indexed
	var f := sprite.frame + 1
	return SPIN_ATTACK_FRAMES.has(f)


func _physics_process(delta: float) -> void:
	if (is_attacking or ground_is_attacking) and not _custom_sword_skill_active and not _is_berserk_active and sprite.animation != "attack" and sprite.animation != "attack_ground":
		is_attacking = false
		ground_is_attacking = false
		is_using_skill = false
		_custom_sword_skill_active = false
		_contact_attack_target = null
		_reset_attack_cycle_state()
		var effective_attack_speed := _get_effective_attack_speed()
		fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0

	# Handle berserk mode updates FIRST
	if _is_berserk_active:
		_update_berserk_mode(delta)
		return

	if is_using_skill:
		return

	# ─── Damage scan: every physics frame, check if we are on a damage frame
	#     and scan enemies by distance. No reliance on Area2D overlap timing. ───
	if ground_is_attacking and _is_current_frame_active():
		var current_frame := sprite.frame + 1
		# If we moved to a new damage frame, clear per-frame hit tracking
		if _active_damage_frame != current_frame:
			hit_targets.clear()
			_active_damage_frame = current_frame
		_do_damage_scan()

	_ground_physics_process(delta)


# ─── Animation frame logic ───
func _on_frame_changed_for_skill() -> void:
	var current_frame = sprite.frame
	
	if sprite.animation == "attack_ground":
		# เล่นเสียงตามจังหวะแกว่งดาบ (อิงจากดาเมจเฟรมแรกๆ ของแต่ละชุด: 2, 5, 9)
		if current_frame == 2 or current_frame == 5 or current_frame == 9:
			_play_slash_sound()
			
		if ground_is_attacking and _is_current_frame_active():
			_try_fire_passive_sword_wave()
		return
		
	if sprite.animation != "attack":
		return
		
	# เล่นเสียงสำหรับท่า attack บนอากาศหรือสกิล
	if current_frame == 2 or current_frame == 5:
		_play_slash_sound()
		
	if _custom_sword_skill_active:
		return
	
	# Speed up wind-up frames for Berserk mode
	if _is_berserk_active and sprite.animation == "attack":
		if current_frame < 3:
			sprite.speed_scale = 3.0
		else:
			sprite.speed_scale = 1.0
			
	if current_frame == 0:
		frames_fired.clear()
	if is_using_skill and current_frame in shot_frames and not current_frame in frames_fired:
		frames_fired.append(current_frame)
		if current_frame == 3:
			if not _is_berserk_active:
				_shoot_skill()


func _find_ground_target_any() -> Node2D:
	var assist_target := _find_assist_target()
	if assist_target != null:
		return assist_target

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var nearest: Node2D = null
	var min_dist: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue
		var dist_to_base := base_position.distance_to(enemy.global_position)
		if dist_to_base > defense_range:
			continue
		if dist_to_base < min_dist:
			min_dist = dist_to_base
			nearest = enemy
	return nearest


func _find_assist_target() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var best_target: Node2D = null
	var best_dist: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue
		if global_position.distance_to(enemy.global_position) > assist_range:
			continue

		var enemy_target = enemy.get("target") if enemy.get("target") != null else null
		if not is_instance_valid(enemy_target):
			continue
		if not enemy_target.is_in_group("heroes"):
			continue
		if enemy_target == self:
			continue
		if "is_dead" in enemy_target and enemy_target.is_dead:
			continue
		if global_position.distance_to(enemy_target.global_position) > assist_range:
			continue

		var dist_to_enemy := global_position.distance_to(enemy.global_position)
		if dist_to_enemy < best_dist:
			best_dist = dist_to_enemy
			best_target = enemy

	return best_target


func _find_lion_ground_target() -> Node2D:
	var assist_target := _find_assist_target()
	if assist_target != null:
		return assist_target

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var nearest: Node2D = null
	var min_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue

		var dist_to_base := base_position.distance_to(enemy.global_position)
		if dist_to_base > defense_range:
			continue

		if dist_to_base < min_dist:
			min_dist = dist_to_base
			nearest = enemy

	return nearest


func _is_outside_defense_range() -> bool:
	return global_position.distance_to(base_position) > defense_range


func _should_return_to_base() -> bool:
	return global_position.distance_to(base_position) > 8.0


func _face_default_direction() -> void:
	match marker_zone:
		MarkerZone.CENTER:
			sprite.flip_h = true
		MarkerZone.LEFT:
			sprite.flip_h = true
		MarkerZone.RIGHT:
			sprite.flip_h = false
	_update_attack_visual_direction()


func _update_facing(target_pos: Vector2) -> void:
	var diff_x: float = target_pos.x - global_position.x
	if abs(diff_x) > 10.0:
		sprite.flip_h = diff_x < 0
	else:
		_face_default_direction()
	_update_attack_visual_direction()


func _on_lion_animation_finished() -> void:
	if sprite.animation == "attack" or sprite.animation == "attack_ground":
		if _is_berserk_active and sprite.animation == "attack":
			sprite.play("attack")
			sprite.frame = 0
			return
		if _custom_sword_skill_active:
			return
		var finished_animation := StringName(sprite.animation)
		is_attacking = false
		ground_is_attacking = false
		_custom_sword_skill_active = false
		_contact_attack_target = null
		_walk_target = null
		_reset_attack_cycle_state()
		if finished_animation != &"attack_ground":
			var effective_attack_speed := _get_effective_attack_speed()
			fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0
		sprite.play("idle")


func use_active_skill() -> bool:
	if is_dead:
		return false
	if not super.use_active_skill():
		return false
	
	var sword_wave_config: Dictionary = _get_lion_sword_wave_config()
	var level: int = int(sword_wave_config.get("level", 0))
	
	# Check if berserk mode (level 5) is active
	if level >= 5:
		# Activate berserk mode instead of normal skill
		_activate_berserk_mode(sword_wave_config)
		return true
	# Normal skill for levels < 5
	_custom_sword_skill_active = true
	call_deferred("_execute_sword_emperor_skill", sword_wave_config)
	return true


func _activate_berserk_mode(sword_wave_config: Dictionary) -> void:
	"""Activate berserk mode for level 5"""
	_is_berserk_active = true
	is_using_skill = true  # Still needed for skill cooldown tracking
	is_attacking = true
	ground_is_attacking = true
	_restore_lion_visual_state()
	velocity = Vector2.ZERO
	_berserk_timer = float(sword_wave_config.get("berserk_duration", 5.0))
	_berserk_wave_timer = 0.0
	_berserk_waves_released = 0
	sprite.play("attack")
	sprite.frame = 0
	fire_timer = 999.0
	frames_fired.clear()


func _update_berserk_mode(delta: float) -> void:
	"""Update berserk mode - release waves periodically"""
	if not _is_berserk_active:
		return
	
	# Update timers
	_berserk_timer -= delta
	_berserk_wave_timer -= delta
	
	# Release wave every interval
	if _berserk_wave_timer <= 0.0:
		var sword_wave_config: Dictionary = _get_lion_sword_wave_config()
		var dir: Vector2 = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		
		# Try to find target for direction
		var target: Node2D = _find_ground_target_any()
		if target and is_instance_valid(target):
			dir = (target.global_position - global_position).normalized()
			_update_facing(target.global_position)
		
		# Spawn berserk wave
		_spawn_berserk_wave(dir, sword_wave_config)
		
		# Reset wave timer
		_berserk_wave_timer = float(sword_wave_config.get("berserk_wave_interval", 0.5))

		_berserk_waves_released += 1
		
		# Check if we've released all waves
		if _berserk_waves_released >= int(sword_wave_config.get("berserk_wave_count", 10)):
			_finish_berserk_mode()
			return
	
	# Check if berserk duration has ended
	if _berserk_timer <= 0.0:
		_finish_berserk_mode()


func _spawn_berserk_wave(dir: Vector2, sword_wave_config: Dictionary) -> void:
	"""Spawn a single wave during berserk mode"""
	if not skill_projectile_scene:
		return
	
	# Add a small random angle offset (-6 to +6 degrees) for Lv.3 (level 5)
	var spread_rad := deg_to_rad(randf_range(-6.0, 6.0))
	var final_dir := dir.rotated(spread_rad)
	
	var proj = skill_projectile_scene.instantiate()
	proj.global_position = global_position
	proj.target_pos = proj.global_position + (final_dir.normalized() * 1000.0)
	proj.damage_data = calculate_damage()
	
	# Use berserk wave damage multiplier
	proj.damage_multiplier = float(sword_wave_config.get("berserk_wave_damage", 1.5)) * 2.0
	proj.push_force = float(sword_wave_config.get("knockback_force", 500.0))  # Heavy push
	proj.destroy_on_hit = false
	proj.slow_pct = float(sword_wave_config.get("slow_pct", 0.50))  # 50% slow
	proj.slow_duration = float(sword_wave_config.get("slow_duration", 2.0))  # 2 seconds
	proj.collision_stun_duration = float(sword_wave_config.get("collision_stun_duration", 1.0))  # 1 second stun
	proj.width_multiplier = float(sword_wave_config.get("width_multiplier", 1.0))
	proj.travel_distance_multiplier = float(sword_wave_config.get("range_multiplier", 1.5))  # +50% range
	proj.travel_speed_multiplier = float(sword_wave_config.get("travel_speed_multiplier", 0.6))
	proj.movement_drag = 1.0
	proj.auto_fade_delay = 1.7
	proj.fade_speed = 4.0
	proj.lifetime_seconds = 2.0
	proj.damage_hit_cooldown = 0.3
	proj.repeat_hit_while_overlapping = true
	proj.overlap_hit_interval = 0.3
	proj.enable_chain_collision_damage = false
	
	get_tree().current_scene.add_child(proj)
	_play_ult_sound()


func _finish_berserk_mode() -> void:
	"""End berserk mode and reset state"""
	_is_berserk_active = false
	_berserk_timer = 0.0
	_berserk_wave_timer = 0.0
	_berserk_waves_released = 0
	_restore_after_custom_skill()
	start_cooldown()  # Important: start cooldown after berserk ends


func _shoot_skill() -> void:
	if not skill_projectile_scene:
		return
	var sword_wave_config: Dictionary = _get_lion_sword_wave_config()

	var proj = skill_projectile_scene.instantiate()
	var spawn_pos = global_position
	var target: Node2D = _find_ground_target_any()
	var dir: Vector2 = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT

	if target and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
		_update_facing(target.global_position)

	proj.global_position = spawn_pos
	proj.target_pos = spawn_pos + (dir * 1000.0)
	proj.damage_data = calculate_damage()
	proj.damage_multiplier = float(sword_wave_config.get("active_damage_multiplier", 1.0))
	proj.push_force = float(sword_wave_config.get("knockback_force", 260.0))
	proj.destroy_on_hit = false
	proj.slow_pct = float(sword_wave_config.get("slow_pct", 0.0))
	proj.slow_duration = float(sword_wave_config.get("slow_duration", 0.0))
	proj.collision_stun_duration = float(sword_wave_config.get("collision_stun_duration", 0.0))
	proj.width_multiplier = float(sword_wave_config.get("width_multiplier", 1.0))
	proj.travel_distance_multiplier = float(sword_wave_config.get("range_multiplier", 1.0))
	proj.travel_speed_multiplier = float(sword_wave_config.get("travel_speed_multiplier", 0.6))
	proj.movement_drag = 1.0
	proj.auto_fade_delay = 0.8
	proj.fade_speed = 4.0
	proj.lifetime_seconds = 1.2

	proj.lifetime_seconds = 1.2

	get_tree().current_scene.add_child(proj)

	is_using_skill = false
	ground_is_attacking = false


func _finish_ground_attack() -> void:
	is_attacking = false
	ground_is_attacking = false
	_contact_attack_target = null
	_walk_target = null
	_reset_attack_cycle_state()
	var effective_attack_speed := _get_effective_attack_speed()
	fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0
	sprite.play("idle")


func _update_attack_visual_direction() -> void:
	var direction := -1.0 if sprite.flip_h else 1.0
	attack_hitbox.scale = Vector2(direction, 1.0)


func _start_attack_cycle() -> void:
	hit_targets.clear()
	_swing_hit_count = 0
	_hit_pause_triggered = false
	_active_damage_frame = -1
	_normal_wave_proc_checked = false
	_last_wave_frame = -1


func _reset_attack_cycle_state() -> void:
	hit_targets.clear()
	_swing_hit_count = 0
	_hit_pause_triggered = false
	_active_damage_frame = -1
	_normal_wave_proc_checked = false
	_last_wave_frame = -1


# ─── The actual damage scan: pure distance-based, no Area2D dependency ───
func _do_damage_scan() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hits_this_pass := 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not (enemy is Node2D):
			continue
		if "is_dead" in enemy and bool(enemy.is_dead):
			continue
		if not enemy.has_method("take_damage"):
			continue

		var target_id := enemy.get_instance_id()
		if hit_targets.has(target_id):
			continue

		var dist := global_position.distance_to(enemy.global_position)
		var enemy_reach := _get_collision_reach(enemy as Node2D)
		if dist <= _spin_radius + enemy_reach:
			hit_targets[target_id] = true

			var dmg_data := calculate_damage()
			var hit_direction: Vector2 = (enemy.global_position - global_position).normalized()
			if hit_direction == Vector2.ZERO:
				hit_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
			enemy.take_damage(dmg_data["amount"], "death_slash", hit_direction, dmg_data["is_crit"])
			_swing_hit_count += 1
			hits_this_pass += 1

	if hits_this_pass > 0:
		_play_jelly_hit_sound()
		if not _hit_pause_triggered:
			_trigger_hit_stop(heavy_hit_stop_duration if _swing_hit_count >= 3 else hit_stop_duration)


func _get_collision_reach(body: Node2D) -> float:
	if body == null:
		return 0.0

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

	return 0.0


func _get_surface_distance_to(body: Node2D) -> float:
	if body == null:
		return INF
	var center_distance := global_position.distance_to(body.global_position)
	return max(0.0, center_distance - _get_collision_reach(self) - _get_collision_reach(body))


func _trigger_hit_stop(duration: float) -> void:
	if _hit_pause_triggered:
		return
	_hit_pause_triggered = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _ground_physics_process(delta: float) -> void:
	if fire_timer > 0.0:
		fire_timer -= delta

	if _contact_attack_target and not is_instance_valid(_contact_attack_target):
		_contact_attack_target = null

	# Clear walk target if it became invalid
	if _walk_target != null and not is_instance_valid(_walk_target):
		_walk_target = null

	# Stay committed to walk target while walking — don't switch targets mid-walk
	if _walk_target != null:
		ground_target = _walk_target
	else:
		ground_target = _find_lion_ground_target()

	var has_priority_target := ground_target != null and is_instance_valid(ground_target)

	if _is_outside_defense_range() and not has_priority_target:
		ground_target = null
		_contact_attack_target = null
		_walk_target = null
		if ground_is_attacking:
			_finish_ground_attack()
		move_back_to_base(move_speed)
		fire_timer = 0.0
		return

	if not has_priority_target:
		_contact_attack_target = null
		_walk_target = null
		if not ground_is_attacking:
			if _should_return_to_base():
				move_back_to_base(move_speed)
			else:
				velocity = Vector2.ZERO
				move_and_slide()
				if sprite.animation != "idle":
					sprite.play("idle")
		fire_timer = 0.0
		return

	var surface_dist := _get_surface_distance_to(ground_target)
	var dir = (ground_target.global_position - global_position).normalized()
	var engage_distance: float = max(0.0, contact_engage_buffer)
	_update_facing(ground_target.global_position)

	if ground_is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if surface_dist > engage_distance:
		# Lock target so we don't switch targets mid-walk
		_walk_target = ground_target
		if sprite.animation != "run_ground":
			sprite.play("run_ground")
		velocity = dir * move_speed
		move_and_slide()

		var touching = get_slide_collision_count() > 0 or surface_dist <= engage_distance + 10.0
		if touching:
			if fire_timer <= 0.0:
				# Reached target and ready to attack — commit
				velocity = Vector2.ZERO
				_contact_attack_target = ground_target
				_walk_target = null
				_ground_attack(ground_target)
			else:
				# Reached target but cooldown not ready — wait in place instead of pushing
				velocity = Vector2.ZERO
				move_and_slide()
				if sprite.animation != "idle":
					sprite.play("idle")
	elif sprite.animation != "idle":
		sprite.play("idle")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if fire_timer <= 0.0:
			_contact_attack_target = ground_target
			_walk_target = null
			_ground_attack(ground_target)


func _ground_attack(target_enemy: Node2D) -> void:
	if not is_instance_valid(target_enemy):
		return
	ground_is_attacking = true
	is_attacking = true
	_reset_attack_cycle_state()
	var effective_attack_speed := _get_effective_attack_speed()
	fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0

	_update_facing(target_enemy.global_position)

	sprite.play("attack_ground")
	sprite.frame = 0


func _play_slash_sound() -> void:
	var player = AudioStreamPlayer2D.new()
	player.global_position = global_position
	get_tree().current_scene.add_child(player)
	player.stream = slash_sound
	player.bus = "SFX"
	player.max_distance = 2000
	player.volume_db = -4.0 # ลดความบาดหูลงอีก
	player.pitch_scale = 0.85 # ทำให้ทุ้มขึ้น
	player.play()
	player.finished.connect(player.queue_free)


func _play_ult_sound() -> void:
	var player = AudioStreamPlayer2D.new()
	player.global_position = global_position
	get_tree().current_scene.add_child(player)
	player.stream = ult_sound
	player.bus = "SFX"
	player.max_distance = 2500
	player.volume_db = -2.0 # ลดความบาดหูลงจาก 0.0
	player.pitch_scale = 0.8
	player.play()
	player.finished.connect(player.queue_free)


func _play_jelly_hit_sound() -> void:
	var player = AudioStreamPlayer2D.new()
	player.global_position = global_position
	get_tree().current_scene.add_child(player)
	player.stream = hit_jelly_sound
	player.bus = "SFX"
	player.max_distance = 1800
	player.volume_db = -10.0 # ลดความดังลงจาก 0.0
	player.pitch_scale = 0.75 # ทำให้ทุ้มขึ้นอีก
	player.play()
	player.finished.connect(player.queue_free)


func _try_fire_passive_sword_wave() -> void:
	if is_using_skill:
		return
	# กัน fire ซ้ำเฟรมเดิม
	var current_frame := sprite.frame
	if current_frame == _last_wave_frame:
		return
	_last_wave_frame = current_frame

	var sword_wave_config: Dictionary = _get_lion_sword_wave_config()
	var proc_chance: float = float(sword_wave_config.get("proc_chance", 0.0))
	if proc_chance <= 0.0:
		return
	# Randomly spawn around Lion
	if randf() > proc_chance:
		return
	var random_angle := randf() * TAU
	var dir := Vector2(cos(random_angle), sin(random_angle))
	_spawn_sword_wave(dir, false, sword_wave_config)


func _execute_sword_emperor_skill(sword_wave_config: Dictionary) -> void:
	is_using_skill = true
	is_attacking = true
	ground_is_attacking = true
	_restore_lion_visual_state()
	velocity = Vector2.ZERO
	frames_fired.clear()
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	fire_timer = 999.0
	await _perform_sword_wave_charge(sword_wave_config)
	if not is_inside_tree() or is_dead:
		_restore_after_custom_skill()
		return
	var target: Node2D = _find_ground_target_any()
	var dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	if is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
		_update_facing(target.global_position)
	if float(sword_wave_config.get("pull_duration", 0.0)) > 0.0:
		await _perform_sword_wave_pull(sword_wave_config)
	if not is_inside_tree() or is_dead:
		_restore_after_custom_skill()
		return
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		sprite.frame = 0
		await _wait_for_sword_skill_release_frame()

		if not is_inside_tree() or is_dead:
			_restore_after_custom_skill()
			return
	_spawn_sword_wave(dir, true, sword_wave_config)
	
	# Handle Lv.2 (code level 4) which launches 2 waves
	if int(sword_wave_config.get("level", 0)) == 4:
		await get_tree().create_timer(0.3).timeout
		if is_inside_tree() and not is_dead:
			var second_target = _find_ground_target_any()
			var second_dir = dir
			if is_instance_valid(second_target):
				second_dir = (second_target.global_position - global_position).normalized()
				_update_facing(second_target.global_position)
			_spawn_sword_wave(second_dir, true, sword_wave_config)

	start_cooldown()
	_restore_after_custom_skill()


func _perform_sword_wave_charge(sword_wave_config: Dictionary) -> void:
	var charge_time: float = float(sword_wave_config.get("active_charge_time", 0.0))
	if charge_time <= 0.0:
		return
	await get_tree().create_timer(charge_time).timeout


func _wait_for_sword_skill_release_frame() -> void:
	while is_inside_tree() and is_instance_valid(sprite) and sprite.animation == "attack" and sprite.frame < 3:
		await get_tree().process_frame


func _perform_sword_wave_pull(sword_wave_config: Dictionary) -> void:
	var pull_duration: float = float(sword_wave_config.get("pull_duration", 0.0))
	if pull_duration <= 0.0:
		return
	var pull_radius: float = float(sword_wave_config.get("pull_radius", 160.0))
	var pull_force: float = float(sword_wave_config.get("pull_force", 650.0))
	var elapsed := 0.0
	while elapsed < pull_duration:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy):
				continue
			var dist := global_position.distance_to(enemy.global_position)
			if dist > pull_radius or not enemy.has_method("apply_knockback"):
				continue
			var pull_dir: Vector2 = (global_position - enemy.global_position).normalized()
			enemy.apply_knockback(pull_dir * pull_force)
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _spawn_sword_wave(dir: Vector2, is_active_skill: bool, sword_wave_config: Dictionary) -> void:
	var proj_scene: PackedScene = skill_projectile_scene if is_active_skill else mini_wave_projectile_scene
	if not proj_scene:
		return
	var proj = proj_scene.instantiate()
	var spawn_offset := 22.0 if is_active_skill else 40.0
	proj.global_position = global_position + (dir.normalized() * spawn_offset)
	proj.target_pos = proj.global_position + (dir.normalized() * 1000.0)
	proj.damage_data = calculate_damage()

	if is_active_skill:
		proj.damage_multiplier = float(sword_wave_config.get("active_damage_multiplier", 1.0))
		proj.destroy_on_hit = false
		proj.collision_stun_duration = float(sword_wave_config.get("collision_stun_duration", 0.0))
		proj.travel_distance_multiplier = float(sword_wave_config.get("range_multiplier", 1.0))
		proj.push_force = float(sword_wave_config.get("knockback_force", 260.0))
		proj.slow_pct = float(sword_wave_config.get("slow_pct", 0.0))
		proj.slow_duration = float(sword_wave_config.get("slow_duration", 0.0))
		proj.movement_drag = 1.0
		proj.auto_fade_delay = 0.8
		proj.fade_speed = 4.0
		proj.lifetime_seconds = 1.2
		proj.damage_hit_cooldown = 0.3
	else:
		proj.damage_multiplier = float(sword_wave_config.get("damage_multiplier", 1.0))
		proj.destroy_on_hit = false
		proj.collision_stun_duration = 0.0
		proj.travel_distance_multiplier = minf(1.0, float(sword_wave_config.get("range_multiplier", 1.0)))
		proj.push_force = 0.0
		proj.slow_pct = 0.0
		proj.slow_duration = 0.0

	proj.width_multiplier = float(sword_wave_config.get("width_multiplier", 1.0))
	proj.travel_speed_multiplier = float(sword_wave_config.get("travel_speed_multiplier", 0.6))
	get_tree().current_scene.add_child(proj)
	
	if is_active_skill:
		_play_ult_sound()


func _get_lion_sword_wave_config() -> Dictionary:
	var modifier_state = _get_card_modifier_state()
	if modifier_state != null and bool(modifier_state.lion_sword_wave_enabled):
		var config := {
			"level": int(modifier_state.lion_sword_wave_level),
			"proc_chance": float(modifier_state.lion_sword_wave_proc_chance),
			"damage_multiplier": float(modifier_state.lion_sword_wave_damage_multiplier),
			"active_damage_multiplier": float(modifier_state.lion_sword_wave_active_damage_multiplier),
			"range_multiplier": float(modifier_state.lion_sword_wave_range_multiplier),
			"width_multiplier": float(modifier_state.lion_sword_wave_width_multiplier),
			"knockback_force": float(modifier_state.lion_sword_wave_knockback_force),
			"slow_pct": float(modifier_state.lion_sword_wave_slow_pct),
			"slow_duration": float(modifier_state.lion_sword_wave_slow_duration),
			"active_charge_time": float(modifier_state.lion_sword_wave_active_charge_time),
			"active_pierce": bool(modifier_state.lion_sword_wave_active_pierce),
			"collision_stun_duration": float(modifier_state.lion_sword_wave_collision_stun_duration),
			"pull_duration": float(modifier_state.lion_sword_wave_pull_duration),
			"pull_radius": float(modifier_state.lion_sword_wave_pull_radius),
			"pull_force": float(modifier_state.lion_sword_wave_pull_force),
			"travel_speed_multiplier": float(modifier_state.lion_sword_wave_travel_speed_multiplier) if "lion_sword_wave_travel_speed_multiplier" in modifier_state else 0.6,
		}
		# Include berserk values when level >= 5
		if int(modifier_state.lion_sword_wave_level) >= 5:
			config["berserk_duration"] = float(modifier_state.berserk_duration)
			config["berserk_wave_interval"] = float(modifier_state.berserk_wave_interval)
			config["berserk_wave_count"] = int(modifier_state.berserk_wave_count)
			config["berserk_wave_damage"] = float(modifier_state.berserk_wave_damage)
			config["damage_reduction"] = float(modifier_state.damage_reduction)
		return config
	return BASE_SWORD_WAVE_CONFIG.duplicate(true)


func _restore_after_custom_skill() -> void:
	is_using_skill = false
	is_attacking = false
	ground_is_attacking = false
	_custom_sword_skill_active = false
	_contact_attack_target = null
	_reset_attack_cycle_state()
	fire_timer = 0.0
	_restore_lion_visual_state()
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _restore_lion_visual_state() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.visible = true
	var current_modulate := sprite.modulate
	current_modulate.a = 1.0
	sprite.modulate = current_modulate
	sprite.speed_scale = 1.0


# OVERRIDE: Take 30% less damage when berserk is active
func take_damage(amount: int, damage_type: String = "physical"):
	# Reduce damage by 30% when berserk is active
	var final_amount = amount
	if _is_berserk_active:
		var reduction = int(amount * 0.3)  # 30% reduction
		final_amount = max(1, amount - reduction)  # Ensure at least 1 damage
	
	# Call parent method with reduced amount
	super.take_damage(final_amount, damage_type)
