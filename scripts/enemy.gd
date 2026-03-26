extends CharacterBody2D

signal died(enemy: Node2D)

# ── Core Combat Stats (ค่าสู้หลัก) ──────────────────────────────────────
@export_group("Core Combat Stats")
## HP – พลังชีวิต
@export var max_hp: int = 50
## ATK ค่าเดียว – ประเภทดาเมจระบุตอนโจมตี ("physical" / "magic" / "true")
@export var damage: int = 10
## DEF – ป้องกันกายภาพ
@export var defense: int = 0
## MDEF – ป้องกันเวท
@export var mdef: int = 0

# ── Secondary Combat Stats (ค่าสู้รอง) ──────────────────────────────────
@export_group("Secondary Combat Stats")
## Move Speed – ความเร็วเคลื่อนที่
@export var move_speed: float = 100.0
## Dodge – โอกาสหลบ (0.0–1.0)
@export var dodge: float = 0.0
## Tenacity – ต้านสถานะ (0.0–1.0)
@export var tenacity: float = 0.0

# ── Enemy Config ──────────────────────────────────────────────────────────
@export_group("Enemy Config")
@export var attack_cooldown: float = 1.0 # Seconds between attacks
@export var use_attack_windup_when_waiting: bool = false
@export var xp_reward: int = 10

@export_group("")

var attack_timer: float = 0.0
var current_hp: int
var target: Node2D = null
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 0.5


# Status Effects
var knockback_velocity: Vector2 = Vector2.ZERO
var speed_multiplier: float = 1.0
var slow_duration: float = 0.0
var slow_multiplier: float = 1.0

var _death_tween: Tween = null
var _fade_tween: Tween = null
var _is_death_exploding: bool = false

# Restricted zone check cache
var _wave_manager: Node = null

# Bleed
var bleed_duration: float = 0.0
var bleed_damage_timer: float = 0.0
var is_bleeding: bool = false

# Burn
var burn_duration: float = 0.0
var burn_damage_timer: float = 0.0
var is_burning: bool = false

# Stun
var stun_duration: float = 0.0
var is_stunned: bool = false

# Blue Fire
var blue_fire_duration: float = 0.0
var is_blue_fire: bool = false

var is_in_pig_suction: bool = false
var spawn_delay: float = 0.0
var pig_suction_owner: Node = null # the BloodPigSkill node that owns this enemy
var pig_release_idle_timer: float = 0.0
var _pending_suction_death: bool = false # killed while in suction → wait for finalize

const RESTRICTED_TOP_ZONE_MARGIN := 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _find_target() -> void:
	# Priority 1: Find nearest living hero
	var heroes := get_tree().get_nodes_in_group("heroes")
	var best_hero: Node2D = null
	var best_dist: float = INF
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		# ฮีโร่ที่มี is_dead flag (ถ้ามี) → ข้าม
		if "is_dead" in hero and hero.is_dead:
			continue
		var d := global_position.distance_to(hero.global_position)
		if d < best_dist:
			best_dist = d
			best_hero = hero

	if best_hero:
		target = best_hero
		return

	# Priority 2: Fall back to crystal heart
	target = get_tree().get_first_node_in_group("crystal_heart")


func _ready() -> void:
	current_hp = max_hp
	z_index = 75 # เรียงอยู่ชั้นเหนือกว่าสกิลหมู (50) และอยู่ล่างฮีโร่ตอนลงสนาม (100)
	add_to_group("enemies")
	_wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if _wave_manager == null and get_tree().current_scene != null:
		_wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	_find_target()
	_resolve_restricted_top_zone_presence()
	sprite.play("walk")
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if is_in_pig_suction or (is_dead and sprite.animation in ["hurt", "walk"]):
		# Force loop if still in suction
		if sprite.animation == "hurt":
			sprite.play("hurt")
		elif sprite.animation == "walk":
			sprite.play("walk")


