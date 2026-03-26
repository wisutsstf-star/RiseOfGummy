extends RefCounted
class_name UIFonts

const REGULAR_FONT := preload("res://shared/ui/assets/fonts/CMU-Regular.ttf")
static var _button_bold_font: FontVariation

static func apply(control: Control) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", REGULAR_FONT)
	if control is RichTextLabel:
		control.add_theme_font_override("normal_font", REGULAR_FONT)
		control.add_theme_font_override("bold_font", REGULAR_FONT)
		control.add_theme_font_override("italics_font", REGULAR_FONT)
		control.add_theme_font_override("bold_italics_font", REGULAR_FONT)
		control.add_theme_font_override("mono_font", REGULAR_FONT)

static func apply_tree(node: Node) -> void:
	if node == null:
		return
	if node is Control:
		apply(node)
	for child in node.get_children():
		apply_tree(child)

static func get_button_bold_font() -> FontVariation:
	if _button_bold_font == null:
		_button_bold_font = FontVariation.new()
		_button_bold_font.base_font = REGULAR_FONT
		_button_bold_font.variation_embolden = 0.9
	return _button_bold_font
