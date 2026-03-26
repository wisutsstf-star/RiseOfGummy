extends CanvasLayer

signal card_selected(selection: Dictionary)
signal next_wave_requested()
signal reroll_requested()

const UIFontsClass = preload("res://shared/ui/scripts/ui_fonts.gd")
const CARD_SELECT_BGM = preload("res://shared/audio/bgm/Music_pick_card.wav")
const STAR_PARTICLE_TEX = preload("res://shared/ui/assets/star_particle.png")

const LANE_ORDER := ["pig", "rabbit", "lion"]

const CARD_W := 280
const CARD_H := 400
const CARD_SIZE := Vector2(CARD_W, CARD_H)
const CARD_GAP := 40

const DESC_LEFT := 28.0
const DESC_TOP := 200.0
const DESC_WIDTH := 224.0
const DESC_HEIGHT := 165.0
const DESC_COLOR := Color(0.09, 0.09, 0.09, 1.0) # #181818
const DESC_STROKE := Color(0.94, 0.85, 0.73, 1.0) # #f0dab9
const DESC_HIGHLIGHT := "#e10b0b"

const OVERLAY_COLOR := Color(0, 0, 0, 0.68)
const DIM_MODULATE := Color(0.55, 0.55, 0.55, 0.75)
const HOVER_SCALE := 1.05
const RIBBON_COLORS := [
	Color(0.98, 0.47, 0.58, 0.95),
	Color(0.99, 0.84, 0.34, 0.95),
	Color(0.93, 0.31, 0.39, 0.95),
	Color(0.85, 0.58, 0.98, 0.90),
]
const RIBBON_BURST_MIN := 4
const RIBBON_BURST_MAX := 7
const RIBBON_THROW_STAGGER_MIN := 0.04
const RIBBON_THROW_STAGGER_MAX := 0.10
const RIBBON_HANDFULS_PER_ROUND := 2
const RIBBON_HANDFUL_PAUSE_MIN := 0.22
const RIBBON_HANDFUL_PAUSE_MAX := 0.38
const RIBBON_BURST_INTERVAL_MIN := 0.85
const RIBBON_BURST_INTERVAL_MAX := 1.45
const RIBBON_MIN_WIDTH := 5.0
const RIBBON_MAX_WIDTH := 12.0
const RIBBON_MIN_HEIGHT := 18.0
const RIBBON_MAX_HEIGHT := 42.0
const RIBBON_SPAWN_SPREAD := 240.0
const RIBBON_ROTATION_MIN := -0.45
const RIBBON_ROTATION_MAX := 0.45
const RIBBON_DRIFT_MIN := -150.0
const RIBBON_DRIFT_MAX := 150.0
const RIBBON_ASCEND_TIME_MIN := 0.7
const RIBBON_ASCEND_TIME_MAX := 1.15
const RIBBON_FALL_TIME_MIN := 1.7
const RIBBON_FALL_TIME_MAX := 2.7
const RIBBON_APEX_MIN := 55.0
const RIBBON_APEX_MAX := 175.0
const RIBBON_BOTTOM_SPAWN_MIN := 140.0
const RIBBON_BOTTOM_SPAWN_MAX := 260.0
const RIBBON_SIDE_SWING_MIN := 30.0
const RIBBON_SIDE_SWING_MAX := 130.0
const STAR_BURST_MIN := 2
const STAR_BURST_MAX := 4
const STAR_MIN_SIZE := 10.0
const STAR_MAX_SIZE := 22.0
const STAR_APEX_MIN := 130.0
const STAR_APEX_MAX := 280.0
const STAR_DRIFT_MIN := -110.0
const STAR_DRIFT_MAX := 110.0
const STAR_ASCEND_TIME_MIN := 0.75
const STAR_ASCEND_TIME_MAX := 1.2
const STAR_FALL_TIME_MIN := 1.8
const STAR_FALL_TIME_MAX := 2.8