func _physics_process(delta: float) -> void:
	if spawn_delay > 0.0:
		spawn_delay -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_dead:
		if is_in_pig_suction:
			if sprite.animation == "hurt" and not sprite.is_playing():
				sprite.frame = 0
				sprite.play("hurt")
			elif sprite.animation == "walk" and not sprite.is_playing():
				sprite.frame = 0
				sprite.play("walk")
		return

	_resolve_restricted_top_zone_presence()
	
	_handle_status_effects(delta)

	if pig_release_idle_timer > 0.0:
		pig_release_idle_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite != null and sprite.sprite_frames != null:
			if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
				sprite.play("idle")
			elif not sprite.sprite_frames.has_animation("idle") and sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
				sprite.play("walk")
		return
	
	if is_in_pig_suction:
		if sprite.animation == "hurt" and not sprite.is_playing():
			sprite.frame = 0
			sprite.play("hurt")
		elif sprite.animation == "walk" and not sprite.is_playing():
			sprite.frame = 0
			sprite.play("walk")
			
	if is_stunned:
		return # Skip movement and attack if stunned
	
	# Re-evaluate target periodically
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = RETARGET_INTERVAL
		_find_target()
	
	if not target or not is_instance_valid(target):
		# เป้าหมายหายไป → reset สถานะทั้งหมดแล้วหาใหม่
		is_attacking = false
		_find_target()
		if target and not is_hurt:
			sprite.play("walk")
		return

	
	# Movement Logic
	var direction: Vector2 = (target.global_position - global_position).normalized()

	# Combine normal movement with knockback
	var final_velocity = knockback_velocity

	var dist_to_target = global_position.distance_to(target.global_position)
	var is_in_range_for_move = dist_to_target <= 80.0

	if not is_attacking and not is_hurt and not is_in_range_for_move:
		# Check if moving would enter restricted top zone
		var proposed_movement = direction * move_speed * speed_multiplier
		var proposed_position = global_position + proposed_movement
		if _is_in_restricted_top_zone(proposed_position):
			# Block movement into restricted zone - push downward
			if proposed_position.y < global_position.y:
				proposed_position.y = global_position.y
				final_velocity = Vector2.ZERO
			else:
				final_velocity += direction * move_speed * speed_multiplier
		else:
			final_velocity += direction * move_speed * speed_multiplier
		
	velocity = final_velocity
	move_and_slide()
	
	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	
	# Sprite direction
	
	var is_in_range = dist_to_target <= 80.0
	# ถ้าชนกับอะไรบางอย่างก่อนถึงระยะ (เช่นกรอบชนใหญ่กว่า) ก็ถือว่าถึงประชิดแล้ว
	if get_slide_collision_count() > 0:
		is_in_range = true

	if abs(direction.x) > 0.1 and not is_attacking and not is_hurt and not is_in_range:
		sprite.flip_h = direction.x < 0
	
	# Attack Logic
	if attack_timer > 0.0:
		attack_timer -= delta
		
	if is_in_range:
		if not is_attacking and not is_hurt:
			if use_attack_windup_when_waiting:
				if sprite.animation != "hit" or sprite.is_playing() or sprite.frame != 0:
					sprite.play("hit")
					sprite.pause()
					sprite.frame = 0
			elif sprite.animation == "walk":
				if sprite.sprite_frames.has_animation("idle"):
					sprite.play("idle")
				else:
					sprite.stop()
			
		if attack_timer <= 0.0 and not is_attacking and not is_hurt:
			_attack_target()
			attack_timer = attack_cooldown


func _handle_status_effects(delta: float) -> void:
	speed_multiplier = 1.0 # Reset every frame, then re-apply modifiers
	
	# Bleed
	if is_bleeding:
		bleed_duration -= delta
		speed_multiplier *= 0.5 # Slow by 50%
		
		bleed_damage_timer += delta
		if bleed_damage_timer >= 1.0:
			bleed_damage_timer = 0.0
			take_damage(5, "die")
			
		if bleed_duration <= 0:
			is_bleeding = false
			sprite.modulate = Color.WHITE

	# Burn
	if is_burning:
		burn_duration -= delta
		
		burn_damage_timer += delta
		if burn_damage_timer >= 1.0:
			burn_damage_timer = 0.0
			take_damage(2, "die")
		
		if burn_duration <= 0:
			is_burning = false
			sprite.modulate = Color.WHITE
			
	# Stun
	if is_stunned:
		stun_duration -= delta
		if stun_duration <= 0:
			is_stunned = false

	if slow_duration > 0.0:
		slow_duration -= delta
		speed_multiplier *= slow_multiplier
		if slow_duration <= 0.0:
			slow_duration = 0.0
			slow_multiplier = 1.0
			
	# Blue Fire
	if is_blue_fire:
		blue_fire_duration -= delta
		speed_multiplier *= 0.7 # Slow 30%? (Prompt just said "Slow")
		
		if blue_fire_duration <= 0:
			is_blue_fire = false

