extends Node2D

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_stages_completed()
signal request_show_cards(cards: Array[CardData])
signal stage_advanced(stage_level: int)

const WAVES_PER_STAGE := 10
const WAVE_START_DELAY := 1.0
const SPAWN_OUTSIDE_OFFSET := 100.0
const SPAWN_MIDDLE_MIN_RATIO := 0.20
const SPAWN_MIDDLE_MAX_RATIO := 0.80
const STAGE_HP_SCALE := 0.25
const STAGE_SPEED_SCALE := 0.05
const STAGE_COOLDOWN_SCALE := 0.04

# Restricted zone: top 20% of screen - enemies can't WALK here (keeps movement out of sky)
const RESTRICTED_TOP_ZONE_HEIGHT_RATIO := 0.2
const RESTRICTED_TOP_ZONE_SPAWN_MARGIN := 12.0

# Side-spawn restriction: left/right enemies spawn only from bottom 50% of screen
const SIDE_SPAWN_MIN_Y_RATIO := 0.5

@export_range(0, 999, 1) var max_stages: int = 0

const DEFAULT_JELLY_BEAN_MELEE_SCENE := preload("res://shared/enemies/jelly_bean_melee/scenes/jelly_bean_melee.tscn")
const DEFAULT_JELLY_BEAN_2_SCENE := preload("res://shared/enemies/jelly_bean_2/scenes/jelly_bean_2.tscn")
const DEFAULT_JELLY_STRAW_SCENE := preload("res://shared/enemies/jelly_Straw/scenes/jelly_straw.tscn")
const DEFAULT_GUMMY_BEAR_SCENE := preload("res://shared/enemies/gummy_bear/scenes/gummy_bear.tscn")
const GUMMY_BEAR_MINIBOSS_SCENE := preload("res://shared/enemies/gummy_bear/scenes/gummy_bear_miniboss.tscn")
const JELLY_STRAW_LONGRANGE_SCENE := preload("res://shared/enemies/jelly_Straw/scenes/jelly_straw_longrange.tscn")

@export var jelly_bean_melee_scene: PackedScene
@export var jelly_bean_2_scene: PackedScene
@export var spawn_points: Array[Node2D] = []

var current_wave: int = 0
var current_stage: int = 1
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_spawning_wave: bool = false

const SPAWN_INTERVAL := 0.5
const BATCH_DELAY := 5.0
const BATCH_PERCENTAGES: Array[float] = [0.10, 0.15, 0.40, 0.35]
const LAST_BATCH_INDEX := 3
var is_card_wave_pending: bool = false
var _runtime_spawn_points: Array[Node2D] = []

const AUTO_NEXT_WAVE_DELAY := 3.0
const CARD_WAVE_DRAW_COUNT := 3
const FIRST_CARD_WAVE := 1
const CARD_WAVE_INTERVAL := 1

const PIG_ULTIMATE_CARD_IDS := [
	"pig_blood_spiral_lv1",
	"pig_blood_spiral_lv2",
	"pig_blood_spiral_lv3",
	"pig_blood_spiral_lv4",
	"pig_blood_spiral_lv5",
]
const MAX_PIG_ULT_LEVEL := 5

var wave_data := {
	1: {"jelly_bean_melee": 10},
	2: {"jelly_bean_melee": 50},
	3: {"jelly_bean_melee": 100},
	4: {"gummy_bear_miniboss": 1},
	5: {"jelly_bean_melee": 100, "jelly_bean_2": 50},
	6: {"jelly_bean_melee": 100, "jelly_Straw": 10, "jelly_bean_2": 50},
	7: {"jelly_bean_melee": 100, "jelly_bean_2": 100},
	8: {"jelly_Straw": 20, "jelly_bean_2": 150, "gummy_bear": 20},
	9: {"jelly_Straw": 50, "gummy_bear": 20},
	10: {"gummy_bear": 100}
}

var _prepared_card_wave: int = -1


func _ready() -> void:
	add_to_group("wave_manager")
	_refresh_spawn_points()


func get_stage_level() -> int:
	return current_stage


func start_next_wave() -> void:
	if is_wave_active:
		return
	
	if is_card_wave_pending:
		return

	if current_wave >= WAVES_PER_STAGE:
		if _has_completed_all_stages():
			all_stages_completed.emit()
			return
		current_stage += 1
		current_wave = 0
		_prepared_card_wave = -1
		stage_advanced.emit(current_stage)

	var next_wave := current_wave + 1
	if _should_show_cards_before_wave(next_wave) and _prepared_card_wave != next_wave:
		var cards := _draw_card_wave_cards()
		if not cards.is_empty():
			is_card_wave_pending = true
			_prepared_card_wave = next_wave
			request_show_cards.emit(cards)
			return

	current_wave += 1
	enemies_alive = 0
	is_wave_active = true
	wave_started.emit(current_wave)

	await get_tree().create_timer(WAVE_START_DELAY, false).timeout

	if not is_inside_tree() or not is_wave_active:
		return

	spawn_wave(current_wave)