var _fallback_card_tex: Texture2D = null
var _overlay: ColorRect
var _ribbon_layer: Control
var _card_root: HBoxContainer
var _drawn_cards: Array[Dictionary] = []
var _card_panels: Array[Control] = []
var _selected_index: int = -1
var _selected_data: Dictionary = {}
var _next_button: Button
var _action_buttons: HBoxContainer
var _main_container: VBoxContainer
var _empty_label: Label
var _card_music: AudioStreamPlayer
var _ribbon_spawn_token: int = 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_fallback_card_tex = load("res://assets/cards/blackbullet_card_base.png") as Texture2D
	_card_music = AudioStreamPlayer.new()
	_card_music.name = "CardSelectMusic"
	_card_music.stream = CARD_SELECT_BGM
	_card_music.volume_db = -14.0
	_card_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_card_music)
	_build_ui()


func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = OVERLAY_COLOR
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	_ribbon_layer = Control.new()
	_ribbon_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ribbon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ribbon_layer)

	_main_container = VBoxContainer.new()
	_main_container.set_anchor(SIDE_LEFT, 0.5)
	_main_container.set_anchor(SIDE_RIGHT, 0.5)
	_main_container.set_anchor(SIDE_TOP, 0.5)
	_main_container.set_anchor(SIDE_BOTTOM, 0.5)
	_main_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_main_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	_main_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_container.add_theme_constant_override("separation", 18)
	add_child(_main_container)

	var title_wrap := Control.new()
	title_wrap.custom_minimum_size = Vector2(420, 94)
	title_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_main_container.add_child(title_wrap)

	var title_bg := TextureRect.new()
	title_bg.texture = load("res://shared/ui/assets/bar_wave.png") as Texture2D
	title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_bg.stretch_mode = TextureRect.STRETCH_SCALE
	title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_wrap.add_child(title_bg)

	var title := Label.new()
	title.text = "เลือกการ์ด 1 ใบ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title_wrap.add_child(title)

	_empty_label = Label.new()
	_empty_label.text = "ไม่มีการ์ดให้เลือก"
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", Color.WHITE)
	_empty_label.visible = false
	_main_container.add_child(_empty_label)

	_card_root = HBoxContainer.new()
	_card_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_root.add_theme_constant_override("separation", CARD_GAP)
	_main_container.add_child(_card_root)

	_action_buttons = HBoxContainer.new()
	_action_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_buttons.add_theme_constant_override("separation", 24)
	_main_container.add_child(_action_buttons)

	var btn_tex = load("res://assets/cards/btn_select.png") as Texture2D
	var reroll_btn_tex = load("res://assets/cards/btn_select_re.png") as Texture2D
	
	var btn_normal_style = StyleBoxTexture.new()
	btn_normal_style.texture = btn_tex
	btn_normal_style.texture_margin_left = 32
	btn_normal_style.texture_margin_right = 32
	btn_normal_style.texture_margin_top = 16
	btn_normal_style.texture_margin_bottom = 16
	
	var btn_hover_style = btn_normal_style.duplicate() as StyleBoxTexture
	btn_hover_style.modulate_color = Color(1.2, 1.2, 1.2)

	var btn_pressed_style = btn_normal_style.duplicate() as StyleBoxTexture
	btn_pressed_style.modulate_color = Color(0.8, 0.8, 0.8)

	var reroll_btn_normal_style = btn_normal_style.duplicate() as StyleBoxTexture
	reroll_btn_normal_style.texture = reroll_btn_tex

	var reroll_btn_hover_style = reroll_btn_normal_style.duplicate() as StyleBoxTexture
	reroll_btn_hover_style.modulate_color = Color(1.2, 1.2, 1.2)

	var reroll_btn_pressed_style = reroll_btn_normal_style.duplicate() as StyleBoxTexture
	reroll_btn_pressed_style.modulate_color = Color(0.8, 0.8, 0.8)

	var btn_empty_style = StyleBoxEmpty.new()

	var reroll_btn = Button.new()
	reroll_btn.text = " รีใหม่ "
	reroll_btn.custom_minimum_size = Vector2(205, 62)
	reroll_btn.add_theme_font_override("font", UIFontsClass.get_button_bold_font())
	reroll_btn.add_theme_font_size_override("font_size", 26)
	reroll_btn.add_theme_color_override("font_color", Color.WHITE)
	reroll_btn.add_theme_color_override("font_outline_color", Color.BLACK)
	reroll_btn.add_theme_constant_override("outline_size", 8)
	reroll_btn.add_theme_stylebox_override("normal", reroll_btn_normal_style)
	reroll_btn.add_theme_stylebox_override("hover", reroll_btn_hover_style)
	reroll_btn.add_theme_stylebox_override("pressed", reroll_btn_pressed_style)
	reroll_btn.add_theme_stylebox_override("focus", btn_empty_style)
	
	reroll_btn.pressed.connect(func(): reroll_requested.emit())
	_action_buttons.add_child(reroll_btn)

	_next_button = Button.new()
	_next_button.text = "NEXT WAVE"
	_next_button.custom_minimum_size = Vector2(205, 62)
	_next_button.add_theme_font_override("font", UIFontsClass.get_button_bold_font())
	_next_button.add_theme_font_size_override("font_size", 26)
	_next_button.add_theme_color_override("font_color", Color.WHITE)
	_next_button.add_theme_color_override("font_outline_color", Color.BLACK)
	_next_button.add_theme_constant_override("outline_size", 8)
	_next_button.add_theme_stylebox_override("normal", btn_normal_style)
	_next_button.add_theme_stylebox_override("hover", btn_hover_style)
	_next_button.add_theme_stylebox_override("pressed", btn_pressed_style)
	_next_button.add_theme_stylebox_override("focus", btn_empty_style)
	_next_button.pressed.connect(_on_next_pressed)
	
	_action_buttons.add_child(_next_button)
	UIFontsClass.apply_tree(_main_container)
	reroll_btn.add_theme_font_override("font", UIFontsClass.get_button_bold_font())
	_next_button.add_theme_font_override("font", UIFontsClass.get_button_bold_font())


