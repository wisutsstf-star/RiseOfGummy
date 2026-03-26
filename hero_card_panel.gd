extends "res://upgrade_card_panel.gd"

signal hero_card_selected(hero_id: String, level: int)
signal all_cards_processed()

const LANE_DRAW_COUNT := 3
const MAX_LEVEL := 5
const HERO_UPGRADE_CHAINS := {
	"pig": [
		"pig_blood_spiral_lv1",
		"pig_blood_spiral_lv2",
		"pig_blood_spiral_lv3",
		"pig_blood_spiral_lv4",
		"pig_blood_spiral_lv5",
	],
	"rabbit": [
		"rabbit_black_bullet_lv1",
		"rabbit_black_bullet_lv2",
		"rabbit_black_bullet_lv3",
		"rabbit_black_bullet_lv4",
		"rabbit_black_bullet_lv5",
	],
	"lion": [
		"lion_ultimate_lv1",
		"lion_ultimate_lv2",
		"lion_ultimate_lv3",
	],
}


func _ready() -> void:
	super._ready()
	card_selected.connect(_on_card_selected_compat)
	next_wave_requested.connect(_on_next_wave_requested_compat)


func show_upgrade_cards() -> void:
	var card_manager := get_node_or_null("/root/CardManager")
	if card_manager == null or not card_manager.has_method("draw_cards_for_heroes"):
		push_warning("HeroCardPanel: CardManager not found.")
		show_cards([])
		return

	var heroes := _get_live_heroes()
	var drawn_entries: Array[Dictionary] = card_manager.draw_cards_for_heroes(heroes, LANE_DRAW_COUNT)
	var cards: Array[CardData] = []
	for entry in drawn_entries:
		var card: CardData = entry.get("card", null)
		if card != null:
			cards.append(card)

	show_cards(cards)


func get_hero_card_level(hero_id: String) -> int:
	var card_manager := get_node_or_null("/root/CardManager")
	if card_manager == null or not card_manager.has_method("has_card"):
		return 0

	var chain: Array = HERO_UPGRADE_CHAINS.get(hero_id, [])
	var level := 0
	for index in range(chain.size()):
		if bool(card_manager.has_card(hero_id, String(chain[index]))):
			level = index + 1
	return level


func has_hero_card(hero_id: String) -> bool:
	return get_hero_card_level(hero_id) > 0


func is_hero_max_level(hero_id: String) -> bool:
	return get_hero_card_level(hero_id) >= MAX_LEVEL


func get_heroes_ready_for_upgrade() -> Array[String]:
	var result: Array[String] = []
	var card_manager := get_node_or_null("/root/CardManager")
	if card_manager == null or not card_manager.has_method("get_next_upgrade_card_for_hero"):
		return result

	for hero_id_variant in HERO_UPGRADE_CHAINS.keys():
		var hero_id := String(hero_id_variant)
		if card_manager.get_next_upgrade_card_for_hero(hero_id) != null:
			result.append(hero_id)
	return result


func set_hero_level(hero_id: String, level: int) -> void:
	var target_level := clampi(level, 0, MAX_LEVEL)
	var current_level := get_hero_card_level(hero_id)
	if target_level <= current_level:
		return

	var card_manager := get_node_or_null("/root/CardManager")
	if card_manager == null or not card_manager.has_method("apply_card"):
		return

	var chain: Array = HERO_UPGRADE_CHAINS.get(hero_id, [])
	for index in range(current_level, mini(target_level, chain.size())):
		card_manager.apply_card(String(chain[index]), null, hero_id)


func get_save_data() -> Dictionary:
	var data := {}
	for hero_id_variant in HERO_UPGRADE_CHAINS.keys():
		var hero_id := String(hero_id_variant)
		data[hero_id] = get_hero_card_level(hero_id)
	return data


func load_save_data(data: Dictionary) -> void:
	for hero_id_variant in HERO_UPGRADE_CHAINS.keys():
		var hero_id := String(hero_id_variant)
		set_hero_level(hero_id, int(data.get(hero_id, 0)))


func _get_live_heroes() -> Array:
	var heroes: Array = []
	for hero in get_tree().get_nodes_in_group("heroes"):
		if not is_instance_valid(hero):
			continue
		if "is_dead" in hero and bool(hero.get("is_dead")):
			continue
		heroes.append(hero)
	return heroes


func _on_card_selected_compat(selection: Dictionary) -> void:
	var card: CardData = selection.get("card", null)
	if card == null:
		return
	hero_card_selected.emit(String(selection.get("hero_id", card.hero_id)), int(card.level))


func _on_next_wave_requested_compat() -> void:
	all_cards_processed.emit()
