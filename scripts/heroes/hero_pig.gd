extends HeroBase

# ── Pig Skill VFX & Gameplay ──────────────────────────────
# Sequence: MagicCircle → RedSphere → Smoke → OrbitSpark
# Gameplay: Spawns at nearest enemy. Sucks enemies in via Area2D. Deals 5 ticks of damage, then explodes.

const SKILL_DURATION: float = 2.0
const SMOKE_ROTATE_SPEED: float = 2.5 # rad/s
const SUCTION_RADIUS: float = 135.0
const SUCTION_POWER: float = 80.0
const TOTAL_TICKS: int = 3
const BLOOD_PIG_SKILL_SCENE = preload("res://scenes/skills/blood_pig_skill.tscn")
const BLOOD_COURIER_SCRIPT = preload("res://scripts/heroes/pig_blood_courier.gd")
const PIG_HEMOBLOOM_SCENE = preload("res://characters/pig/scenes/pig_hemobloom.tscn")
const PIG_HIT_SOUND = preload("res://characters/pig/assets/audio/pig hit.wav")
const BLOOD_PIG_HIT_SOUND = preload("res://characters/pig/assets/audio/blood_pig_hit.wav")
const BLOOD_PIG_CAST_SOUND = preload("res://characters/pig/assets/audio/blood_pig_cast2.wav")

func get_hero_id() -> String:
	return "pig"

# VFX node references (created at runtime)
var _vfx_container: Node2D
var _magic_circle: Sprite2D
var _red_sphere: Sprite2D
var _smoke_pivot: Node2D
var _orbit_spark: AnimatedSprite2D
var _skill_area: Area2D
var _skill_running: bool = false
var _skill_center: Vector2 = Vector2.ZERO
var _pulse_tween: Tween
var _pulse_tween_orbit: Tween
var _blur_shader: Shader
var _hit_frames: SpriteFrames
var _sucked_enemies: Array[Node2D] = []

var _hemobloom_hit_counter: int = 0

# ── Textures ────────────────────────────────────────────
var _tex_magic_circle: Texture2D
var _tex_red_sphere: Texture2D
var _tex_smoke: Texture2D
var _orbit_spark_textures: Array[Texture2D] = []
var _suction_textures: Array[Texture2D] = []
var _tex_big_red_sphere: Texture2D
var _tex_suction_5: Texture2D

func _die() -> void:
	super._die()
	_skill_running = false
	if is_instance_valid(_vfx_container):
		_vfx_container.queue_free()

func _ready() -> void:
	super._ready()
	sprite.animation_finished.connect(_on_pig_animation_finished)
	
	_tex_magic_circle = load("res://characters/pig/assets/magic_circle.png")
	_tex_red_sphere = load("res://characters/pig/assets/red_sphere.png")
	_tex_smoke = load("res://characters/pig/assets/smoke_particle.png")
	
	if not skill_icon_2:
		skill_icon_2 = _tex_red_sphere
	
	_orbit_spark_textures.clear()
	for i in range(1, 6):
		var tex_path = "res://characters/pig/assets/orbit_spark (%d).png" % i
		var tex = load(tex_path)
		if tex:
			_orbit_spark_textures.append(tex)
			
	_suction_textures.clear()
	for i in range(1, 5):
		var tex_path = "res://characters/pig/assets/Suction Effect (%d).png" % i
		var tex = load(tex_path)
		if tex:
			_suction_textures.append(tex)
			
	_tex_big_red_sphere = load("res://characters/pig/assets/big_red_sphere.png")
	_tex_suction_5 = load("res://characters/pig/assets/Suction Effect (5).png")
	
	# เตรียม SpriteFrames สำหรับ Hit Effect 
	var tex_hit = load("res://characters/pig/assets/pig_hit.png")
	if tex_hit:
		_hit_frames = SpriteFrames.new()
		# รูป pig_hit มี 3 เฟรม ขนาดเฟรมละ 85x64
		_hit_frames.add_animation("hit")
		_hit_frames.set_animation_loop("hit", false)
		_hit_frames.set_animation_speed("hit", 12.0)
		for i in range(3):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex_hit
			atlas.region = Rect2(i * 85, 0, 85, 64)
			_hit_frames.add_frame("hit", atlas)
	
	_blur_shader = Shader.new()
	_blur_shader.code = """
shader_type canvas_item;
render_mode blend_add;
uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec4 color = textureLod(TEXTURE, UV, blur_amount);
	COLOR = color;
}
"""


# ── Pig's own animation finished handler ──────────
func _on_pig_animation_finished() -> void:
	if sprite.animation == "attack" or sprite.animation == "attack_ground":
		sprite.play("idle")


# ── Pig's own face direction ──────────────────────
func _pig_face_default_direction() -> void:
	sprite.flip_h = true # หันซ้าย


