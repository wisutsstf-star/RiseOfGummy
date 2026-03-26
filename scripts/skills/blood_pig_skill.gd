extends Node2D
class_name BloodPigSkill

signal skill_finished(skill: BloodPigSkill)

const BLOOD_COURIER_SCRIPT = preload("res://scripts/heroes/pig_blood_courier.gd")
const BLOOD_SPIRAL_SCENE = preload("res://characters/pig/scenes/PigBloodSpiral.tscn")
const BLOOD_ORB_SCENE = preload("res://characters/pig/scenes/PigBloodOrb.tscn")
const BLOOD_CORE_SCENE = preload("res://characters/pig/scenes/PigBloodCore.tscn")
const BLOOD_EXPLOSION_SCENE = preload("res://characters/pig/scenes/PigBloodExplosion.tscn")
const SUCTION_TEXTURES = [
	preload("res://characters/pig/assets/Suction Effect (1).png"),
	preload("res://characters/pig/assets/Suction Effect (2).png"),
	preload("res://characters/pig/assets/Suction Effect (3).png"),
	preload("res://characters/pig/assets/Suction Effect (4).png"),
]
const HIT_TEXTURE = preload("res://characters/pig/assets/pig_hit.png")
const DAMAGE_TICK_COUNT := 3

@export var suction_radius: float = 135.0
@export var suction_power: float = 80.0
@export var skill_duration: float = 2.0
@export var orb_count: int = 5
@export var orb_spawn_radius: float = 82.0
@export var orb_move_speed: float = 0.0
@export var orb_fallback_delay: float = 0.45
@export var explosion_radius: float = 58.0
@export var tick_damage_multiplier: float = 0.5
@export var explosion_damage_multiplier: float = 5.0

var owner_hero: Node = null
var base_damage: int = 25

var _skill_center: Vector2 = Vector2.ZERO
var _sucked_enemies: Array[Node2D] = []
var _active_orbs: Array[Node2D] = []
var _orbs_reached_center: int = 0
var _core_phase_started: bool = false
var _cleanup_started: bool = false
var _explosion_started: bool = false
var _explosion_position: Vector2 = Vector2.ZERO
var _core_sequence_finished: bool = false
var _explosion_effect_finished: bool = true
var _hit_frames: SpriteFrames = null

# ── New ultimate scaling config ───────────────────────────
var skill_level: int = 0
var ap_multiplier: float = 1.4
var lifesteal_pct: float = 0.0
var bat_count: int = 0
var bat_speed: float = 120.0
var radius_multiplier: float = 1.0
var pull_force_override: float = -1.0
var slow_pct: float = 0.0
var slow_duration: float = 0.0
var pulse_count: int = 1
var pulse_interval: float = 0.0
var center_damage_pct: float = 0.0
var shield_pct: float = 0.0
var team_heal: bool = false
var _lifesteal_pool: int = 0
var _slow_timers: Dictionary = {}
var _prepared_bat_targets: Array[Node] = []
var _prepared_bat_heal_per_bat: int = 0
var _use_upgrade_profile: bool = false
var _blood_spiral_effects: Array[Node2D] = []

@onready var _magic_circle: Sprite2D = $MagicCircle
@onready var _top_aura: Sprite2D = $TopAura
@onready var _suction_area: Area2D = $SuctionArea
@onready var _cast_sound: AudioStreamPlayer2D = $CastSound
@onready var _orb_container: Node2D = $OrbContainer
@onready var _core_container: Node2D = $CoreContainer
@onready var _effect_container: Node2D = $EffectContainer

