class_name BaseProjectile
extends Area2D

@export var speed: float = 400.0
@export var damage: int = 25
## damage_type – ประเภทดาเมจ: "physical" / "magic" / "true"
@export_enum("physical", "magic", "true") var damage_type: String = "physical"
var damage_data: Dictionary = {"amount": 25, "is_crit": false, "damage_type": "physical"}
@export var max_distance: float = 1000.0

var target_pos: Vector2
var direction: Vector2
var start_pos: Vector2
var is_moving: bool = true
## ผู้ยิง – ตั้งค่าโดย hero ตอน spawn projectile (ใช้สำหรับ life_steal)
var shooter: Node2D = null

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	start_pos = global_position
	direction = (target_pos - global_position).normalized()
	rotation = direction.angle()
	
	if sprite:
		sprite.play("fly")

func _physics_process(delta: float) -> void:
	if not is_moving:
		return
		
	position += direction * speed * delta
	
	if global_position.distance_to(start_pos) > max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not is_moving:
		return
	
	if body.is_in_group("enemies"):
		_on_hit_enemy(body)

func _on_hit_enemy(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var atk: int = damage_data.get("amount", damage)
		var crit: bool = damage_data.get("is_crit", false)
		var dtype: String = damage_data.get("damage_type", damage_type)
		body.take_damage(atk, "die", direction, crit, dtype)
		# Life Steal – คืน HP ให้ shooter (true damage ไม่ lifesteal ตามมาตรฐาน)
		if dtype != "true" and is_instance_valid(shooter) and shooter.has_method("heal"):
			var steal: float = shooter.get("life_steal") if "life_steal" in shooter else 0.0
			if steal > 0.0:
				shooter.heal(max(1, int(float(atk) * steal)))

	_play_hit_effect()

func _play_hit_effect() -> void:
	is_moving = false
	if sprite:
		sprite.play("hit")
		await sprite.animation_finished
	queue_free()