# ── Pig's own shoot (projectile spawn) ────────────
func _pig_shoot(target: Node2D) -> void:
	var modifier = _get_card_modifier_state()
	if modifier and modifier.get("pig_hemobloom_enabled"):
		_hemobloom_hit_counter += 1
		if _hemobloom_hit_counter >= 3:
			_hemobloom_hit_counter = 0
			_fire_hemobloom(target)
			return

	if not projectile_scene:
		return
	
	var proj: Node2D = projectile_scene.instantiate()
	
	if "target_pos" in proj:
		proj.target_pos = target.global_position
	
	var dmg_data = calculate_damage()
	if "damage_data" in proj:
		proj.damage_data = dmg_data
	else:
		proj.damage = dmg_data["amount"]
	if "shooter" in proj:
		proj.shooter = self
	
	proj.position = global_position
	get_tree().current_scene.add_child(proj)


# ── Pig's own queue shot (delayed) ────────────────
func _pig_queue_shot(target: Node2D) -> void:
	var tween: Tween = create_tween()
	tween.tween_callback(func():
		if sprite.animation == "attack" and is_instance_valid(target):
			_pig_shoot(target)
	).set_delay(attack_delay)


# ── Pig's own ground mode physics ─────────────────
func _pig_ground_physics_process(delta: float) -> void:
	if fire_timer > 0.0:
		fire_timer -= delta

	# หาเป้าหมายใกล้สุดโดยอิงฐานเป็นศูนย์กลาง
	ground_target = _find_patrol_target(_get_base_defense_range())

	# เช็คว่ากลับฐานหรือหยุดเดิน
	if _is_outside_base_defense_range() and not ground_is_attacking:
		ground_target = null
		move_back_to_base(move_speed)
		fire_timer = 0.0
		return

	if not ground_target or not is_instance_valid(ground_target):
		if not ground_is_attacking:
			if global_position.distance_to(base_position) > 8.0:
				move_back_to_base(move_speed)
			elif sprite.animation != "idle":
				sprite.play("idle")
		fire_timer = 0.0
		return

	var dist = global_position.distance_to(ground_target.global_position)
	var dir = (ground_target.global_position - global_position).normalized()

	# หันหน้าเข้าศัตรู
	sprite.flip_h = dir.x < 0

	if dist > ground_attack_range:
		# เดินเข้าไป
		if not ground_is_attacking:
			if sprite.animation != "idle":
				sprite.play("idle")
			global_position += dir * move_speed * delta
	else:
		# ถึงระยะตี → โจมตี
		velocity = Vector2.ZERO
		move_and_slide()
		
		if fire_timer <= 0.0 and not ground_is_attacking:
			var effective_attack_speed := _get_effective_attack_speed()
			fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0
			ground_is_attacking = true
			sprite.play("attack")
			
			var modifier = _get_card_modifier_state()
			if modifier and modifier.get("pig_hemobloom_enabled"):
				_hemobloom_hit_counter += 1
				if _hemobloom_hit_counter >= 3:
					_hemobloom_hit_counter = 0
					_fire_hemobloom(ground_target)
					ground_is_attacking = false
					return
			
			# ทำดาเมจประชิด
			if is_instance_valid(ground_target) and ground_target.has_method("take_damage"):
				if global_position.distance_to(ground_target.global_position) <= ground_melee_hit_range:
					var dmg_data = calculate_damage()
					var dmg_dir = (ground_target.global_position - global_position).normalized()
					ground_target.take_damage(dmg_data["amount"], "death_slash", dmg_dir, dmg_data["is_crit"])
					_play_pig_hit_sound(ground_target.global_position)
			ground_is_attacking = false


func _physics_process(delta: float) -> void:
	# ── Pig's own Base Mode attack loop ──
	if not _skill_running:
		# ── Ground Mode ──
		if is_ground_mode:
			_pig_ground_physics_process(delta)
		else:
			# ── Base Mode: ยิงปกติ ──
			var target: Node2D = _find_nearest_enemy(get_tree().get_nodes_in_group("enemies"))
			
			if target:
				# หันหน้าไปทางเป้าหมาย
				var dir: Vector2 = target.global_position - global_position
				sprite.flip_h = dir.x < 0
				
				# ยิงเมื่อพร้อม
				fire_timer -= delta
				if fire_timer <= 0.0:
					var effective_attack_speed := _get_effective_attack_speed()
					fire_timer = 1.0 / effective_attack_speed if effective_attack_speed > 0 else 1.0
					sprite.play("attack")
					_pig_queue_shot(target)
			else:
				# ไม่มีเป้าหมาย
				fire_timer = 0.0
				if _is_outside_base_defense_range():
					move_back_to_base(move_speed)
				else:
					_pig_face_default_direction()
					if sprite.animation != "idle":
						if sprite.animation != "attack":
							sprite.play("idle")
	
	# ── Skill VFX rotation ──
	if not _skill_running:
		return

	# 1. Rotate smoke and suction effect
	if is_instance_valid(_smoke_pivot):
		_smoke_pivot.rotation += SMOKE_ROTATE_SPEED * delta
		
	# 2. Suction logic
	var current_overlapping = []
	if is_instance_valid(_skill_area) and _skill_area.monitoring:
		var enemies = _skill_area.get_overlapping_bodies()
		for enemy in enemies:
			if enemy.is_in_group("enemies") and is_instance_valid(enemy):
				current_overlapping.append(enemy)
				if not _sucked_enemies.has(enemy):
					_sucked_enemies.append(enemy)
					
	for enemy in _sucked_enemies:
		if is_instance_valid(enemy):
			var should_suck = false
			if current_overlapping.has(enemy):
				should_suck = true
			elif "is_dead" in enemy and enemy.is_dead:
				should_suck = true
				
			if should_suck:
				var dir = (_skill_center - enemy.global_position).normalized()
				var dist = enemy.global_position.distance_to(_skill_center)
				if dist > 10.0:
					enemy.global_position += dir * SUCTION_POWER * delta


