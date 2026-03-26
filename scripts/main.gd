extends Node2D

const ENABLE_RABBIT_AIRSTRIKE_TEST := false
const STAGE1_BGM := preload("res://shared/audio/bgm/Clockwork Cupcake Clash.mp3")
const PICK_CARD_SFX := preload("res://shared/audio/sfx/pick_card.wav")

const UIFonts = preload("res://shared/ui/scripts/ui_fonts.gd")

@onready var crystal_heart: Area2D = $CrystalHeart
@onready var stage_bgm: AudioStreamPlayer = $Stage1BGM
@onready var pick_card_sfx: AudioStreamPlayer = $PickCardSFX
@onready var hp_label: Label = $UI/HPContainer/HPLabel
@onready var potion_label: Label = $UI/HPContainer/PotionLabel
@onready var enemy_label: Label = $UI/EnemyLabel
@onready var wave_status_label: Label = $UI/WaveStatusLabel
@onready var skill_container: HBoxContainer = $UI/SkillContainer
@onready var wave_manager: Node2D = $WaveManager

var skill_btn_scene: PackedScene = preload("res://shared/ui/scenes/SkillButton.tscn")
var rabbit_airstrike_script := preload("res://scripts/card_skills/rabbit_airstrike.gd")
var card_manager_script = load("res://scripts/cards/card_manager.gd")

var _card_panel: CanvasLayer
var _wave_hud: CanvasLayer
var _rabbit_airstrike: Node2D
var _card_manager: Node


func _ready() -> void:
	_card_manager = _ensure_card_manager()
	_setup_stage_bgm()

	GameStats.stats_changed.connect(_on_stats_changed_ui)
	_on_stats_changed_ui()
	UIFonts.apply_tree($UI)

	crystal_heart.hp_changed.connect(_on_hp_changed)
	crystal_heart.destroyed.connect(_on_destroyed)

	# Initialize HP display
	_on_hp_changed(crystal_heart.current_hp, crystal_heart.max_hp)

	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.all_stages_completed.connect(_on_all_stages_completed)

	_card_panel = CanvasLayer.new()
	_card_panel.set_script(load("res://upgrade_card_panel.gd"))
	add_child(_card_panel)
	_card_panel.card_selected.connect(_on_card_selected)

	_wave_hud = CanvasLayer.new()
	_wave_hud.set_script(load("res://wave_hud.gd"))
	_wave_hud.set("wave_manager", wave_manager)
	_wave_hud.set("card_panel", _card_panel)
	add_child(_wave_hud)

	_rabbit_airstrike = Node2D.new()
	_rabbit_airstrike.set_script(rabbit_airstrike_script)
	_rabbit_airstrike.set("wave_manager", wave_manager)
	add_child(_rabbit_airstrike)

	if ENABLE_RABBIT_AIRSTRIKE_TEST and not GameStats.has_upgrade("rabbit_airstrike"):
		GameStats.apply_upgrade({"type": "rabbit_airstrike", "value": 1})

	var heroes: Array[Node] = $Heroes.get_children()
	heroes.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	for hero in heroes:
		var btn = skill_btn_scene.instantiate()
		skill_container.add_child(btn)
		if btn.has_method("setup"):
			btn.setup(hero, 0)
		btn.set_meta("hero", hero)
		btn.set_meta("skill_index", 0)

	_apply_fixed_hero_modes(heroes)

	call_deferred("_start_initial_wave")


func _process(_delta: float) -> void:
	if is_instance_valid($Heroes):
		for hero in $Heroes.get_children():
			if hero.has_method("has_active_skill") and hero.has_active_skill(1):
				if not hero.get_meta("second_skill_unlocked_ui", false):
					hero.set_meta("second_skill_unlocked_ui", true)
					for btn in skill_container.get_children():
						if btn.has_meta("hero") and btn.has_meta("skill_index"):
							if btn.get_meta("hero") == hero and btn.get_meta("skill_index") == 1:
								if btn.has_method("setup"):
									btn.setup(hero, 1)


func _start_initial_wave() -> void:
	if is_instance_valid(wave_manager) and wave_manager.get("current_wave") == 0:
		wave_manager.start_next_wave()


func _ensure_card_manager() -> Node:
	var existing := get_node_or_null("/root/CardManager")
	if existing != null:
		return existing

	var manager: Node = card_manager_script.new()
	manager.name = "CardManager"
	get_tree().root.call_deferred("add_child", manager)
	return manager


func _apply_fixed_hero_modes(heroes: Array[Node]) -> void:
	var ground_slot_index := 0

	for hero in heroes:
		if not is_instance_valid(hero) or not hero.has_method("set_ground_mode"):
			continue

		if _is_lion_hero(hero):
			hero.set_ground_mode(true, ground_slot_index)
			ground_slot_index += 1
		else:
			hero.set_ground_mode(false)


func _is_lion_hero(hero: Node) -> bool:
	var hero_type := hero.name.to_lower()
	var scene_path := hero.scene_file_path.to_lower() if hero.scene_file_path else ""
	return "lion" in hero_type or "lion" in scene_path


func _on_wave_started(_wave_number: int) -> void:
	crystal_heart.stop_healing()

	# wave_status_label removed - handled by wave_hud.gd
	pass


func _on_wave_cleared(_wave_number: int) -> void:
	# wave_status_label removed - handled by wave_hud.gd
	pass

	var heroes: Array[Node] = []
	for hero in $Heroes.get_children():
		if _is_living_hero(hero):
			heroes.append(hero)
	# Healing disabled - keep for future feature
	#if heroes.size() > 0:
	#	crystal_heart.start_healing(heroes)


func _is_living_hero(hero: Node) -> bool:
	if not is_instance_valid(hero):
		return false
	if not ("is_dead" in hero):
		return false
	return not bool(hero.get("is_dead"))


func _on_all_stages_completed() -> void:
	# wave_status_label removed - handled by wave_hud.gd
	pass


func _on_card_selected(selection: Dictionary) -> void:
	_play_pick_card_sfx()

	if _card_manager != null and selection.has("card"):
		var hero = selection.get("hero", null)
		if _card_manager.has_method("apply_card"):
			_card_manager.apply_card(selection.get("card"), hero, String(selection.get("hero_id", "")))
		return

	if selection.has("type"):
		GameStats.apply_upgrade(selection)



func _on_hp_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]


func _on_stats_changed_ui() -> void:
	if potion_label:
		potion_label.text = "Potions: %d" % GameStats.blue_potions


func _on_destroyed() -> void:
	hp_label.text = "GAME OVER"
	# wave_status_label removed
	get_tree().paused = true


func _setup_stage_bgm() -> void:
	if not is_instance_valid(stage_bgm):
		return

	if stage_bgm.stream == null:
		stage_bgm.stream = STAGE1_BGM

	var loop_callback := Callable(self, "_on_stage_bgm_finished")
	if not stage_bgm.is_connected("finished", loop_callback):
		stage_bgm.connect("finished", loop_callback)

	stage_bgm.play()


func _on_stage_bgm_finished() -> void:
	if not is_instance_valid(stage_bgm):
		return

	stage_bgm.play()


func _play_pick_card_sfx() -> void:
	if not is_instance_valid(pick_card_sfx):
		return

	if pick_card_sfx.stream == null:
		pick_card_sfx.stream = PICK_CARD_SFX

	pick_card_sfx.stop()
	pick_card_sfx.play()
