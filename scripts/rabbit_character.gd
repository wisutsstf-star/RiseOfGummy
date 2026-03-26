extends HeroBase

@export var projectile_angle_offset: float = 10.0

const BLACK_BULLET_UPGRADE_TYPE := "rabbit_black_bullet"
const HERO_ID := "rabbit"
const BASE_BLACK_BULLET_CONFIG := {
	"shots": 3,
	"pierce_targets": 1,
	"falloff": 0.0,
	"speed_multiplier": 1.0,
	"full_damage_pierce": false,
}

var is_attacking: bool = false
var headshot_ready: bool = false
var is_using_headshot: bool = false
var headshot_wait_timer: float = 0.0
var normal_shots_fired: int = 0

@onready var headshot_timer: Timer = $HeadshotTimer
var shoot_sound = load("res://characters/rabbit/assets/audio/rabbit_gunshot.wav")
var ult_sound = load("res://characters/rabbit/assets/audio/rabbit_ultimate_gunshot.wav")
var audio_player: AudioStreamPlayer2D
var audio_player_ult: AudioStreamPlayer2D



func _ready() -> void:
	super._ready()
	
	# headshot_timer is no longer used for auto-fire, it's triggered by UI
	headshot_ready = false
	_card_modifier_state = _get_card_modifier_state()
	
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = shoot_sound
	audio_player.max_distance = 2000
	audio_player.volume_db = -4.0
	audio_player.pitch_scale = 0.9
	audio_player.bus = "SFX"
	
	audio_player_ult = AudioStreamPlayer2D.new()
	add_child(audio_player_ult)
	audio_player_ult.stream = ult_sound
	audio_player_ult.max_distance = 2000
	audio_player_ult.volume_db = -6.0
	audio_player_ult.pitch_scale = 0.85
	audio_player_ult.bus = "SFX"



func _die() -> void:
	super._die()
	is_using_headshot = false
	headshot_wait_timer = 0.0
	headshot_ready = false

func _find_priority_target() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = _get_base_defense_range()

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue

		var dist_to_base: float = base_position.distance_to(enemy.global_position)
		if dist_to_base > _get_base_defense_range():
			continue

		if dist_to_base < nearest_dist:
			nearest = enemy
			nearest_dist = dist_to_base

	return nearest

func _perform_normal_attack():
	var target = _find_priority_target()
	if not target:
		return
	
	var modifier_state = _get_card_modifier_state()

	var projectile_count := 2
	if modifier_state != null:
		projectile_count += int(modifier_state.projectile_count_bonus)
	projectile_count = maxi(1, projectile_count)
	
	for i in range(projectile_count):
		# Handle special bullet from passive
		var modifier_state_loc = _get_card_modifier_state()
		var fire_special = false
		var pierce_all = false
		if modifier_state_loc != null and float(modifier_state_loc.special_bullet_every_x_shots) > 0:
			var req_shots = int(modifier_state_loc.special_bullet_every_x_shots)
			normal_shots_fired += 1
			if normal_shots_fired >= req_shots:
				fire_special = true
				normal_shots_fired = 0
				if bool(modifier_state_loc.special_bullet_pierce_all):
					pierce_all = true
		
		# Play sound once per volley
		if fire_special:
			if audio_player_ult:
				audio_player_ult.play()
		else:
			if audio_player:
				audio_player.play()

		var spread_step = deg_to_rad(1.5)
		var spread_index = float(i) - (float(projectile_count - 1) * 0.5)
		var base_direction = (target.global_position - global_position).normalized()
		var bullet_dir = base_direction.rotated(spread_index * spread_step)

		if fire_special:
			var spec_count = max(1, int(modifier_state_loc.special_bullet_count)) if modifier_state_loc else 2
			for j in range(spec_count):
				var bullet_scene = preload("res://characters/rabbit/scenes/bullet_rabbit_black.tscn")
				if bullet_scene:
					var bullet = bullet_scene.instantiate()
					bullet.global_position = global_position
					
					var s_spread_step = deg_to_rad(10.0)
					var s_spread_index = float(j) - (float(spec_count - 1) * 0.5)
					var final_dir = bullet_dir.rotated(s_spread_index * s_spread_step)
					
					if "direction" in bullet:
						bullet.direction = final_dir
					if "target_pos" in bullet:
						bullet.target_pos = global_position + final_dir * 3000.0
					
					var dmg_data = calculate_damage()
					dmg_data["amount"] = dmg_data["amount"]
					
					if pierce_all:
						if "max_pierce_targets" in bullet:
							bullet.max_pierce_targets = -1
						if "keep_full_damage_on_pierce" in bullet:
							bullet.keep_full_damage_on_pierce = true
					else:
						# Do not pierce
						if "max_pierce_targets" in bullet:
							bullet.max_pierce_targets = 1
					
					if modifier_state_loc != null and float(modifier_state_loc.explode_chance_pct) > 0:
						bullet.set_meta("explode_chance_pct", float(modifier_state_loc.explode_chance_pct))
						bullet.set_meta("explode_splash_pct", float(modifier_state_loc.explode_splash_pct))
					
					
					if "damage_data" in bullet:
						bullet.damage_data = dmg_data
					if "shooter" in bullet:
						bullet.shooter = self
					else:
						bullet.damage = dmg_data["amount"]
						
					get_tree().current_scene.add_child(bullet)

		else:
			var bullet = preload("res://characters/rabbit/scenes/RabbitProjectile.tscn").instantiate()
			bullet.global_position = global_position
			bullet.direction = bullet_dir
			
			if modifier_state_loc != null and float(modifier_state_loc.explode_chance_pct) > 0:
				bullet.set_meta("explode_chance_pct", float(modifier_state_loc.explode_chance_pct))
				bullet.set_meta("explode_splash_pct", float(modifier_state_loc.explode_splash_pct))
			
			var dmg_data = calculate_damage()
			dmg_data["amount"] = int(dmg_data["amount"] * 0.5) # ดาเมจลดลง 50%
			if "damage_data" in bullet:
				bullet.damage_data = dmg_data
			if "shooter" in bullet:
				bullet.shooter = self
			else:
				bullet.damage = dmg_data["amount"]
				
			get_tree().current_scene.add_child(bullet)



