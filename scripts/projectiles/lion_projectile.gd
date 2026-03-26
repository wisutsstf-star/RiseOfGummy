extends BaseProjectile

@export var knockback_force: float = 300.0

@onready var anim_sprite: AnimatedSprite2D = $Sprite2D

var hit_count: int = 0
var hit_enemies: Array[Node2D] = []
var hit_jelly_sound = load("res://characters/lion/assets/audio/jelly swords clashing.wav")
var _last_hit_sound_time: float = -1.0

func _ready() -> void:
	# ── Sword Wave: พุ่งไปข้างหน้าระยะกึ่งใกล้-กลาง ──
	speed = 350.0
	max_distance = 220.0
	is_moving = true

	super._ready()

	# เล่น "hit" animation เป็น visual ขณะบิน
	if anim_sprite:
		anim_sprite.play("hit")


func _on_body_entered(body: Node2D) -> void:
	if not is_moving:
		return
	
	if body.is_in_group("enemies") and not hit_enemies.has(body):
		hit_enemies.append(body)
		_apply_hit(body)
		_play_hit_sound()
		hit_count += 1


func _apply_hit(body: Node2D) -> void:
	# ── Knockback ──
	if body.has_method("apply_knockback"):
		var knockback_dir = (body.global_position - start_pos).normalized()
		body.apply_knockback(knockback_dir * knockback_force)

	# ── Damage ──
	if body.has_method("take_damage"):
		var base_atk = damage_data["amount"] if damage_data.has("amount") else damage
		var crit = damage_data["is_crit"] if damage_data.has("is_crit") else false

		var multiplier: float = max(1.0 - hit_count * 0.2, 0.5)
		var final_atk
		if typeof(base_atk) == TYPE_INT:
			final_atk = int(round(base_atk * multiplier))
		else:
			final_atk = base_atk * multiplier

		if body.get_method_argument_count("take_damage") >= 4:
			body.take_damage(final_atk, "death_slash", direction, crit)
		else:
			body.take_damage(final_atk, "death_slash")


func _play_hit_effect() -> void:
	# Override base to do nothing here so the projectile doesn't stop and fade out
	# Projectile will naturally queue_free() when distance > max_distance handled in base_projectile.gd
	pass
func _play_hit_sound() -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now - _last_hit_sound_time < 0.08: # 80ms throttle
		return
	_last_hit_sound_time = now
	
	var player = AudioStreamPlayer2D.new()
	player.global_position = global_position
	get_tree().current_scene.add_child(player)
	player.stream = hit_jelly_sound
	player.bus = "SFX"
	player.max_distance = 1500
	player.volume_db = -10.0
	player.pitch_scale = 0.75
	player.play()
	player.finished.connect(player.queue_free)