func spawn_wave(wave_number: int) -> void:
	var enemies: Dictionary = wave_data.get(wave_number, {})
	if enemies.is_empty():
		push_warning("WaveManager: wave %d has no configured enemies." % wave_number)
		return

	is_spawning_wave = true

	var wave_enemies: Array[String] = []
	for enemy_type in enemies.keys():
		var count: int = int(enemies[enemy_type])
		for i in range(count):
			wave_enemies.append(String(enemy_type))
			
	wave_enemies.shuffle()
	
	var total: int = wave_enemies.size()
	var batches: Array[int] = []
	var spawned_so_far: int = 0
	
	for i in range(BATCH_PERCENTAGES.size()):
		var count: int = 0
		if i == BATCH_PERCENTAGES.size() - 1:
			count = total - spawned_so_far
		else:
			count = round(total * BATCH_PERCENTAGES[i])
		batches.append(count)
		spawned_so_far += count
		
	var enemy_index: int = 0
	for batch_idx in range(batches.size()):
		var count = batches[batch_idx]
		if count <= 0:
			continue
			
		var is_last_batch: bool = (batch_idx == LAST_BATCH_INDEX)
		
		for i in range(count):
			if not is_wave_active:
				is_spawning_wave = false
				return
				
			var enemy_type = wave_enemies[enemy_index]
			enemy_index += 1
			var enemy = _spawn_single_enemy(enemy_type)
			
			if is_last_batch and enemy != null:
				enemy.spawn_delay = randf_range(0.0, 3.0)
			
			if not is_last_batch and i < count - 1:
				await get_tree().create_timer(SPAWN_INTERVAL, false).timeout
				
		if not is_last_batch and batch_idx < batches.size() - 1:
			await get_tree().create_timer(BATCH_DELAY, false).timeout
			
	is_spawning_wave = false
	if enemies_alive <= 0 and is_wave_active:
		is_wave_active = false
		_on_wave_cleared()


func _spawn_single_enemy(enemy_type: String) -> Node:
	var scene := _resolve_enemy_scene(enemy_type)
	if scene == null:
		push_warning("WaveManager: missing scene for enemy type '%s'." % enemy_type)
		return null

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		push_warning("WaveManager: current_scene is missing, cannot spawn enemies.")
		return null

	var enemy: Node = scene.instantiate()
	if not (enemy is Node2D):
		push_warning("WaveManager: spawned scene for '%s' is not a Node2D." % enemy_type)
		return null

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

	var spawn_position: Vector2 = _get_random_spawn_position()
	var enemy_node := enemy as Node2D
	current_scene.add_child(enemy_node)
	enemy_node.global_position = spawn_position
	_apply_stage_modifiers(enemy)
	enemies_alive += 1
	return enemy_node


func _resolve_enemy_scene(enemy_type: String) -> PackedScene:
	match enemy_type:
		"jelly_bean_melee":
			return jelly_bean_melee_scene if jelly_bean_melee_scene != null else DEFAULT_JELLY_BEAN_MELEE_SCENE
		"jelly_bean_2":
			return jelly_bean_2_scene if jelly_bean_2_scene != null else DEFAULT_JELLY_BEAN_2_SCENE
		"jelly_Straw":
			return DEFAULT_JELLY_STRAW_SCENE
		"gummy_bear":
			return DEFAULT_GUMMY_BEAR_SCENE
		"gummy_bear_miniboss":
			return GUMMY_BEAR_MINIBOSS_SCENE
		"jelly_straw_longrange":
			return JELLY_STRAW_LONGRANGE_SCENE
		_:
			return null


