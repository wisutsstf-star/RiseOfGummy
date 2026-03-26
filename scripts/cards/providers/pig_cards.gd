extends RefCounted
class_name PigCards

const CardDataType = preload("res://scripts/cards/card_data.gd")
const HERO_ID := "pig"
const _icon_skill := preload("res://assets/portraits/ui_hero_pig_skill_1.png")
const CARD_BACKGROUND_PIG := preload("res://assets/cards/BloodPigSkill.png")


static func _hl(text: String) -> String:
	return "[b]%s[/b]" % text


static func build_cards() -> Array[CardData]:
	return [
		_make_blood_spiral_lv1(),
		_make_blood_spiral_lv2(),
		_make_blood_spiral_lv3(),
		_make_blood_spiral_lv4(),
		_make_blood_spiral_lv5(),
		_make_hemobloom_lv1(),
		_make_hemobloom_lv2(),
		_make_hemobloom_lv3(),
	]


static func _make_blood_spiral_lv1() -> CardData:
	return CardDataType.make({
		"id": "pig_blood_spiral_lv1",
		"hero_id": HERO_ID,
		"card_name": "Blood Curse",
		"card_type": "ultimate",
		"description": "ปล่อยวงเลือดวน ดาเมจ %s ดูดเลือด %s\nส่งค้างคาว %s ไล่ล่าศัตรู" % [
			_hl("140% AP"), _hl("35%"), _hl("1 ตัว")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.85, 0.15, 0.15, 1.0),
		"effect_id": "pig_blood_spiral",
		"values": {"level": 1},
		"rarity": 4,
		"level": 1,
		"weight": 0.7,
	})


static func _make_blood_spiral_lv2() -> CardData:
	return CardDataType.make({
		"id": "pig_blood_spiral_lv2",
		"hero_id": HERO_ID,
		"card_name": "Bat Swarm",
		"card_type": "ultimate",
		"description": "ดาเมจ %s ดูดเลือด %s\nค้างคาว %s บินเร็วขึ้น" % [
			_hl("170% AP"), _hl("45%"), _hl("2 ตัว")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.80, 0.10, 0.10, 1.0),
		"effect_id": "pig_blood_spiral",
		"values": {"level": 2},
		"rarity": 4,
		"level": 2,
		"weight": 0.65,
		"required_card_ids": ["pig_blood_spiral_lv1"],
	})


static func _make_blood_spiral_lv3() -> CardData:
	return CardDataType.make({
		"id": "pig_blood_spiral_lv3",
		"hero_id": HERO_ID,
		"card_name": "Blood Ritual",
		"card_type": "ultimate",
		"description": "ดาเมจ %s ดูดเลือด %s\nค้างคาว %s ชะลอศัตรู %s" % [
			_hl("210% AP"), _hl("55%"), _hl("3 ตัว"), _hl("20%")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.75, 0.05, 0.05, 1.0),
		"effect_id": "pig_blood_spiral",
		"values": {"level": 3},
		"rarity": 4,
		"level": 3,
		"weight": 0.6,
		"required_card_ids": ["pig_blood_spiral_lv2"],
	})


static func _make_blood_spiral_lv4() -> CardData:
	return CardDataType.make({
		"id": "pig_blood_spiral_lv4",
		"hero_id": HERO_ID,
		"card_name": "Blood Frenzy",
		"card_type": "ultimate",
		"description": "ดาเมจ %s ดูดเลือด %s\nค้างคาว %s ชะลอ %s\nศัตรูตรงกลางโดนดาเมจเพิ่ม" % [
			_hl("260% AP"), _hl("70%"), _hl("4 ตัว"), _hl("30%")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.70, 0.00, 0.00, 1.0),
		"effect_id": "pig_blood_spiral",
		"values": {"level": 4},
		"rarity": 4,
		"level": 4,
		"weight": 0.55,
		"required_card_ids": ["pig_blood_spiral_lv3"],
	})


static func _make_blood_spiral_lv5() -> CardData:
	return CardDataType.make({
		"id": "pig_blood_spiral_lv5",
		"hero_id": HERO_ID,
		"card_name": "Bat Queen",
		"card_type": "ultimate",
		"description": "วงเลือด %s ลูก ดาเมจ %s\nดูดเลือด %s ค้างคาว %s\nฟื้นเลือดทีม + โล่เลือด" % [
			_hl("7"), _hl("320% AP"), _hl("85%"), _hl("6 ตัว")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.65, 0.00, 0.00, 1.0),
		"effect_id": "pig_blood_spiral",
		"values": {"level": 5},
		"rarity": 4,
		"level": 5,
		"weight": 0.5,
		"required_card_ids": ["pig_blood_spiral_lv4"],
	})


static func _make_hemobloom_lv1() -> CardData:
	return CardDataType.make({
		"id": "pig_hemobloom_lv1",
		"hero_id": HERO_ID,
		"card_name": "Hemobloom",
		"card_type": "passive",
		"description": "การโจมตีปกติทุก %s ครั้ง\nยิงลูกเลือดไปข้างหน้า" % _hl("3"),
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.85, 0.2, 0.3, 1.0),
		"effect_id": "pig_hemobloom",
		"values": {"level": 1},
		"rarity": 4,
		"level": 1,
		"weight": 0.7,
	})


static func _make_hemobloom_lv2() -> CardData:
	return CardDataType.make({
		"id": "pig_hemobloom_lv2",
		"hero_id": HERO_ID,
		"card_name": "Hemobloom II",
		"card_type": "passive",
		"description": "การโจมตีปกติทุก %s ครั้ง\nยิงลูกเลือด %s แรงขึ้น" % [_hl("3"), _hl("ใหญ่ขึ้น")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.80, 0.15, 0.25, 1.0),
		"effect_id": "pig_hemobloom",
		"values": {"level": 2},
		"rarity": 4,
		"level": 2,
		"weight": 0.65,
		"required_card_ids": ["pig_hemobloom_lv1"],
	})


static func _make_hemobloom_lv3() -> CardData:
	return CardDataType.make({
		"id": "pig_hemobloom_lv3",
		"hero_id": HERO_ID,
		"card_name": "Hemobloom III",
		"card_type": "passive",
		"description": "การโจมตีปกติทุก %s ครั้ง\nยิงลูกเลือดใหญ่ %s เมื่อชน" % [_hl("3"), _hl("ระเบิด")],
		"icon": _icon_skill,
		"card_background": CARD_BACKGROUND_PIG,
		"placeholder_color": Color(0.75, 0.1, 0.2, 1.0),
		"effect_id": "pig_hemobloom",
		"values": {"level": 3},
		"rarity": 4,
		"level": 3,
		"weight": 0.6,
		"required_card_ids": ["pig_hemobloom_lv2"],
	})