var _suction_anim: AnimatedSprite2D = null
func setup(config: Dictionary) -> BloodPigSkill:
	owner_hero = config.get("owner_hero", owner_hero)
	base_damage = int(config.get("base_damage", base_damage))
	suction_radius = float(config.get("suction_radius", suction_radius))
	suction_power = float(config.get("suction_power", suction_power))
	skill_duration = float(config.get("skill_duration", skill_duration))
	orb_count = int(config.get("orb_count", orb_count))
	_use_upgrade_profile = config.has("skill_level")
	if _use_upgrade_profile:
		skill_level = int(config.get("skill_level", skill_level))
		ap_multiplier = float(config.get("ap_multiplier", ap_multiplier))
		lifesteal_pct = minf(float(config.get("lifesteal_pct", lifesteal_pct)), 0.90)
		bat_count = int(config.get("bat_count", bat_count))
		bat_speed = float(config.get("bat_speed", bat_speed))
		radius_multiplier = float(config.get("radius_multiplier", radius_multiplier))
		pull_force_override = float(config.get("pull_force", pull_force_override))
		slow_pct = float(config.get("slow_pct", slow_pct))
		slow_duration = float(config.get("slow_duration", slow_duration))
		pulse_count = maxi(1, int(config.get("pulse_count", pulse_count)))
		pulse_interval = maxf(0.0, float(config.get("pulse_interval", pulse_interval)))
		center_damage_pct = float(config.get("center_damage_pct", center_damage_pct))
		shield_pct = float(config.get("shield_pct", shield_pct))
		team_heal = bool(config.get("team_heal", team_heal))
		suction_radius *= radius_multiplier
		_recalculate_upgrade_profile()
	return self


func _ready() -> void:
	_skill_center = global_position
	_setup_hit_frames()
	_configure_suction_area()
	_setup_magic_circle()
	_setup_suction_vfx()
	_spawn_orbs()
	if is_instance_valid(_cast_sound):
		_cast_sound.play()
	_run_tick_sequence()
	_start_finale_guard()


func _physics_process(delta: float) -> void:
	if _cleanup_started or _core_phase_started or _explosion_started:
		return

	_pull_enemies_toward_center(delta)


func _exit_tree() -> void:
	_release_enemies()


func _configure_suction_area() -> void:
	var shape_node := _suction_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = suction_radius


