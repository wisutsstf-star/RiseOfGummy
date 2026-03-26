extends Node2D
class_name PigBloodCore

signal explosion_requested(position: Vector2)
signal sequence_finished(core: PigBloodCore)

@export var normal_scale: Vector2 = Vector2(0.12, 0.12)
@export var implode_scale: Vector2 = Vector2(0.06, 0.06)
@export var expand_scale: Vector2 = Vector2(0.32, 0.32)
@export var settle_duration: float = 0.12
@export var implode_duration: float = 0.14
@export var expand_duration: float = 0.22

var _started: bool = false
var _spark_scale_ratio: Vector2 = Vector2.ONE

@onready var _core_sprite: Sprite2D = $CoreSprite
@onready var _orbit_spark: AnimatedSprite2D = $OrbitSpark


func _ready() -> void:
	if is_instance_valid(_orbit_spark) and normal_scale.x != 0.0 and normal_scale.y != 0.0:
		_spark_scale_ratio = Vector2(
			_orbit_spark.scale.x / normal_scale.x,
			_orbit_spark.scale.y / normal_scale.y
		)
	_apply_visual_state(normal_scale, 1.0)


func start_sequence() -> void:
	if _started:
		return
	_started = true
	_run_sequence()


func _run_sequence() -> void:
	await get_tree().create_timer(settle_duration).timeout
	if not is_inside_tree():
		return

	var implode_tween := create_tween().set_parallel(true)
	implode_tween.tween_property(_core_sprite, "scale", implode_scale, implode_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	implode_tween.tween_property(_orbit_spark, "scale", _get_spark_scale(implode_scale), implode_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await implode_tween.finished
	if not is_inside_tree():
		return

	explosion_requested.emit(global_position)

	var expand_tween := create_tween().set_parallel(true)
	expand_tween.tween_property(_core_sprite, "scale", expand_scale, expand_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	expand_tween.tween_property(_core_sprite, "modulate:a", 0.0, expand_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	expand_tween.tween_property(_orbit_spark, "scale", _get_spark_scale(expand_scale), expand_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	expand_tween.tween_property(_orbit_spark, "modulate:a", 0.0, expand_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await expand_tween.finished
	if not is_inside_tree():
		return

	sequence_finished.emit(self)
	queue_free()


func _apply_visual_state(target_scale: Vector2, alpha: float) -> void:
	if is_instance_valid(_core_sprite):
		_core_sprite.scale = target_scale
		_core_sprite.modulate.a = alpha
	if is_instance_valid(_orbit_spark):
		_orbit_spark.scale = _get_spark_scale(target_scale)
		_orbit_spark.modulate.a = alpha
		if not _orbit_spark.is_playing():
			_orbit_spark.play("fly")


func _get_spark_scale(target_scale: Vector2) -> Vector2:
	return Vector2(
		target_scale.x * _spark_scale_ratio.x,
		target_scale.y * _spark_scale_ratio.y
	)
