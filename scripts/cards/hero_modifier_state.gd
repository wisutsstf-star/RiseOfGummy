extends RefCounted
class_name HeroModifierState

var hero_id: String = ""

var attack_speed_bonus_pct: float = 0.0
var projectile_count_bonus: int = 0
var cooldown_reduction_pct: float = 0.0
var bonus_damage_flat: int = 0

var unlocked_skills: Dictionary = {}
var tags: Dictionary = {}

var black_bullet_enabled: bool = false
var black_bullet_shot_count: int = 3
var black_bullet_damage_multiplier: float = 1.0
var black_bullet_shot_interval: float = 1.2
var black_bullet_pierce: int = 1
var black_bullet_falloff: float = 0.0
var black_bullet_speed_multiplier: float = 1.0
var black_bullet_full_damage: bool = false

var special_bullet_every_x_shots: int = 0
var special_bullet_count: int = 1
var special_bullet_pierce_all: bool = false
var explode_chance_pct: float = 0.0
var explode_splash_pct: float = 0.0
var attack_range_bonus: float = 0.0

var lion_sword_wave_level: int = 0
var lion_sword_wave_enabled: bool = false
var lion_sword_wave_proc_chance: float = 0.0
var lion_sword_wave_damage_multiplier: float = 1.0
var lion_sword_wave_active_damage_multiplier: float = 1.0
var lion_sword_wave_range_multiplier: float = 1.0
var lion_sword_wave_width_multiplier: float = 1.0
var lion_sword_wave_knockback_force: float = 280.0
var lion_sword_wave_slow_pct: float = 0.0
var lion_sword_wave_slow_duration: float = 0.0
var lion_sword_wave_active_charge_time: float = 0.0
var lion_sword_wave_active_pierce: bool = false
var lion_sword_wave_collision_stun_duration: float = 0.0
var lion_sword_wave_pull_duration: float = 0.0
var lion_sword_wave_pull_radius: float = 160.0
var lion_sword_wave_pull_force: float = 650.0

# Berserk mode specific
var berserk_duration: float = 5.0
var berserk_wave_interval: float = 0.5
var berserk_wave_count: int = 10
var berserk_wave_damage: float = 1.5
var damage_reduction: float = 0.3

# Pig blood ultimate
var pig_blood_level: int = 0
var pig_blood_enabled: bool = false
var pig_blood_ap_multiplier: float = 0.0
var pig_blood_lifesteal_pct: float = 0.0
var pig_blood_bat_count: int = 0
var pig_blood_bat_speed: float = 100.0
var pig_blood_radius_multiplier: float = 1.0
var pig_blood_pull_force: float = 0.0
var pig_blood_slow_pct: float = 0.0
var pig_blood_slow_duration: float = 0.0
var pig_blood_pulse_count: int = 1
var pig_blood_pulse_interval: float = 0.4
var pig_blood_center_damage_pct: float = 0.0
var pig_blood_shield_pct: float = 0.0
var pig_blood_team_heal: bool = false

# Pig Hemobloom skill
var pig_hemobloom_enabled: bool = false
var pig_hemobloom_level: int = 0

func setup(p_hero_id: String) -> HeroModifierState:
	hero_id = p_hero_id
	return self


func get_attack_speed_multiplier() -> float:
	return 1.0 + (attack_speed_bonus_pct * 0.01)


func is_skill_unlocked(skill_id: String) -> bool:
	return bool(unlocked_skills.get(skill_id, false))


