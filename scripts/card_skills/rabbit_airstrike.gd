extends Node2D

const UPGRADE_TYPE := "rabbit_airstrike"
const AIRSTRIKE_BOMB_SCENE := preload("res://characters/rabbit/scenes/RabbitAirstrikeBomb.tscn")
const BARRAGE_COOLDOWN := 6.0
const BOMB_DELAY := 0.12
const IMPACT_RADIUS := 90.0
const TARGET_JITTER := 36.0
const BOMBS_PER_LEVEL := [0, 3, 6, 9]   # index = airstrike_level

var wave_manager: Node
var _cooldown_left: float = BARRAGE_COOLDOWN
var _is_barrage_running: bool = false


func _get_airstrike_level() -> int:
	return clampi(GameStats.get_upgrade_count(UPGRADE_TYPE), 0, BOMBS_PER_LEVEL.size() - 1)


func _get_bomb_count() -> int:
	return BOMBS_PER_LEVEL[_get_airstrike_level()]


func _process(delta: float) -> void:
	if _get_airstrike_level() <= 0:
		return

	if not _is_wave_active():
		_cooldown_left = min(_cooldown_left, BARRAGE_COOLDOWN)
		return

	if _is_barrage_running:
		return

	if _get_live_enemies().is_empty():
		return

	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return

	_cooldown_left = BARRAGE_COOLDOWN
	_run_barrage()


func _is_wave_active() -> bool:
	return is_instance_valid(wave_manager) and bool(wave_manager.get("is_wave_active"))


func _run_barrage() -> void:
	if _is_barrage_running:
		return

	_is_barrage_running = true
	call_deferred("_call_barrage")


func _call_barrage() -> void:
	var bomb_count := _get_bomb_count()
	for i in range(bomb_count):
		if not _is_wave_active():
			break

		var enemies := _get_live_enemies()
		if enemies.is_empty():
			break

		var target: Node2D = enemies[randi() % enemies.size()]
		var target_pos := target.global_position
		target_pos.x += randf_range(-TARGET_JITTER, TARGET_JITTER)
		target_pos.y += randf_range(-TARGET_JITTER * 0.35, TARGET_JITTER * 0.35)
		_spawn_bomb(target_pos)

		if i < bomb_count - 1:
			await get_tree().create_timer(BOMB_DELAY).timeout

	_is_barrage_running = false


func _spawn_bomb(target_pos: Vector2) -> void:
	var bomb_root := AIRSTRIKE_BOMB_SCENE.instantiate()
	bomb_root.global_position = _get_spawn_position_above_screen(target_pos.x)
	bomb_root.target_position = target_pos
	bomb_root.damage = _get_bomb_damage()
	bomb_root.impact_radius = IMPACT_RADIUS
	add_child(bomb_root)


func _get_bomb_damage() -> int:
	var rabbit := _find_rabbit_hero()
	if is_instance_valid(rabbit) and rabbit.has_method("calculate_damage"):
		var damage_data: Dictionary = rabbit.calculate_damage()
		return max(4, int(round(float(damage_data.get("amount", 12)) * 0.35)))
	return max(4, 6 + int(GameStats.get_damage_bonus() * 0.35))


func _get_spawn_position_above_screen(target_x: float) -> Vector2:
	var rect := get_viewport().get_visible_rect()
	var y := rect.position.y - 140.0
	return Vector2(target_x, y)


func _find_rabbit_hero() -> Node2D:
	for hero in get_tree().get_nodes_in_group("heroes"):
		if not is_instance_valid(hero):
			continue
		var hero_name := String(hero.name).to_lower()
		var scene_path := String(hero.scene_file_path).to_lower()
		if "rabbit" in hero_name or "rabbit" in scene_path:
			return hero
	return null


func _get_live_enemies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and bool(enemy.get("is_dead")):
			continue
		result.append(enemy)
	return result
