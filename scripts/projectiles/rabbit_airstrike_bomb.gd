extends Node2D

@export var impact_radius: float = 90.0
@export var fall_duration: float = 0.55

var target_position: Vector2 = Vector2.ZERO
var damage: int = 10

@onready var shadow: Sprite2D = get_node_or_null("Shadow") as Sprite2D
@onready var bomb_sprite: AnimatedSprite2D = $BombSprite
@onready var impact_ring: Line2D = $ImpactRing


func _ready() -> void:
	z_index = 1000
	impact_ring.visible = false
	bomb_sprite.play("fall")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_position, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if is_instance_valid(shadow):
		tween.tween_property(shadow, "scale", Vector2(0.92, 0.3), fall_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(shadow, "modulate:a", 0.35, fall_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(bomb_sprite, "scale", Vector2(0.78, 0.78), fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(_explode)


func _explode() -> void:
	global_position = target_position
	if is_instance_valid(shadow):
		shadow.visible = false
	bomb_sprite.rotation = 0.0
	bomb_sprite.scale = Vector2(0.95, 0.95)
	bomb_sprite.play("boom")

	impact_ring.visible = true
	impact_ring.scale = Vector2.ONE
	impact_ring.modulate.a = 0.95
	var ring_tween := create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(impact_ring, "scale", Vector2(2.8, 1.7), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ring_tween.tween_property(impact_ring, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_apply_aoe_damage()
	bomb_sprite.animation_finished.connect(func() -> void:
		queue_free()
	, CONNECT_ONE_SHOT)


func _apply_aoe_damage() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and bool(enemy.get("is_dead")):
			continue
		if enemy.global_position.distance_to(target_position) > impact_radius:
			continue
		if enemy.has_method("take_damage"):
			var hit_direction: Vector2 = (enemy.global_position - target_position).normalized()
			enemy.take_damage(damage, "death_explode", hit_direction)