func _get_random_spawn_position() -> Vector2:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var rect_position: Vector2 = visible_rect.position
	var size: Vector2 = visible_rect.size
	var horizontal_min: float = rect_position.x + (size.x * SPAWN_MIDDLE_MIN_RATIO)
	var horizontal_max: float = rect_position.x + (size.x * SPAWN_MIDDLE_MAX_RATIO)

	# Left/right enemies spawn only in the bottom 50% of screen
	var side_vertical_min: float = rect_position.y + (size.y * SIDE_SPAWN_MIN_Y_RATIO)
	var side_vertical_max: float = rect_position.y + (size.y * SPAWN_MIDDLE_MAX_RATIO)
	if side_vertical_min > side_vertical_max:
		side_vertical_min = side_vertical_max

	# Bottom-edge enemies use the existing restricted-zone logic
	var restricted_boundary: float = get_restricted_top_zone_boundary() + RESTRICTED_TOP_ZONE_SPAWN_MARGIN
	var vertical_min: float = maxf(rect_position.y + (size.y * SPAWN_MIDDLE_MIN_RATIO), restricted_boundary)
	var vertical_max: float = rect_position.y + (size.y * SPAWN_MIDDLE_MAX_RATIO)
	if vertical_min > vertical_max:
		vertical_min = vertical_max

	var side_roll: int = randi_range(0, 2)

	match side_roll:
		0:
			# Left edge — bottom 50% only
			return Vector2(rect_position.x - SPAWN_OUTSIDE_OFFSET, randf_range(side_vertical_min, side_vertical_max))
		1:
			# Right edge — bottom 50% only
			return Vector2(rect_position.x + size.x + SPAWN_OUTSIDE_OFFSET, randf_range(side_vertical_min, side_vertical_max))
		_:
			# Bottom edge — existing logic unchanged
			return Vector2(randf_range(horizontal_min, horizontal_max), rect_position.y + size.y + SPAWN_OUTSIDE_OFFSET)


func _apply_stage_modifiers(enemy: Node) -> void:
	if current_stage <= 1:
		return

	var stage_offset: int = current_stage - 1
	var hp_multiplier: float = 1.0 + (float(stage_offset) * STAGE_HP_SCALE)
	var speed_multiplier: float = 1.0 + (float(stage_offset) * STAGE_SPEED_SCALE)
	var cooldown_multiplier: float = max(0.2, 1.0 - (float(stage_offset) * STAGE_COOLDOWN_SCALE))

	var scaled_hp: int = max(1, int(round(float(enemy.get("max_hp")) * hp_multiplier)))
	var scaled_speed: float = max(1.0, float(enemy.get("move_speed")) * speed_multiplier)
	var scaled_cooldown: float = max(0.2, float(enemy.get("attack_cooldown")) * cooldown_multiplier)

	enemy.set("max_hp", scaled_hp)
	enemy.set("current_hp", scaled_hp)
	enemy.set("move_speed", scaled_speed)
	enemy.set("attack_cooldown", scaled_cooldown)


func _refresh_spawn_points() -> void:
	var valid_points: Array[Node2D] = []

	for point in spawn_points:
		if is_instance_valid(point):
			valid_points.append(point)

	if valid_points.is_empty():
		valid_points = _find_spawn_points_in_scene()

	if valid_points.is_empty():
		valid_points = _ensure_runtime_edge_spawn_points()

	spawn_points = valid_points


func _find_spawn_points_in_scene() -> Array[Node2D]:
	var points: Array[Node2D] = []
	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return points

	var spawn_root: Node = current_scene.get_node_or_null("SpawnPoints")
	if spawn_root == null:
		spawn_root = current_scene.find_child("SpawnPoints", true, false)

	if spawn_root == null:
		return points

	for child in spawn_root.get_children():
		if child is Node2D:
			points.append(child as Node2D)

	return points


func _ensure_runtime_edge_spawn_points() -> Array[Node2D]:
	var valid_points: Array[Node2D] = []
	for point in _runtime_spawn_points:
		if is_instance_valid(point):
			valid_points.append(point)

	if not valid_points.is_empty():
		_runtime_spawn_points = valid_points
		return _runtime_spawn_points

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return []

	var visible_rect := get_viewport().get_visible_rect()
	var size := visible_rect.size
	var positions := [
		Vector2(24.0, size.y * 0.5),
		Vector2(size.x * 0.5, 24.0),
		Vector2(size.x - 24.0, size.y * 0.5),
		Vector2(size.x * 0.5, size.y - 24.0)
	]

	_runtime_spawn_points.clear()
	for index in range(positions.size()):
		var marker := Marker2D.new()
		marker.name = "RuntimeSpawnPoint%d" % index
		marker.global_position = positions[index]
		current_scene.add_child.call_deferred(marker)
		_runtime_spawn_points.append(marker)

	return _runtime_spawn_points


func _get_pig_ult_level() -> int:
	if not Engine.has_singleton("GameStats"):
		return 0
	var stats = Engine.get_singleton("GameStats")
	if stats == null:
		return 0
	if stats.has_method("get_pig_ult_level"):
		return int(stats.get_pig_ult_level())
	if "pig_ult_level" in stats:
		return int(stats.pig_ult_level)
	return 0


