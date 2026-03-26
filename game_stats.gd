extends Node
# ═══════════════════════════════════════════
#  GAME STATS — Rise of Gummy  (Autoload)
#  เก็บ stats ที่ upgrade card เพิ่มให้
#
#  วิธีใช้ใน Project Settings → Autoload:
#    Path : res://game_stats.gd
#    Name : GameStats
# ═══════════════════════════════════════════

signal stats_changed()

# ── Global Upgrade Values ──────────────────
var bonus_damage:     int   = 0   # +damage flat ทุกตัว
var bonus_atkspd_pct: float = 0.0 # +% attack speed (อนาคต)
var bonus_hp:         int   = 0   # +HP flat (อนาคต)
var unlocked_upgrades: Dictionary = {}
var pig_ult_level: int = 0
const MAX_PIG_ULT_LEVEL := 5

var blue_potions: int = 0

# ══════════════════════════════════════════
#  APPLY UPGRADE  (เรียกจาก UpgradeCardPanel)
# ══════════════════════════════════════════
func apply_upgrade(upgrade: Dictionary) -> void:
	var type:  String = upgrade.get("type",  "")
	var value: int    = upgrade.get("value", 0)
	if not type.is_empty():
		unlocked_upgrades[type] = int(unlocked_upgrades.get(type, 0)) + 1

	match type:
		"damage_flat":
			bonus_damage += value
			print("GameStats: +%d damage → total bonus = %d" % [value, bonus_damage])
		"atkspd_pct":
			bonus_atkspd_pct += value
		"hp_flat":
			bonus_hp += value
		"rabbit_airstrike":
			pass
		"rabbit_black_bullet":
			pass
		_:
			push_warning("GameStats: unknown upgrade type '%s'" % type)

	stats_changed.emit()

# ══════════════════════════════════════════
#  POTIONS
# ══════════════════════════════════════════
func add_blue_potions(amount: int) -> void:
	if amount <= 0: return
	blue_potions += amount
	stats_changed.emit()

func spend_blue_potion() -> bool:
	if blue_potions > 0:
		blue_potions -= 1
		stats_changed.emit()
		return true
	return false

# ══════════════════════════════════════════
#  RESET  (เรียกตอน Again)
# ══════════════════════════════════════════
func reset() -> void:
	bonus_damage     = 0
	bonus_atkspd_pct = 0.0
	bonus_hp         = 0
	unlocked_upgrades.clear()
	pig_ult_level = 0
	blue_potions = 0
	stats_changed.emit()
	print("GameStats: reset")


func get_pig_ult_level() -> int:
	return pig_ult_level


func set_pig_ult_level(level: int) -> void:
	pig_ult_level = clampi(level, 0, MAX_PIG_ULT_LEVEL)
	stats_changed.emit()


func advance_pig_ult_level() -> void:
	if pig_ult_level >= MAX_PIG_ULT_LEVEL:
		return
	pig_ult_level += 1
	stats_changed.emit()

# ══════════════════════════════════════════
#  HELPER — ใช้ใน enemy/player script
#  เช่น:  var dmg = base_damage + GameStats.bonus_damage
# ══════════════════════════════════════════
func get_damage_bonus() -> int:
	return bonus_damage


func has_upgrade(type: String) -> bool:
	return int(unlocked_upgrades.get(type, 0)) > 0


func get_upgrade_count(type: String) -> int:
	return int(unlocked_upgrades.get(type, 0))
