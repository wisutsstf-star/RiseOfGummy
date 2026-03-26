extends Node
class_name CardManager

const CardEffectsType = preload("res://scripts/cards/card_effects.gd")
const HeroModifierStateType = preload("res://scripts/cards/hero_modifier_state.gd")
const LionCardsProvider = preload("res://scripts/cards/providers/lion_cards.gd")
const PigCardsProvider = preload("res://scripts/cards/providers/pig_cards.gd")
const RabbitCardsProvider = preload("res://scripts/cards/providers/rabbit_cards.gd")

# Deterministic hero upgrade chains.
# Each hero owns one lane and can only receive the next card in order.
const HERO_LANE_ORDER := ["pig", "rabbit", "lion"]
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

var card_pool: Array[CardData] = []
var _cards_by_id: Dictionary = {}
var _modifier_states_by_hero_id: Dictionary = {}
var _owned_cards_by_hero_id: Dictionary = {}


func _ready() -> void:
	if not card_pool.is_empty():
		return
	register_cards(LionCardsProvider.build_cards())
	register_cards(PigCardsProvider.build_cards())
	register_cards(RabbitCardsProvider.build_cards())


func register_cards(cards: Array[CardData]) -> void:
	for card in cards:
		if card == null or card.id.is_empty():
			continue
		card_pool.append(card)
		_cards_by_id[card.id] = card


func get_card(card_id: String) -> CardData:
	return _cards_by_id.get(card_id, null)


func get_modifier_state_for_hero_id(hero_id: String) -> HeroModifierState:
	if not _modifier_states_by_hero_id.has(hero_id):
		_modifier_states_by_hero_id[hero_id] = HeroModifierStateType.new().setup(hero_id)
	return _modifier_states_by_hero_id[hero_id]


func get_owned_count(hero_id: String, card_id: String) -> int:
	var hero_cards: Dictionary = _owned_cards_by_hero_id.get(hero_id, {})
	return int(hero_cards.get(card_id, 0))


func has_card(hero_id: String, card_id: String) -> bool:
	return get_owned_count(hero_id, card_id) > 0


