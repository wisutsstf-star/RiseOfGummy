extends "res://shared/enemies/gummy_bear/scripts/gummy_bear.gd"

# ====================================================
# Gummy Bear Miniboss - Wave 4 Boss
# ====================================================
# - Scale 3x, z_index หน้าสุด
# - โจมตีต่อเนื่อง, เดินดัน hero ได้
# - ไม่แสดงท่าเจ็บจากการโจมตีปกติ
# - แสดงท่าเจ็บเฉพาะเมื่อเสียเลือดครบ 30%
# ====================================================

var hp_thresholds: Array[int] = []
var next_threshold_index: int = 0
var is_playing_threshold_hurt: bool = false

func _ready() -> void:
	super._ready()
	
	xp_reward = 1000
	scale = Vector2(3.0, 3.0)
	z_index = 200
	
	hp_thresholds = [
		int(max_hp * 0.70),
		int(max_hp * 0.40),
		int(max_hp * 0.10)
	]
	next_threshold_index = 0

# Override play_hurt — ไม่แสดงท่าเจ็บจากการโจมตีปกติ
func play_hurt() -> void:
	pass

func take_damage(amount: int, death_anim: String = "die", hit_direction: Vector2 = Vector2.ZERO, is_crit: bool = false, damage_type: String = "physical") -> void:
	var prev_hp := current_hp
	super.take_damage(amount, death_anim, hit_direction, is_crit, damage_type)
	
	if not is_dead and next_threshold_index < hp_thresholds.size():
		var threshold := hp_thresholds[next_threshold_index]
		if current_hp <= threshold and prev_hp > threshold:
			next_threshold_index += 1
			_play_threshold_hurt_animation()

func _play_threshold_hurt_animation() -> void:
	if is_dead or is_playing_threshold_hurt:
		return
	is_playing_threshold_hurt = true
	is_hurt = true
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	await get_tree().create_timer(1.0).timeout
	is_playing_threshold_hurt = false
	is_hurt = false
	if not is_dead and not is_attacking:
		sprite.play("walk")

func _attack_target() -> void:
	if is_dead:
		return
	
	is_attacking = true
	sprite.play("hit")
	
	var attack_target := target
	await get_tree().create_timer(0.08).timeout
	if not is_dead and is_attacking and _can_land_contact_hit(attack_target):
		attack_target.take_damage(damage)
	
	await sprite.animation_finished
	
	is_attacking = false
	
	if is_dead:
		return
	
	_find_target()
	if not is_hurt and not is_playing_threshold_hurt:
		sprite.play("walk")


func _can_land_contact_hit(attack_target: Node2D) -> bool:
	if is_stunned or is_playing_threshold_hurt:
		return false
	if not is_instance_valid(attack_target):
		return false
	if not attack_target.has_method("take_damage"):
		return false
	if "is_dead" in attack_target and bool(attack_target.is_dead):
		return false
	if sprite == null or sprite.animation != "hit":
		return false
	return _get_surface_distance_to_target(attack_target) <= 12.0


func _get_surface_distance_to_target(body: Node2D) -> float:
	if body == null:
		return INF
	var center_distance := global_position.distance_to(body.global_position)
	return max(0.0, center_distance - _get_collision_reach(self) - _get_collision_reach(body))


func _get_collision_reach(body: Node2D) -> float:
	if body == null:
		return 0.0

	for child in body.get_children():
		var collision_shape := child as CollisionShape2D
		if collision_shape == null or collision_shape.shape == null or collision_shape.disabled:
			continue

		var shape_scale := collision_shape.global_scale.abs()
		if collision_shape.shape is CircleShape2D:
			var circle := collision_shape.shape as CircleShape2D
			return circle.radius * max(shape_scale.x, shape_scale.y)
		if collision_shape.shape is RectangleShape2D:
			var rectangle := collision_shape.shape as RectangleShape2D
			return rectangle.size.length() * 0.5 * max(shape_scale.x, shape_scale.y)

	return 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_handle_status_effects(delta)

	if pig_release_idle_timer > 0.0:
		pig_release_idle_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite.sprite_frames.has_animation("idle"):
			if sprite.animation != "idle":
				sprite.play("idle")
		elif sprite.animation != "walk":
			sprite.play("walk")
		return
	
	if is_stunned:
		return
	
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = RETARGET_INTERVAL
		_find_target()
	
	if not target or not is_instance_valid(target):
		is_attacking = false
		_find_target()
		if target:
			sprite.play("walk")
		return
	
	var direction: Vector2 = (target.global_position - global_position).normalized()
	var _dist_to_target := global_position.distance_to(target.global_position)
	
	# Movement - เดินตลอดไม่หยุด (ดัน hero ได้)
	var final_velocity = knockback_velocity
	if not is_attacking:
		final_velocity += direction * move_speed * speed_multiplier
		if sprite.animation != "walk" and not is_attacking:
			sprite.play("walk")
	
	velocity = final_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	
	if abs(direction.x) > 0.1 and not is_attacking:
		sprite.flip_h = direction.x < 0
	
	# Attack Logic
	if attack_timer > 0.0:
		attack_timer -= delta
	
	var is_in_range := _get_surface_distance_to_target(target) <= 12.0
	
	if is_in_range and attack_timer <= 0.0 and not is_attacking and not is_playing_threshold_hurt:
		_attack_target()
		attack_timer = attack_cooldown