func show_cards(cards: Array[CardData]) -> void:
	_selected_index = -1
	_selected_data = {}
	_drawn_cards = _build_fixed_lane_cards(cards)
	_clear_cards()
	_create_cards()
	_empty_label.visible = _drawn_cards.is_empty()
	if is_instance_valid(_action_buttons):
		_action_buttons.visible = not _drawn_cards.is_empty()
	visible = true
	if _drawn_cards.is_empty():
		_stop_card_music()
		_clear_ribbons()
	else:
		_play_card_music()
		_start_ribbon_rain()
	get_tree().paused = true


func _build_fixed_lane_cards(cards: Array[CardData]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var cards_by_hero := {}
	for card in cards:
		if card == null:
			continue
		var hero_id := String(card.hero_id).to_lower()
		if not cards_by_hero.has(hero_id):
			cards_by_hero[hero_id] = []
		cards_by_hero[hero_id].append(card)
	for hero_id in LANE_ORDER:
		if cards_by_hero.has(hero_id):
			for card in cards_by_hero[hero_id]:
				result.append({
					"hero": _resolve_live_hero(hero_id),
					"hero_id": hero_id,
					"card": card,
				})
	return result


func _resolve_live_hero(hero_id: String) -> Node:
	var normalized := hero_id.to_lower()
	for hero in get_tree().get_nodes_in_group("heroes"):
		if not is_instance_valid(hero):
			continue
		if "hero_id" in hero and String(hero.get("hero_id")).to_lower() == normalized:
			return hero
		if hero.has_method("get_hero_id") and String(hero.call("get_hero_id")).to_lower() == normalized:
			return hero
		if String(hero.name).to_lower() == normalized:
			return hero
	return null


func _clear_cards() -> void:
	for child in _card_root.get_children():
		child.queue_free()
	_card_panels.clear()


func _create_cards() -> void:
	for index in range(_drawn_cards.size()):
		var card_node := _make_card(_drawn_cards[index], index)
		_card_root.add_child(card_node)
		_card_panels.append(card_node)


func _make_card(data: Dictionary, idx: int) -> Control:
	var card: CardData = data.get("card", null)

	var tex: Texture2D = _fallback_card_tex
	if card != null and card.card_background != null:
		tex = card.card_background

	# Card image as root — same as before adding text
	var img := TextureRect.new()
	img.texture = tex
	img.custom_minimum_size = CARD_SIZE
	img.size = CARD_SIZE
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	img.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	img.pivot_offset = CARD_SIZE * 0.5

	# Skill description text area with perfect vertical centering
	var desc_area := Control.new()
	var desc_offset_x := 0.0
	if card != null and String(card.hero_id).to_lower() == "lion":
		desc_offset_x = 8.0
	desc_area.position = Vector2(DESC_LEFT + desc_offset_x, DESC_TOP)
	desc_area.size = Vector2(DESC_WIDTH, DESC_HEIGHT)
	desc_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.add_child(desc_area)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desc_area.add_child(center)

	var desc := RichTextLabel.new()
	UIFontsClass.apply(desc)
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(DESC_WIDTH, 0)
	
	desc.add_theme_font_size_override("normal_font_size", 17)
	desc.add_theme_font_size_override("bold_font_size", 17)
	desc.add_theme_color_override("default_color", DESC_COLOR)
	desc.add_theme_color_override("font_outline_color", DESC_STROKE)
	desc.add_theme_constant_override("outline_size", 6)
	desc.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.clear()
	
	var raw_desc := card.description if card != null else ""
	# Apply highlight color to any [b] tags
	var colored_desc := raw_desc.replace("[b]", "[b][color=" + DESC_HIGHLIGHT + "]").replace("[/b]", "[/color][/b]")
	desc.append_text("[center]" + colored_desc + "[/center]")
	center.add_child(desc)

	# Click handler
	img.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_clicked(idx)
	)
	img.mouse_entered.connect(func() -> void:
		if _selected_index < 0:
			img.scale = Vector2(HOVER_SCALE, HOVER_SCALE)
	)
	img.mouse_exited.connect(func() -> void:
		if _selected_index < 0:
			img.scale = Vector2.ONE
	)

	return img


