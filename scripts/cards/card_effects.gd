extends RefCounted
class_name CardEffects

static func apply_effect(effect_id: String, hero: Node, modifier_state: HeroModifierState, params: Dictionary) -> void:
	match effect_id:
		"modify_rabbit_passive":
			modifier_state.apply_rabbit_passive_config(params)
		"modify_black_bullet":
			modifier_state.apply_black_bullet_config(params)
		"modify_lion_sword_wave":
			modifier_state.apply_lion_sword_wave_config(params)
		"modify_lion_sword_wave_berserk":
			modifier_state.apply_lion_sword_wave_berserk_config(params)
		"add_attack_speed":
			modifier_state.attack_speed_bonus_pct += float(params.get("amount_pct", 0.0))
		"add_projectile":
			modifier_state.projectile_count_bonus += int(params.get("count", 1))
		"reduce_cooldown":
			modifier_state.cooldown_reduction_pct += float(params.get("amount_pct", 0.0))
		"unlock_skill":
			modifier_state.unlock_skill(String(params.get("skill_id", "")))
		"add_damage_flat":
			modifier_state.bonus_damage_flat += int(params.get("amount", 0))
		"set_tag":
			modifier_state.set_tag(String(params.get("tag_id", "")), bool(params.get("enabled", true)))
		"pig_blood_spiral":
			modifier_state.apply_pig_blood_config(params)
		"pig_hemobloom":
			modifier_state.apply_pig_hemobloom_config(params)
		_:
			printerr("CardEffects: unknown effect_id '%s'" % effect_id)

	_notify_hero(hero, modifier_state)


static func _notify_hero(hero: Node, modifier_state: HeroModifierState) -> void:
	if not is_instance_valid(hero):
		return
	if hero.has_method("set_card_modifier_state"):
		hero.set_card_modifier_state(modifier_state)
	elif hero.has_method("on_card_modifier_state_changed"):
		hero.on_card_modifier_state_changed(modifier_state)