func _setup_magic_circle() -> void:
	if is_instance_valid(_magic_circle):
		var circle_tween := create_tween().set_parallel(true)
		circle_tween.tween_property(_magic_circle, "scale", Vector2(0.5, 0.22), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		circle_tween.tween_property(_magic_circle, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if is_instance_valid(_top_aura):
		var aura_tween := create_tween().set_parallel(true)
		aura_tween.tween_property(_top_aura, "scale", Vector2(1.28, 0.62), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		aura_tween.tween_property(_top_aura, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _setup_suction_vfx() -> void:
	_suction_anim = AnimatedSprite2D.new()
	_suction_anim.name = "SuctionAnim"
	_suction_anim.position = Vector2.ZERO
	_suction_anim.scale = Vector2(0.1, 0.05)
	_suction_anim.z_index = 0

	var frames := SpriteFrames.new()
	frames.add_animation("suck")
	frames.set_animation_speed("suck", 20.0)
	frames.set_animation_loop("suck", true)
	for i in range(SUCTION_TEXTURES.size() - 1, -1, -1):
		frames.add_frame("suck", SUCTION_TEXTURES[i])
	_suction_anim.sprite_frames = frames

	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_suction_anim.material = glow_mat

	_effect_container.add_child(_suction_anim)
	_suction_anim.play("suck")

	var tween := create_tween()
	tween.tween_property(_suction_anim, "scale", Vector2(0.66, 0.3), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _setup_blood_spiral() -> void:
	if BLOOD_SPIRAL_SCENE == null:
		return
	_blood_spiral_effects.clear()
	var spiral_count := 3 if skill_level >= 5 else 2
	for i in range(spiral_count):
		var spiral_instance := BLOOD_SPIRAL_SCENE.instantiate()
		if not (spiral_instance is Node2D):
			continue
		var spiral := spiral_instance as Node2D
		if spiral.has_method("setup"):
			spiral.setup({
				"start_angle": (TAU / float(spiral_count)) * float(i),
				"orbit_radius": maxf(28.0, suction_radius * 0.22),
				"orbit_radius_growth": maxf(18.0, suction_radius * 0.12),
				"angular_speed": 1.25 + float(i) * 0.18,
				"pulse_speed": 4.8 + float(i) * 0.35,
				"visual_scale": maxf(0.8, suction_radius / 56.0),
				"launch_duration": 0.28,
			})
		spiral.position = Vector2.ZERO
		spiral.z_index = 1 + i
		spiral.modulate.a = 0.0
		_effect_container.add_child(spiral)
		_blood_spiral_effects.append(spiral)

	var tween := create_tween().set_parallel(true)
	for spiral in _blood_spiral_effects:
		tween.tween_property(spiral, "modulate:a", 0.92, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _spawn_orbs() -> void:
	if BLOOD_ORB_SCENE == null or orb_count <= 0:
		return

	var resolved_speed := orb_move_speed
	if resolved_speed <= 0.0:
		resolved_speed = orb_spawn_radius / maxf(skill_duration * 0.9, 0.2)

	for i in range(orb_count):
		var angle := (TAU / float(orb_count)) * float(i)
		var spawn_pos := _skill_center + Vector2(cos(angle), sin(angle)) * orb_spawn_radius
		var orb = BLOOD_ORB_SCENE.instantiate()
		if not (orb is Node2D):
			continue

		_orb_container.add_child(orb)
		(orb as Node2D).global_position = spawn_pos

		if orb.has_method("setup"):
			orb.setup({
				"owner_hero": owner_hero,
				"target_position": _skill_center,
				"orb_duration": skill_duration + orb_fallback_delay + 0.5,
				"move_speed": resolved_speed,
				"converge_only": true,
			})

		if orb.has_signal("orb_finished"):
			orb.orb_finished.connect(_on_orb_finished)
		if orb.has_signal("orb_reached_center"):
			orb.orb_reached_center.connect(_on_orb_reached_center)

		_active_orbs.append(orb)


func _run_tick_sequence() -> void:
	var tick_count := _get_damage_tick_count()
	var tick_interval := _get_damage_tick_interval(tick_count)
	for _i in range(tick_count):
		await get_tree().create_timer(tick_interval).timeout
		if _cleanup_started or _core_phase_started or not is_inside_tree():
			return
		_deal_tick_damage()


func _start_finale_guard() -> void:
	await get_tree().create_timer(skill_duration + orb_fallback_delay).timeout
	if _cleanup_started or _core_phase_started or not is_inside_tree():
		return
	_begin_core_phase()


func _pull_enemies_toward_center(delta: float) -> void:
	if not is_instance_valid(_suction_area):
		return

	var bodies := _suction_area.get_overlapping_bodies()
	var current_overlapping: Array = []

	for enemy in bodies:
		if not _is_valid_enemy(enemy):
			continue
		current_overlapping.append(enemy)
		if not _sucked_enemies.has(enemy):
			_sucked_enemies.append(enemy)
			if "is_in_pig_suction" in enemy:
				enemy.is_in_pig_suction = true
			if "pig_suction_owner" in enemy:
				enemy.pig_suction_owner = self

	for enemy in _sucked_enemies:
		if not is_instance_valid(enemy):
			continue

		var should_pull := false
		if current_overlapping.has(enemy):
			should_pull = true
		elif "is_dead" in enemy and enemy.is_dead:
			should_pull = true

		if should_pull:
			var pull := suction_power
			if pull_force_override >= 0.0:
				pull = pull_force_override
			var dir := (_skill_center - enemy.global_position).normalized()
			if enemy.global_position.distance_to(_skill_center) > 10.0:
				enemy.global_position += dir * pull * delta


func _deal_tick_damage() -> void:
	if not is_instance_valid(_suction_area):
		return

	var tick_damage := maxi(1, int(round(float(base_damage) * tick_damage_multiplier)))
	for enemy in _suction_area.get_overlapping_bodies():
		if not _is_valid_enemy(enemy):
			continue
		if not _sucked_enemies.has(enemy):
			_sucked_enemies.append(enemy)
		enemy.take_damage(tick_damage, "suction_hold")
		_spawn_hit_effect(enemy.global_position)
		# Lifesteal
		if lifesteal_pct > 0.0:
			_lifesteal_pool += maxi(1, int(round(float(tick_damage) * lifesteal_pct)))
		# Slow
		_apply_slow(enemy)

	_play_owner_attack_animation()


func _begin_core_phase() -> void:
	if _core_phase_started or _cleanup_started:
		return

	_core_phase_started = true
	_core_sequence_finished = false
	_explosion_effect_finished = false
	_collapse_remaining_orbs()
	_fade_suction_vfx()
	_spawn_core_orb()
	# Apply blood shield at level 5
	if skill_level >= 5 and shield_pct > 0.0:
		_apply_blood_shield()


func _collapse_remaining_orbs() -> void:
	for orb in _active_orbs.duplicate():
		if not is_instance_valid(orb):
			continue
		if orb.has_method("on_pig_existing_skill_hit"):
			orb.on_pig_existing_skill_hit()
		else:
			orb.queue_free()
	_active_orbs.clear()


func _fade_suction_vfx() -> void:
	if is_instance_valid(_suction_anim):
		var tween := create_tween()
		tween.tween_property(_suction_anim, "modulate:a", 0.0, 0.22)


func _spawn_core_orb() -> void:
	if BLOOD_CORE_SCENE == null:
		_core_sequence_finished = true
		_explosion_effect_finished = true
		_fade_out_and_cleanup()
		return

	var core = BLOOD_CORE_SCENE.instantiate()
	if not (core is Node2D):
		_core_sequence_finished = true
		_explosion_effect_finished = true
		_fade_out_and_cleanup()
		return

	_core_container.add_child(core)
	(core as Node2D).position = Vector2.ZERO

	if core.has_signal("explosion_requested"):
		core.explosion_requested.connect(_on_core_explosion_requested)
	if core.has_signal("sequence_finished"):
		core.sequence_finished.connect(_on_core_sequence_finished)
	if core.has_method("start_sequence"):
		core.start_sequence()


func _on_core_explosion_requested(explosion_position: Vector2) -> void:
	_prepare_for_explosion()
	# Explosion is visual only — no explosion damage
	# _deal_explosion_damage(explosion_position)
	_deliver_lifesteal()
	_spawn_bats()
	_release_enemies()
	_spawn_explosion_effect(explosion_position)
	_play_owner_attack_animation()


func _spawn_explosion_effect(explosion_position: Vector2) -> void:
	if BLOOD_EXPLOSION_SCENE == null:
		_explosion_effect_finished = true
		_complete_finale_if_ready()
		return

	var effect = BLOOD_EXPLOSION_SCENE.instantiate()
	if not (effect is Node2D):
		_explosion_effect_finished = true
		_complete_finale_if_ready()
		return

	_effect_container.add_child(effect)
	(effect as Node2D).global_position = explosion_position

	if effect.has_signal("effect_finished"):
		effect.effect_finished.connect(_on_explosion_effect_finished)
	if effect.has_method("play_explosion"):
		effect.play_explosion()
	else:
		_explosion_effect_finished = true
		_complete_finale_if_ready()


func _deal_explosion_damage(center: Vector2) -> void:
	_explosion_position = center
	var damage := maxi(1, int(round(float(base_damage) * explosion_damage_multiplier)))

	var seen_ids: Dictionary = {}
	var explosion_targets: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null:
			continue
		var enemy_id := enemy.get_instance_id()
		if seen_ids.has(enemy_id):
			continue
		seen_ids[enemy_id] = true
		explosion_targets.append(enemy)
	for enemy in _sucked_enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if seen_ids.has(enemy_id):
			continue
		seen_ids[enemy_id] = true
		explosion_targets.append(enemy)

	for enemy in explosion_targets:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var enemy_2d := enemy as Node2D
		if enemy_2d == null:
			continue
		if enemy_2d.global_position.distance_to(center) > explosion_radius:
			continue
		var dir: Vector2 = (enemy_2d.global_position - center).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var final_damage := damage
		if center_damage_pct > 0.0 and enemy_2d.global_position.distance_to(center) <= explosion_radius * 0.45:
			final_damage += maxi(1, int(round(float(base_damage) * center_damage_pct)))
		enemy.take_damage(final_damage, "death_explode", dir)
		_spawn_hit_effect(enemy_2d.global_position)
		if lifesteal_pct > 0.0:
			_lifesteal_pool += maxi(1, int(round(float(final_damage) * lifesteal_pct)))
		_apply_slow(enemy)


func _prepare_for_explosion() -> void:
	if _explosion_started:
		return
	_explosion_started = true
	if is_instance_valid(_suction_area):
		_suction_area.monitoring = false


func _on_orb_finished(orb: Node) -> void:
	_active_orbs.erase(orb)


func _on_orb_reached_center(_orb: Node) -> void:
	_orbs_reached_center += 1
	if _orbs_reached_center >= orb_count:
		_begin_core_phase()


func _on_core_sequence_finished(_core: Node) -> void:
	_core_sequence_finished = true
	_complete_finale_if_ready()


func _on_explosion_effect_finished(_effect: Node) -> void:
	_explosion_effect_finished = true
	_complete_finale_if_ready()


func _complete_finale_if_ready() -> void:
	if not _core_sequence_finished or not _explosion_effect_finished:
		return
	_fade_out_and_cleanup()


func _fade_out_and_cleanup() -> void:
	if _cleanup_started:
		return

	_cleanup_started = true
	var fade_tween := create_tween().set_parallel(true)
	if is_instance_valid(_magic_circle):
		fade_tween.tween_property(_magic_circle, "modulate:a", 0.0, 0.25)
	if is_instance_valid(_top_aura):
		fade_tween.tween_property(_top_aura, "modulate:a", 0.0, 0.25)
	if is_instance_valid(_suction_anim):
		fade_tween.tween_property(_suction_anim, "modulate:a", 0.0, 0.2)
	for spiral in _blood_spiral_effects:
		if is_instance_valid(spiral):
			fade_tween.tween_property(spiral, "modulate:a", 0.0, 0.2)

	await fade_tween.finished
	skill_finished.emit(self)
	queue_free()


func _release_enemies() -> void:
	for enemy in _sucked_enemies:
		if not is_instance_valid(enemy):
			continue
		var death_dir := Vector2.ZERO
		if enemy is Node2D:
			var ref := _explosion_position if _explosion_position != Vector2.ZERO else _skill_center
			death_dir = ((enemy as Node2D).global_position - ref).normalized()
		if death_dir == Vector2.ZERO:
			death_dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		if enemy.has_method("finalize_pig_suction_death"):
			enemy.finalize_pig_suction_death(death_dir)
		else:
			if "is_in_pig_suction" in enemy:
				enemy.is_in_pig_suction = false
			if "pig_suction_owner" in enemy:
				enemy.pig_suction_owner = null
	_sucked_enemies.clear()
	_slow_timers.clear()


func _play_owner_attack_animation() -> void:
	if not is_instance_valid(owner_hero):
		return
	if "sprite" in owner_hero and is_instance_valid(owner_hero.sprite):
		if owner_hero.sprite.sprite_frames.has_animation("attack"):
			owner_hero.sprite.play("attack")


func _is_valid_enemy(enemy: Node) -> bool:
	if not (is_instance_valid(enemy) and enemy.is_in_group("enemies") and enemy.has_method("take_damage")):
		return false
	if "is_dead" in enemy and bool(enemy.is_dead):
		return false
	return true


func _setup_hit_frames() -> void:
	if HIT_TEXTURE == null:
		return
	_hit_frames = SpriteFrames.new()
	_hit_frames.add_animation("hit")
	_hit_frames.set_animation_loop("hit", false)
	_hit_frames.set_animation_speed("hit", 12.0)
	for i in range(3):
		var atlas := AtlasTexture.new()
		atlas.atlas = HIT_TEXTURE
		atlas.region = Rect2(i * 85, 0, 85, 64)
		_hit_frames.add_frame("hit", atlas)


func _spawn_hit_effect(pos: Vector2) -> void:
	if _hit_frames == null:
		return

	var hit_anim := AnimatedSprite2D.new()
	hit_anim.sprite_frames = _hit_frames
	hit_anim.position = _effect_container.to_local(pos) + Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))
	hit_anim.z_index = 90
	hit_anim.scale = Vector2(1.5, 1.5)
	hit_anim.rotation = randf_range(0.0, TAU)
	_effect_container.add_child(hit_anim)
	hit_anim.play("hit")
	hit_anim.animation_finished.connect(_on_hit_effect_finished.bind(hit_anim))


# ══════════════════════════════════════════════════════════
# ── NEW: Slow system ──────────────────────────────────────
# ══════════════════════════════════════════════════════════

func _apply_slow(enemy: Node) -> void:
	if slow_pct <= 0.0 or slow_duration <= 0.0:
		return
	if not ("move_speed" in enemy):
		return
	var original_speed := float(enemy.get_meta("_pig_blood_original_speed", enemy.move_speed))
	var token := int(enemy.get_meta("_pig_blood_slow_token", 0)) + 1
	enemy.set_meta("_pig_blood_original_speed", original_speed)
	enemy.set_meta("_pig_blood_slow_token", token)
	enemy.move_speed = original_speed * (1.0 - slow_pct)

	var timer := get_tree().create_timer(slow_duration)
	timer.timeout.connect(_on_slow_timeout.bind(enemy.get_instance_id(), token))


func _remove_slow(enemy: Node) -> void:
	if is_instance_valid(enemy) and enemy.has_meta("_pig_blood_original_speed"):
		enemy.move_speed = float(enemy.get_meta("_pig_blood_original_speed"))
		enemy.remove_meta("_pig_blood_original_speed")
	if is_instance_valid(enemy) and enemy.has_meta("_pig_blood_slow_token"):
		enemy.remove_meta("_pig_blood_slow_token")


func _on_hit_effect_finished(hit_anim: AnimatedSprite2D) -> void:
	if is_instance_valid(hit_anim):
		hit_anim.queue_free()


func _on_slow_timeout(enemy_id: int, token: int) -> void:
	var enemy := instance_from_id(enemy_id) as Node
	if not is_instance_valid(enemy):
		return
	if int(enemy.get_meta("_pig_blood_slow_token", 0)) != token:
		return
	if enemy.has_meta("_pig_blood_original_speed"):
		enemy.move_speed = float(enemy.get_meta("_pig_blood_original_speed"))
		enemy.remove_meta("_pig_blood_original_speed")
	if enemy.has_meta("_pig_blood_slow_token"):
		enemy.remove_meta("_pig_blood_slow_token")


# ══════════════════════════════════════════════════════════
# ── NEW: Lifesteal delivery ──────────────────────────────
# ══════════════════════════════════════════════════════════

func _deliver_lifesteal() -> void:
	_prepared_bat_targets.clear()
	_prepared_bat_heal_per_bat = 0
	if _lifesteal_pool <= 0:
		return

	var targets := _resolve_heal_targets()
	if targets.is_empty():
		return

	if bat_count <= 0:
		var direct_target: Node = targets[0]
		if is_instance_valid(direct_target) and direct_target.has_method("heal"):
			direct_target.heal(_lifesteal_pool)
		return

	_prepared_bat_targets = targets.duplicate()
	_prepared_bat_heal_per_bat = maxi(1, int(round(float(_lifesteal_pool) / float(bat_count))))


# ══════════════════════════════════════════════════════════
# ── NEW: Bats ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════════

func _spawn_bats() -> void:
	if bat_count <= 0:
		return

	var targets := _prepared_bat_targets if not _prepared_bat_targets.is_empty() else _resolve_heal_targets()
	if targets.is_empty():
		return

	for i in range(bat_count):
		var target_idx := i % targets.size()
		var target: Node = targets[target_idx]
		var angle := (TAU / float(bat_count)) * float(i) + randf_range(-0.3, 0.3)
		var spawn_radius := suction_radius * 0.5
		var spawn_pos := _skill_center + Vector2(cos(angle), sin(angle)) * spawn_radius

		var courier = BLOOD_COURIER_SCRIPT.new()
		courier.global_position = spawn_pos
		courier.debug_mode = false
		var target_node: Node2D = target as Node2D
		var arrive_call := Callable()
		if is_instance_valid(target) and target.has_method("heal"):
			arrive_call = Callable(target, "heal")
		courier.setup({
			"heal_amount": _prepared_bat_heal_per_bat,
			"move_speed": maxf(bat_speed, 180.0),
			"target_node": target_node,
			"target_position": target_node.global_position if is_instance_valid(target_node) else _skill_center,
			"start_position": spawn_pos,
			"on_arrive": arrive_call,
			"hp_drained": _prepared_bat_heal_per_bat,
		})
		get_tree().current_scene.add_child(courier)


# ══════════════════════════════════════════════════════════
# ── NEW: Blood shield (level 5) ──────────────────────────
# ══════════════════════════════════════════════════════════

func _apply_blood_shield() -> void:
	if shield_pct <= 0.0:
		return
	var heroes := get_tree().get_nodes_in_group("heroes")
	for h in heroes:
		if not is_instance_valid(h):
			continue
		if "is_dead" in h and h.is_dead:
			continue
		if not ("max_hp" in h):
			continue
		var shield_amount := int(round(float(h.max_hp) * shield_pct))
		if h.has_method("apply_blood_shield"):
			h.apply_blood_shield(shield_amount, 3.0)
		elif "shield_hp" in h:
			h.shield_hp = maxi(int(h.shield_hp), shield_amount)


func _recalculate_upgrade_profile() -> void:
	var tick_count := _get_damage_tick_count()
	if pulse_count > DAMAGE_TICK_COUNT and pulse_interval > 0.0:
		skill_duration = maxf(skill_duration, 0.35 + pulse_interval * float(maxi(0, tick_count - 1)) + 0.45)

	var tick_share := 0.65
	var explosion_share := 0.35
	if pulse_count > DAMAGE_TICK_COUNT:
		tick_share = 0.85
		explosion_share = 0.15

	tick_damage_multiplier = maxf(0.05, ap_multiplier * tick_share / float(maxi(1, tick_count)))
	explosion_damage_multiplier = maxf(0.05, ap_multiplier * explosion_share)


func _get_damage_tick_count() -> int:
	if pulse_count > DAMAGE_TICK_COUNT:
		return pulse_count
	return DAMAGE_TICK_COUNT


func _get_damage_tick_interval(tick_count: int) -> float:
	if pulse_count > DAMAGE_TICK_COUNT and pulse_interval > 0.0:
		return pulse_interval
	return skill_duration / float(maxi(1, tick_count))


func _resolve_heal_targets() -> Array[Node]:
	var heroes := get_tree().get_nodes_in_group("heroes")
	var targets: Array[Node] = []
	if team_heal:
		for h in heroes:
			if is_instance_valid(h) and (not ("is_dead" in h) or not h.is_dead):
				targets.append(h)
		return targets

	var lowest: Node = null
	var lowest_ratio := 1.0
	for h in heroes:
		if not is_instance_valid(h):
			continue
		if "is_dead" in h and h.is_dead:
			continue
		if not ("current_hp" in h and "max_hp" in h):
			continue
		var ratio := float(h.current_hp) / maxf(float(h.max_hp), 1.0)
		if lowest == null or ratio < lowest_ratio:
			lowest_ratio = ratio
			lowest = h
	if lowest != null:
		targets.append(lowest)
	elif is_instance_valid(owner_hero):
		targets.append(owner_hero)
	return targets