func _physics_process(delta: float) -> void:
	if is_using_headshot:
		if headshot_wait_timer > 0:
			headshot_wait_timer -= delta
		return

	# Update timers
	if fire_timer > 0:
		fire_timer -= delta

	var nearest = _find_priority_target()
	
	# ไม่มีศัตรู → idle
	if not nearest:
		is_attacking = false
		if _is_outside_base_defense_range():
			move_back_to_base(move_speed)
		elif sprite.animation != "idle":
			sprite.play("idle")
		return
	
	# Face target
	var dir = nearest.global_position - global_position
	sprite.flip_h = dir.x < 0
	
	var dist = global_position.distance_to(nearest.global_position)
	
	# Headshot auto-trigger disabled, now driven by UI
	# if headshot_ready and dist <= attack_range:
	# 	_fire_headshot(nearest)
	# 	return
	
	# ถ้ากำลังเล่น attack อยู่ ไม่ต้องขัด
	if is_attacking:
		return
	
	# ถ้าติด cooldown
	if fire_timer > 0:
		if sprite.animation != "idle":
			sprite.play("idle")
		return

	var current_attack_range = attack_range
	var modifier_state_loc = _get_card_modifier_state()
	if modifier_state_loc != null and modifier_state_loc.get("attack_range_bonus") != null:
		current_attack_range += float(modifier_state_loc.attack_range_bonus)

	if dist <= current_attack_range:
		_play_attack()
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

