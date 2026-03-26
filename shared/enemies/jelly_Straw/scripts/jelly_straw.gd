extends "res://scripts/enemy.gd"

@export var projectile_scene: PackedScene = preload("res://shared/enemies/jelly_Straw/scenes/jelly_straw_projectile.tscn")
@export var attack_range: float = 250.0
@export var retreat_range: float = 105.0
@export var projectile_spawn_offset: Vector2 = Vector2(18.0, -8.0)


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	if is_dead:
		if is_in_pig_suction:
			_keep_suction_animation_alive()
		return

	_handle_status_effects(delta)

	if pig_release_idle_timer > 0.0:
		pig_release_idle_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite.sprite_frames.has_animation("idle"):
			if sprite.animation != "idle":
				sprite.play("idle")
		elif sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
			sprite.play("walk")
		return

	if is_in_pig_suction:
		_keep_suction_animation_alive()

	if is_stunned:
		return

	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = RETARGET_INTERVAL
		_find_target()

	if not target or not is_instance_valid(target):
		is_attacking = false
		_find_target()
		if target and not is_hurt:
			sprite.play("walk")
		return

	var to_target: Vector2 = target.global_position - global_position
	var direction: Vector2 = to_target.normalized()
	var distance_to_target: float = to_target.length()
	var final_velocity: Vector2 = knockback_velocity
	var should_retreat: bool = target.is_in_group("heroes") and distance_to_target < retreat_range
	var should_advance: bool = distance_to_target > attack_range

	if not is_attacking and not is_hurt:
		if should_advance:
			final_velocity += direction * move_speed * speed_multiplier
			if sprite.animation != "walk":
				sprite.play("walk")
		elif should_retreat:
			final_velocity -= direction * move_speed * 0.7 * speed_multiplier
			if sprite.animation != "walk":
				sprite.play("walk")
		elif sprite.animation == "walk":
			sprite.stop()
			sprite.frame = 0

	velocity = final_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)

	if abs(direction.x) > 0.1 and not is_attacking and not is_hurt:
		sprite.flip_h = direction.x < 0

	if attack_timer > 0.0:
		attack_timer -= delta

	if distance_to_target <= attack_range and attack_timer <= 0.0 and not is_attacking and not is_hurt:
		_attack_target()
		attack_timer = attack_cooldown


func _attack_target() -> void:
	if is_dead or projectile_scene == null:
		return

	is_attacking = true
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")

	await get_tree().create_timer(0.15).timeout

	if is_dead or not is_attacking:
		return

	_spawn_projectile()

	if sprite.sprite_frames.has_animation("hit"):
		await sprite.animation_finished

	is_attacking = false

	if is_dead:
		return

	_find_target()
	if not is_hurt:
		sprite.play("walk")


func _spawn_projectile() -> void:
	if projectile_scene == null or not target or not is_instance_valid(target):
		return

	var projectile: Node2D = projectile_scene.instantiate()
	var offset := projectile_spawn_offset
	offset.x = offset.x * (-1.0 if sprite.flip_h else 1.0)
	projectile.global_position = global_position + offset

	if "target_pos" in projectile:
		projectile.target_pos = target.global_position
	if "direction" in projectile:
		projectile.direction = (target.global_position - projectile.global_position).normalized()
	if "damage" in projectile:
		projectile.damage = damage

	get_tree().current_scene.add_child(projectile)


func _keep_suction_animation_alive() -> void:
	if sprite.animation == "hurt" and not sprite.is_playing():
		sprite.frame = 0
		sprite.play("hurt")
	elif sprite.animation == "walk" and not sprite.is_playing():
		sprite.frame = 0
		sprite.play("walk")
