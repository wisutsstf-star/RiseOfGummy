extends CanvasLayer

signal next_wave_requested()

const UIFonts = preload("res://shared/ui/scripts/ui_fonts.gd")

const PANEL_COLOR := Color(0.12, 0.12, 0.18, 0.95)
const OVERLAY_COLOR := Color(0, 0, 0, 0.65)
const BTN_NORMAL_COLOR := Color(0.15, 0.15, 0.25, 0.90)
const BTN_HOVER_COLOR := Color(0.25, 0.25, 0.40, 1.00)
const BTN_ACCENT_COLOR := Color(0.2, 0.6, 1.0, 1.0)
const ITEM_BG_COLOR := Color(0.08, 0.08, 0.12, 0.9)

var _overlay: ColorRect
var _main_container: VBoxContainer
var _hero_list: VBoxContainer
var _potion_label: Label
var _next_button: Button

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build_ui()

func show_panel() -> void:
	_refresh_ui()
	visible = true
	get_tree().paused = true

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = OVERLAY_COLOR
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	_main_container = VBoxContainer.new()
	_main_container.set_anchor(SIDE_LEFT, 0.5)
	_main_container.set_anchor(SIDE_RIGHT, 0.5)
	_main_container.set_anchor(SIDE_TOP, 0.5)
	_main_container.set_anchor(SIDE_BOTTOM, 0.5)
	_main_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_main_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	_main_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_container.add_theme_constant_override("separation", 24)
	add_child(_main_container)

	var title := Label.new()
	title.text = "Hero Upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	_main_container.add_child(title)

	var potion_hbox = HBoxContainer.new()
	potion_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	potion_hbox.add_theme_constant_override("separation", 10)
	_main_container.add_child(potion_hbox)
	
	var potion_icon = ColorRect.new()
	potion_icon.custom_minimum_size = Vector2(24, 24)
	potion_icon.color = Color(0.2, 0.4, 1.0, 1.0)
	potion_hbox.add_child(potion_icon)
	
	_potion_label = Label.new()
	_potion_label.add_theme_font_size_override("font_size", 20)
	potion_hbox.add_child(_potion_label)

	_hero_list = VBoxContainer.new()
	_hero_list.add_theme_constant_override("separation", 16)
	_hero_list.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_container.add_child(_hero_list)

	_next_button = Button.new()
	_next_button.text = "Next Wave"
	_next_button.custom_minimum_size = Vector2(196, 48)
	_next_button.add_theme_font_size_override("font_size", 20)
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = BTN_NORMAL_COLOR
	normal_style.border_color = BTN_ACCENT_COLOR
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	_next_button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = BTN_HOVER_COLOR
	_next_button.add_theme_stylebox_override("hover", hover_style)
	
	_next_button.pressed.connect(_on_next_pressed)
	_main_container.add_child(_next_button)
	UIFonts.apply_tree(_main_container)

func _refresh_ui() -> void:
	_potion_label.text = "Blue Potions: %d" % GameStats.blue_potions
	
	for child in _hero_list.get_children():
		child.queue_free()
	
	var heroes = get_tree().get_nodes_in_group("heroes")
	for hero in heroes:
		if is_instance_valid(hero) and not hero.get("is_dead"):
			_hero_list.add_child(_create_hero_row(hero))

func _create_hero_row(hero: Node) -> Control:
	var row = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = ITEM_BG_COLOR
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	row.add_child(hbox)
	
	var name_label = Label.new()
	name_label.custom_minimum_size = Vector2(120, 0)
	var hid = hero.get_hero_id() if hero.has_method("get_hero_id") else hero.name
	name_label.text = String(hid).capitalize()
	name_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(name_label)
	
	var level_label = Label.new()
	level_label.custom_minimum_size = Vector2(100, 0)
	var current_level = hero.get("current_level") if "current_level" in hero else 1
	var max_level = hero.get("max_level") if "max_level" in hero else 8
	level_label.text = "Lv %d / %d" % [current_level, max_level]
	level_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(level_label)
	
	var up_btn = Button.new()
	up_btn.text = "  +  "
	up_btn.add_theme_font_size_override("font_size", 20)
	up_btn.add_theme_color_override("font_color", Color.WHITE)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	up_btn.add_theme_stylebox_override("normal", btn_style)
	
	up_btn.disabled = (GameStats.blue_potions <= 0 or current_level >= max_level)
	up_btn.pressed.connect(func(): _on_upgrade_pressed(hero))
	hbox.add_child(up_btn)
	UIFonts.apply_tree(row)
	
	return row

func _on_upgrade_pressed(hero: Node) -> void:
	if "current_level" in hero and "max_level" in hero:
		if hero.current_level < hero.max_level:
			if GameStats.spend_blue_potion():
				if hero.has_method("force_level_up"):
					hero.force_level_up()
				else:
					hero.current_level += 1
					if hero.has_signal("leveled_up"):
						hero.leveled_up.emit(hero.current_level)
				_refresh_ui()

func _on_next_pressed() -> void:
	visible = false
	next_wave_requested.emit()
