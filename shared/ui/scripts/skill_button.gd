extends Control
class_name SkillButton

const UIFonts = preload("res://shared/ui/scripts/ui_fonts.gd")

var star_tex: Texture2D

@onready var portrait: TextureButton = $RoundedMask/Portrait
@onready var overlay: TextureProgressBar = $RoundedMask/Portrait/CooldownOverlay
@onready var cooldown_label: Label = $RoundedMask/Portrait/CooldownLabel
@onready var level_label: Label = $LevelBadge/MarginContainer/Label
@onready var element_icon: TextureRect = $ElementBadge
@onready var damage_bar: TextureProgressBar = $HealthMask/DamageBar
@onready var health_bar: TextureProgressBar = $HealthMask/HealthBar
@onready var aura: Panel = $Aura
@onready var aura_burst: Panel = $AuraBurst
@onready var border_panel: Panel = $Border

static var _shared_time: float = 0.0
static var _last_frame: int = -1

var hero_ref: Node2D = null
var is_showing_skill_icon: bool = false
var is_skill_ready: bool = false
var is_skill_active: bool = false
var is_dead: bool = false
var skill_index: int = 0
var is_unlocked: bool = false

var _breathing: bool = false
const BREATHE_SPEED: float = 0.8
const BREATHE_AMOUNT: float = 0.035

var flip_tween: Tween
var aura_tween: Tween
var burst_tween: Tween
var scale_tween: Tween
var damage_tween: Tween

var _grayscale_shader: Shader
var _aura_style: StyleBoxFlat
var _aura_burst_style: StyleBoxFlat

func _kill_tween(tw: Tween) -> void:
	if tw and tw.is_valid():
		tw.kill()

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

func _get_skill_color() -> Color:
	if is_instance_valid(hero_ref) and "skill_color" in hero_ref:
		return hero_ref.skill_color
	return Color(1.0, 0.85, 0.3, 1.0)

func _get_cooldown_stroke_color() -> Color:
	var skill_color := _get_skill_color()
	return skill_color.darkened(0.45)

func _get_button_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	if custom_minimum_size.x > 0.0 and custom_minimum_size.y > 0.0:
		return custom_minimum_size
	return Vector2(100.0, 100.0)

func _get_border_radius() -> int:
	var border_style := border_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if border_style == null:
		return 16
	return border_style.corner_radius_top_left

func _reset_aura_layers() -> void:
	aura.scale = Vector2.ONE
	aura_burst.scale = Vector2.ONE
	aura.modulate = Color(1, 1, 1, 0)
	aura_burst.modulate = Color(1, 1, 1, 0)

func _apply_aura_theme() -> void:
	var skill_color := _get_skill_color()
	var radius := _get_border_radius()
	cooldown_label.add_theme_color_override("font_outline_color", _get_cooldown_stroke_color())

	if _aura_style == null:
		var base_aura := aura.get_theme_stylebox("panel") as StyleBoxFlat
		if base_aura != null:
			_aura_style = base_aura.duplicate(true) as StyleBoxFlat
	if _aura_style != null:
		_aura_style.bg_color = _with_alpha(skill_color, 0.1)
		_aura_style.border_width_left = 6
		_aura_style.border_width_top = 6
		_aura_style.border_width_right = 6
		_aura_style.border_width_bottom = 6
		_aura_style.border_color = _with_alpha(skill_color, 0.8)
		_aura_style.corner_radius_top_left = radius
		_aura_style.corner_radius_top_right = radius
		_aura_style.corner_radius_bottom_left = radius
		_aura_style.corner_radius_bottom_right = radius
		aura.add_theme_stylebox_override("panel", _aura_style)

	if _aura_burst_style == null:
		var base_burst := aura_burst.get_theme_stylebox("panel") as StyleBoxFlat
		if base_burst != null:
			_aura_burst_style = base_burst.duplicate(true) as StyleBoxFlat
	if _aura_burst_style != null:
		_aura_burst_style.bg_color = _with_alpha(skill_color, 0.04)
		_aura_burst_style.border_width_left = 3
		_aura_burst_style.border_width_top = 3
		_aura_burst_style.border_width_right = 3
		_aura_burst_style.border_width_bottom = 3
		_aura_burst_style.border_color = _with_alpha(skill_color, 0.45)
		_aura_burst_style.shadow_color = _with_alpha(skill_color, 0.38)
		_aura_burst_style.shadow_size = 10
		_aura_burst_style.corner_radius_top_left = radius
		_aura_burst_style.corner_radius_top_right = radius
		_aura_burst_style.corner_radius_bottom_left = radius
		_aura_burst_style.corner_radius_bottom_right = radius
		aura_burst.add_theme_stylebox_override("panel", _aura_burst_style)

