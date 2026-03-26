extends Resource
class_name CardData

@export var id: String = ""
@export var hero_id: String = ""
@export var card_name: String = ""
@export_enum("passive", "skill", "ultimate") var card_type: String = "passive"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var hero_portrait: Texture2D
@export var card_background: Texture2D
@export var description_only_layout: bool = false
@export var placeholder_color: Color = Color(0.35, 0.35, 0.35, 1.0)
@export var effect_id: String = ""
@export var values: Dictionary = {}
@export var rarity: int = 1
@export var level: int = 1
@export var weight: float = 1.0
@export var max_pick_count: int = 1
@export var required_card_ids: Array[String] = []


static func make(config: Dictionary) -> CardData:
	var data := CardData.new()
	data.id = String(config.get("id", ""))
	data.hero_id = String(config.get("hero_id", ""))
	data.card_name = String(config.get("card_name", data.id))
	data.card_type = String(config.get("card_type", "passive"))
	data.description = String(config.get("description", ""))
	data.icon = config.get("icon", null)
	data.hero_portrait = config.get("hero_portrait", null)
	data.card_background = config.get("card_background", null)
	data.description_only_layout = bool(config.get("description_only_layout", false))
	data.placeholder_color = config.get("placeholder_color", data.placeholder_color)
	data.effect_id = String(config.get("effect_id", ""))
	data.values = config.get("values", {}).duplicate(true)
	data.rarity = int(config.get("rarity", 1))
	data.level = int(config.get("level", 1))
	data.weight = float(config.get("weight", 1.0))
	data.max_pick_count = int(config.get("max_pick_count", 1))
	for required_id in config.get("required_card_ids", []):
		data.required_card_ids.append(String(required_id))
	return data


func to_debug_dict() -> Dictionary:
	return {
		"id": id,
		"hero_id": hero_id,
		"card_name": card_name,
		"card_type": card_type,
		"description": description,
		"card_background": card_background,
		"description_only_layout": description_only_layout,
		"effect_id": effect_id,
		"values": values.duplicate(true),
		"rarity": rarity,
		"level": level,
		"weight": weight,
		"max_pick_count": max_pick_count,
		"required_card_ids": required_card_ids.duplicate(),
	}
