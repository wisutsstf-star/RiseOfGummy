extends Node2D
class_name PigBloodExplosion

signal effect_finished(effect: PigBloodExplosion)

@export var sphere_start_scale: Vector2 = Vector2(0.2, 0.2)
@export var sphere_peak_scale: Vector2 = Vector2(1.3, 1.3)
@export var flash_start_scale: Vector2 = Vector2(0.2, 0.1)
@export var flash_peak_scale: Vector2 = Vector2(1.5, 0.7)
@export var suction_finish_start_scale: Vector2 = Vector2(0.16, 0.08)
@export var suction_finish_peak_scale: Vector2 = Vector2(1.18, 0.54)
@export var burst_duration: float = 0.18
@export var fade_duration: float = 0.16

var _started: bool = false

@onready var _sound: AudioStreamPlayer2D = $ExplosionSound
@onready var _sphere: Sprite2D = $BigRedSphere
@onready var _flash: Sprite2D = $Flash
@onready var _finish_suction: Sprite2D = $FinishSuction


func _ready() -> void:
	_reset_visuals()


func play_explosion() -> void:
	if _started:
		return
	_started = true
	_reset_visuals()
	if is_instance_valid(_sound):
		_sound.play()
	_run_sequence()


func _run_sequence() -> void:
	var burst_tween := create_tween().set_parallel(true)
	burst_tween.tween_property(_sphere, "scale", sphere_peak_scale, burst_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(_sphere, "modulate:a", 0.95, burst_duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(_flash, "scale", flash_peak_scale, burst_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(_flash, "modulate:a", 0.8, burst_duration * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(_finish_suction, "scale", suction_finish_peak_scale, burst_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(_finish_suction, "modulate:a", 0.72, burst_duration * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await burst_tween.finished
	if not is_inside_tree():
		return

	var fade_tween := create_tween().set_parallel(true)
	fade_tween.tween_property(_sphere, "scale", sphere_peak_scale * 1.12, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(_sphere, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(_flash, "scale", flash_peak_scale * 1.08, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(_flash, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(_finish_suction, "scale", suction_finish_peak_scale * 1.1, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(_finish_suction, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fade_tween.finished
	if not is_inside_tree():
		return

	effect_finished.emit(self)
	queue_free()


func _reset_visuals() -> void:
	if is_instance_valid(_sphere):
		_sphere.scale = sphere_start_scale
		_sphere.modulate.a = 0.0
	if is_instance_valid(_flash):
		_flash.scale = flash_start_scale
		_flash.modulate.a = 0.0
	if is_instance_valid(_finish_suction):
		_finish_suction.scale = suction_finish_start_scale
		_finish_suction.modulate.a = 0.0
		_finish_suction.rotation = 0.0