# ── Skill Activation (called by UI) ─────────────────────
var _suction_anim: AnimatedSprite2D

func _fire_hemobloom(target: Node2D) -> void:
	if not is_instance_valid(target): return
	var root := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	if root == null or PIG_HEMOBLOOM_SCENE == null: return
	
	var skill_pos = global_position + Vector2(0, -20)
	var aim_dir = (target.global_position - skill_pos).normalized()
	
	var orb = PIG_HEMOBLOOM_SCENE.instantiate()
	var dmg_data = calculate_damage()
	var final_dmg = int(dmg_data["amount"] * 1.0)
	
	var config = {"level": 1, "base_damage": final_dmg}
	var modifier = _get_card_modifier_state()
	if modifier and modifier.get("pig_hemobloom_enabled"):
		config["level"] = modifier.pig_hemobloom_level
		
	if orb.has_method("setup"):
		orb.setup(config, aim_dir, self)
	
	orb.global_position = skill_pos
	root.add_child(orb)

func use_active_skill_2() -> bool:
	return false

func has_active_skill(index: int) -> bool:
	if index == 0:
		return true
	return false

func use_active_skill() -> bool:
	if not super.use_active_skill():
		return false
	
	# Find spawn location
	if BLOOD_PIG_SKILL_SCENE == null:
		is_skill_active = false
		return false
	
	var root := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	if root == null:
		is_skill_active = false
		return false
	
	# Find spawn location (at nearest enemy or in front of hero)
	var skill_position := global_position
	var target := _find_nearest_enemy(get_tree().get_nodes_in_group("enemies"))
	
	if is_instance_valid(target):
		skill_position = target.global_position
	else:
		# No enemy - spawn in front of hero
		var aim_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		skill_position = global_position + aim_dir * 300.0

	skill_position = _clamp_skill_position_to_walkable_zone(skill_position)
	
	var skill := BLOOD_PIG_SKILL_SCENE.instantiate()
	if not (skill is Node2D):
		is_skill_active = false
		return false
	
	var damage_data := calculate_damage()
	var scaled_damage := maxi(1, int(damage_data["amount"] * 1.5))  # 1.5x multiplier for ultimate

	var modifier_state = _get_card_modifier_state()
	var skill_config := {
		"owner_hero": self,
		"base_damage": scaled_damage,
		"suction_radius": SUCTION_RADIUS,
		"suction_power": SUCTION_POWER,
		"skill_duration": SKILL_DURATION,
		"orb_count": 5,
	}

	if modifier_state != null and bool(modifier_state.pig_blood_enabled):
		skill_config["skill_level"] = int(modifier_state.pig_blood_level)
		skill_config["ap_multiplier"] = float(modifier_state.pig_blood_ap_multiplier)
		skill_config["lifesteal_pct"] = float(modifier_state.pig_blood_lifesteal_pct)
		skill_config["bat_count"] = int(modifier_state.pig_blood_bat_count)
		skill_config["bat_speed"] = float(modifier_state.pig_blood_bat_speed)
		skill_config["radius_multiplier"] = float(modifier_state.pig_blood_radius_multiplier)
		skill_config["pull_force"] = float(modifier_state.pig_blood_pull_force)
		skill_config["slow_pct"] = float(modifier_state.pig_blood_slow_pct)
		skill_config["slow_duration"] = float(modifier_state.pig_blood_slow_duration)
		skill_config["pulse_count"] = int(modifier_state.pig_blood_pulse_count)
		skill_config["pulse_interval"] = float(modifier_state.pig_blood_pulse_interval)
		skill_config["center_damage_pct"] = float(modifier_state.pig_blood_center_damage_pct)
		skill_config["shield_pct"] = float(modifier_state.pig_blood_shield_pct)
		skill_config["team_heal"] = bool(modifier_state.pig_blood_team_heal)

	if skill.has_method("setup"):
		skill.setup(skill_config)
	
	skill.global_position = skill_position
	
	# Connect to skill finished signal
	if skill.has_signal("skill_finished"):
		skill.skill_finished.connect(_on_skill_finished)
	
	root.add_child(skill)
	_play_blood_pig_cast_sound(skill_position)
	
	# Face toward skill
	sprite.flip_h = skill_position.x < global_position.x
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	
	return true


func _on_skill_finished(_skill: Node) -> void:
	if is_dead:
		is_skill_active = false
		return
	start_cooldown()


