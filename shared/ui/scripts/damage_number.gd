extends Node2D
class_name DamageNumber

const UIFonts = preload("res://shared/ui/scripts/ui_fonts.gd")

@onready var label: Label = $Label
@onready var icon: Sprite2D = $Sprite2D

var amount: int = 0
var is_crit: bool = false
var is_heal: bool = false
var is_hero_damage: bool = false

func _ready() -> void:
	z_as_relative = false
	UIFonts.apply(label)

	if is_heal:
		label.text = "+" + str(amount)
	else:
		label.text = str(amount)

	# ROV-style outline so they pop from background
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)

	if is_heal:
		label.modulate = Color(0.2, 1.0, 0.3)
		icon.visible = false
		label.position = Vector2(-20, -18)
		self.z_index = 400
		_animate()
		return

	if is_crit:
		label.modulate = Color(1.0, 0.8, 0.0) # ROV Yellow/Gold Crit
		icon.visible = true
		_fit_crit_icon_to_label()

		# Position the text just behind the icon
		label.position = Vector2(-10, -18)

		# On top of almost everything
		self.z_index = 410
	elif is_hero_damage:
		# Hero damage: Red text + Yellow/Gold stroke
		label.modulate = Color(1.0, 0.15, 0.15) # Red
		label.add_theme_color_override("font_outline_color", Color(1.0, 0.85, 0.0)) # Yellow stroke
		label.add_theme_constant_override("outline_size", 5)
		icon.visible = false
		label.position = Vector2(-20, -18)
		self.z_index = 400
	else:
		label.modulate = Color.WHITE
		icon.visible = false

		# Center label
		label.position = Vector2(-20, -18)

		self.z_index = 400

	_animate()

func _animate() -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# Randomize horizontal arc direction like in ROV
	var rand_x = randf_range(-40.0, 40.0)

	if is_crit:
		# Start scale small
		scale = Vector2(1.5, 1.5)

		# Scale Pop: Huge then bounce to large
		var scale_tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1).set_delay(0.15)

		# Arc Movement: Jump high, then fall
		var pos_tween_y = create_tween()
		pos_tween_y.tween_property(self, "position:y", position.y - 28.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pos_tween_y.tween_property(self, "position:y", position.y - 12.0, 0.22).set_delay(0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tween.tween_property(self, "position:x", position.x + rand_x, 0.5).set_trans(Tween.TRANS_LINEAR)

		# Stay a bit longer, then fade
		tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.5)

	else:
		# Start scale small
		scale = Vector2(1.5, 1.5)

		# Scale Pop: Normal then settle
		var scale_tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)

		# Arc Movement: Quick jump, small fall
		var pos_tween_y = create_tween()
		pos_tween_y.tween_property(self, "position:y", position.y - 18.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pos_tween_y.tween_property(self, "position:y", position.y - 6.0, 0.16).set_delay(0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tween.tween_property(self, "position:x", position.x + (rand_x * 0.7), 0.35).set_trans(Tween.TRANS_LINEAR)

		# Fade out quickly
		tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.35)

	# Clean up after the longest animation (Crit takes 0.5+0.3 = 0.8s)
	await get_tree().create_timer(0.9).timeout
	queue_free()

func _fit_crit_icon_to_label() -> void:
	var texture_size := icon.texture.get_size()
	if texture_size.y <= 0.0:
		return

	var font_size := label.get_theme_font_size("font_size")
	var font := label.get_theme_font("font")
	var target_height := float(font_size)
	if font != null:
		target_height = font.get_height(font_size)

	var scale_ratio := target_height / texture_size.y
	icon.scale = Vector2.ONE * scale_ratio
	icon.position = Vector2(-18, -2)
