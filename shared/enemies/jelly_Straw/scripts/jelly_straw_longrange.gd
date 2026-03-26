extends "res://shared/enemies/jelly_Straw/scripts/jelly_straw.gd"

# ====================================================
# Jelly Straw Long Range - Wave 4 Miniboss Support
# ====================================================
# - Normal attack range (same as regular jelly_straw)
# - 2x bigger size
# ====================================================

func _ready() -> void:
	super._ready()
	
	# Scale up 2x
	scale = Vector2(2.0, 2.0)