func spawn_orb_blood_fly_to_pig(start_position: Vector2, amount: int) -> void:
	if amount <= 0 or get_tree().current_scene == null:
		return
	var courier = BLOOD_COURIER_SCRIPT.new()
	courier.debug_mode = false
	courier.setup({
		"heal_amount": amount,
		"move_speed": 220.0,
		"target_node": self,
		"target_position": global_position,
		"start_position": start_position,
		"on_arrive": Callable(self, "heal"),
		"hp_drained": amount,
	})
	get_tree().current_scene.add_child(courier)


func _clamp_skill_position_to_walkable_zone(pos: Vector2) -> Vector2:
	var wave_manager := get_tree().get_first_node_in_group("wave_manager")
	if wave_manager == null and get_tree().current_scene != null:
		wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")

	var result_pos = pos
	if wave_manager != null and wave_manager.has_method("clamp_below_restricted_top_zone"):
		var clamped_pos = wave_manager.clamp_below_restricted_top_zone(result_pos)
		if clamped_pos is Vector2:
			result_pos = clamped_pos

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var min_y := viewport_rect.position.y + (viewport_rect.size.y * 0.5)
	result_pos = Vector2(result_pos.x, maxf(result_pos.y, min_y))

	var min_base_dist: float = 160.0
	if result_pos.distance_to(base_position) < min_base_dist:
		var dir_from_base = (result_pos - base_position).normalized()
		if dir_from_base == Vector2.ZERO:
			dir_from_base = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT
		result_pos = base_position + dir_from_base * min_base_dist

	return result_pos