# ... skipping down to replace _play_attack_windup and _play_attack_fire
func _execute_headshot_sequence() -> void:
	is_using_headshot = true
	var black_bullet_config := _get_black_bullet_config()
	print("HEADSHOT: Skill activated. Waiting for targets up to 10s.")
	
	# Pause normal attacks immediately
	is_attacking = false
	
	var shots_fired = 0
	var has_aimed = false
	var total_shots: int = int(black_bullet_config.get("shots", 6))
	var shot_interval: float = float(black_bullet_config.get("shot_interval", 0.6))
	var shot_delay: float = shot_interval
	var original_speed_scale: float = sprite.speed_scale
	sprite.speed_scale = 4.0 # Extremely snappy animation
	
	while shots_fired < total_shots and headshot_wait_timer > 0:
		if not is_inside_tree() or not is_instance_valid(self ):
			sprite.speed_scale = original_speed_scale
			return
		
		var current_target = _find_priority_target()
		
		if current_target:
			if not has_aimed:
				# Face target
				var aim_dir = current_target.global_position - global_position
				sprite.flip_h = aim_dir.x < 0
				
				# Play aim animation once
				sprite.play("aim")
				while sprite.is_playing() and sprite.animation == "aim":
					if not is_inside_tree() or not is_instance_valid(self ):
						sprite.speed_scale = original_speed_scale
						return
					await get_tree().process_frame
				sprite.pause()
				has_aimed = true
				
			# Check timer again after aim wait
			if headshot_wait_timer <= 0:
				break
				
			# Retarget right before shooting
			current_target = _find_priority_target()
			if not current_target:
				continue
				
			var target_pos = current_target.global_position
			var dir = target_pos - global_position
			sprite.flip_h = dir.x < 0
			
			var start_shoot_time = Time.get_ticks_msec() / 1000.0
			
			print("HEADSHOT: Shot ", shots_fired + 1)
			sprite.play("shoot")
			
			await _wait_for_shoot_frame(current_target, target_pos, black_bullet_config)
			
			while sprite.is_playing() and sprite.animation == "shoot":
				if not is_inside_tree() or not is_instance_valid(self ):
					sprite.speed_scale = original_speed_scale
					return
				await get_tree().process_frame
				
			shots_fired += 1
			
			if shots_fired < total_shots:
				var elapsed = (Time.get_ticks_msec() / 1000.0) - start_shoot_time
				var delay = maxf(0.01, shot_delay - elapsed)
				while delay > 0 and headshot_wait_timer > 0:
					if not is_inside_tree() or not is_instance_valid(self ):
						sprite.speed_scale = original_speed_scale
						return
					await get_tree().process_frame
					delay -= get_process_delta_time()
		else:
			# No target in range, just wait.
			if has_aimed:
				sprite.animation = "aim"
				sprite.frame = sprite.sprite_frames.get_frame_count("aim") - 1
			else:
				if sprite.animation != "idle":
					sprite.play("idle")
			
			if not is_inside_tree() or not is_instance_valid(self ):
				sprite.speed_scale = original_speed_scale
				return
			await get_tree().process_frame
			
	if not is_inside_tree() or not is_instance_valid(self ):
		sprite.speed_scale = original_speed_scale
		return
	print("HEADSHOT: Sequence finished or timed out. Shots fired:", shots_fired)
	
	if has_aimed:
		sprite.play_backwards("aim")
		await sprite.animation_finished
		
	if not is_inside_tree() or not is_instance_valid(self ):
		sprite.speed_scale = original_speed_scale
		return
	sprite.speed_scale = original_speed_scale
	
	is_using_headshot = false
	headshot_ready = false
	headshot_wait_timer = 0.0
	start_cooldown()
	
	# Immediately check for target and resume normal attack
	var next_target = _find_priority_target()
	if next_target:
		var next_dir: Vector2 = next_target.global_position - global_position
		sprite.flip_h = next_dir.x < 0
		_play_attack()
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _play_attack():
	is_attacking = true
	sprite.play("attack")
	
	# Wait until frame 3 (roughly the shot frame) to fire the projectile
	while sprite.animation == "attack" and is_playing(sprite) and sprite.frame < 3:
		await get_tree().process_frame
		
	# Fire the bullets
	if sprite.animation == "attack": # and haven't transitioned to something else
		_perform_normal_attack()
	
	# Wait for animation to finish
	while sprite.animation == "attack" and is_playing(sprite):
		await get_tree().process_frame
		
	is_attacking = false
	var effective_attack_speed := _get_effective_attack_speed()
	fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0

func is_playing(anim_sprite: AnimatedSprite2D) -> bool:
	return anim_sprite.is_playing() and anim_sprite.frame < anim_sprite.sprite_frames.get_frame_count(anim_sprite.animation) - 1


func _wait_for_shoot_frame(target: Node2D, fallback_pos: Vector2, black_bullet_config: Dictionary) -> void:
	print("HEADSHOT: Waiting for frame 0, current frame: ", sprite.frame)
	# Wait until we hit frame 0 of shoot animation
	while sprite.animation == "shoot" and sprite.frame != 0:
		await get_tree().process_frame
	
	print("HEADSHOT: Frame 0 reached, spawning bullet")
	# Recalculate position right as we spawn to track moving targets
	var final_pos = fallback_pos
	if is_instance_valid(target):
		final_pos = target.global_position
		
	# Spawn bullet at frame 0
	if sprite.animation == "shoot":
		_spawn_black_bullet_at_position(final_pos, black_bullet_config)


func _spawn_black_bullet_at_position(target_pos: Vector2, black_bullet_config: Dictionary) -> void:
	var bullet_scene = preload("res://characters/rabbit/scenes/bullet_rabbit_black.tscn")
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	# Calculate direction to target position
	if "direction" in bullet:
		bullet.direction = (target_pos - global_position).normalized()
	if "target_pos" in bullet:
		bullet.target_pos = target_pos
	
	var dmg_data = calculate_damage()
	var dmg_mult = float(black_bullet_config.get("damage_multiplier", 1.0))
	dmg_data["amount"] = int(round(float(dmg_data["amount"]) * dmg_mult))
	
	if "max_pierce_targets" in bullet:
		bullet.max_pierce_targets = int(black_bullet_config.get("pierce_targets", 1))
	if "pierce_damage_falloff" in bullet:
		bullet.pierce_damage_falloff = float(black_bullet_config.get("falloff", 0.0))
	if "keep_full_damage_on_pierce" in bullet:
		bullet.keep_full_damage_on_pierce = bool(black_bullet_config.get("full_damage_pierce", false))
	if "damage_data" in bullet:
		bullet.damage_data = dmg_data
	if "shooter" in bullet:
		bullet.shooter = self
	else:
		bullet.damage = dmg_data["amount"]
		
	var modifier_state_loc = _get_card_modifier_state()
	if modifier_state_loc != null and float(modifier_state_loc.explode_chance_pct) > 0:
		bullet.set_meta("explode_chance_pct", float(modifier_state_loc.explode_chance_pct))
		bullet.set_meta("explode_splash_pct", float(modifier_state_loc.explode_splash_pct))
		
	if audio_player_ult:
		audio_player_ult.play()
		
	get_tree().current_scene.add_child(bullet)