func apply_knockback(force: Vector2) -> void:
	# Check if knockback would push enemy into restricted top zone
	var proposed_position = global_position + force
	if _is_in_restricted_top_zone(proposed_position):
		# Block knockback into restricted zone - redirect downward
		if force.y < 0:
			knockback_velocity = Vector2(force.x, 0)
		else:
			knockback_velocity = force
	else:
		knockback_velocity = force


func apply_bleed(duration: float) -> void:
	if is_dead: return
	is_bleeding = true
	bleed_duration = duration # Refresh or Set
	sprite.modulate = Color(1.0, 0.5, 0.5)

func apply_burn(duration: float) -> void:
	if is_dead: return
	is_burning = true
	burn_duration = duration # Logic: "Resets timer to 5s if applied again"
	sprite.modulate = Color(1.0, 0.6, 0.2) # Orange tint

func apply_stun(duration: float) -> void:
	if is_dead: return
	is_stunned = true
	stun_duration = max(stun_duration, duration) # Extend if already stunned? Or just set? Prompt implies simple apply. I'll use simple set or max.


func apply_slow(multiplier: float, duration: float) -> void:
	if is_dead:
		return
	slow_multiplier = min(slow_multiplier, clampf(multiplier, 0.05, 1.0))
	slow_duration = max(slow_duration, duration)

func apply_blue_fire(duration: float) -> void:
	if is_dead: return
	is_blue_fire = true
	blue_fire_duration = duration
	# Maybe blue tint?
	sprite.modulate = Color(0.5, 0.5, 1.0)

# Check if enemy is in restricted top zone (via WaveManager)
func _is_in_restricted_top_zone(pos: Vector2) -> bool:
	if _wave_manager == null or not _wave_manager.has_method("is_in_restricted_top_zone"):
		return false
	return bool(_wave_manager.is_in_restricted_top_zone(pos))


func _clamp_below_restricted_top_zone(pos: Vector2, margin: float = 0.0) -> Vector2:
	if _wave_manager != null and _wave_manager.has_method("clamp_below_restricted_top_zone"):
		var clamped_pos = _wave_manager.clamp_below_restricted_top_zone(pos, margin)
		if clamped_pos is Vector2:
			return clamped_pos

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var min_y := viewport_rect.position.y + (viewport_rect.size.y * 0.2) + margin
	return Vector2(pos.x, maxf(pos.y, min_y))


func _resolve_restricted_top_zone_presence() -> void:
	if not _is_in_restricted_top_zone(global_position):
		return

	global_position = _clamp_below_restricted_top_zone(global_position, RESTRICTED_TOP_ZONE_MARGIN)
	velocity = Vector2.ZERO
	if knockback_velocity.y < 0.0:
		knockback_velocity.y = 0.0

func play_hurt() -> void:
	if is_dead or is_hurt:
		return
	is_hurt = true
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	await get_tree().create_timer(0.3).timeout
	is_hurt = false
	if not is_dead and not is_attacking:
		sprite.play("walk")


func release_from_pig_suction() -> void:
	if is_dead:
		return

	is_in_pig_suction = false
	is_hurt = false
	is_attacking = false
	pig_release_idle_timer = 0.45

	if sprite == null or sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	elif sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")


# Called when enemy hp hits 0 while captured in pig suction: freeze in hurt anim, don't die yet
func _enter_suction_death_hold() -> void:
	is_dead = true
	_pending_suction_death = true
	died.emit(self )
	remove_from_group("enemies")
	add_to_group("corpses")
	# Disable collision but stay in scene; physics handled by pig pull
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	# Play hurt loop
	if sprite != null and sprite.sprite_frames != null:
		if sprite.sprite_frames.has_animation("hurt"):
			sprite.play("hurt")
		elif sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")


# Called by BloodPigSkill when the skill ends: flings everyone in suction (dead or alive)
func finalize_pig_suction_death(hit_direction: Vector2 = Vector2.ZERO) -> void:
	if not is_dead and not _pending_suction_death:
		# Enemy survived skill damage — release to continue walking normally
		release_from_pig_suction()
		return

	# Enemy died from tick damage (hp hit 0 while sucked) — play fling death anim
	_pending_suction_death = false
	is_in_pig_suction = false
	pig_suction_owner = null
	is_hurt = false
	is_attacking = false
	pig_release_idle_timer = 0.0
	set_physics_process(false)
	velocity = Vector2.ZERO

	_die("death_explode", hit_direction)