# ── Main Skill Sequence ─────────────────────────────────
func _execute_pig_skill() -> void:
	_skill_running = true
	_sucked_enemies.clear()

	# หาเป้าหมายที่ใกล้ที่สุด — ไม่สนใจ range เพื่อไม่ให้สกิลไปเกิดที่ฐาน
	var target = _find_nearest_enemy(get_tree().get_nodes_in_group("enemies"))
	if target:
		# มีศัตรู → ตามไปหาเสมอ ไม่ว่าจะอยู่ไกลแค่ไหน
		_skill_center = target.global_position
	else:
		# ไม่มีศัตรูในเกมเลย → วางไว้หน้าหมูในทิศที่กำลังโจมตี (ไม่ใช่ทิศฐาน)
		var aim_dir = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT
		_skill_center = global_position + aim_dir * 300.0

	_skill_center = _clamp_skill_position_to_walkable_zone(_skill_center)
	
	# ── Container for all VFX / Logic ──
	_vfx_container = Node2D.new()
	_vfx_container.global_position = _skill_center
	_vfx_container.z_index = 50 # ให้อยู่สูงกว่าพื้น แต่หลังมอนสเตอร์ (z_index 75) และหลังฮีโร่ (z_index 100+)
	# *** ลดขนาดภาพรวมของสกิลทั้งหมดลงเหลือ 0.5x ตามคำขอ ***
	_vfx_container.scale = Vector2(0.5, 0.5)
	get_tree().current_scene.add_child(_vfx_container)

	# ── Area2D for Suction and Damage Hitbox ──
	_skill_area = Area2D.new()
	_skill_area.collision_mask = 2 # mask ของศัตรู
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	# เนื่องจาก parent container ถูกลด scale เหลือ 0.5 เราต้องคูณ 2 คืนให้ radius เพื่อให้ระยะ Area2D กว้างเท่าเดิม
	shape.radius = SUCTION_RADIUS * 2.0
	col.shape = shape
	_skill_area.add_child(col)
	_vfx_container.add_child(_skill_area)

	# ───────────────────────────────────────────
	# 1. MagicCircle  (fade-in + scale-up)
	# ───────────────────────────────────────────
	_magic_circle = Sprite2D.new()
	_magic_circle.texture = _tex_magic_circle
	_magic_circle.scale = Vector2.ZERO
	_magic_circle.modulate.a = 0.0
	_magic_circle.z_index = -1
	
	# เพิ่ม Material เรืองแสง (Additive Blend Mode)
	var glow_mat = CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_magic_circle.material = glow_mat
	
	_vfx_container.add_child(_magic_circle)

	var tw_mc: Tween = create_tween().set_parallel(true)
	# ใช้สเกลตั้งต้นก่อนย่อ (เพราะ Container ย่อให้แล้ว)
	tw_mc.tween_property(_magic_circle, "scale", Vector2(0.8, 0.35), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_mc.tween_property(_magic_circle, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# --- แสงออร่าสีแดงบนสุดของสกิล (Top Red Aura) ---
	var top_aura = Sprite2D.new()
	var aura_tex = GradientTexture2D.new()
	aura_tex.width = 256
	aura_tex.height = 256
	aura_tex.fill = GradientTexture2D.FILL_RADIAL
	aura_tex.fill_from = Vector2(0.5, 0.5)
	aura_tex.fill_to = Vector2(0.5, 0.0)
	var aura_g = Gradient.new()
	aura_g.colors = [Color(1.0, 0.1, 0.1, 0.25), Color(1.0, 0.0, 0.0, 0.0)]
	aura_g.offsets = [0.0, 1.0]
	aura_tex.gradient = aura_g
	top_aura.texture = aura_tex
	top_aura.material = glow_mat # เรืองแสงด้วย
	top_aura.scale = Vector2(2.0, 1.0) # ทำให้เป็นวงรีรับกับพื้น
	top_aura.z_index = -1 # เปลี่ยนจาก 10 เป็น -1 เพื่อให้อยู่หลังมอนสเตอร์
	_vfx_container.add_child(top_aura)
	
	# ทำให้ Aura ค่อยๆ สว่างขึ้นมา
	top_aura.modulate.a = 0.0
	create_tween().tween_property(top_aura, "modulate:a", 1.0, 0.5)
	
	# ───────────────────────────────────────────
	# 2. RedSphere  (scale 0→1, ลอยขึ้นเหนือพื้นหน่อย)
	# ───────────────────────────────────────────
	_red_sphere = Sprite2D.new()
	_red_sphere.texture = _tex_red_sphere
	_red_sphere.position = Vector2(0, -20)
	_red_sphere.scale = Vector2.ZERO
	_red_sphere.z_index = 1
	_vfx_container.add_child(_red_sphere)

	# --- 1. แสงสีแดงบนลูกบอลสีแดง (Red Glow) ---
	var red_glow = Sprite2D.new()
	var g_tex = GradientTexture2D.new()
	g_tex.width = 128
	g_tex.height = 128
	g_tex.fill = GradientTexture2D.FILL_RADIAL
	g_tex.fill_from = Vector2(0.5, 0.5)
	g_tex.fill_to = Vector2(0.5, 0.0)
	var g = Gradient.new()
	g.colors = [Color(1.0, 0.2, 0.2, 0.8), Color(1.0, 0.0, 0.0, 0.0)]
	g.offsets = [0.0, 1.0]
	g_tex.gradient = g
	red_glow.texture = g_tex
	red_glow.show_behind_parent = true # ให้อยู่หลังลูกบอลนิดนึง จะได้เป็นแสงคลุม
	
	# ใส่ Additive Material ให้เรืองแสง
	var glow_mat_red = CanvasItemMaterial.new()
	glow_mat_red.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	red_glow.material = glow_mat_red
	_red_sphere.add_child(red_glow)

	var tw_sphere: Tween = create_tween().set_parallel(true)
	# ใช้สเกลตั้งต้นก่อนย่อ
	tw_sphere.tween_property(_red_sphere, "scale", Vector2(0.6, 0.6), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	tw_sphere.tween_property(_red_sphere, "position", Vector2(0, -60), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.2)

	# เริ่ม Damage Routine ควบคู่ไปกับ VFX
	_run_damage_routine()

	# ───────────────────────────────────────────
	# 3. Smoke  (หมุนอยู่กลางลูกบอลแดง)
	# ───────────────────────────────────────────
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree() or not is_instance_valid(_vfx_container): return

	_smoke_pivot = Node2D.new()
	_smoke_pivot.position = _red_sphere.position # หมุนที่แกน RedSphere
	_smoke_pivot.z_index = 2
	_vfx_container.add_child(_smoke_pivot)

	var smoke1 = Sprite2D.new()
	# ตั้งชื่อให้เข้าถึงได้ง่ายตอนทำแอนิเมชัน
	smoke1.name = "smoke1"
	smoke1.texture = _tex_smoke
	smoke1.position = Vector2(0, 0) # กึ่งกลางบนลูกบอลแดง
	smoke1.scale = Vector2(0.6, 0.6) # สเกลเท่า RedSphere
	smoke1.modulate = Color(1.0, 1.0, 1.0, 0.8)
	
	_smoke_pivot.add_child(smoke1)
	
	# แอนิเมชันหัวใจเต้น (ย่อ/ขยาย ต่อเนื่อง) ให้บอลแดงและควัน
	if is_instance_valid(_red_sphere):
		_pulse_tween = create_tween().set_loops()
		# ขยาย
		_pulse_tween.tween_property(_red_sphere, "scale", Vector2(0.65, 0.65), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.parallel().tween_property(smoke1, "scale", Vector2(0.65, 0.65), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# หด
		_pulse_tween.tween_property(_red_sphere, "scale", Vector2(0.55, 0.55), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.parallel().tween_property(smoke1, "scale", Vector2(0.55, 0.55), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ───────────────────────────────────────────
	# 4. OrbitSpark  (Animated loop)
	# ───────────────────────────────────────────
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or not is_instance_valid(_vfx_container): return

	_orbit_spark = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	frames.add_animation("spark")
	frames.set_animation_speed("spark", 10.0)
	frames.set_animation_loop("spark", true)
	for tex in _orbit_spark_textures:
		frames.add_frame("spark", tex)
		
	_orbit_spark.sprite_frames = frames
	_orbit_spark.position = _red_sphere.position
	_orbit_spark.scale = Vector2(0.5, 0.5)
	_orbit_spark.z_index = 3
	_vfx_container.add_child(_orbit_spark)
	_orbit_spark.play("spark")
	
	if is_instance_valid(_orbit_spark):
		_pulse_tween_orbit = create_tween().set_loops()
		_pulse_tween_orbit.tween_property(_orbit_spark, "scale", Vector2(0.55, 0.55), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween_orbit.tween_property(_orbit_spark, "scale", Vector2(0.45, 0.45), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ───────────────────────────────────────────
	# 5. Suction Vortex Frame Animation
	# ───────────────────────────────────────────
	_suction_anim = AnimatedSprite2D.new()
	var suc_frames = SpriteFrames.new()
	suc_frames.add_animation("suck")
	suc_frames.set_animation_speed("suck", 20.0) # 0.05s per frame
	suc_frames.set_animation_loop("suck", true)
	
	# Play in reverse: 4 -> 3 -> 2 -> 1
	for i in range(_suction_textures.size() - 1, -1, -1):
		suc_frames.add_frame("suck", _suction_textures[i])
		
	# สร้าง Material โหมด Additive (Godot ไม่มี Lighten แบบตรงๆ ให้ใช้ Add แทนซึ่งให้ผลลัพธ์ใกล้เคียงที่สุด)
	var glow_mat_lighten = CanvasItemMaterial.new()
	glow_mat_lighten.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_suction_anim.sprite_frames = suc_frames
	_suction_anim.position = _magic_circle.position # วางระดับเดียวกับวงเวทย์ที่พื้น
	_suction_anim.scale = Vector2(1.1, 0.48) # ทำให้แบนราบไปกับพื้นแบบเดียวกับเวทย์ (ขยายออกอีกนิด)
	_suction_anim.z_index = 0 # อยู่เหนือวงเวทย์ (วงเวทย์ z_index = -1) แต่อยู่ใต้ลูกบอลแดง
	_suction_anim.material = glow_mat_lighten # ใช้ Lighten mode ตามคำขอ
	
	# แอนิเมชันตอนเกิด ให้สเกลจาก 0 ขึ้นมาพร้อมวงเวทย์ด้วย
	var start_scale = Vector2(1.1, 0.48)
	_suction_anim.scale = Vector2.ZERO
	create_tween().tween_property(_suction_anim, "scale", start_scale, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_vfx_container.add_child(_suction_anim)
	_suction_anim.play("suck")


func _run_damage_routine() -> void:
	# Tick spacing: ระยะเวลาทั้งหมด 3 วินาที แบ่ง 5 ครั้ง ก็ประมาณ 0.5 - 0.6 วิ ต่อครั้ง
	var tick_interval: float = (SKILL_DURATION - 0.5) / float(TOTAL_TICKS)
	
	# รอก่อน Tick แรกนิดนึง ให้ลูกบอลขยายก่อน
	await get_tree().create_timer(0.4).timeout
	
	# ลูปทำดาเมจ 5 ครั้ง
	for i in range(TOTAL_TICKS):
		if not _skill_running or not is_instance_valid(_skill_area): break
		
		# คำนวณดาเมจพื้นฐาน (สมมติ 50% ของ attack ต่อ 1 tick)
		var dmg_data = calculate_damage()
		var sub_dmg = max(1, int(dmg_data["amount"] * 0.5))
		
		var enemies = _skill_area.get_overlapping_bodies()
		var hit_anyone = false
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
				if not _sucked_enemies.has(enemy):
					_sucked_enemies.append(enemy)
				# ตอนโดนดูดยังไม่ให้กระเด็น ให้ดรอปตายปกติ แต่ตั้งเป็น suction_hold เพื่อไม่ให้ศพหาย
				enemy.take_damage(sub_dmg, "suction_hold")
				hit_anyone = true
				_spawn_hit_effect(enemy.global_position)
					
		# ถ้าทำดาเมจโดนศัตรู ให้หมูเล่นท่าโจมตี
		if hit_anyone and is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")
					
		await get_tree().create_timer(tick_interval).timeout

	if not _skill_running or not is_instance_valid(_vfx_container): return


	# ───────────────────────────────────────────
	# 5. ENDING: RedSphere ย่อตัวลงอย่างรวดเร็ว → สีขาว → ขยายพ่นดาเมจครั้งสุดท้าย
	# ───────────────────────────────────────────
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill() # หยุดแอนิเมชันหัวใจเต้น
	if is_instance_valid(_pulse_tween_orbit):
		_pulse_tween_orbit.kill()

	if is_instance_valid(_red_sphere):
		var tw_implode = create_tween().set_parallel(true)
		tw_implode.tween_property(_red_sphere, "scale", Vector2(0.2, 0.2), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
		if is_instance_valid(_smoke_pivot) and _smoke_pivot.has_node("smoke1"):
			var smoke1 = _smoke_pivot.get_node("smoke1")
			tw_implode.tween_property(smoke1, "scale", Vector2(0.2, 0.2), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
		if is_instance_valid(_orbit_spark):
			tw_implode.tween_property(_orbit_spark, "scale", Vector2(0.2, 0.2), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
		await tw_implode.finished
		
		# หลังจากหดตัวแล้ว ให้แสดงเอฟเฟกต์ระเบิดใหม่ (Big Red Sphere + Suction 5) แล้วซ่อนของเดิม
		if is_instance_valid(_red_sphere):
			_red_sphere.visible = false
			
		var final_boom_node = Node2D.new()
		final_boom_node.position = _red_sphere.position
		final_boom_node.z_index = _red_sphere.z_index + 1
		
		# สร้าง Big Red Sphere
		var boom_sphere = Sprite2D.new()
		boom_sphere.texture = _tex_big_red_sphere
		boom_sphere.scale = Vector2.ZERO
		
		# สร้าง Suction Effect 5
		var boom_suction = Sprite2D.new()
		boom_suction.texture = _tex_suction_5
		boom_suction.position = Vector2(0, 40) # ขยับรูปลงล่างอีกนิดนึงให้ตรงกับพื้น
		boom_suction.scale = Vector2.ZERO
		
		# เลิกใช้ _suction_anim.material เปลี่ยนมาใช้ Shader เรืองแสงและเบลอได้
		var mat_blur = ShaderMaterial.new()
		mat_blur.shader = _blur_shader
		mat_blur.set_shader_parameter("blur_amount", 0.0)
		boom_suction.material = mat_blur
		boom_suction.z_index = -1 # ให้อยู่ระดับต่ำๆ เหมือน magic_circle
		
		final_boom_node.add_child(boom_sphere)
		final_boom_node.add_child(boom_suction)
		_vfx_container.add_child(final_boom_node)
		
		var tw_explode = create_tween().set_parallel(true)
		# ขยายจากเล็กไปใหญ่ (Suction เอามาทำเป็นวงรีแบนๆ ให้อยู่ระดับรูปลงพื้น)
		tw_explode.tween_property(boom_sphere, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# ขยาย Suction แบบเดิม
		tw_explode.tween_property(boom_suction, "scale", Vector2(1.8, 0.78), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# เบลอภาพให้ฟุ้ง
		tw_explode.tween_method(func(val: float): mat_blur.set_shader_parameter("blur_amount", val), 0.0, 3.0, 0.2)
		
		# Fade out อย่างรวดเร็วมาก (เหลือ 0.15 วิ)
		tw_explode.tween_property(boom_sphere, "modulate:a", 0.0, 0.15).set_delay(0.1)
		tw_explode.tween_property(boom_suction, "modulate:a", 0.0, 0.15).set_delay(0.05)
		
		# ดาเมจระเบิดตอนจบ x4 จาก stat ทันทีที่รูปเริ่มขยาย ไม่ต้องรอจบ
		var final_dmg = int(calculate_damage()["amount"] * 4.0)
		var hit_anyone = false
		
		# นำมอนสเตอร์ใหม่ที่อยู่ในพื้นที่เข้ามารวมกับตัวที่โดนดูดอยู่ก่อน
		if is_instance_valid(_skill_area):
			var current_enemies = _skill_area.get_overlapping_bodies()
			for enemy in current_enemies:
				if is_instance_valid(enemy) and enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
					if not _sucked_enemies.has(enemy):
						_sucked_enemies.append(enemy)
		
		for enemy in _sucked_enemies:
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				var dir = (enemy.global_position - _skill_center).normalized()
				enemy.take_damage(final_dmg, "death_explode", dir)
				hit_anyone = true
				_spawn_hit_effect(enemy.global_position)
				
		# หมูชูหมัดจังหวะระเบิด
		if hit_anyone and is_instance_valid(sprite) and sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")

		# ซ่อน node อื่นทันที
		if is_instance_valid(_smoke_pivot): _smoke_pivot.visible = false
		if is_instance_valid(_orbit_spark): _orbit_spark.visible = false
		if is_instance_valid(_magic_circle): _magic_circle.visible = false
		if is_instance_valid(_red_sphere): _red_sphere.visible = false
		if is_instance_valid(_skill_area): _skill_area.monitoring = false
		
		# Fade out suction หมุนดูด
		if is_instance_valid(_suction_anim):
			var fade_suc = create_tween()
			fade_suc.tween_property(_suction_anim, "modulate:a", 0.0, 0.2)
			
		# ระเบิดเม็ดสีแดงกระจาย
		_spawn_red_explosion()
		await tw_explode.finished
		final_boom_node.queue_free()

	if not is_inside_tree() or not is_instance_valid(_vfx_container): return

	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree(): return

	_skill_running = false
	if is_instance_valid(_vfx_container):
		_vfx_container.queue_free()

	start_cooldown()


# ── Spawn Hit Effect ──────────────────────────────────────
func _spawn_hit_effect(pos: Vector2) -> void:
	if not _hit_frames: return
	
	var hit_anim = AnimatedSprite2D.new()
	hit_anim.sprite_frames = _hit_frames
	
	# สุ่มตำแหน่งให้เหลื่อมจากจุดศูนย์กลางศัตรูนิดหน่อยเพื่อความเป็นธรรมชาติ
	var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	hit_anim.global_position = pos + random_offset
	hit_anim.z_index = 85 # ให้อยู่ทับมอนสเตอร์แต่อยู่ใต้ฮีโร่
	hit_anim.scale = Vector2(1.5, 1.5) # ขยายใหญ่ขึ้นหน่อยให้เห็นชัด
	
	# หมุนสุ่มมุม
	hit_anim.rotation = randf_range(0, TAU)
	
	get_tree().current_scene.add_child(hit_anim)
	hit_anim.play("hit")
	
	hit_anim.animation_finished.connect(func():
		if is_instance_valid(hit_anim):
			hit_anim.queue_free()
	)


# ── Red Explosion Burst ──────────────────────────────────
func _spawn_red_explosion() -> void:
	if not is_instance_valid(_vfx_container): return
	
	var burst_count: int = randi_range(16, 20)
	var burst_origin: Vector2 = Vector2(0, -60) # ตำแหน่งลูกบอลตอนลอยสุด
	
	for i in burst_count:
		var p_tex = GradientTexture2D.new()
		p_tex.width = 32
		p_tex.height = 32
		p_tex.fill = GradientTexture2D.FILL_RADIAL
		p_tex.fill_from = Vector2(0.5, 0.5)
		p_tex.fill_to = Vector2(0.5, 0.0)
		var grad = Gradient.new()
		grad.colors = [Color(1.0, 0.9, 0.8, 1.0), Color(1.0, 0.2, 0.15, 1.0), Color(0.8, 0.1, 0.05, 0.0)]
		grad.offsets = [0.0, 0.35, 1.0]
		p_tex.gradient = grad

		var particle = Sprite2D.new()
		particle.texture = p_tex
		var p_size = randf_range(6.0, 14.0)
		particle.scale = Vector2(p_size / 32.0, p_size / 32.0)
		particle.position = burst_origin
		particle.z_index = 5
		_vfx_container.add_child(particle)

		var angle = (TAU / burst_count) * i + randf_range(-0.25, 0.25)
		var dist = randf_range(80.0, 200.0) # ระเบิดออกกว้างๆ ให้สมเป็นสกิลหมู่
		var end_pos = burst_origin + Vector2(cos(angle), sin(angle)) * dist
		var dur = randf_range(0.3, 0.55)
		var delay = randf_range(0.0, 0.05)

		var tw = create_tween().set_parallel(true)
		tw.tween_property(particle, "position", end_pos, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.tween_property(particle, "scale", Vector2(0.0, 0.0), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay)
		tw.tween_property(particle, "modulate", Color(1, 1, 1, 0), dur * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay + dur * 0.4)
		tw.chain().tween_callback(particle.queue_free)

	# Flash screen shake effect
	var flash = Sprite2D.new()
	var flash_tex = GradientTexture2D.new()
	flash_tex.width = 128
	flash_tex.height = 128
	flash_tex.fill = GradientTexture2D.FILL_RADIAL
	flash_tex.fill_from = Vector2(0.5, 0.5)
	flash_tex.fill_to = Vector2(0.5, 0.0)
	var fg = Gradient.new()
	fg.colors = [Color(1.0, 1.0, 1.0, 0.9), Color(1.0, 0.4, 0.3, 0.4), Color(1.0, 0.2, 0.1, 0.0)]
	fg.offsets = [0.0, 0.4, 1.0]
	flash_tex.gradient = fg
	flash.texture = flash_tex
	flash.position = burst_origin
	flash.scale = Vector2(0.5, 0.5)
	flash.z_index = 4
	_vfx_container.add_child(flash)

	var tw_flash = create_tween().set_parallel(true)
	tw_flash.tween_property(flash, "scale", Vector2(3.5, 3.5), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_flash.tween_property(flash, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_flash.chain().tween_callback(flash.queue_free)


func _play_blood_pig_hit_sound(pos: Vector2) -> void:
	var player = AudioStreamPlayer2D.new()
	player.global_position = pos
	get_tree().current_scene.add_child(player)
	player.stream = BLOOD_PIG_HIT_SOUND
	player.bus = "SFX"
	player.max_distance = 2000
	player.volume_db = -6.0
	player.pitch_scale = 0.85 # โทนต่ำตามความชอบเดิม
	player.play()
	player.finished.connect(player.queue_free)


func _play_blood_pig_cast_sound(pos: Vector2) -> void:
	var player = AudioStreamPlayer2D.new()
	player.global_position = pos
	get_tree().current_scene.add_child(player)
	player.stream = BLOOD_PIG_CAST_SOUND
	player.bus = "SFX"
	player.max_distance = 2500
	player.volume_db = -2.0
	player.pitch_scale = 1.15
	await get_tree().create_timer(0.08, false).timeout
	if not is_instance_valid(player):
		return
	player.play()
	player.finished.connect(player.queue_free)


func _play_pig_hit_sound(pos: Vector2) -> void:
	var player = AudioStreamPlayer2D.new()
	player.global_position = pos
	get_tree().current_scene.add_child(player)
	player.stream = PIG_HIT_SOUND
	player.bus = "SFX"
	player.max_distance = 1600
	player.volume_db = -10.0
	player.pitch_scale = 1.0
	player.play()
	player.finished.connect(player.queue_free)
