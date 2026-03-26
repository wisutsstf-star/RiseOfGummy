extends CanvasLayer

const UIFonts = preload("res://shared/ui/scripts/ui_fonts.gd")

# Wave HUD - Rise of Gummy
# แสดงข้อมูล Wave และจัดการ UI
# - Wave ปกติ: เริ่มอัตโนมัติหลังเคลียร์ 3 วิ
# - Card Wave: แสดงการ์ดให้เลือก แล้วกด Next Wave ใต้การ์ด

@export var wave_manager: Node
@export var card_panel: CanvasLayer

var _btn_next_wave: Button
var _btn_again: Button
var _wave_label: Label
var _wave_bg: TextureRect

const BTN_NORMAL_COLOR := Color(0.15, 0.15, 0.25, 0.90)
const BTN_HOVER_COLOR := Color(0.25, 0.25, 0.40, 1.00)
const BTN_ACCENT_COLOR := Color(0.85, 0.75, 0.25, 1.00)
const BTN_AGAIN_COLOR := Color(0.20, 0.20, 0.20, 0.90)
const LABEL_COLOR := Color(1.00, 1.00, 1.00, 1.00)


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	_connect_signals()
	_set_idle_state()


func _build_ui() -> void:
# ... keeping this intact ...
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_wave_bg = TextureRect.new()
	_wave_bg.texture = load("res://shared/ui/assets/bar_wave.png")
	_wave_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wave_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_wave_bg.set_anchor(SIDE_LEFT, 1.0)
	_wave_bg.set_anchor(SIDE_RIGHT, 1.0)
	_wave_bg.set_anchor(SIDE_TOP, 0.0)
	_wave_bg.set_anchor(SIDE_BOTTOM, 0.0)
	_wave_bg.offset_left = -300
	_wave_bg.offset_right = -20
	_wave_bg.offset_top = 16
	_wave_bg.offset_bottom = 76
	root.add_child(_wave_bg)

	_wave_label = Label.new()
	_wave_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wave_label.text = "Stage 1 - Wave 0"
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_label.add_theme_color_override("font_color", LABEL_COLOR)
	_wave_label.add_theme_font_size_override("font_size", 16)
	_wave_bg.add_child(_wave_label)

	_btn_next_wave = _make_button("Next Wave", BTN_ACCENT_COLOR)
	_btn_next_wave.set_anchor(SIDE_LEFT, 1.0)
	_btn_next_wave.set_anchor(SIDE_RIGHT, 1.0)
	_btn_next_wave.set_anchor(SIDE_TOP, 1.0)
	_btn_next_wave.set_anchor(SIDE_BOTTOM, 1.0)
	_btn_next_wave.offset_left = -220
	_btn_next_wave.offset_right = -20
	_btn_next_wave.offset_top = -70
	_btn_next_wave.offset_bottom = -20
	_btn_next_wave.pressed.connect(_on_next_wave_pressed)
	root.add_child(_btn_next_wave)

	_btn_again = _make_button("Again", BTN_AGAIN_COLOR)
	_btn_again.set_anchor(SIDE_LEFT, 0.0)
	_btn_again.set_anchor(SIDE_RIGHT, 0.0)
	_btn_again.set_anchor(SIDE_TOP, 1.0)
	_btn_again.set_anchor(SIDE_BOTTOM, 1.0)
	_btn_again.offset_left = 20
	_btn_again.offset_right = 180
	_btn_again.offset_top = -70
	_btn_again.offset_bottom = -20
	_btn_again.pressed.connect(_on_again_pressed)
	root.add_child(_btn_again)
	UIFonts.apply_tree(root)


func _make_button(label_text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = BTN_NORMAL_COLOR
	normal_style.border_color = accent
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = BTN_HOVER_COLOR
	btn.add_theme_stylebox_override("hover", hover_style)

	return btn


func _connect_signals() -> void:
	if wave_manager == null:
		push_warning("WaveHUD: wave_manager not assigned.")
		return

	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)
	if wave_manager.has_signal("wave_cleared"):
		wave_manager.wave_cleared.connect(_on_wave_cleared)
	if wave_manager.has_signal("request_show_cards"):
		wave_manager.request_show_cards.connect(_on_show_cards)
	if wave_manager.has_signal("all_stages_completed"):
		wave_manager.all_stages_completed.connect(_on_all_completed)

	if card_panel != null and card_panel.has_signal("card_selected"):
		card_panel.card_selected.connect(_on_card_selected)
	if card_panel != null and card_panel.has_signal("next_wave_requested"):
		card_panel.next_wave_requested.connect(_on_next_wave_from_card)


func _on_wave_started(wave_number: int) -> void:
	_wave_label.text = _format_wave_label(wave_number)
	_wave_bg.visible = true
	_btn_next_wave.visible = false


func _on_wave_cleared(_wave_number: int) -> void:
	_wave_bg.visible = true


func _on_show_cards(cards: Array[CardData]) -> void:
	if card_panel != null:
		card_panel.show_cards(cards)


func _on_card_selected(_upgrade: Dictionary) -> void:
	# ไม่ทำอะไรตอนเลือกการ์ด รอให้กดปุ่ม Next Wave ใต้การ์ดก่อน
	pass


func _on_next_wave_from_card() -> void:
	if wave_manager != null:
		wave_manager.on_card_selected()


func _on_all_completed() -> void:
	_wave_label.text = "All Waves Cleared!"
	_btn_next_wave.visible = false


func _on_next_wave_pressed() -> void:
	if wave_manager == null:
		return

	_btn_next_wave.visible = false
	wave_manager.start_next_wave()


func _on_again_pressed() -> void:
	if Engine.has_singleton("GameStats"):
		Engine.get_singleton("GameStats").reset()
	var card_manager := get_node_or_null("/root/CardManager")
	if card_manager != null and card_manager.has_method("reset_runtime"):
		card_manager.reset_runtime()
	get_tree().reload_current_scene()


func _set_idle_state() -> void:
	_btn_next_wave.visible = false
	_btn_again.visible = false


func _format_wave_label(wave_number: int) -> String:
	var stage_number := 1
	if wave_manager != null and wave_manager.has_method("get_stage_level"):
		stage_number = wave_manager.get_stage_level()

	return "Stage %d - Wave %d" % [stage_number, wave_number]