func get_cards_for_hero(hero_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in card_pool:
		if card.hero_id == hero_id:
			result.append(card)
	return result


func get_offerable_cards_for_hero(hero_id: String, exclude_passive: bool = false) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in get_cards_for_hero(hero_id):
		if exclude_passive and card.card_type == "passive":
			continue
		if _can_offer_card(hero_id, card):
			result.append(card)
	return result


func draw_cards_for_hero(hero_id: String, count: int, rng: RandomNumberGenerator = null) -> Array[CardData]:
	var draw_rng := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		draw_rng.randomize()

	var candidates := get_offerable_cards_for_hero(hero_id)
	var picked: Array[CardData] = []
	while picked.size() < count and not candidates.is_empty():
		var card := _pick_weighted_random(candidates, draw_rng)
		if card == null:
			break
		picked.append(card)
		candidates.erase(card)
	return picked


func get_offerable_ultimate_cards_for_hero(hero_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in get_offerable_cards_for_hero(hero_id, true):
		if card.card_type == "ultimate":
			result.append(card)
	return result


func get_offerable_skill_cards_for_hero(hero_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in get_offerable_cards_for_hero(hero_id, true):
		if card.card_type == "skill":
			result.append(card)
	return result


func get_next_upgrade_card_for_hero(hero_id: String) -> CardData:
	var chain: Array = HERO_UPGRADE_CHAINS.get(hero_id, [])
	for card_id_variant in chain:
		var card_id := String(card_id_variant)
		if has_card(hero_id, card_id):
			continue
		var card := get_card(card_id)
		if card == null:
			return null
		if _can_offer_card(hero_id, card):
			return card
		return null
	return null


func draw_cards_for_heroes(heroes: Array, _count: int, _rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var draw_rng := _rng if _rng != null else RandomNumberGenerator.new()
	if _rng == null:
		draw_rng.randomize()

	var heroes_by_id: Dictionary = {}
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		var hero_id := _resolve_hero_id(hero)
		if hero_id.is_empty() or heroes_by_id.has(hero_id):
			continue
		heroes_by_id[hero_id] = hero

	var picked: Array[Dictionary] = []
	for hero_id in HERO_LANE_ORDER:
		if not heroes_by_id.has(hero_id):
			continue
			
		# Ultimate card
		var ult_candidates := get_offerable_ultimate_cards_for_hero(hero_id)
		var picked_ult = _pick_weighted_random(ult_candidates, draw_rng)
		if picked_ult != null:
			picked.append({
				"hero": heroes_by_id[hero_id],
				"hero_id": hero_id,
				"card": picked_ult,
			})
			
		# Non-ultimate card
		var skill_candidates := get_offerable_skill_cards_for_hero(hero_id)
		var picked_skill = _pick_weighted_random(skill_candidates, draw_rng)
		if picked_skill != null:
			picked.append({
				"hero": heroes_by_id[hero_id],
				"hero_id": hero_id,
				"card": picked_skill,
			})

	return picked


func apply_card(card_or_id: Variant, hero: Node = null, hero_id_override: String = "") -> bool:
	var card: CardData = card_or_id if card_or_id is CardData else get_card(String(card_or_id))
	if card == null:
		return false

	var hero_id := hero_id_override if not hero_id_override.is_empty() else _resolve_hero_id(hero, card.hero_id)
	if hero_id.is_empty() or not _can_offer_card(hero_id, card):
		return false

	var modifier_state := get_modifier_state_for_hero_id(hero_id)
	CardEffectsType.apply_effect(card.effect_id, hero, modifier_state, card.values)
	_register_card_pick(hero_id, card.id)
	
	# Sync pig ultimate progress if applicable
	_sync_pig_ultimate_progress(card)
	
	return true


func force_apply_card(card_id: String, hero: Node, hero_id_override: String = "") -> bool:
	var card: CardData = get_card(card_id)
	if card == null:
		return false
	var hero_id := hero_id_override if not hero_id_override.is_empty() else _resolve_hero_id(hero, card.hero_id)
	if hero_id.is_empty():
		return false
	if has_card(hero_id, card_id):
		return false # already applied
	var modifier_state := get_modifier_state_for_hero_id(hero_id)
	CardEffectsType.apply_effect(card.effect_id, hero, modifier_state, card.values)
	_register_card_pick(hero_id, card_id)
	return true


func reset_runtime() -> void:
	_modifier_states_by_hero_id.clear()
	_owned_cards_by_hero_id.clear()


func _register_card_pick(hero_id: String, card_id: String) -> void:
	var hero_cards: Dictionary = _owned_cards_by_hero_id.get(hero_id, {})
	hero_cards[card_id] = int(hero_cards.get(card_id, 0)) + 1
	_owned_cards_by_hero_id[hero_id] = hero_cards

func _sync_pig_ultimate_progress(card: CardData) -> void:
	if card == null:
		return
	if card.hero_id != "pig" or card.card_type != "ultimate":
		return
	if not Engine.has_singleton("GameStats"):
		return

	var stats = Engine.get_singleton("GameStats")
	if stats == null:
		return

	var current_level := 0
	if stats.has_method("get_pig_ult_level"):
		current_level = int(stats.get_pig_ult_level())
	elif "pig_ult_level" in stats:
		current_level = int(stats.pig_ult_level)

	var target_level := maxi(current_level, int(card.level))
	if stats.has_method("set_pig_ult_level"):
		stats.set_pig_ult_level(target_level)
	elif "pig_ult_level" in stats:
		stats.pig_ult_level = target_level


func _can_offer_card(hero_id: String, card: CardData) -> bool:
	if card.hero_id != hero_id:
		return false
	if card.max_pick_count > 0 and get_owned_count(hero_id, card.id) >= card.max_pick_count:
		return false
	for required_card_id in card.required_card_ids:
		if not has_card(hero_id, required_card_id):
			return false
	return true


func _resolve_hero_id(hero: Node, fallback_hero_id: String = "") -> String:
	if is_instance_valid(hero):
		if hero.has_method("get_hero_id"):
			return String(hero.get_hero_id())
		if not String(hero.name).is_empty():
			return String(hero.name).to_lower()
	return fallback_hero_id


func _pick_weighted_random(cards: Array[CardData], rng: RandomNumberGenerator) -> CardData:
	if cards.is_empty():
		return null

	var total_weight := 0.0
	for card in cards:
		total_weight += maxf(0.0, card.weight)

	if total_weight <= 0.0:
		return cards[rng.randi_range(0, cards.size() - 1)]

	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for card in cards:
		cursor += maxf(0.0, card.weight)
		if roll <= cursor:
			return card
	return cards.back()


func _pick_weighted_random_entry(entries: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	if entries.is_empty():
		return {}

	var total_weight := 0.0
	for entry in entries:
		var card: CardData = entry.get("card", null)
		if card != null:
			total_weight += maxf(0.0, card.weight)

	if total_weight <= 0.0:
		return entries[rng.randi_range(0, entries.size() - 1)]

	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for entry in entries:
		var card: CardData = entry.get("card", null)
		if card == null:
			continue
		cursor += maxf(0.0, card.weight)
		if roll <= cursor:
			return entry
	return entries.back()