func _on_card_clicked(idx: int) -> void:
	if idx < 0 or idx >= _drawn_cards.size():
		return

	_selected_index = idx
	_selected_data = _drawn_cards[idx]
	_selected_data["hero"] = _resolve_live_hero(String(_selected_data.get("hero_id", "")))

	for card_index in range(_card_panels.size()):
		var panel := _card_panels[card_index]
		if card_index == idx:
			panel.modulate = Color.WHITE
			panel.scale = Vector2(HOVER_SCALE, HOVER_SCALE)
		else:
			panel.modulate = DIM_MODULATE
			panel.scale = Vector2.ONE

	card_selected.emit(_selected_data)


func _on_next_pressed() -> void:
	_stop_card_music()
	_clear_ribbons()
	next_wave_requested.emit()
	visible = false


func is_card_selected() -> bool:
	return _selected_index != -1


func get_selected_upgrade() -> Dictionary:
	return _selected_data


func _play_card_music() -> void:
	if not is_instance_valid(_card_music):
		return

	if _card_music.stream == null:
		_card_music.stream = CARD_SELECT_BGM

	if not _card_music.finished.is_connected(_on_card_music_finished):
		_card_music.finished.connect(_on_card_music_finished)

	_card_music.stop()
	_card_music.play()


func _stop_card_music() -> void:
	if is_instance_valid(_card_music):
		_card_music.stop()


func _on_card_music_finished() -> void:
	if visible and is_instance_valid(_card_music):
		_card_music.play()


func _start_ribbon_rain() -> void:
	_ribbon_spawn_token += 1
	var token: int = _ribbon_spawn_token
	_clear_ribbons(false)
	if not is_instance_valid(_ribbon_layer):
		return

	_run_ribbon_rain(token)


