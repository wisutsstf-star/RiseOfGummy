extends Node2D
## RestrictedZoneVisualizer
## Optional debug visualizer to show the restricted top zone boundary
## Add this to your main scene for debugging

@export var show_debug_line: bool = true
@export var debug_line_color: Color = Color.RED
@export var debug_line_width: float = 2.0

var _wave_manager: Node = null


func _ready() -> void:
	_wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if _wave_manager == null and get_tree().current_scene != null:
		_wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")


func _draw() -> void:
	if not show_debug_line:
		return
	
	if _wave_manager == null or not _wave_manager.has_method("get_restricted_top_zone_boundary"):
		return
	
	var boundary_y: float = float(_wave_manager.get_restricted_top_zone_boundary())
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	
	# Draw horizontal line at the boundary
	draw_line(
		Vector2(viewport_rect.position.x, boundary_y),
		Vector2(viewport_rect.position.x + viewport_rect.size.x, boundary_y),
		debug_line_color,
		debug_line_width,
		true
	)
	
	# Draw semi-transparent rectangle for the restricted zone
	draw_rect(
		Rect2(viewport_rect.position.x, viewport_rect.position.y, viewport_rect.size.x, boundary_y - viewport_rect.position.y),
		Color(debug_line_color.r, debug_line_color.g, debug_line_color.b, 0.15)
	)