func unlock_skill(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	unlocked_skills[skill_id] = true


func set_tag(tag_id: String, enabled: bool = true) -> void:
	if tag_id.is_empty():
		return
	tags[tag_id] = enabled


func has_tag(tag_id: String) -> bool:
	return bool(tags.get(tag_id, false))


func apply_black_bullet_config(config: Dictionary) -> void:
	black_bullet_enabled = bool(config.get("enabled", black_bullet_enabled))
	black_bullet_shot_count = int(config.get("shot_count", black_bullet_shot_count))
	black_bullet_damage_multiplier = float(config.get("damage_multiplier", black_bullet_damage_multiplier))
	black_bullet_shot_interval = float(config.get("shot_interval", black_bullet_shot_interval))
	black_bullet_pierce = int(config.get("pierce", black_bullet_pierce))
	black_bullet_falloff = float(config.get("falloff", black_bullet_falloff))
	black_bullet_speed_multiplier = float(config.get("speed_multiplier", black_bullet_speed_multiplier))
	black_bullet_full_damage = bool(config.get("full_damage", black_bullet_full_damage))

func apply_rabbit_passive_config(config: Dictionary) -> void:
	special_bullet_every_x_shots = int(config.get("special_bullet_every_x_shots", special_bullet_every_x_shots))
	special_bullet_count = int(config.get("special_bullet_count", special_bullet_count))
	special_bullet_pierce_all = bool(config.get("special_bullet_pierce_all", special_bullet_pierce_all))
	explode_chance_pct = float(config.get("explode_chance_pct", explode_chance_pct))
	explode_splash_pct = float(config.get("explode_splash_pct", explode_splash_pct))
	attack_range_bonus += float(config.get("attack_range_bonus", 0.0))


func apply_lion_sword_wave_config(config: Dictionary) -> void:
	lion_sword_wave_level = maxi(lion_sword_wave_level, int(config.get("level", lion_sword_wave_level)))
	lion_sword_wave_enabled = bool(config.get("enabled", lion_sword_wave_enabled))
	lion_sword_wave_proc_chance = float(config.get("proc_chance", lion_sword_wave_proc_chance))
	lion_sword_wave_damage_multiplier = float(config.get("damage_multiplier", lion_sword_wave_damage_multiplier))
	lion_sword_wave_active_damage_multiplier = float(config.get("active_damage_multiplier", lion_sword_wave_active_damage_multiplier))
	lion_sword_wave_range_multiplier = float(config.get("range_multiplier", lion_sword_wave_range_multiplier))
	lion_sword_wave_width_multiplier = float(config.get("width_multiplier", lion_sword_wave_width_multiplier))
	lion_sword_wave_knockback_force = float(config.get("knockback_force", lion_sword_wave_knockback_force))
	lion_sword_wave_slow_pct = float(config.get("slow_pct", lion_sword_wave_slow_pct))
	lion_sword_wave_slow_duration = float(config.get("slow_duration", lion_sword_wave_slow_duration))
	lion_sword_wave_active_charge_time = float(config.get("active_charge_time", lion_sword_wave_active_charge_time))
	lion_sword_wave_active_pierce = bool(config.get("active_pierce", lion_sword_wave_active_pierce))
	lion_sword_wave_collision_stun_duration = float(config.get("collision_stun_duration", lion_sword_wave_collision_stun_duration))
	lion_sword_wave_pull_duration = float(config.get("pull_duration", lion_sword_wave_pull_duration))
	lion_sword_wave_pull_radius = float(config.get("pull_radius", lion_sword_wave_pull_radius))
	lion_sword_wave_pull_force = float(config.get("pull_force", lion_sword_wave_pull_force))


func apply_lion_sword_wave_berserk_config(config: Dictionary) -> void:
	# Apply base sword wave values first (level, proc_chance, damage, etc.)
	apply_lion_sword_wave_config(config)
	# Then apply berserk-specific values
	berserk_duration = float(config.get("berserk_duration", berserk_duration))
	berserk_wave_interval = float(config.get("berserk_wave_interval", berserk_wave_interval))
	berserk_wave_count = int(config.get("berserk_wave_count", berserk_wave_count))
	berserk_wave_damage = float(config.get("berserk_wave_damage", berserk_wave_damage))
	damage_reduction = float(config.get("damage_reduction", damage_reduction))


func apply_pig_blood_config(config: Dictionary) -> void:
	var lvl: int = int(config.get("level", 1))
	pig_blood_level = maxi(pig_blood_level, lvl)
	pig_blood_enabled = true
	pig_blood_bat_speed = 120.0 + float(pig_blood_level - 1) * 30.0
	pig_blood_team_heal = pig_blood_level >= 5
	match pig_blood_level:
		1:
			pig_blood_ap_multiplier = 1.4
			pig_blood_lifesteal_pct = 0.35
			pig_blood_bat_count = 1
			pig_blood_radius_multiplier = 1.0
			pig_blood_pull_force = 60.0
			pig_blood_slow_pct = 0.0
			pig_blood_slow_duration = 0.0
			pig_blood_pulse_count = 1
			pig_blood_pulse_interval = 0.0
			pig_blood_center_damage_pct = 0.0
			pig_blood_shield_pct = 0.0
		2:
			pig_blood_ap_multiplier = 1.7
			pig_blood_lifesteal_pct = 0.45
			pig_blood_bat_count = 2
			pig_blood_radius_multiplier = 1.0
			pig_blood_pull_force = 60.0
			pig_blood_slow_pct = 0.0
			pig_blood_slow_duration = 0.0
			pig_blood_pulse_count = 1
			pig_blood_pulse_interval = 0.0
			pig_blood_center_damage_pct = 0.0
			pig_blood_shield_pct = 0.0
		3:
			pig_blood_ap_multiplier = 2.1
			pig_blood_lifesteal_pct = 0.55
			pig_blood_bat_count = 3
			pig_blood_radius_multiplier = 1.0
			pig_blood_pull_force = 100.0
			pig_blood_slow_pct = 0.20
			pig_blood_slow_duration = 2.0
			pig_blood_pulse_count = 1
			pig_blood_pulse_interval = 0.0
			pig_blood_center_damage_pct = 0.0
			pig_blood_shield_pct = 0.0
		4:
			pig_blood_ap_multiplier = 2.6
			pig_blood_lifesteal_pct = 0.70
			pig_blood_bat_count = 4
			pig_blood_radius_multiplier = 1.25
			pig_blood_pull_force = 100.0
			pig_blood_slow_pct = 0.30
			pig_blood_slow_duration = 2.5
			pig_blood_pulse_count = 1
			pig_blood_pulse_interval = 0.0
			pig_blood_center_damage_pct = 0.4
			pig_blood_shield_pct = 0.0
		5:
			pig_blood_ap_multiplier = 3.2
			pig_blood_lifesteal_pct = 0.85
			pig_blood_bat_count = 6
			pig_blood_radius_multiplier = 1.25
			pig_blood_pull_force = 100.0
			pig_blood_slow_pct = 0.30
			pig_blood_slow_duration = 2.5
			pig_blood_pulse_count = 7
			pig_blood_pulse_interval = 0.4
			pig_blood_center_damage_pct = 0.0
			pig_blood_shield_pct = 0.15
		_:
			pig_blood_ap_multiplier = 3.2
			pig_blood_lifesteal_pct = 0.85
			pig_blood_bat_count = 6
			pig_blood_radius_multiplier = 1.25
			pig_blood_pull_force = 100.0
			pig_blood_slow_pct = 0.30
			pig_blood_slow_duration = 2.5
			pig_blood_pulse_count = 7
			pig_blood_pulse_interval = 0.4
			pig_blood_center_damage_pct = 0.0
			pig_blood_shield_pct = 0.15

func apply_pig_hemobloom_config(config: Dictionary) -> void:
	var lvl: int = int(config.get("level", 1))
	pig_hemobloom_level = maxi(pig_hemobloom_level, lvl)
	pig_hemobloom_enabled = true

func to_debug_dict() -> Dictionary:
	return {
		"hero_id": hero_id,
		"attack_speed_bonus_pct": attack_speed_bonus_pct,
		"projectile_count_bonus": projectile_count_bonus,
		"cooldown_reduction_pct": cooldown_reduction_pct,
		"bonus_damage_flat": bonus_damage_flat,
		"black_bullet_enabled": black_bullet_enabled,
		"black_bullet_shot_count": black_bullet_shot_count,
		"black_bullet_damage_multiplier": black_bullet_damage_multiplier,
		"black_bullet_shot_interval": black_bullet_shot_interval,
		"special_bullet_every_x_shots": special_bullet_every_x_shots,
		"special_bullet_count": special_bullet_count,
		"special_bullet_pierce_all": special_bullet_pierce_all,
		"explode_chance_pct": explode_chance_pct,
		"explode_splash_pct": explode_splash_pct,
		"attack_range_bonus": attack_range_bonus,
		"black_bullet_pierce": black_bullet_pierce,
		"black_bullet_falloff": black_bullet_falloff,
		"black_bullet_speed_multiplier": black_bullet_speed_multiplier,
		"black_bullet_full_damage": black_bullet_full_damage,
		"lion_sword_wave_level": lion_sword_wave_level,
		"lion_sword_wave_enabled": lion_sword_wave_enabled,
		"lion_sword_wave_proc_chance": lion_sword_wave_proc_chance,
		"lion_sword_wave_damage_multiplier": lion_sword_wave_damage_multiplier,
		"lion_sword_wave_active_damage_multiplier": lion_sword_wave_active_damage_multiplier,
		"lion_sword_wave_range_multiplier": lion_sword_wave_range_multiplier,
		"lion_sword_wave_width_multiplier": lion_sword_wave_width_multiplier,
		"lion_sword_wave_knockback_force": lion_sword_wave_knockback_force,
		"lion_sword_wave_slow_pct": lion_sword_wave_slow_pct,
		"lion_sword_wave_slow_duration": lion_sword_wave_slow_duration,
		"lion_sword_wave_active_charge_time": lion_sword_wave_active_charge_time,
		"lion_sword_wave_active_pierce": lion_sword_wave_active_pierce,
		"lion_sword_wave_collision_stun_duration": lion_sword_wave_collision_stun_duration,
		"lion_sword_wave_pull_duration": lion_sword_wave_pull_duration,
		"lion_sword_wave_pull_radius": lion_sword_wave_pull_radius,
		"lion_sword_wave_pull_force": lion_sword_wave_pull_force,
		# Berserk mode
		"berserk_duration": berserk_duration,
		"berserk_wave_interval": berserk_wave_interval,
		"berserk_wave_count": berserk_wave_count,
		"berserk_wave_damage": berserk_wave_damage,
		"damage_reduction": damage_reduction,
		# Pig blood ultimate
		"pig_blood_level": pig_blood_level,
		"pig_blood_enabled": pig_blood_enabled,
		"pig_blood_ap_multiplier": pig_blood_ap_multiplier,
		"pig_blood_lifesteal_pct": pig_blood_lifesteal_pct,
		"pig_blood_bat_count": pig_blood_bat_count,
		"pig_blood_bat_speed": pig_blood_bat_speed,
		"pig_blood_radius_multiplier": pig_blood_radius_multiplier,
		"pig_blood_pull_force": pig_blood_pull_force,
		"pig_blood_slow_pct": pig_blood_slow_pct,
		"pig_blood_slow_duration": pig_blood_slow_duration,
		"pig_blood_pulse_count": pig_blood_pulse_count,
		"pig_blood_pulse_interval": pig_blood_pulse_interval,
		"pig_blood_center_damage_pct": pig_blood_center_damage_pct,
		"pig_blood_shield_pct": pig_blood_shield_pct,
		"pig_blood_team_heal": pig_blood_team_heal,
		"pig_hemobloom_enabled": pig_hemobloom_enabled,
		"pig_hemobloom_level": pig_hemobloom_level,
		"unlocked_skills": unlocked_skills.duplicate(true),
		"tags": tags.duplicate(true),
	}