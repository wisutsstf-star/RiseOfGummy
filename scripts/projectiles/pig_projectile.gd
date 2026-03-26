extends BaseProjectile

const PIG_HIT_SOUND = preload("res://characters/pig/assets/audio/pig hit.wav")

func _on_hit_enemy(body: Node2D) -> void:
	_play_pig_hit_sound(body.global_position)
	super._on_hit_enemy(body)
	
	# 5-10% chance to apply Bleed
	var chance = randf()
	if chance <= 0.10: # 10% chance (covering 5-10%)
		if body.has_method("apply_bleed"):
			body.apply_bleed(3.0) # Bleed for 3 seconds


func _play_pig_hit_sound(pos: Vector2) -> void:
	var player := AudioStreamPlayer2D.new()
	player.global_position = pos
	get_tree().current_scene.add_child(player)
	player.stream = PIG_HIT_SOUND
	player.bus = "SFX"
	player.max_distance = 1600
	player.volume_db = -10.0
	player.pitch_scale = 1.0
	player.play()
	player.finished.connect(player.queue_free)
