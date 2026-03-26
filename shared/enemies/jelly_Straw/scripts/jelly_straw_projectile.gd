extends Area2D

@export var speed: float = 360.0
@export var damage: int = 3
@export var max_travel_distance: float = 520.0

var target_pos: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var _travelled_distance: float = 0.0
var _has_hit: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if target_pos != Vector2.ZERO:
		direction = (target_pos - global_position).normalized()

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	rotation = direction.angle()
	sprite.play("fly")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	var motion := direction * speed * delta
	global_position += motion
	_travelled_distance += motion.length()

	if _travelled_distance >= max_travel_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _has_hit:
		return

	if body.is_in_group("heroes"):
		_apply_hit(body)


func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return

	if area.is_in_group("crystal_heart"):
		_apply_hit(area)


func _apply_hit(target: Node) -> void:
	_has_hit = true
	set_deferred("monitoring", false)

	if target.has_method("take_damage"):
		target.take_damage(damage)

	queue_free()