func take_damage(amount: int, death_anim: String = "die", hit_direction: Vector2 = Vector2.ZERO, is_crit: bool = false, damage_type: String = "physical") -> void:
	# Always spawn damage number, even if already dead (for multi-hit attacks like Lion)
	_spawn_damage_number(amount, is_crit)
	
	if is_dead:
		if death_anim == "death_explode":
			# Allow pig explosion to fling dead-but-sucked enemies
			_die(death_anim, hit_direction)
		elif death_anim == "suction_hold" or is_in_pig_suction:
			# Still in suction → keep hurt anim looping
			if sprite.sprite_frames.has_animation("hurt"):
				sprite.play("hurt")
			elif sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		return

	# Flash Effect (before hp reduction so we always flash)
	var tween: Tween
	if sprite != null:
		tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.1)
		var target_color = Color.WHITE
		if is_bleeding: target_color = Color(1.0, 0.5, 0.5)
		elif is_burning: target_color = Color(1.0, 0.6, 0.2)
		elif is_blue_fire: target_color = Color(0.5, 0.5, 1.0)
		tween.tween_property(sprite, "modulate", target_color, 0.1)

	# Hurt animation
	if is_in_pig_suction or death_anim == "suction_hold":
		is_hurt = true
		if sprite.sprite_frames.has_animation("hurt"):
			if sprite.animation != "hurt" or not sprite.is_playing():
				sprite.frame = 0
				sprite.play("hurt")
		elif sprite.sprite_frames.has_animation("walk"):
			if sprite.animation != "walk" or not sprite.is_playing():
				sprite.frame = 0
				sprite.play("walk")
	else:
		# Apply knockback for direct explosion hits that survive
		if death_anim == "death_explode":
			var kdir = hit_direction.normalized()
			if kdir == Vector2.ZERO:
				kdir = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT
			apply_knockback(kdir * 300.0)
		play_hurt()
	
	# Dodge ─ กายภาพเท่านั้นที่หลบได้
	if damage_type == "physical" and randf() < dodge:
		_spawn_damage_number(0, false) # แสดง "miss"
		return
	# คำนวณ mitigation ตาม damage_type
	var actual_damage: int
	match damage_type:
		"magic":
			actual_damage = max(1, int(float(amount) * (100.0 / (100.0 + max(0, mdef)))))
		"true":
			actual_damage = max(1, amount)
		_: # "physical"
			actual_damage = max(1, int(float(amount) * (100.0 / (100.0 + max(0, defense)))))
	current_hp -= actual_damage
	
	if current_hp <= 0:
		if is_blue_fire:
			pass # Blue Fire death effect placeholder
		
		# If in pig suction → enter zombie hold state, wait for finalize
		if is_in_pig_suction and death_anim != "death_explode":
			_enter_suction_death_hold()
		else:
			_die(death_anim, hit_direction)


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	if _is_in_restricted_top_zone(global_position):
		return

	var damage_num_scene = preload("res://shared/ui/scenes/damage_number.tscn")
	if damage_num_scene:
		var damage_num = damage_num_scene.instantiate()
		damage_num.amount = amount
		damage_num.is_crit = is_crit
		damage_num.global_position = global_position
		get_tree().current_scene.add_child(damage_num)


