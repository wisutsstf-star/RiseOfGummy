extends Area2D

@export var speed: float = 350.0
@export var base_damage: int = 10
@export var level: int = 1

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = true
var is_nova: bool = false
var nova_timer: float = 0.0
var tick_timer: float = 0.0

var _nova_speed_multi: float = 0.05
var _slow_pct: float = 0.5
var _slow_duration: float = 1.5
var _aoe_radius: float = 60.0
var _orb_rotate_speed: float = 5.0

var _hero_owner: Node2D = null

# Visual nodes (created at runtime like PigBloodOrb)
var _orb_sprite: Sprite2D = null
var _orbit_spark: AnimatedSprite2D = null
var _spark_base_scale: Vector2 = Vector2.ZERO

const ORB_BASE_SCALE := Vector2(0.12, 0.12)
const ORBIT_SPARK_TEXTURE_PATHS := [
	"res://characters/pig/assets/orbit_spark (1).png",
	"res://characters/pig/assets/orbit_spark (2).png",
	"res://characters/pig/assets/orbit_spark (3).png",
	"res://characters/pig/assets/orbit_spark (4).png",
	"res://characters/pig/assets/orbit_spark (5).png",
]
var _orbit_spark_textures: Array[Texture2D] = []

func _ready() -> void:
	z_index = 80 # Render above enemies (75)
	
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(1.5).timeout.connect(_on_timeout)
	
	# Build visuals at runtime (clean, no scene children needed)
	_orb_sprite = Sprite2D.new()
	_orb_sprite.texture = load("res://characters/pig/assets/red_sphere.png")
	_orb_sprite.scale = ORB_BASE_SCALE
	_orb_sprite.modulate = Color(1.0, 0.45, 0.45, 0.95)
	add_child(_orb_sprite)
	
	# Setup animated orbit spark (frame-by-frame like PigBloodOrb)
	_orbit_spark_textures.clear()
	for path in ORBIT_SPARK_TEXTURE_PATHS:
		var tex = load(path) as Texture2D
		if tex:
			_orbit_spark_textures.append(tex)
	
	_orbit_spark = AnimatedSprite2D.new()
	_orbit_spark.name = "OrbitSpark"
	var frames = SpriteFrames.new()
	frames.add_animation("spark")
	frames.set_animation_speed("spark", 8.0)
	frames.set_animation_loop("spark", true)
	for tex in _orbit_spark_textures:
		frames.add_frame("spark", tex)
	_orbit_spark.sprite_frames = frames
	_orbit_spark.animation = "spark"
	
	# Scale orbit spark to match orb size ratio but make it slightly larger so it wraps around
	var orb_tex = _orb_sprite.texture
	if orb_tex and not _orbit_spark_textures.is_empty():
		var orb_size = orb_tex.get_size()
		var spark_size = _orbit_spark_textures[0].get_size()
		if spark_size.x > 0.0 and spark_size.y > 0.0:
			_spark_base_scale = Vector2(
				ORB_BASE_SCALE.x * (orb_size.x / spark_size.x),
				ORB_BASE_SCALE.y * (orb_size.y / spark_size.y)
			)
			_orbit_spark.scale = _spark_base_scale
	
	_orbit_spark.z_index = 1
	_orbit_spark.visible = false  # Hidden during travel phase
	add_child(_orbit_spark)
	_orbit_spark.play("spark")

func setup(config: Dictionary, cast_dir: Vector2, hero: Node2D) -> void:
	level = config.get("level", 1)
	base_damage = config.get("base_damage", 10)
	direction = cast_dir.normalized()
	_hero_owner = hero

	if level == 1:
		pass  # Base scale from script handles actual size
	elif level == 2:
		speed *= 1.2
		base_damage = int(base_damage * 1.5)
	elif level >= 3:
		speed *= 1.2
		base_damage = int(base_damage * 2.0)

func _process(delta: float) -> void:
	if not is_active: return
	
	if is_instance_valid(_orb_sprite):
		_orb_sprite.rotation -= _orb_rotate_speed * delta
	
	if not is_nova:
		position += direction * speed * delta
	else:
		position += direction * (speed * _nova_speed_multi) * delta
		nova_timer -= delta
		tick_timer -= delta
		
		if tick_timer <= 0.0:
			tick_timer = 0.5
			_tick_damage(int(base_damage * 0.4))
			
		if nova_timer <= 0.0:
			_finish_nova()

func _on_body_entered(body: Node2D) -> void:
	if not is_active: return
	if body.is_in_group("enemies") and not body.get("is_dead"):
		if not is_nova:
			_erupt(body)

func _on_timeout() -> void:
	if is_active and not is_nova:
		_erupt()

func _erupt(hit_body: Node2D = null) -> void:
	is_nova = true
	nova_timer = 2.0
	
	var tw = create_tween().set_parallel(true)
	
	# Show orbit spark on erupt
	if is_instance_valid(_orbit_spark):
		_orbit_spark.visible = true
		tw.tween_property(_orbit_spark, "scale", _spark_base_scale * 1.3, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Expand orb slightly and make it translucent on impact so enemies underneath look shadowed
	if is_instance_valid(_orb_sprite):
		tw.tween_property(_orb_sprite, "scale", ORB_BASE_SCALE * 1.3, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_orb_sprite, "modulate:a", 0.90, 0.2)
	
	# Stun the direct-hit enemy
	if is_instance_valid(hit_body) and hit_body.is_in_group("enemies") and not hit_body.get("is_dead"):
		if hit_body.has_method("apply_stun"):
			hit_body.apply_stun(1.0)
		_apply_hit(hit_body, base_damage)
		tick_timer = 0.5
	else:
		tick_timer = 0.0

func _tick_damage(dmg: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			if global_position.distance_to(enemy.global_position) <= _aoe_radius * scale.x:
				_apply_hit(enemy, dmg)
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(_slow_pct, _slow_duration)

func _finish_nova() -> void:
	is_active = false
	is_nova = false
	
	var tw = create_tween()
	if level >= 3:
		# Level 3: Final explosion burst
		var impact_sprite = Sprite2D.new()
		impact_sprite.texture = load("res://characters/pig/assets/smoke_particle.png")
		impact_sprite.modulate = Color(1.0, 0.2, 0.2, 0.8)
		impact_sprite.scale = Vector2(0.2, 0.2)
		add_child(impact_sprite)
		
		if is_instance_valid(_orb_sprite):
			tw.parallel().tween_property(_orb_sprite, "scale", ORB_BASE_SCALE * 1.5, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if is_instance_valid(_orbit_spark):
			tw.parallel().tween_property(_orbit_spark, "scale", _spark_base_scale * 1.5, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		tw.parallel().tween_property(impact_sprite, "scale", Vector2(0.5, 0.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(impact_sprite, "modulate:a", 0.0, 0.25)
		
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.get("is_dead"):
				if global_position.distance_to(enemy.global_position) <= _aoe_radius * scale.x * 1.2:
					_apply_hit(enemy, int(base_damage * 1.0))
	
	# Fade out everything
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(self.queue_free)

func _apply_hit(enemy: Node2D, dmg: int) -> void:
	if is_instance_valid(enemy) and enemy.has_method("take_damage"):
		var dmg_dir = (enemy.global_position - global_position).normalized()
		enemy.take_damage(dmg, "normal", dmg_dir)