func _get_next_pig_ultimate_card(cards: Array[CardData]) -> CardData:
	var pig_ult_level := _get_pig_ult_level()
	if pig_ult_level >= MAX_PIG_ULT_LEVEL:
		return null

	var next_index := pig_ult_level
	if next_index < 0 or next_index >= PIG_ULTIMATE_CARD_IDS.size():
		return null

	var next_card_id := String(PIG_ULTIMATE_CARD_IDS[next_index])
	for card in cards:
		if card != null and card.id == next_card_id:
			return card
	return null


func _filter_out_ultimate_cards(cards: Array[CardData]) -> Array[CardData]:
	var filtered: Array[CardData] = []
	for card in cards:
		if card == null:
			continue
		if card.card_type == "ultimate":
			continue
		filtered.append(card)
	return filtered


func enemy_killed() -> void:
	_decrement_enemy_count()


func _on_enemy_died(_enemy: Node2D) -> void:
	_decrement_enemy_count()
	_grant_shared_xp(_enemy)


func _grant_shared_xp(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	var xp: int = int(enemy.get("xp_reward")) if "xp_reward" in enemy else 0
	if xp <= 0:
		return
	for hero in get_tree().get_nodes_in_group("heroes"):
		if not is_instance_valid(hero):
			continue
		if "is_dead" in hero and bool(hero.get("is_dead")):
			continue
		if hero.has_method("gain_xp"):
			hero.gain_xp(xp)


func _decrement_enemy_count() -> void:
	enemies_alive -= 1
	enemies_alive = max(enemies_alive, 0)

	if enemies_alive <= 0 and is_wave_active and not is_spawning_wave:
		is_wave_active = false
		_on_wave_cleared()


func _on_wave_cleared() -> void:
	wave_cleared.emit(current_wave)
	
	# รอ 3 วิแล้วเริ่ม wave ถัดไปอัตโนมัติ
	await get_tree().create_timer(AUTO_NEXT_WAVE_DELAY, false).timeout
	_auto_start_next_wave()


func _auto_start_next_wave() -> void:
	if current_wave >= WAVES_PER_STAGE:
		if _has_completed_all_stages():
			all_stages_completed.emit()
		return

	start_next_wave()


func on_card_selected() -> void:
	is_card_wave_pending = false
	get_tree().paused = false
	start_next_wave()


func _should_show_cards_before_wave(wave_number: int) -> bool:
	if wave_number < FIRST_CARD_WAVE:
		return false
	return ((wave_number - FIRST_CARD_WAVE) % CARD_WAVE_INTERVAL) == 0


func _has_completed_all_stages() -> bool:
	return max_stages > 0 and current_stage >= max_stages


# Check if a global position is in the restricted top zone (top 20% of screen)
func is_in_restricted_top_zone(global_pos: Vector2) -> bool:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var restricted_top_boundary: float = visible_rect.position.y + (visible_rect.size.y * RESTRICTED_TOP_ZONE_HEIGHT_RATIO)
	return global_pos.y < restricted_top_boundary


# Get the boundary Y position of the restricted top zone
func get_restricted_top_zone_boundary() -> float:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	return visible_rect.position.y + (visible_rect.size.y * RESTRICTED_TOP_ZONE_HEIGHT_RATIO)


func clamp_below_restricted_top_zone(global_pos: Vector2, margin: float = 0.0) -> Vector2:
	var clamped_pos := global_pos
	var min_y := get_restricted_top_zone_boundary() + margin
	if clamped_pos.y < min_y:
		clamped_pos.y = min_y
	return clamped_pos


func _draw_card_wave_cards() -> Array[CardData]:
	var card_manager := get_node_or_null("/root/CardManager")
	if card_manager == null or not card_manager.has_method("draw_cards_for_heroes"):
		push_warning("WaveManager: CardManager not found, skipping card wave.")
		return []

	var heroes: Array = []
	for hero in get_tree().get_nodes_in_group("heroes"):
		if not is_instance_valid(hero):
			continue
		if "is_dead" in hero and bool(hero.get("is_dead")):
			continue
		heroes.append(hero)

	var drawn_entries: Array[Dictionary] = card_manager.draw_cards_for_heroes(heroes, CARD_WAVE_DRAW_COUNT)
	var cards: Array[CardData] = []
	for entry in drawn_entries:
		var card: CardData = entry.get("card", null)
		if card != null:
			cards.append(card)

	return cards
