extends Area2D

@export var speed: float = 700.0
@export var damage: int = 25
var damage_data: Dictionary = {}

var direction: Vector2 = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var hit_audio_stream = preload("res://characters/rabbit/assets/audio/the chewing gum exploded.wav")

func _ready():
	rotation = direction.angle()
	sprite.scale = Vector2(0.5, 0.5) # fly เล็ก
	sprite.play("fly")

func _physics_process(delta):
	# บินตรงไปเรื่อยๆ ไม่ติดตามเป้าหมาย
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			var base_dmg = damage
			if damage_data.has("amount"):
				base_dmg = damage_data["amount"]
			
			body.take_damage(base_dmg)
			
			var explode_chance = 0.0
			if has_meta("explode_chance_pct"):
				explode_chance = get_meta("explode_chance_pct")
			
			if explode_chance > 0.0 and randf() * 100.0 <= explode_chance:
				var splash_pct = 0.0
				if has_meta("explode_splash_pct"):
					splash_pct = get_meta("explode_splash_pct") / 100.0
				var splash_dmg = int(float(base_dmg) * splash_pct)
				
				var enemies = get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if e != body and is_instance_valid(e) and not (e.has_method("is_dead") and e.is_dead()):
						if e.global_position.distance_to(global_position) <= 150.0:
							if e.has_method("take_damage"):
								e.take_damage(splash_dmg)
		# hit ใหญ่
		sprite.scale = Vector2(1.2, 1.2)
		# เล่นอนิเมชั่น hit แล้วหายไป
		sprite.play("hit")
		
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.global_position = global_position
		get_tree().current_scene.add_child(audio_player)
		audio_player.stream = hit_audio_stream
		audio_player.bus = "SFX"
		audio_player.max_distance = 1500
		audio_player.volume_db = -5.0
		audio_player.pitch_scale = 0.82
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
		set_physics_process(false)
		await sprite.animation_finished
		queue_free()

func _on_timer_timeout():
	queue_free()
