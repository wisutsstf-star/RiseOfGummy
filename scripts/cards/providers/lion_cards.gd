extends RefCounted
class_name LionCards

const CardDataType = preload("res://scripts/cards/card_data.gd")
const HERO_ID := "lion"
const _icon_skill := preload("res://assets/portraits/ui_hero_lion_skill_1.png")
const CARD_BACKGROUND_LION := preload("res://assets/cards/Lionblade Beam.png")


static func _hl(text: String) -> String:
	return "[b]%s[/b]" % text


static func build_cards() -> Array[CardData]:
	return [
		# ── Passive branch ──
		_make_passive_lv1(),
		_make_passive_lv2(),
		# ── Ultimate branch ──
		_make_ultimate_lv1(),
		_make_ultimate_lv2(),
		_make_ultimate_lv3(),
	]


# ═══════════════════════════════════════════════════
#  Passive Branch  (passive_lv1 → passive_lv2)
# ═══════════════════════════════════════════════════

static func _make_passive_lv1() -> CardData:
	return CardDataType.make({
		"id": "lion_passive_lv1",
		"hero_id": HERO_ID,
		"card_name": "ดาบสั่น",
		"card_type": "passive",
		"description": "โจมตีปกติมีโอกาส %s ปล่อยคลื่นสั้น\nขนาด %s ของ ultimate\nดาเมจ %s ของ ultimate" % [
			_hl("20%"), _hl("1/3"), _hl("20%")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_LION,
		"placeholder_color": Color(0.96, 0.77, 0.24, 1.0),
		"effect_id": "modify_lion_sword_wave",
		"values": {
			"level": 1,
			"enabled": true,
			"proc_chance": 0.20,
			"damage_multiplier": 0.20,
		},
		"rarity": 2,
		"level": 1,
	})


static func _make_passive_lv2() -> CardData:
	return CardDataType.make({
		"id": "lion_passive_lv2",
		"hero_id": HERO_ID,
		"card_name": "คมมีด",
		"card_type": "passive",
		"description": "โจมตีปกติ %s ปล่อยคลื่นสั้น\nดาเมจ %s ของ ultimate ผลักเล็กน้อย" % [
			_hl("ทุกครั้ง"), _hl("25%")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_LION,
		"placeholder_color": Color(0.98, 0.66, 0.18, 1.0),
		"effect_id": "modify_lion_sword_wave",
		"values": {
			"level": 2,
			"enabled": true,
			"proc_chance": 1.0,
			"damage_multiplier": 0.50,
		},
		"rarity": 3,
		"level": 2,
		"required_card_ids": ["lion_passive_lv1"],
	})


# ═══════════════════════════════════════════════════
#  Ultimate Branch  (ultimate_lv1 → ultimate_lv2 → ultimate_lv3)
# ═══════════════════════════════════════════════════

static func _make_ultimate_lv1() -> CardData:
	return CardDataType.make({
		"id": "lion_ultimate_lv1",
		"hero_id": HERO_ID,
		"card_name": "คลื่นดาบราชัน",
		"card_type": "ultimate",
		"description": "ปล่อยคลื่นดาบไปยังศัตรู\nที่ใกล้ที่สุด ทะลุศัตรูทั้งหมด\nพร้อมผลักเล็กน้อย\n\nดาเมจ: %s" % _hl("100% ATK"),
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_LION,
		"placeholder_color": Color(1.0, 0.53, 0.12, 1.0),
		"effect_id": "modify_lion_sword_wave",
		"values": {
			"level": 3,
			"enabled": true,
			"active_damage_multiplier": 1.0,
			"range_multiplier": 1.0,
			"width_multiplier": 1.0,
			"knockback_force": 400.0,
			"slow_pct": 0.50,
			"slow_duration": 2.0,
			"active_charge_time": 0.0,
			"active_pierce": true,
			"collision_stun_duration": 0.0,
			"pull_duration": 0.0,
		},
		"rarity": 4,
		"level": 1,
	})


static func _make_ultimate_lv2() -> CardData:
	return CardDataType.make({
		"id": "lion_ultimate_lv2",
		"hero_id": HERO_ID,
		"card_name": "คลื่นดาบราชัน Lv.2",
		"card_type": "ultimate",
		"description": "คลื่นดาบกว้างขึ้น\nไกลขึ้น แรงผลักเพิ่ม\n\nดาเมจ: %s\nโจมตีต่อเนื่อง %s ครั้ง" % [
			_hl("120% ATK"), _hl("2")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_LION,
		"placeholder_color": Color(1.0, 0.39, 0.10, 1.0),
		"effect_id": "modify_lion_sword_wave",
		"values": {
			"level": 4,
			"enabled": true,
			"active_damage_multiplier": 1.2,
			"range_multiplier": 1.5,
			"width_multiplier": 1.2,
			"knockback_force": 600.0,
			"slow_pct": 0.60,
			"slow_duration": 2.0,
			"active_charge_time": 0.0,
			"active_pierce": true,
			"collision_stun_duration": 0.0,
			"pull_duration": 0.0,
		},
		"rarity": 5,
		"level": 2,
		"required_card_ids": ["lion_ultimate_lv1"],
	})


static func _make_ultimate_lv3() -> CardData:
	return CardDataType.make({
		"id": "lion_ultimate_lv3",
		"hero_id": HERO_ID,
		"card_name": "คลื่นดาบราชัน Lv.3",
		"card_type": "ultimate",
		"description": "ปล่อยคลื่นดาบต่อเนื่อง\nทุกคลื่นทะลุ + ผลักรัว ๆ\n\nดาเมจ: %s\nโจมตีต่อเนื่อง %s ครั้ง" % [
			_hl("150% ATK"), _hl("8")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_LION,
		"placeholder_color": Color(1.0, 0.23, 0.08, 1.0),
		"effect_id": "modify_lion_sword_wave_berserk",
		"values": {
			"level": 5,
			"enabled": true,
			"active_damage_multiplier": 1.5,
			"range_multiplier": 2.0,
			"width_multiplier": 1.5,
			"knockback_force": 800.0,
			"slow_pct": 0.70,
			"slow_duration": 3.0,
			"active_charge_time": 0.0,
			"active_pierce": true,
			"collision_stun_duration": 0.0,
			"pull_duration": 0.0,
			"berserk_duration": 5.0,
			"berserk_wave_interval": 0.35,
			"berserk_wave_count": 8,
			"berserk_wave_damage": 1.5,
			"damage_reduction": 0.30,
		},
		"rarity": 5,
		"level": 3,
		"required_card_ids": ["lion_ultimate_lv2"],
	})