func _die(anim_name: String, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if is_in_pig_suction and anim_name != "death_explode":
		anim_name = "suction_hold"

	if not is_dead: # Prevent multiple emits if called again for explode
		is_dead = true
		died.emit(self )

		if not is_in_pig_suction:
			set_physics_process(false)
		remove_from_group("enemies")
		add_to_group("corpses")
		$CollisionShape2D.set_deferred("disabled", true)

	if anim_name == "death_explode" and _is_death_exploding:
		return

	if anim_name == "death_explode":
		_is_death_exploding = true
		if _death_tween and _death_tween.is_valid():
			_death_tween.kill()
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()

	if anim_name == "suction_hold" or (is_in_pig_suction and anim_name != "death_explode"):
		if sprite.sprite_frames.has_animation("hurt"):
			if sprite.animation != "hurt" or not sprite.is_playing():
				sprite.frame = 0
				sprite.play("hurt")
		elif sprite.sprite_frames.has_animation("walk"):
			if sprite.animation != "walk" or not sprite.is_playing():
				sprite.frame = 0
				sprite.play("walk")
		return

	if anim_name == "death_explode":
		# Check if enemy is in restricted top zone - if so, no knockback animation
		if _is_in_restricted_top_zone(global_position):
			# In restricted zone: show skill effect but no knockback death
			# Just fade out without the explosion animation
			if sprite != null:
				sprite.modulate.a = 1.0
			_fade_tween = create_tween()
			_fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			await _fade_tween.finished
			queue_free()
			return

		var knockback_dir = hit_direction.normalized()
		if knockback_dir == Vector2.ZERO:
			if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
				knockback_dir = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT
			else:
				knockback_dir = Vector2.RIGHT

		var knockback_distance := 65.0
		var rise_height := 45.0
		var drop_height := 5.0
		var rise_duration := 0.35
		var fall_duration := 0.45

		# Smooth arc: rise up then soft fall
		var start_pos = global_position
		var peak_pos = start_pos + knockback_dir * (knockback_distance * 0.5) + Vector2.UP * rise_height
		var end_pos = start_pos + knockback_dir * knockback_distance + Vector2.DOWN * drop_height

		# Position tween (Movement sequence)
		var pos_tween = create_tween().set_parallel(false)
		pos_tween.tween_property(self, "global_position", peak_pos, rise_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pos_tween.tween_property(self, "global_position", end_pos, fall_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var base_scale := self.scale
		# Scale sequence (Parallel to rotation, but in its own sequence)
		var scale_tween = create_tween().set_parallel(false)
		scale_tween.tween_property(self, "scale", base_scale * Vector2(1.2, 0.8), rise_duration * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", base_scale * Vector2(0.85, 1.15), rise_duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		scale_tween.tween_property(self, "scale", base_scale, fall_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if sprite != null and sprite.sprite_frames != null:
			if sprite.sprite_frames.has_animation("explode"):
				sprite.play("explode")
			elif sprite.sprite_frames.has_animation("die"):
				sprite.play("die")
				sprite.pause()
				sprite.frame = sprite.sprite_frames.get_frame_count("die") - 1
			elif sprite.sprite_frames.has_animation("hurt"):
				sprite.play("hurt")
				sprite.pause()

		if sprite != null:
			sprite.modulate.a = 1.0

		await pos_tween.finished

		if sprite != null:
			_fade_tween = create_tween().set_parallel(false)
			_fade_tween.tween_interval(rise_duration * 0.3)
			_fade_tween.tween_property(sprite, "modulate:a", 0.0, (rise_duration * 0.7) + fall_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await _fade_tween.finished
			
		queue_free()
		return
		
	elif anim_name == "death_slash" and sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("slash"):
		# Lion slash death
		sprite.play("slash")
		await sprite.animation_finished
		
		# Stay on last frame then fade out
		await get_tree().create_timer(0.5).timeout
		if _is_death_exploding: return
		_fade_tween = create_tween()
		_fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await _fade_tween.finished

	elif sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		await sprite.animation_finished
		
		# Stay on last frame then fade out
		await get_tree().create_timer(0.5).timeout
		if _is_death_exploding: return
		_fade_tween = create_tween()
		_fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await _fade_tween.finished
			
	else:
		# Fallback: ถ้า animation ที่ขอไม่มี → เล่น "die" ก่อนเสมอ
		if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("die"):
			sprite.play("die")
			await sprite.animation_finished
			await get_tree().create_timer(0.3).timeout
			if _is_death_exploding: return
			_fade_tween = create_tween()
			_fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
			await _fade_tween.finished
		elif sprite != null:
			# ไม่มีแม้แต่ "die" → scale tween
			_death_tween = create_tween()
			_death_tween.tween_property(self , "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_BACK)
			await _death_tween.finished

	if not _is_death_exploding:
		queue_free()


func _attack_target() -> void:
	if is_dead:
		return
		
	is_attacking = true
	sprite.play("hit")
	
	# ฟัง frame_changed เพื่อทำดาเมจตรงเฟรมที่ 2 และ 4
	var hit_frames := [1, 3]
	
	var on_frame := func():
		if is_dead or not is_attacking:
			return
		if sprite.animation != "hit":
			return
		if sprite.frame in hit_frames:
			if target and is_instance_valid(target):
				if global_position.distance_to(target.global_position) <= 85.0:
					if target.has_method("take_damage"):
						target.take_damage(damage)
	
	sprite.frame_changed.connect(on_frame)
	await sprite.animation_finished
	sprite.frame_changed.disconnect(on_frame)
	
	is_attacking = false
	
	if is_dead:
		return
	
	# หลังตีเสร็จทุกครั้ง หาเป้าหมายใหม่เสมอ
	_find_target()
	
	if not is_hurt:
		sprite.play("walk")