func _on_headshot_timer_timeout() -> void:
	pass

# Called by the CRK Skill UI
func use_active_skill() -> bool:
	if super.use_active_skill():
		# Skill successfully activated (not on CD)
		headshot_ready = true
		headshot_wait_timer = _get_black_bullet_duration()
		_execute_headshot_sequence()
		return true
		
	return false


func get_hero_id() -> String:
	return HERO_ID


func _get_black_bullet_upgrade_level() -> int:
	return GameStats.get_upgrade_count(BLACK_BULLET_UPGRADE_TYPE)


func _get_black_bullet_duration() -> float:
	var black_bullet_config := _get_black_bullet_config()
	var total_shots: int = int(black_bullet_config.get("shots", 6))
	var shot_interval: float = float(black_bullet_config.get("shot_interval", 1.2))
	return maxf(6.0, 2.0 + (float(total_shots) * shot_interval))


func _get_black_bullet_config() -> Dictionary:
	var modifier_state = _get_card_modifier_state()
	if modifier_state != null and bool(modifier_state.black_bullet_enabled):
		return {
			"shots": int(modifier_state.black_bullet_shot_count),
			"damage_multiplier": float(modifier_state.black_bullet_damage_multiplier),
			"shot_interval": float(modifier_state.black_bullet_shot_interval),
			"pierce_targets": int(modifier_state.black_bullet_pierce),
			"falloff": float(modifier_state.black_bullet_falloff),
			"full_damage_pierce": true,
		}

	var level := _get_black_bullet_upgrade_level()
	match level:
		1: return { "shots": 6, "damage_multiplier": 1.0, "shot_interval": 0.6, "pierce_targets": -1, "falloff": 0.0, "full_damage_pierce": true }
		2: return { "shots": 10, "damage_multiplier": 1.15, "shot_interval": 0.45, "pierce_targets": -1, "falloff": 0.0, "full_damage_pierce": true }
		3: return { "shots": 12, "damage_multiplier": 1.3, "shot_interval": 0.35, "pierce_targets": -1, "falloff": 0.0, "full_damage_pierce": true }
		4: return { "shots": 15, "damage_multiplier": 1.5, "shot_interval": 0.25, "pierce_targets": -1, "falloff": 0.0, "full_damage_pierce": true }
		5: return { "shots": 20, "damage_multiplier": 1.75, "shot_interval": 0.15, "pierce_targets": -1, "falloff": 0.0, "full_damage_pierce": true }
		_: return { "shots": 6, "damage_multiplier": 1.0, "shot_interval": 0.6, "pierce_targets": -1, "falloff": 0.0, "full_damage_pierce": true }


func _fire_dual_projectiles(target: Node2D) -> void:
	if not projectile_scene:
		return

	var base_dir: Vector2 = (target.global_position - global_position).normalized()
	var offset_rad: float = deg_to_rad(projectile_angle_offset)

	# Projectile 1: -10 degrees
	_spawn_projectile(base_dir.rotated(-offset_rad))
	# Projectile 2: +10 degrees
	_spawn_projectile(base_dir.rotated(offset_rad))


func _fire_forward() -> void:
	if not projectile_scene:
		return

	var forward: Vector2 = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var offset_rad: float = deg_to_rad(projectile_angle_offset)

	_spawn_projectile(forward.rotated(-offset_rad))
	_spawn_projectile(forward.rotated(offset_rad))


func _spawn_projectile(dir: Vector2) -> void:
	var proj: Node2D = projectile_scene.instantiate()

	proj.global_position = global_position
	if "target_pos" in proj:
		proj.target_pos = global_position + dir * 3000.0
	
	var dmg_data = calculate_damage()
	if "damage_data" in proj:
		proj.damage_data = dmg_data
	if "shooter" in proj:
		proj.shooter = self
	else:
		proj.damage = dmg_data["amount"]
	get_tree().current_scene.add_child(proj)