func _make_circle_panel(radius: float, col: Color) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	panel.add_theme_stylebox_override("panel", style)
	var diameter := radius * 2.0
	panel.size = Vector2(diameter, diameter)
	panel.pivot_offset = Vector2(radius, radius)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _make_frame_panel(frame_size: Vector2, radius: int, border_width: int, border_color: Color, fill_color: Color) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", style)
	panel.size = frame_size
	panel.pivot_offset = frame_size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _ready() -> void:
	UIFonts.apply_tree(self)

	overlay.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	portrait.pressed.connect(_on_portrait_pressed)

	overlay.visible = false
	cooldown_label.visible = false
	aura.visible = false
	aura_burst.visible = false
	_reset_aura_layers()

	pivot_offset = Vector2(50, 50)

	if ResourceLoader.exists("res://shared/ui/assets/star_particle.png"):
		star_tex = load("res://shared/ui/assets/star_particle.png")

	_grayscale_shader = Shader.new()
	_grayscale_shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec4 col = texture(TEXTURE, UV);
		float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		COLOR = vec4(gray, gray, gray, col.a);
	}
	"""

func _process(delta: float) -> void:
	var frame := Engine.get_process_frames()
	if frame != _last_frame:
		_last_frame = frame
		_shared_time += delta

	if _breathing:
		var t: float = sin(_shared_time * BREATHE_SPEED * TAU) * 0.5 + 0.5
		var s: float = 1.0 + t * BREATHE_AMOUNT
		scale = Vector2(s, s)

func _apply_locked_visuals() -> void:
	portrait.disabled = true
	var empty_tex = load("res://shared/ui/assets/skill_empty.png")
	if empty_tex:
		portrait.texture_normal = empty_tex
	health_bar.get_parent().visible = false # hide HealthMask
	level_label.get_parent().get_parent().visible = false # hide LevelBadge
	element_icon.visible = false
	overlay.visible = false
	cooldown_label.visible = false
	portrait.self_modulate = Color(0.4, 0.4, 0.4, 0.8)

func setup(hero: Node2D, idx: int = 0) -> void:
	hero_ref = hero
	skill_index = idx
	_apply_aura_theme()
	_reset_aura_layers()
	
	if hero.has_method("has_active_skill"):
		is_unlocked = hero.has_active_skill(idx)
	else:
		is_unlocked = (idx == 0)

	if not is_unlocked:
		_apply_locked_visuals()
		return
		
	# Re-enable in case it was locked before
	portrait.disabled = false
	health_bar.get_parent().visible = true
	level_label.get_parent().get_parent().visible = false
	element_icon.visible = true
	portrait.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	if hero.avatar_icon:
		portrait.texture_normal = hero.avatar_icon
	if hero.element_icon:
		element_icon.texture = hero.element_icon
		element_icon.show()
	else:
		element_icon.hide()

	level_label.text = str(hero.current_level)

	if skill_index == 0:
		hero.cooldown_updated.connect(_on_cooldown_updated)
		hero.skill_ready.connect(_on_skill_ready)
		if hero.has_signal("skill_activated"):
			hero.skill_activated.connect(_on_skill_activated)
	else:
		if hero.has_signal("cooldown_updated_2"):
			hero.cooldown_updated_2.connect(_on_cooldown_updated)
		if hero.has_signal("skill_ready_2"):
			hero.skill_ready_2.connect(_on_skill_ready)
		if hero.has_signal("skill_activated_2"):
			hero.skill_activated_2.connect(_on_skill_activated)

	if hero.has_signal("hp_updated"):
		hero.hp_updated.connect(_on_hp_updated)
	if hero.has_signal("hero_died"):
		hero.hero_died.connect(_on_hero_died)

	if "max_hp" in hero:
		health_bar.max_value = hero.max_hp
		damage_bar.max_value = hero.max_hp
	if "current_hp" in hero:
		health_bar.value = hero.current_hp
		damage_bar.value = hero.current_hp

	if skill_index == 0:
		if "current_cooldown" in hero and hero.current_cooldown > 0:
			var cooldown_max: float = hero.max_cooldown if "max_cooldown" in hero else 12.0
			if hero.has_method("_get_effective_skill_cooldown"):
				cooldown_max = hero._get_effective_skill_cooldown()
			_on_cooldown_updated(hero.current_cooldown, cooldown_max)
		else:
			_on_skill_ready()
	else:
		if "current_cooldown_2" in hero and hero.current_cooldown_2 > 0:
			var cooldown_max: float = hero.max_cooldown_2 if "max_cooldown_2" in hero else 12.0
			if hero.has_method("_get_effective_skill_cooldown_2"):
				cooldown_max = hero._get_effective_skill_cooldown_2()
			_on_cooldown_updated(hero.current_cooldown_2, cooldown_max)
		else:
			_on_skill_ready()

func _on_hp_updated(current: int, maximum: int) -> void:
	if is_dead or not is_unlocked:
		return

	health_bar.max_value = maximum
	damage_bar.max_value = maximum

	var previous_hp := health_bar.value
	health_bar.value = current

	if current < previous_hp:
		_kill_tween(damage_tween)
		damage_tween = create_tween()
		damage_tween.tween_interval(0.2)
		damage_tween.tween_property(damage_bar, "value", float(current), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		damage_bar.value = current

func _flip_to_texture(new_tex: Texture2D) -> void:
	_kill_tween(flip_tween)
	var container := $RoundedMask
	flip_tween = create_tween()
	flip_tween.tween_property(container, "scale", Vector2(0.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	flip_tween.tween_callback(func():
		portrait.texture_normal = new_tex
	)
	flip_tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _start_aura_pulse() -> void:
	_kill_tween(aura_tween)
	_apply_aura_theme()
	_reset_aura_layers()
	aura.visible = true
	aura.modulate = Color(1, 1, 1, 0.84)
	aura_tween = create_tween().set_loops()
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0.5), 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0.9), 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _fade_out_aura(duration: float = 0.8) -> void:
	_kill_tween(aura_tween)
	aura_tween = create_tween()
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	aura_tween.tween_callback(func():
		aura.scale = Vector2.ONE
		aura.visible = false
	)

func _fire_aura_burst() -> void:
	_kill_tween(burst_tween)
	_apply_aura_theme()
	aura.visible = true
	aura_burst.visible = true
	aura.scale = Vector2.ONE
	aura_burst.scale = Vector2.ONE
	aura_burst.modulate = Color(1, 1, 1, 1.0)
	burst_tween = create_tween()
	burst_tween.tween_property(aura_burst, "scale", Vector2(1.12, 1.12), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.parallel().tween_property(aura, "scale", Vector2(1.06, 1.06), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.parallel().tween_property(aura_burst, "modulate", Color(1, 1, 1, 0), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.parallel().tween_property(aura, "modulate", Color(1, 1, 1, 0.42), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_callback(func():
		aura_burst.scale = Vector2.ONE
		aura_burst.visible = false
	)

func _start_breathe() -> void:
	if not is_unlocked: return
	_kill_tween(scale_tween)
	_breathing = true

func _stop_breathe() -> void:
	if not is_unlocked: return
	_breathing = false
	_kill_tween(scale_tween)
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _spawn_golden_burst() -> void:
	var center := _get_button_size() * 0.5
	var frame_size := _get_button_size()
	var radius := _get_border_radius()
	var skill_color := _get_skill_color()

	var flash := ColorRect.new()
	flash.color = _with_alpha(skill_color, 0.2)
	flash.size = frame_size
	flash.position = Vector2.ZERO
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$RoundedMask.add_child(flash)

	var flash_tw := create_tween()
	flash_tw.tween_property(flash, "color", _with_alpha(skill_color, 0.0), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	flash_tw.tween_callback(flash.queue_free)

	var frame_1 := _make_frame_panel(frame_size, radius, 4, _with_alpha(skill_color, 0.8), _with_alpha(skill_color, 0.08))
	frame_1.position = center - frame_size * 0.5
	add_child(frame_1)

	var frame_1_tw := create_tween()
	frame_1_tw.tween_property(frame_1, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	frame_1_tw.parallel().tween_property(frame_1, "modulate", Color(1, 1, 1, 0), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	frame_1_tw.tween_callback(frame_1.queue_free)

	var frame_2 := _make_frame_panel(frame_size, radius, 3, _with_alpha(skill_color, 0.5), _with_alpha(skill_color, 0.03))
	frame_2.position = center - frame_size * 0.5
	add_child(frame_2)

	var frame_2_tw := create_tween()
	frame_2_tw.tween_property(frame_2, "scale", Vector2(1.16, 1.16), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.03)
	frame_2_tw.parallel().tween_property(frame_2, "modulate", Color(1, 1, 1, 0), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.03)
	frame_2_tw.tween_callback(frame_2.queue_free)

	var dot_count := randi_range(8, 12)
	for i in dot_count:
		var dot_r := randf_range(2.0, 3.5)
		var dot := _make_circle_panel(dot_r, _with_alpha(skill_color, 0.95))
		dot.position = center - Vector2(dot_r, dot_r)
		add_child(dot)

		var angle := randf() * TAU
		var dist := randf_range(22.0, 42.0)
		var end_pos := dot.position + Vector2(cos(angle), sin(angle)) * dist
		var duration := randf_range(0.18, 0.28)
		var delay := randf_range(0.0, 0.04)

		var tw := create_tween()
		tw.tween_property(dot, "position", end_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.parallel().tween_property(dot, "scale", Vector2(0.0, 0.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay)
		tw.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay)
		tw.tween_callback(dot.queue_free)

func _spawn_star_burst(count: int = 18) -> void:
	if not star_tex:
		return

	var skill_color := _get_skill_color()
	var frame_size := _get_button_size()
	var center := frame_size * 0.5
	var padding := 6.0
	var star_palette := [
		_with_alpha(skill_color.lightened(0.4), 1.0),
		_with_alpha(skill_color, 0.98),
		_with_alpha(skill_color.darkened(0.2), 0.92)
	]

	for i in count:
		var star := TextureRect.new()
		star.texture = star_tex
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var star_size := randf_range(10.0, 28.0)
		star.custom_minimum_size = Vector2(star_size, star_size)
		star.size = Vector2(star_size, star_size)
		star.pivot_offset = Vector2(star_size * 0.5, star_size * 0.5)

		var edge_point := center
		var edge_pick := randi_range(0, 3)
		var edge_slide := randf()
		if edge_pick == 0:
			edge_point = Vector2(lerpf(padding, frame_size.x - padding, edge_slide), padding)
		elif edge_pick == 1:
			edge_point = Vector2(frame_size.x - padding, lerpf(padding, frame_size.y - padding, edge_slide))
		elif edge_pick == 2:
			edge_point = Vector2(lerpf(padding, frame_size.x - padding, edge_slide), frame_size.y - padding)
		else:
			edge_point = Vector2(padding, lerpf(padding, frame_size.y - padding, edge_slide))

		star.position = edge_point - Vector2(star_size * 0.5, star_size * 0.5)
		star.modulate = star_palette[randi_range(0, star_palette.size() - 1)]
		star.rotation = randf() * TAU
		add_child(star)

		var outward := (edge_point - center).normalized()
		var spread := outward.rotated(randf_range(-0.45, 0.45))
		var dist := randf_range(26.0, 54.0)
		var end_pos := star.position + spread * dist
		var duration := randf_range(0.22, 0.38)
		var delay := randf_range(0.0, 0.05)

		var tw := create_tween()
		tw.tween_property(star, "position", end_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.parallel().tween_property(star, "rotation", star.rotation + randf_range(2.0, 4.8), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.parallel().tween_property(star, "scale", Vector2(randf_range(0.15, 0.35), randf_range(0.15, 0.35)), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay)
		tw.parallel().tween_property(star, "modulate", Color(1, 1, 1, 0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay)
		tw.tween_callback(star.queue_free)

func _get_hero_skill_icon() -> Texture2D:
	if not is_instance_valid(hero_ref): return null
	if skill_index == 0 and "skill_icon" in hero_ref: return hero_ref.skill_icon
	if skill_index == 1 and "skill_icon_2" in hero_ref: return hero_ref.skill_icon_2
	return null

func _on_skill_activated() -> void:
	if is_dead or not is_unlocked:
		return

	is_skill_active = true

	if is_instance_valid(hero_ref):
		var ic = _get_hero_skill_icon()
		if ic:
			if not is_showing_skill_icon:
				is_showing_skill_icon = true
				_flip_to_texture(ic)

	_stop_breathe()
	_start_aura_pulse()

func _on_hero_died() -> void:
	is_dead = true
	_kill_tween(damage_tween)
	_kill_tween(scale_tween)
	_kill_tween(aura_tween)
	_kill_tween(burst_tween)
	_kill_tween(flip_tween)

	_stop_breathe()

	overlay.visible = false
	cooldown_label.visible = false
	aura.visible = false
	aura_burst.visible = false
	_reset_aura_layers()
	health_bar.value = 0
	damage_bar.value = 0

	portrait.disabled = true

	if is_showing_skill_icon and is_instance_valid(hero_ref) and hero_ref.avatar_icon:
		is_showing_skill_icon = false
		portrait.texture_normal = hero_ref.avatar_icon

	var mat := ShaderMaterial.new()
	mat.shader = _grayscale_shader
	portrait.material = mat
	portrait.self_modulate = Color(0.25, 0.25, 0.25, 0.9)

	if is_instance_valid(element_icon):
		element_icon.self_modulate = Color(0.3, 0.3, 0.3, 0.8)

func _on_cooldown_updated(current: float, maximum: float) -> void:
	if is_dead or not is_unlocked:
		return

	overlay.visible = true
	cooldown_label.visible = true

	if is_skill_active:
		is_skill_active = false
		_fade_out_aura(0.8)
	elif not is_skill_ready:
		aura.visible = false
		_reset_aura_layers()

	_kill_tween(burst_tween)
	aura_burst.visible = false
	aura_burst.scale = Vector2.ONE

	is_skill_ready = false
	_stop_breathe()

	if is_instance_valid(hero_ref) and hero_ref.avatar_icon:
		if is_showing_skill_icon:
			is_showing_skill_icon = false
			_flip_to_texture(hero_ref.avatar_icon)
		elif portrait.texture_normal != hero_ref.avatar_icon:
			portrait.texture_normal = hero_ref.avatar_icon

	portrait.self_modulate = Color(0.6, 0.6, 0.6)

	overlay.max_value = maximum
	overlay.value = current
	cooldown_label.text = str(int(ceil(current)))

func _on_skill_ready() -> void:
	if is_dead or not is_unlocked:
		return

	overlay.visible = false
	cooldown_label.visible = false
	is_skill_ready = true
	is_skill_active = false

	portrait.self_modulate = Color(1.1, 1.1, 1.1)

	if is_instance_valid(hero_ref) and hero_ref.avatar_icon:
		if is_showing_skill_icon:
			is_showing_skill_icon = false
			_flip_to_texture(hero_ref.avatar_icon)
		elif portrait.texture_normal != hero_ref.avatar_icon:
			portrait.texture_normal = hero_ref.avatar_icon

	_start_aura_pulse()
	_fire_aura_burst()
	_start_breathe()

func _on_portrait_pressed() -> void:
	if is_dead or not is_instance_valid(hero_ref) or not is_unlocked:
		return

	var success: bool = false
	if skill_index == 0:
		success = hero_ref.use_active_skill()
	else:
		if hero_ref.has_method("use_active_skill_2"):
			success = hero_ref.use_active_skill_2()

	if success:
		is_skill_ready = false
		_stop_breathe()
		_fire_aura_burst()
		_spawn_golden_burst()
		_spawn_star_burst(randi_range(20, 30))
	else:
		_kill_tween(scale_tween)
		scale_tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.05)
