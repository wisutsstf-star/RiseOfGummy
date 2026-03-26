extends RefCounted
class_name RabbitCards

const CardDataType = preload("res://scripts/cards/card_data.gd")
const HERO_ID := "rabbit"
const CARD_BACKGROUND_RABBIT := preload("res://assets/cards/blackbullet_card_base.png")
const ICON_BLACK_BULLET := preload("res://assets/cards/blackbullet_card_base.png")


static func _hl(text: String) -> String:
	return "[b]%s[/b]" % text


static func build_cards() -> Array[CardData]:
	return [
		_make_black_bullet_lv1(),
		_make_black_bullet_lv2(),
		_make_black_bullet_lv3(),
		_make_black_bullet_lv4(),
		_make_black_bullet_lv5(),
		_make_black_bullet_passive_lv1(),
		_make_black_bullet_passive_lv2(),
		_make_black_bullet_passive_lv3(),
	]


# ═══════════════════════════════════════════════════
#  Ultimate Branch — Black Bullet (lv1 → lv5)
# ═══════════════════════════════════════════════════

static func _make_black_bullet_lv1() -> CardData:
	return _make_black_bullet_card(
		"rabbit_black_bullet_lv1", 1, 6, 100, 0.6, 3, 1.0,
		Color(0.18, 0.18, 0.18, 1.0), [])


static func _make_black_bullet_lv2() -> CardData:
	return _make_black_bullet_card(
		"rabbit_black_bullet_lv2", 2, 10, 115, 0.45, 3, 0.95,
		Color(0.23, 0.23, 0.23, 1.0), ["rabbit_black_bullet_lv1"])


static func _make_black_bullet_lv3() -> CardData:
	return _make_black_bullet_card(
		"rabbit_black_bullet_lv3", 3, 12, 130, 0.35, 4, 0.9,
		Color(0.28, 0.28, 0.28, 1.0), ["rabbit_black_bullet_lv2"])


static func _make_black_bullet_lv4() -> CardData:
	return _make_black_bullet_card(
		"rabbit_black_bullet_lv4", 4, 15, 150, 0.25, 4, 0.8,
		Color(0.33, 0.33, 0.33, 1.0), ["rabbit_black_bullet_lv3"])


static func _make_black_bullet_lv5() -> CardData:
	return _make_black_bullet_card(
		"rabbit_black_bullet_lv5", 5, 20, 175, 0.15, 5, 0.65,
		Color(0.07, 0.07, 0.07, 1.0), ["rabbit_black_bullet_lv4"])


# ═══════════════════════════════════════════════════
#  Passive Branch — Piercing / Explosive Rounds
# ═══════════════════════════════════════════════════

static func _make_black_bullet_passive_lv1() -> CardData:
	return CardDataType.make({
		"id": "rabbit_black_bullet_passive_lv1",
		"hero_id": HERO_ID,
		"card_name": "Piercing Rounds",
		"card_type": "passive",
		"description": "ทุก %s นัด\nยิงกระสุนพิเศษ %s นัด" % [_hl("10"), _hl("2")],
		"icon": ICON_BLACK_BULLET,
		"card_background": CARD_BACKGROUND_RABBIT,
		"placeholder_color": Color(0.6, 0.2, 0.8, 1.0),
		"effect_id": "modify_rabbit_passive",
		"values": {
			"special_bullet_every_x_shots": 10,
			"special_bullet_count": 2,
			"special_bullet_pierce_all": false,
		},
		"rarity": 3,
		"level": 1,
		"weight": 1.0,
		"required_card_ids": ["rabbit_black_bullet_lv1"],
	})


static func _make_black_bullet_passive_lv2() -> CardData:
	return CardDataType.make({
		"id": "rabbit_black_bullet_passive_lv2",
		"hero_id": HERO_ID,
		"card_name": "Explosive Rounds",
		"card_type": "passive",
		"description": "กระสุนทุกนัดมีโอกาส %s ระเบิด\nดาเมจสาด %s ระยะยิง %s" % [
			_hl("30%"), _hl("20%"), _hl("+50")],
		"icon": ICON_BLACK_BULLET,
		"card_background": CARD_BACKGROUND_RABBIT,
		"placeholder_color": Color(0.7, 0.3, 0.9, 1.0),
		"effect_id": "modify_rabbit_passive",
		"values": {
			"explode_chance_pct": 30.0,
			"explode_splash_pct": 20.0,
			"attack_range_bonus": 50.0,
		},
		"rarity": 3,
		"level": 2,
		"weight": 0.9,
		"required_card_ids": ["rabbit_black_bullet_passive_lv1"],
	})


static func _make_black_bullet_passive_lv3() -> CardData:
	return CardDataType.make({
		"id": "rabbit_black_bullet_passive_lv3",
		"hero_id": HERO_ID,
		"card_name": "Explosive Rounds II",
		"card_type": "passive",
		"description": "กระสุนทุกนัดมีโอกาส %s ระเบิด\nดาเมจสาด %s ระยะยิง %s" % [
			_hl("50%"), _hl("50%"), _hl("+100")],
		"icon": ICON_BLACK_BULLET,
		"card_background": CARD_BACKGROUND_RABBIT,
		"placeholder_color": Color(0.8, 0.4, 1.0, 1.0),
		"effect_id": "modify_rabbit_passive",
		"values": {
			"explode_chance_pct": 50.0,
			"explode_splash_pct": 50.0,
			"attack_range_bonus": 100.0,
		},
		"rarity": 4,
		"level": 3,
		"weight": 0.8,
		"required_card_ids": ["rabbit_black_bullet_passive_lv2"],
	})


# ═══════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════

static func _make_black_bullet_card(
	card_id: String,
	level: int,
	shot_count: int,
	damage_pct: int,
	shot_interval: float,
	rarity: int,
	weight: float,
	placeholder_color: Color,
	required_card_ids: Array[String]
) -> CardData:
	return CardDataType.make({
		"id": card_id,
		"hero_id": HERO_ID,
		"card_name": "Black Bullet",
		"card_type": "ultimate",
		"description": "กระสุนดำ ยิง %s นัด %s ศัตรูทั้งหมด\nสร้างดาเมจ %s ต่อเป้าหมาย" % [
			_hl(str(shot_count)), _hl("ทะลุ"), _hl("%d%%" % damage_pct)],
		"icon": ICON_BLACK_BULLET,
		"card_background": CARD_BACKGROUND_RABBIT,
		"placeholder_color": placeholder_color,
		"effect_id": "modify_black_bullet",
		"values": {
			"enabled": true,
			"shot_count": shot_count,
			"damage_multiplier": float(damage_pct) / 100.0,
			"shot_interval": shot_interval,
			"pierce": -1,
		},
		"rarity": rarity,
		"level": level,
		"weight": weight,
		"required_card_ids": required_card_ids,
	})
