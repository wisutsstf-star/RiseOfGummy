extends "res://scripts/enemy.gd"

# ====================================================
# Gummy Bear
# ====================================================
# ค่าทั้งหมดปรับได้ผ่าน Inspector (@export จาก enemy.gd)
# รองรับ death animations พิเศษ: slash / explode
# ====================================================

func _ready() -> void:
	use_attack_windup_when_waiting = true
	xp_reward = 20
	super._ready()
