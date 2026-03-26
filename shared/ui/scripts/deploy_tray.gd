extends Control
const UIFonts = preload("res://shared/ui/scripts/ui_fonts.gd")
## Deploy Tray UI — มุมซ้ายล่าง แบบใหม่ สวยงามขึ้น

signal hero_deploy_toggled(hero: Node2D, is_ground: bool)

const TRAY_SLIDE_DURATION: float = 0.35
const SLOT_SIZE: float = 72.0
const SLOT_GAP: float = 16.0
const TOGGLE_SIZE: float = 64.0
const ICON_SIZE: float = 56.0

var is_open: bool = false
var hero_slots: Array[Dictionary] = [] # {hero, icon, button, is_deployed}
var _tray_tween: Tween

# Nodes
var toggle_btn: Button
var arrow_label: Label
var tray_panel: PanelContainer
var tray_container: HBoxContainer
var _grayscale_shader: Shader

func _ready() -> void:
	# สร้าง Grayscale Shader สำหรับตอนฮีโร่ตาย
	_grayscale_shader = Shader.new()
	_grayscale_shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec4 col = texture(TEXTURE, UV);
		float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		COLOR = vec4(gray, gray, gray, col.a);
	}
	"""
	
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(24, viewport_size.y - TOGGLE_SIZE - 24)

	# ── Toggle Button ──
	toggle_btn = Button.new()
	toggle_btn.custom_minimum_size = Vector2(TOGGLE_SIZE, TOGGLE_SIZE)
	toggle_btn.size = Vector2(TOGGLE_SIZE, TOGGLE_SIZE)
	toggle_btn.position = Vector2(0, 0)
	toggle_btn.pressed.connect(_on_toggle_pressed)
	toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_btn.pivot_offset = Vector2(TOGGLE_SIZE / 2.0, TOGGLE_SIZE / 2.0)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style_normal.corner_radius_top_left = int(TOGGLE_SIZE / 2)
	style_normal.corner_radius_top_right = int(TOGGLE_SIZE / 2)
	style_normal.corner_radius_bottom_left = int(TOGGLE_SIZE / 2)
	style_normal.corner_radius_bottom_right = int(TOGGLE_SIZE / 2)
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_color = Color(0.5, 0.7, 1.0, 0.8)
	style_normal.shadow_color = Color(0, 0, 0, 0.4)
	style_normal.shadow_size = 6
	style_normal.shadow_offset = Vector2(0, 2)

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.18, 0.2, 0.3, 0.95)
	style_hover.border_color = Color(0.7, 0.85, 1.0, 1.0)
	style_hover.shadow_size = 8

	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	style_pressed.border_color = Color(0.3, 0.5, 0.8, 1.0)

	toggle_btn.add_theme_stylebox_override("normal", style_normal)
	toggle_btn.add_theme_stylebox_override("hover", style_hover)
	toggle_btn.add_theme_stylebox_override("pressed", style_pressed)
	toggle_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	toggle_btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(toggle_btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_SINE)
	)
	toggle_btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(toggle_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	)

	add_child(toggle_btn)

	arrow_label = Label.new()
	arrow_label.text = "⚔️"
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_label.position = Vector2(0, 0)
	arrow_label.size = Vector2(TOGGLE_SIZE, TOGGLE_SIZE)
	arrow_label.add_theme_font_size_override("font_size", 28)
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle_btn.add_child(arrow_label)

	# ── Tray Background Panel ──
	tray_panel = PanelContainer.new()
	tray_panel.position = Vector2(TOGGLE_SIZE + 16, (TOGGLE_SIZE - SLOT_SIZE) / 2.0 - 8)
	tray_panel.modulate.a = 0.0
	tray_panel.visible = false
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_color = Color(1, 1, 1, 0.1)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 12
	tray_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(tray_panel)

	# ── Tray Container ──
	tray_container = HBoxContainer.new()
	tray_container.add_theme_constant_override("separation", int(SLOT_GAP))
	tray_panel.add_child(tray_container)

func setup(heroes: Array[Node]) -> void:
	hero_slots.clear()

	for child in tray_container.get_children():
		child.queue_free()

	var slot_index: int = 0
	for hero in heroes:
		var idx = slot_index
		if hero.has_signal("ground_mode_changed"):
			hero.ground_mode_changed.connect(func(is_ground: bool):
				_on_hero_ground_mode_changed(idx, is_ground)
			)
		if hero.has_signal("hero_died"):
			hero.hero_died.connect(func():
				_on_hero_died(idx)
			)
			
		var slot_data: Dictionary = {
			"hero": hero,
			"is_deployed": false,
			"is_dead": false,
		}

		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.pivot_offset = Vector2(SLOT_SIZE / 2.0, SLOT_SIZE / 2.0)

		var slot_style := StyleBoxFlat.new()
		slot_style.corner_radius_top_left = int(SLOT_SIZE / 2.0)
		slot_style.corner_radius_top_right = int(SLOT_SIZE / 2.0)
		slot_style.corner_radius_bottom_left = int(SLOT_SIZE / 2.0)
		slot_style.corner_radius_bottom_right = int(SLOT_SIZE / 2.0)
		slot_style.border_width_top = 3
		slot_style.border_width_bottom = 3
		slot_style.border_width_left = 3
		slot_style.border_width_right = 3
		slot_style.bg_color = Color(0.12, 0.15, 0.2, 0.9)
		slot_style.border_color = Color(0.4, 0.4, 0.5, 0.6)

		if hero.avatar_icon:
			var padding = 4.0 # เว้นขอบให้เห็นกรอบปุ่ม
			var icon_tex := TextureRect.new()
			icon_tex.texture = hero.avatar_icon
			
			# ตั้งต่าให้ยืดขยายเต็มปุ่มโดยอัตโนมัติ
			icon_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_tex.offset_left = padding
			icon_tex.offset_top = padding
			icon_tex.offset_right = - padding
			icon_tex.offset_bottom = - padding
			
			icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_btn.add_child(icon_tex)
			slot_data["icon"] = icon_tex
		
		var slot_hover := slot_style.duplicate()
		slot_hover.bg_color = slot_style.bg_color.lightened(0.2)

		var slot_pressed := slot_style.duplicate()
		slot_pressed.bg_color = Color(0.8, 0.8, 0.8, 0.9)

		slot_btn.add_theme_stylebox_override("normal", slot_style)
		slot_btn.add_theme_stylebox_override("hover", slot_hover)
		slot_btn.add_theme_stylebox_override("pressed", slot_pressed)
		slot_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		slot_btn.text = ""

		slot_btn.pressed.connect(func(): _on_slot_pressed(idx))
		
		slot_btn.mouse_entered.connect(func():
			var tw = create_tween()
			tw.tween_property(slot_btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
		)
		slot_btn.mouse_exited.connect(func():
			var tw = create_tween()
			tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		)

		tray_container.add_child(slot_btn)
		slot_data["button"] = slot_btn
		hero_slots.append(slot_data)
		slot_index += 1

	while hero_slots.size() < 3:
		var empty_btn := Button.new()
		empty_btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
		empty_style.corner_radius_top_left = int(SLOT_SIZE / 2.0)
		empty_style.corner_radius_top_right = int(SLOT_SIZE / 2.0)
		empty_style.corner_radius_bottom_left = int(SLOT_SIZE / 2.0)
		empty_style.corner_radius_bottom_right = int(SLOT_SIZE / 2.0)
		empty_style.border_width_top = 2
		empty_style.border_width_bottom = 2
		empty_style.border_width_left = 2
		empty_style.border_width_right = 2
		empty_style.border_color = Color(0.2, 0.2, 0.25, 0.5)
		
		var plus_label = Label.new()
		plus_label.text = "+"
		plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus_label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		UIFonts.apply(plus_label)
		plus_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1))
		plus_label.add_theme_font_size_override("font_size", 28)
		empty_btn.add_child(plus_label)
		
		empty_btn.add_theme_stylebox_override("normal", empty_style)
		empty_btn.add_theme_stylebox_override("hover", empty_style)
		empty_btn.add_theme_stylebox_override("pressed", empty_style)
		empty_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		empty_btn.text = ""
		empty_btn.disabled = true
		empty_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		tray_container.add_child(empty_btn)
		hero_slots.append({"hero": null, "is_deployed": false, "button": empty_btn})

func _on_toggle_pressed() -> void:
	is_open = !is_open
	if _tray_tween and _tray_tween.is_valid():
		_tray_tween.kill()
	_tray_tween = create_tween()

	var btn_rot_tween = create_tween()
	
	if is_open:
		tray_panel.visible = true
		tray_panel.position.x = TOGGLE_SIZE
		
		_tray_tween.tween_property(tray_panel, "position:x", TOGGLE_SIZE + 16, TRAY_SLIDE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tray_tween.parallel().tween_property(tray_panel, "modulate:a", 1.0, TRAY_SLIDE_DURATION * 0.8)
		
		btn_rot_tween.tween_property(toggle_btn, "rotation", PI, TRAY_SLIDE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_tray_tween.tween_property(tray_panel, "position:x", TOGGLE_SIZE, TRAY_SLIDE_DURATION * 0.7) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_tray_tween.parallel().tween_property(tray_panel, "modulate:a", 0.0, TRAY_SLIDE_DURATION * 0.5)
		_tray_tween.tween_callback(func(): tray_panel.visible = false)
		
		btn_rot_tween.tween_property(toggle_btn, "rotation", 0.0, TRAY_SLIDE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

func _on_slot_pressed(index: int) -> void:
	if index >= hero_slots.size():
		return
	var slot = hero_slots[index]
	if slot["hero"] == null:
		return

	var hero: Node2D = slot["hero"]
	if not is_instance_valid(hero):
		return
	if slot.get("is_dead", false):
		return # ตายอยู่ กดไม่ได้

	slot["is_deployed"] = !slot["is_deployed"]
	var is_deployed: bool = slot["is_deployed"]

	var btn: Button = slot["button"]
	var tw = create_tween()
	tw.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
	tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_update_slot_visual(index, is_deployed)

	if hero.has_method("set_ground_mode"):
		hero.set_ground_mode(is_deployed, index)

	hero_deploy_toggled.emit(hero, is_deployed)

func _on_hero_died(index: int) -> void:
	if index >= hero_slots.size(): return
	var slot = hero_slots[index]
	slot["is_dead"] = true
	slot["is_deployed"] = false # ยืนยันว่ากลับฐาน
	
	var icon: TextureRect = slot.get("icon")
	if icon:
		var mat = ShaderMaterial.new()
		mat.shader = _grayscale_shader
		icon.material = mat
		
	var btn: Button = slot.get("button")
	if btn:
		btn.disabled = true
	
	_update_slot_visual(index, false)


func _on_hero_ground_mode_changed(index: int, is_ground: bool) -> void:
	if index >= hero_slots.size():
		return
	hero_slots[index]["is_deployed"] = is_ground
	_update_slot_visual(index, is_ground)


func _update_slot_visual(index: int, is_deployed: bool) -> void:
	if index >= hero_slots.size():
		return
	var slot = hero_slots[index]
	var btn: Button = slot["button"]
	var is_dead: bool = slot.get("is_dead", false)

	var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()

	if is_dead:
		style.border_color = Color(0.2, 0.2, 0.2, 0.8) # กรอบดำ/เทาเข้ม
		style.bg_color = Color(0.05, 0.05, 0.05, 0.95)
		style.shadow_size = 0
	elif is_deployed:
		style.border_color = Color(0.2, 1.0, 0.5, 1.0) # เขียวสว่าง
		style.bg_color = Color(0.15, 0.35, 0.2, 0.95)
		style.shadow_color = Color(0.2, 1.0, 0.5, 0.3)
		style.shadow_size = 8
	else:
		style.border_color = Color(0.4, 0.4, 0.5, 0.6) # เทาๆ
		style.bg_color = Color(0.12, 0.15, 0.2, 0.9)
		style.shadow_size = 0

	var hover = style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.15)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