func _spawn_ribbon(screen_size: Vector2, lane_ratio: float) -> void:
	if not is_instance_valid(_ribbon_layer):
		return

	var ribbon := ColorRect.new()
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.color = RIBBON_COLORS[randi() % RIBBON_COLORS.size()]
	ribbon.modulate = Color(1, 1, 1, 0.0)
	ribbon.size = Vector2(randf_range(RIBBON_MIN_WIDTH, RIBBON_MAX_WIDTH), randf_range(RIBBON_MIN_HEIGHT, RIBBON_MAX_HEIGHT))
	ribbon.pivot_offset = ribbon.size * 0.5

	var start_x: float = lerpf(screen_size.x * 0.18, screen_size.x * 0.82, lane_ratio)
	start_x += randf_range(-RIBBON_SPAWN_SPREAD, RIBBON_SPAWN_SPREAD)
	var start_y: float = screen_size.y + randf_range(RIBBON_BOTTOM_SPAWN_MIN, RIBBON_BOTTOM_SPAWN_MAX)
	ribbon.position = Vector2(start_x, start_y)
	ribbon.rotation = randf_range(RIBBON_ROTATION_MIN, RIBBON_ROTATION_MAX)
	ribbon.scale = Vector2(0.9, 0.7)
	_ribbon_layer.add_child(ribbon)

	var apex_y: float = randf_range(RIBBON_APEX_MIN, RIBBON_APEX_MAX)
	var end_x: float = clampf(start_x + randf_range(RIBBON_DRIFT_MIN, RIBBON_DRIFT_MAX), -80.0, screen_size.x + 80.0)
	var end_y: float = screen_size.y + ribbon.size.y + randf_range(120.0, 220.0)
	var spin_dir := -1.0 if randf() < 0.5 else 1.0
	var spin_peak := randf_range(0.25, 0.75) * spin_dir
	var spin_land := randf_range(0.85, 2.1) * spin_dir
	var swing_x := clampf(start_x + randf_range(-RIBBON_SIDE_SWING_MIN, RIBBON_SIDE_SWING_MAX), -80.0, screen_size.x + 80.0)
	var ascend_time := randf_range(RIBBON_ASCEND_TIME_MIN, RIBBON_ASCEND_TIME_MAX)
	var fall_time := randf_range(RIBBON_FALL_TIME_MIN, RIBBON_FALL_TIME_MAX)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(ribbon, "position:y", apex_y, ascend_time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(ribbon, "position:x", swing_x, ascend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ribbon, "rotation", ribbon.rotation + spin_peak, ascend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ribbon, "scale", Vector2(1.0, 1.0), ascend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ribbon, "modulate:a", 1.0, ascend_time * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(ribbon, "position:y", end_y, fall_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(ribbon, "position:x", end_x, fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(ribbon, "rotation", ribbon.rotation + spin_land, fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(ribbon, "scale", Vector2(0.92, 0.82), fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(ribbon, "modulate:a", 0.0, fall_time * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ribbon.queue_free)


func _spawn_star_particle(screen_size: Vector2, lane_ratio: float) -> void:
	if not is_instance_valid(_ribbon_layer) or STAR_PARTICLE_TEX == null:
		return

	var star := TextureRect.new()
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.texture = STAR_PARTICLE_TEX
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var star_size: float = randf_range(STAR_MIN_SIZE, STAR_MAX_SIZE)
	star.size = Vector2(star_size, star_size)
	star.pivot_offset = star.size * 0.5
	star.modulate = Color(1.0, 0.93, 0.98, 0.0)

	var start_x: float = lerpf(screen_size.x * 0.2, screen_size.x * 0.8, lane_ratio)
	start_x += randf_range(-RIBBON_SPAWN_SPREAD * 0.45, RIBBON_SPAWN_SPREAD * 0.45)
	var start_y: float = screen_size.y + randf_range(RIBBON_BOTTOM_SPAWN_MIN, RIBBON_BOTTOM_SPAWN_MAX)
	star.position = Vector2(start_x, start_y)
	star.rotation = randf_range(-0.35, 0.35)
	star.scale = Vector2(0.42, 0.42)
	_ribbon_layer.add_child(star)

	var apex_y: float = randf_range(STAR_APEX_MIN, STAR_APEX_MAX)
	var swing_x: float = clampf(start_x + randf_range(STAR_DRIFT_MIN, STAR_DRIFT_MAX), -80.0, screen_size.x + 80.0)
	var end_x: float = clampf(start_x + randf_range(STAR_DRIFT_MIN, STAR_DRIFT_MAX), -80.0, screen_size.x + 80.0)
	var end_y: float = screen_size.y + star.size.y + randf_range(130.0, 230.0)
	var spin_dir: float = -1.0 if randf() < 0.5 else 1.0
	var ascend_time: float = randf_range(STAR_ASCEND_TIME_MIN, STAR_ASCEND_TIME_MAX)
	var fall_time: float = randf_range(STAR_FALL_TIME_MIN, STAR_FALL_TIME_MAX)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(star, "position:y", apex_y, ascend_time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "position:x", swing_x, ascend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "rotation", star.rotation + randf_range(0.45, 1.15) * spin_dir, ascend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "scale", Vector2(0.92, 0.92), ascend_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "modulate:a", 0.95, ascend_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(star, "position:y", end_y, fall_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(star, "position:x", end_x, fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(star, "rotation", star.rotation + randf_range(1.2, 2.8) * spin_dir, fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(star, "scale", Vector2(0.68, 0.68), fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(star, "modulate:a", 0.0, fall_time * 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(star.queue_free)


func _run_ribbon_rain(token: int) -> void:
	while is_inside_tree() and visible and token == _ribbon_spawn_token:
		var screen_size := get_viewport().get_visible_rect().size
		var round_center: float = randf_range(0.22, 0.78)
		var round_spread: float = randf_range(0.06, 0.16)
		for handful_index in range(RIBBON_HANDFULS_PER_ROUND):
			var burst_count := randi_range(RIBBON_BURST_MIN, RIBBON_BURST_MAX)
			var star_count := randi_range(STAR_BURST_MIN, STAR_BURST_MAX)
			var handful_center: float = clampf(round_center + randf_range(-0.06, 0.06), 0.14, 0.86)
			var handful_spread: float = round_spread * randf_range(0.85, 1.1)
			for i in range(star_count):
				if not is_inside_tree() or not visible or token != _ribbon_spawn_token:
					return
				var star_offset_ratio: float = randf_range(-handful_spread * 1.2, handful_spread * 1.2)
				var star_lane_ratio: float = clampf(handful_center + star_offset_ratio, 0.08, 0.92)
				_spawn_star_particle(screen_size, star_lane_ratio)
				if i < star_count - 1:
					await get_tree().create_timer(randf_range(0.03, 0.08), true).timeout
					if not is_inside_tree() or not visible or token != _ribbon_spawn_token:
						return
			for i in range(burst_count):
				if not is_inside_tree() or not visible or token != _ribbon_spawn_token:
					return
				var offset_ratio: float = randf_range(-handful_spread, handful_spread)
				var lane_ratio: float = clampf(handful_center + offset_ratio, 0.08, 0.92)
				_spawn_ribbon(screen_size, lane_ratio)
				if i < burst_count - 1:
					await get_tree().create_timer(randf_range(RIBBON_THROW_STAGGER_MIN, RIBBON_THROW_STAGGER_MAX), true).timeout
					if not is_inside_tree() or not visible or token != _ribbon_spawn_token:
						return
			if handful_index < RIBBON_HANDFULS_PER_ROUND - 1:
				await get_tree().create_timer(randf_range(RIBBON_HANDFUL_PAUSE_MIN, RIBBON_HANDFUL_PAUSE_MAX), true).timeout
				if not is_inside_tree() or not visible or token != _ribbon_spawn_token:
					return

		await get_tree().create_timer(randf_range(RIBBON_BURST_INTERVAL_MIN, RIBBON_BURST_INTERVAL_MAX), true).timeout


func _clear_ribbons(stop_spawn: bool = true) -> void:
	if not is_instance_valid(_ribbon_layer):
		return

	if stop_spawn:
		_ribbon_spawn_token += 1

	for child in _ribbon_layer.get_children():
		child.queue_free()
