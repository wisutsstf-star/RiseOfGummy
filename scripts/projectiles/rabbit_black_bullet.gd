extends Area2D

@export var speed: float = 1200.0 # เร็วขึ้นเป็น 1200 (เดิม 600)
@export var damage: int = 24
var damage_data: Dictionary = {"amount": 24, "is_crit": false}

const DEFAULT_PIERCE_TARGETS := 1

var direction: Vector2 = Vector2.RIGHT
var target_pos: Vector2 = Vector2.ZERO
var max_pierce_targets: int = DEFAULT_PIERCE_TARGETS
var pierce_damage_falloff: float = 0.0
var keep_full_damage_on_pierce: bool = false

var hit_enemies: Array = []

@onready var sprite: AnimatedSprite2D = $Sprite2D # ชื่อใน Scene คือ "Sprite2D"
var hit_audio_stream = preload("res://characters/rabbit/assets/audio/the chewing gum exploded.wav")


func _ready():
	if target_pos != Vector2.ZERO:
		direction = (target_pos - global_position).normalized()
	
	# หมุนกระสุนให้หันตามทิศทางบิน
	rotation = direction.angle()
	
	# fly ขนาดเล็ก (ปกติของกระสุนกระต่าย)
	sprite.scale = Vector2(0.5, 0.5)
	sprite.play("fly")

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# ยิงทะลุ - ตรวจสอบว่ายิงตัวนี้ไปแล้วหรือยัง
		if body in hit_enemies:
			return
		
		hit_enemies.append(body)
		
		if body.has_method("take_damage"):
			var base_damage = damage_data["amount"] if damage_data.has("amount") else damage
			var atk = _calculate_pierce_damage(base_damage, hit_enemies.size())
			var crit = damage_data["is_crit"] if damage_data.has("is_crit") else false
			
			if body.get_method_argument_count("take_damage") >= 4:
				body.take_damage(atk, "death_explode", direction, crit)
			else:
				body.take_damage(atk, "death_explode", direction)
				
			# Splash logic
			var explode_chance = 0.0
			if has_meta("explode_chance_pct"):
				explode_chance = get_meta("explode_chance_pct")
			
			if explode_chance > 0.0 and randf() * 100.0 <= explode_chance:
				var splash_pct = 0.0
				if has_meta("explode_splash_pct"):
					splash_pct = get_meta("explode_splash_pct") / 100.0
				var splash_dmg = int(float(atk) * splash_pct)
				
				var enemies = get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if e != body and is_instance_valid(e) and not (e.has_method("is_dead") and e.is_dead()):
						if e.global_position.distance_to(global_position) <= 150.0:
							if e.has_method("take_damage"):
								e.take_damage(splash_dmg)
			
			# Play hit sound
			var audio_player = AudioStreamPlayer2D.new()
			audio_player.global_position = global_position
			get_tree().current_scene.add_child(audio_player)
			audio_player.stream = hit_audio_stream
			audio_player.bus = "SFX"
			audio_player.max_distance = 1800
			audio_player.volume_db = -5.0
			audio_player.pitch_scale = 0.8
			audio_player.play()
			audio_player.finished.connect(audio_player.queue_free)
		
		if max_pierce_targets > 0 and hit_enemies.size() >= max_pierce_targets:
			queue_free()
		
	else:
		# Hit wall/obstacle -> Destroy bullet
		queue_free()


func _on_timer_timeout():
	# บินนานเกิน 5 วินาทีไม่โดนอะไร ให้ลบ
	queue_free()


func _calculate_pierce_damage(base_damage: int, hit_count: int) -> int:
	if keep_full_damage_on_pierce:
		return base_damage

	var multiplier := maxf(0.0, 1.0 - pierce_damage_falloff * float(maxi(0, hit_count - 1)))
	return int(round(float(base_damage) * multiplier))
