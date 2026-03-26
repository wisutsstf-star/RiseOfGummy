extends CharacterBody2D
class_name HeroBase

@export var projectile_scene: PackedScene
@export var attack_delay: float = 0.25 # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€ข (เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ข)

# UI/Skill Properties (CRK Style)
@export var avatar_icon: Texture2D
@export var skill_icon: Texture2D
@export var element_icon: Texture2D
@export var max_cooldown: float = 12.0
@export var max_cooldown_2: float = 12.0
@export var skill_icon_2: Texture2D
@export var current_level: int = 1
@export var current_xp: int = 0
@export var max_level: int = 8

# Cumulative XP required to reach each level (index 0 = Lv1→2, index 1 = Lv2→3, etc.)
# Easy to tune: just edit this one table.
const XP_THRESHOLDS := [2000, 5000, 9000, 15000, 22000, 31000, 42000]
@export var skill_color: Color = Color(1.0, 0.85, 0.3) # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ Hero เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย VFX เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธโ€ฆ

signal cooldown_updated(current: float, maximum: float)
signal skill_ready()
signal skill_activated() # Signal when skill is pressed and running

signal cooldown_updated_2(current: float, maximum: float)
signal skill_ready_2()
signal skill_activated_2()
signal hp_updated(current: int, maximum: int)
signal hero_died()
signal leveled_up(new_level: int)

# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย (Primary Stats)
# ── Core Combat Stats (ค่าสู้หลัก) ──────────────────────────────────────
@export_group("Core Combat Stats")
## HP – พลังชีวิต
@export var max_hp: int = 100
## ATK ค่าเดียว – ประเภทดาเมจระบุตอนโจมตี ("physical" / "magic" / "true")
@export var attack: int = 25
## DEF – ป้องกันกายภาพ (Physical Defense)
@export var defense: int = 5
## MDEF – ป้องกันเวท (Magic Defense)
@export var mdef: int = 0
## Crit Rate – อัตราคริติคอล (0.0–1.0)
@export var crit_chance: float = 0.05
## Crit DMG – บวกเพิ่มจากคริติคอล (0.0 = ×2, 0.5 = ×2.5 ...)
@export var crit_damage: float = 0.0
## Attack Speed – ตัวคูณความเร็วโจมตี
@export var attack_speed: float = 1.0
## Armor Pen – เจาะเกราะ ลด DEF ของเป้าหมาย
@export var armor_pen: int = 0
## Magic Pen – เจาะเวท ลด MDEF ของเป้าหมาย
@export var magic_pen: int = 0

# ── Secondary Combat Stats (ค่าสู้รอง) ──────────────────────────────────
@export_group("Secondary Combat Stats")
## Life Steal – ดูดเลือด คืน HP % ของดาเมจที่ทำ (0.0–1.0)
@export var life_steal: float = 0.0
## Healing Power – ตัวคูณพลังฮีล (1.0 = ปกติ)
@export var heal_power: float = 1.0
## Dodge – โอกาสหลบการโจมตีกายภาพ (0.0–1.0)
@export var dodge: float = 0.0
## Tenacity – ต้านสถานะ ลด duration ของ CC (0.0–1.0)
@export var tenacity: float = 0.0
## Move Speed – ความเร็วเคลื่อนที่
@export var move_speed: int = 200
## Range – ระยะโจมตี (ใช้แทน attack_range)
@export var attack_range: float = 600.0

# ── Legacy / Resist Stats ─────────────────────────────────────────────────
@export_group("Resist Stats")
@export var cooldown_reduction: float = 0.0
@export var dmg_resist: float = 0.0
@export var debuff_resist: float = 0.0
@export var atk_resist: float = 0.0
@export var shield_hp: int = 0

# ── Ground Mode Stats ─────────────────────────────────────────────────────
@export_group("Ground Mode")
@export var ground_attack_range: float = 80.0
@export var ground_melee_hit_range: float = 120.0
@export var max_patrol_range: float = 450.0

@export_group("")

var fire_timer: float = 0.0
var current_hp: int
var current_cooldown: float = 0.0
var current_cooldown_2: float = 0.0
var is_skill_active: bool = false # is skill currently running before cooldown?
var is_skill_active_2: bool = false
var is_dead: bool = false
var _skill_vfx_tween: Tween
var _level_up_vfx_tween: Tween
var _level_up_vfx_root: Node2D = null
var _level_up_original_material: Material = null
var _old_sprite_material: Material = null
var _forest_recall_root: Node2D = null
var _forest_recall_original_material: Material = null
var _forest_recall_shader: ShaderMaterial = null
var _forest_recall_tween: Tween = null
var _forest_recall_original_sprite_pos: Vector2 = Vector2.ZERO
var _forest_recall_original_sprite_scale: Vector2 = Vector2.ONE
var _forest_recall_original_sprite_modulate: Color = Color.WHITE
var _forest_recall_session_id: int = 0
var _card_modifier_state = null
var _blood_shield_hp: int = 0
var _blood_shield_duration_left: float = 0.0

# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ Ground Mode เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
var is_ground_mode: bool = false # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย
var base_position: Vector2 # เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย
var ground_target: Node2D = null # เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย

var ground_is_attacking: bool = false # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย

signal ground_mode_changed(is_ground: bool)

# Outline shader เน€เธยเนยเธเนโฌย เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€
static var _outline_shader: Shader

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	current_hp = max_hp
	_card_modifier_state = _get_card_modifier_state()
	current_cooldown = _get_effective_skill_cooldown()
	current_cooldown_2 = _get_effective_skill_cooldown_2()
	add_to_group("heroes")
	
	leveled_up.connect(_on_leveled_up)
	sprite.play("idle")
	base_position = global_position # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย

	# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย outline shader เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย (shared เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย)
	if _outline_shader == null:
		_outline_shader = Shader.new()
		_outline_shader.code = """
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.25, 1.0);
uniform float outline_width : hint_range(0.0, 20.0) = 4.0;
uniform float outline_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a > 0.1) {
		COLOR = col;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float a = 0.0;
		// 8 เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย + 8 เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย (16-sample) เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌย
		a = max(a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(-size.x, size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(size.x, size.y)).a);
		// เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย diagonal 45-degree offsets
		a = max(a, texture(TEXTURE, UV + vec2(-size.x * 0.7, -size.y * 0.7)).a);
		a = max(a, texture(TEXTURE, UV + vec2(size.x * 0.7, -size.y * 0.7)).a);
		a = max(a, texture(TEXTURE, UV + vec2(-size.x * 0.7, size.y * 0.7)).a);
		a = max(a, texture(TEXTURE, UV + vec2(size.x * 0.7, size.y * 0.7)).a);
		if (a > 0.1) {
			COLOR = vec4(outline_color.rgb, outline_alpha * a);
		} else {
			COLOR.a = 0.0;
		}
	}
}
"""


func _exit_tree() -> void:
	_clear_level_up_vfx()
	_clear_forest_recall_vfx()


func _process(delta: float) -> void:
	_tick_blood_shield(delta)

	# Skill Cooldown Logic
	if current_cooldown > 0:
		current_cooldown -= delta
		cooldown_updated.emit(current_cooldown, _get_effective_skill_cooldown())
		if current_cooldown <= 0:
			current_cooldown = 0
			skill_ready.emit()

	if current_cooldown_2 > 0:
		current_cooldown_2 -= delta
		cooldown_updated_2.emit(current_cooldown_2, _get_effective_skill_cooldown_2())
		if current_cooldown_2 <= 0:
			current_cooldown_2 = 0
			skill_ready_2.emit()

	# Healing Aura Particles
	if get_meta("_heal_aura_active", false):
		_process_healing_aura(delta)


# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ Targeting Utility (เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย AI) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
func _find_nearest_enemy(enemies: Array[Node]) -> Node2D:
	var defense_range := _get_base_defense_range()
	var nearest: Node2D = null
	var min_dist: float = defense_range
	
	for enemy: Node in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue
		var dist_to_base: float = base_position.distance_to(enemy.global_position)
		if dist_to_base > defense_range:
			continue
		if dist_to_base < min_dist:
			min_dist = dist_to_base
			nearest = enemy
	
	return nearest

func _find_patrol_target(radius: float) -> Node2D:
	var defense_range := minf(radius, _get_base_defense_range())
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var nearest: Node2D = null
	var min_dist: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue
		var dist_to_base = base_position.distance_to(enemy.global_position)
		if dist_to_base <= defense_range:
			if dist_to_base < min_dist:
				min_dist = dist_to_base
				nearest = enemy
	return nearest


func _get_base_defense_range() -> float:
	# ใช้ค่าจาก Inspector แทน hardcode
	return max_patrol_range if is_ground_mode else attack_range


func _is_outside_base_defense_range() -> bool:
	return global_position.distance_to(base_position) > _get_base_defense_range()


# เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€
func calculate_damage(damage_type: String = "physical") -> Dictionary:
	# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธย bonus damage เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย Upgrade Card
	var base_atk: int = attack
	if GameStats:
		base_atk += GameStats.bonus_damage
	var modifier_state = _get_card_modifier_state()
	if modifier_state != null:
		base_atk += int(modifier_state.bonus_damage_flat)
	
	# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย +/- 15% เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€
	var variance = randf_range(0.85, 1.15)
	var dmg = int(base_atk * variance)
	var is_crit = false
	
	# เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ฆ (เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธย x2)
	if randf() < crit_chance:
		dmg = int(dmg * (2.0 + crit_damage))
		is_crit = true
	
	return {
		"amount": max(1, dmg),
		"is_crit": is_crit,
		"damage_type": damage_type
	}

# เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย
func take_damage(amount: int, damage_type: String = "physical"):
	# เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย ATK Resist (% เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธย)
	# Dodge – หลบดาเมจกายภาพ
	if damage_type == "physical" and randf() < dodge:
		_spawn_damage_number(0, false) # Miss
		return
	# คำนวณดาเมจตาม damage_type
	var actual: int
	match damage_type:
		"magic":
			# เวท: ลด MDEF ด้วย magic_pen แล้วหักดาเมจ
			var effective_mdef: int = max(0, mdef - magic_pen)
			actual = max(1, int(float(amount) * (100.0 / (100.0 + effective_mdef))))
		"true":
			# True damage: ผ่านโล่โลหิตเท่านั้น ไม่หักค่าป้องกัน
			actual = max(1, amount)
		_: # "physical" (default)
			# กายภาพ: ลด DEF ด้วย armor_pen + ATK Resist + DMG Resist
			var reduced: float = float(amount) * (1.0 - atk_resist) * (1.0 - dmg_resist)
			var effective_def: int = max(0, defense - armor_pen)
			actual = max(1, int(reduced * (100.0 / (100.0 + effective_def))))
	if _blood_shield_hp > 0:
		var absorbed := mini(_blood_shield_hp, actual)
		_blood_shield_hp -= absorbed
		actual -= absorbed
		if actual <= 0:
			return
	current_hp -= actual
	
	_spawn_damage_number(actual, false)
	
	# เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€ข (Hit)
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("hit"):
		# เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย
		var _prev_anim = sprite.animation
		sprite.play("hit")
		
		# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย Timer เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ hit
		var hit_timer = get_tree().create_timer(0.3)
		hit_timer.timeout.connect(func():
			if not is_dead and is_instance_valid(sprite):
				# เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ idle เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธย เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย
				if sprite.animation == "hit":
					sprite.play("idle")
		)
		
	hp_updated.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		_die()


var _ground_retreating: bool = false # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย _die เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย retreat

func _die() -> void:
	if is_dead or _ground_retreating:
		return

	is_dead = true
	remove_from_group("heroes") # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย group เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ข เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€
	
	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	set_physics_process(false)
	set_process(false)
	velocity = Vector2.ZERO
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("AnimationTree"):
		$AnimationTree.active = false
	
	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย ground mode เน€เธยเธขยเนโฌย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌย ground mode เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	if is_ground_mode:
		is_ground_mode = false
		z_index = 0
		ground_mode_changed.emit(false)
	
	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย (เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€ข) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	hero_died.emit()
	hp_updated.emit(0, max_hp)
	
	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	if is_instance_valid(sprite):
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
			sprite.stop()
		else:
			sprite.stop()



	_start_forest_recall()

func _start_forest_recall() -> void:
	if not is_instance_valid(sprite):
		return

	_clear_forest_recall_vfx()

	_forest_recall_original_sprite_pos = sprite.position
	_forest_recall_original_sprite_scale = sprite.scale
	_forest_recall_original_sprite_modulate = sprite.modulate
	sprite.visible = true
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_forest_recall_root = Node2D.new()
	_forest_recall_root.name = "ForestRecallVFX"
	_forest_recall_root.position = sprite.position
	_forest_recall_root.z_index = sprite.z_index - 1
	add_child(_forest_recall_root)

	var aura: Sprite2D = _make_recall_glow()
	var rune: Node2D = _make_recall_rune()
	_forest_recall_root.add_child(aura)
	_forest_recall_root.add_child(rune)

	aura.modulate = Color(1.0, 1.0, 1.0, 0.2)
	rune.modulate = Color(0.9, 1.0, 0.92, 0.0)
	rune.scale = Vector2(0.72, 0.42)

	# --- Apply white + top-down fade shader ---
	_forest_recall_original_material = sprite.material
	var shader: Shader = Shader.new()
	shader.code = """shader_type canvas_item;
uniform float white_mix : hint_range(0.0, 1.0) = 0.0;
uniform float fade_cutoff : hint_range(0.0, 1.0) = 0.0;
uniform float fade_softness : hint_range(0.01, 0.5) = 0.15;
uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float blur = blur_strength * 0.06;
	vec4 tex = vec4(0.0);
	float total_weight = 0.0;
	const int SAMPLES = 9;
	for (int i = 0; i < SAMPLES; i++) {
		float offset = (float(i) - float(SAMPLES - 1) * 0.5) / (float(SAMPLES - 1) * 0.5);
		float weight = 1.0 - abs(offset) * 0.6;
		vec2 uv_off = UV + vec2(0.0, offset * blur);
		tex += texture(TEXTURE, uv_off) * weight;
		total_weight += weight;
	}
	tex /= total_weight;
	vec3 col = mix(tex.rgb, vec3(1.0), white_mix);
	float fade = smoothstep(fade_cutoff - fade_softness, fade_cutoff, UV.y);
	COLOR = vec4(col, tex.a * fade);
}"""
	_forest_recall_shader = ShaderMaterial.new()
	_forest_recall_shader.shader = shader
	_forest_recall_shader.set_shader_parameter("white_mix", 0.0)
	_forest_recall_shader.set_shader_parameter("fade_cutoff", 0.0)
	_forest_recall_shader.set_shader_parameter("blur_strength", 0.0)
	sprite.material = _forest_recall_shader

	# --- Phase 1: Recall Mark (0s โ’ 0.3s) ---
	# Rune fades in + aura scales up together
	_forest_recall_tween = create_tween()
	_forest_recall_tween.chain().tween_property(rune, "modulate:a", 0.85, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.parallel().tween_property(aura, "scale", Vector2(2.2, 1.5), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# --- Phase 2: Energy Pulse (0.3s โ’ 0.8s) ---
	# Sequential scale bounces โ€” each waits for the previous to finish
	_forest_recall_tween.chain().tween_property(sprite, "scale", _forest_recall_original_sprite_scale * 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.chain().tween_property(sprite, "scale", _forest_recall_original_sprite_scale * 0.95, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_forest_recall_tween.chain().tween_property(sprite, "scale", _forest_recall_original_sprite_scale * 1.15, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Aura + rune breathe during the pulse (runs parallel with last bounce)
	_forest_recall_tween.parallel().tween_property(aura, "modulate:a", 0.32, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_forest_recall_tween.parallel().tween_property(rune, "scale", Vector2(0.95, 0.54), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# --- Phase 3: Turn White (0.8s โ’ 1.05s) ---
	# Sprite transitions to full white silhouette
	_forest_recall_tween.chain().tween_method(func(v: float): _forest_recall_shader.set_shader_parameter("white_mix", v), 0.0, 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_forest_recall_tween.parallel().tween_property(aura, "modulate:a", 0.5, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# --- Phase 4: Shrink Small (1.05s โ’ 1.25s) ---
	# Gather energy โ€” compress into tiny form
	_forest_recall_tween.chain().tween_property(sprite, "scale", _forest_recall_original_sprite_scale * 0.3, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(aura, "scale", Vector2(0.8, 0.6), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(rune, "scale", Vector2(0.4, 0.22), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# --- Phase 5: Expand + Stretch Tall + Aura Burst (1.25s โ’ 1.75s) ---
	# Explosive expansion โ€” stretch tall and launch upward + aura ring burst
	_forest_recall_tween.chain().tween_callback(func():
		_spawn_aura_burst()
		_spawn_forest_recall_particles()
	)
	_forest_recall_tween.chain().tween_property(sprite, "scale", Vector2(_forest_recall_original_sprite_scale.x * 0.6, _forest_recall_original_sprite_scale.y * 2.2), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.parallel().tween_property(sprite, "position:y", _forest_recall_original_sprite_pos.y - 120.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Motion blur kicks in during stretch
	_forest_recall_tween.parallel().tween_method(func(v: float): _forest_recall_shader.set_shader_parameter("blur_strength", v), 0.0, 0.7, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Top-down fade begins here โ€” head starts dissolving as body stretches
	_forest_recall_tween.parallel().tween_method(func(v: float): _forest_recall_shader.set_shader_parameter("fade_cutoff", v), 0.0, 0.35, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(aura, "scale", Vector2(3.5, 3.0), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.parallel().tween_property(aura, "modulate:a", 0.6, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.parallel().tween_property(rune, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.parallel().tween_property(rune, "scale", Vector2(1.4, 0.8), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# --- Phase 6: Continue Fade + Dissolve (1.75s โ’ 2.25s) ---
	# Fade sweeps down through body to feet while stretching thinner upward
	_forest_recall_tween.chain().tween_property(sprite, "position:y", _forest_recall_original_sprite_pos.y - 220.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(sprite, "scale", Vector2(_forest_recall_original_sprite_scale.x * 0.15, _forest_recall_original_sprite_scale.y * 2.8), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Blur intensifies as body stretches thinner
	_forest_recall_tween.parallel().tween_method(func(v: float): _forest_recall_shader.set_shader_parameter("blur_strength", v), 0.7, 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Fade continues sweeping down from where Phase 5 left off โ’ all the way past feet
	_forest_recall_tween.parallel().tween_method(func(v: float): _forest_recall_shader.set_shader_parameter("fade_cutoff", v), 0.35, 1.15, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(aura, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(rune, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_forest_recall_tween.parallel().tween_property(rune, "scale", Vector2(1.8, 1.0), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_forest_recall_tween.chain().tween_callback(_finish_forest_recall)


func _finish_forest_recall() -> void:
	# Guard: only finish if hero is dead AND recall shader still exists
	# When a new recall starts, _clear_forest_recall_vfx() increments session_id
	# and clears shader, so this check will fail for old tween callbacks
	if not is_dead or _forest_recall_shader == null:
		return

	if is_instance_valid(sprite):
		sprite.position = _forest_recall_original_sprite_pos
		sprite.scale = _forest_recall_original_sprite_scale
		sprite.modulate = _forest_recall_original_sprite_modulate
		sprite.material = _forest_recall_original_material
		sprite.visible = false

	_forest_recall_shader = null
	_forest_recall_original_material = null
	global_position = base_position
	_clear_forest_recall_vfx()


func _clear_forest_recall_vfx() -> void:
	if _forest_recall_tween and _forest_recall_tween.is_valid():
		_forest_recall_tween.kill()
	_forest_recall_tween = null

	# Invalidate any pending tween callbacks by incrementing session ID
	_forest_recall_session_id += 1

	if not is_dead and _forest_recall_shader != null and is_instance_valid(sprite):
		sprite.scale = _forest_recall_original_sprite_scale
		sprite.position = _forest_recall_original_sprite_pos
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.visible = true
		sprite.material = _forest_recall_original_material

	if is_instance_valid(_forest_recall_root):
		_forest_recall_root.queue_free()
	_forest_recall_root = null
	_forest_recall_shader = null
	_forest_recall_original_material = null


func _set_recall_sprite_alpha(alpha: float) -> void:
	if not is_instance_valid(sprite):
		return
	var col: Color = sprite.modulate
	col.a = alpha
	sprite.modulate = col


func _make_recall_glow() -> Sprite2D:
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.width = 192
	tex.height = 192
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)

	var gradient: Gradient = Gradient.new()
	gradient.colors = [
		Color(1.0, 1.0, 1.0, 0.85),
		Color(0.93, 1.0, 0.95, 0.28),
		Color(0.9, 1.0, 0.92, 0.0)
	]
	gradient.offsets = [0.0, 0.4, 1.0]
	tex.gradient = gradient

	var glow: Sprite2D = Sprite2D.new()
	glow.texture = tex
	glow.position = Vector2(0.0, 6.0)
	glow.scale = Vector2(1.8, 1.2)
	glow.z_index = -1
	return glow


func _make_recall_rune() -> Node2D:
	var rune: Node2D = Node2D.new()
	rune.position = Vector2(0.0, 26.0)

	rune.add_child(_make_circle_line(48.0, 3.0, Color(0.88, 1.0, 0.9, 0.95)))
	rune.add_child(_make_circle_line(30.0, 2.0, Color(1.0, 1.0, 1.0, 0.9)))

	for i in range(6):
		var angle: float = (TAU / 6.0) * float(i)
		var marker: Line2D = Line2D.new()
		marker.width = 2.0
		marker.default_color = Color(0.88, 1.0, 0.9, 0.8)
		var inner: Vector2 = Vector2(cos(angle), sin(angle)) * 14.0
		var outer: Vector2 = Vector2(cos(angle), sin(angle)) * 44.0
		marker.points = PackedVector2Array([inner, outer])
		rune.add_child(marker)

	var core: Sprite2D = Sprite2D.new()
	core.texture = _make_soft_disc_texture(64, Color(1.0, 1.0, 1.0, 0.22), Color(1.0, 1.0, 1.0, 0.0))
	core.scale = Vector2(0.75, 0.3)
	rune.add_child(core)

	return rune


func _make_circle_line(radius: float, width: float, color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.closed = true
	line.antialiased = true

	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 32
	for i in range(segments):
		var angle: float = (TAU / float(segments)) * float(i)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	line.points = points
	return line


func _make_soft_disc_texture(size: int, center_color: Color, edge_color: Color) -> GradientTexture2D:
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.width = size
	tex.height = size
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)

	var gradient: Gradient = Gradient.new()
	gradient.colors = [center_color, edge_color]
	gradient.offsets = [0.0, 1.0]
	tex.gradient = gradient
	return tex


func _spawn_aura_burst() -> void:
	# Gentle mourning motes โ€” small white dots that linger at the death spot
	# for ~3 seconds, then slowly fade. Persists independently of recall VFX.
	var mote_container: Node2D = Node2D.new()
	mote_container.name = "MourningMotes"
	mote_container.global_position = global_position + sprite.position
	mote_container.z_index = sprite.z_index + 1
	get_parent().add_child(mote_container)

	var mote_count: int = 18
	var body_center: Vector2 = Vector2(0.0, -20.0)
	var last_total_dur: float = 0.0

	for i in range(mote_count):
		var mote: Sprite2D = Sprite2D.new()
		var mote_size: float = randf_range(3.0, 7.0)
		var alpha: float = randf_range(0.45, 0.8)
		mote.texture = _make_soft_disc_texture(
			16,
			Color(1.0, 1.0, 1.0, alpha),
			Color(1.0, 1.0, 0.97, 0.0)
		)
		mote.scale = Vector2.ONE * (mote_size / 16.0)

		# Scatter around the hero body area
		var spawn_angle: float = TAU * randf()
		var spawn_dist: float = randf_range(8.0, 50.0)
		mote.position = body_center + Vector2(cos(spawn_angle), sin(spawn_angle) * 0.6) * spawn_dist
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote_container.add_child(mote)

		# Each mote: fade in โ’ float gently โ’ fade out
		var fade_in_dur: float = randf_range(0.2, 0.5)
		var linger_dur: float = randf_range(1.5, 2.5)
		var fade_out_dur: float = randf_range(0.6, 1.2)
		var appear_delay: float = randf_range(0.0, 0.4)

		# Gentle drift direction โ€” mostly upward with slight horizontal sway
		var drift: Vector2 = Vector2(randf_range(-15.0, 15.0), randf_range(-25.0, -55.0))
		var total_dur: float = fade_in_dur + linger_dur + fade_out_dur
		if appear_delay + total_dur > last_total_dur:
			last_total_dur = appear_delay + total_dur

		var tw: Tween = mote_container.create_tween()
		# Slow gentle drift over the full lifetime
		tw.tween_property(mote, "position", mote.position + drift, total_dur).set_delay(appear_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Fade in
		tw.parallel().tween_property(mote, "modulate:a", 1.0, fade_in_dur).set_delay(appear_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Hold visible, then fade out
		tw.parallel().tween_property(mote, "modulate:a", 0.0, fade_out_dur).set_delay(appear_delay + fade_in_dur + linger_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# Slight scale pulse โ€” breathe in and out gently
		var pulse_scale: Vector2 = mote.scale * randf_range(1.2, 1.6)
		tw.parallel().tween_property(mote, "scale", pulse_scale, total_dur * 0.5).set_delay(appear_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.chain().tween_property(mote, "scale", mote.scale * 0.5, total_dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Self-destruct the container after all motes are done
	var cleanup_tw: Tween = mote_container.create_tween()
	cleanup_tw.tween_callback(mote_container.queue_free).set_delay(last_total_dur + 0.1)


func _spawn_forest_recall_particles() -> void:
	if not is_instance_valid(_forest_recall_root):
		return

	var burst_origin: Vector2 = Vector2(0.0, -14.0)
	var particle_count: int = 16

	for i in range(particle_count):
		var particle: Sprite2D = Sprite2D.new()
		particle.texture = _make_soft_disc_texture(
			24,
			Color(1.0, 1.0, 1.0, 0.95),
			Color(0.88, 1.0, 0.9, 0.0)
		)
		var particle_size: float = randf_range(5.0, 9.5)
		particle.scale = Vector2.ONE * (particle_size / 24.0)
		particle.position = burst_origin + Vector2(randf_range(-12.0, 12.0), randf_range(-6.0, 18.0))
		particle.z_index = sprite.z_index + 1
		_forest_recall_root.add_child(particle)

		var spread_t: float = float(i) / max(1.0, float(particle_count - 1))
		var spread_angle: float = lerpf(-0.9, 0.9, spread_t)
		var end_pos: Vector2 = particle.position + Vector2(randf_range(-18.0, 18.0), -randf_range(70.0, 155.0)).rotated(spread_angle * 0.15)
		var duration: float = randf_range(0.18, 0.34)

		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(particle, "position", end_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(particle, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(particle, "modulate:a", 0.0, duration * 0.72).set_delay(duration * 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(particle.queue_free)
# Check if a specific skill slot is unlocked/available
func has_active_skill(index: int) -> bool:
	if index == 0:
		return true
	return false

# Called by the UI when the user taps the Hero portrait
func use_active_skill() -> bool:
	if current_cooldown <= 0 and not is_skill_active:
		is_skill_active = true
		skill_activated.emit()
		_play_skill_vfx()
		return true
	return false

func use_active_skill_2() -> bool:
	if current_cooldown_2 <= 0 and not is_skill_active_2:
		is_skill_active_2 = true
		skill_activated_2.emit()
		_play_skill_vfx()
		return true
	return false


func get_hero_id() -> String:
	if scene_file_path:
		var file_name: String = scene_file_path.get_file().get_basename().to_lower()
		file_name = file_name.trim_prefix("hero_")
		if not file_name.is_empty():
			return file_name
	var node_name: String = String(name).to_lower().replace(" ", "_")
	return node_name.trim_prefix("hero_")


func set_card_modifier_state(modifier_state) -> void:
	_card_modifier_state = modifier_state
	if current_cooldown > 0.0:
		current_cooldown = min(current_cooldown, _get_effective_skill_cooldown())
		cooldown_updated.emit(current_cooldown, _get_effective_skill_cooldown())
	if current_cooldown_2 > 0.0:
		current_cooldown_2 = min(current_cooldown_2, _get_effective_skill_cooldown_2())
		cooldown_updated_2.emit(current_cooldown_2, _get_effective_skill_cooldown_2())


func _get_card_manager() -> Node:
	return get_node_or_null("/root/CardManager")


func _get_card_modifier_state():
	if _card_modifier_state != null:
		return _card_modifier_state
	var card_manager: Node = _get_card_manager()
	if card_manager != null and card_manager.has_method("get_modifier_state_for_hero_id"):
		_card_modifier_state = card_manager.get_modifier_state_for_hero_id(get_hero_id())
	return _card_modifier_state


func _get_effective_attack_speed() -> float:
	var effective_attack_speed: float = attack_speed
	var modifier_state = _get_card_modifier_state()
	if modifier_state != null:
		effective_attack_speed *= modifier_state.get_attack_speed_multiplier()
	return effective_attack_speed


func _get_effective_skill_cooldown() -> float:
	var total_reduction_pct: float = cooldown_reduction * 100.0
	var modifier_state = _get_card_modifier_state()
	if modifier_state != null:
		total_reduction_pct += float(modifier_state.cooldown_reduction_pct)
	var reduction_ratio: float = clampf(total_reduction_pct * 0.01, 0.0, 0.9)
	return maxf(0.1, max_cooldown * (1.0 - reduction_ratio))

func _get_effective_skill_cooldown_2() -> float:
	var total_reduction_pct: float = cooldown_reduction * 100.0
	var modifier_state = _get_card_modifier_state()
	if modifier_state != null:
		total_reduction_pct += float(modifier_state.cooldown_reduction_pct)
	var reduction_ratio: float = clampf(total_reduction_pct * 0.01, 0.0, 0.9)
	return maxf(0.1, max_cooldown_2 * (1.0 - reduction_ratio))


# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ Cookie Run Kingdom-style Skill Activation VFX เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
func _play_skill_vfx() -> void:
	if _skill_vfx_tween and _skill_vfx_tween.is_valid():
		_skill_vfx_tween.kill()

	var original_scale: Vector2 = sprite.scale
	var pop_scale: Vector2 = original_scale * 1.3

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 1. Golden Outline Shader เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย sprite เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	_old_sprite_material = sprite.material
	var outline_mat: ShaderMaterial = ShaderMaterial.new()
	outline_mat.shader = _outline_shader
	outline_mat.set_shader_parameter("outline_color", skill_color)
	outline_mat.set_shader_parameter("outline_width", 4.0)
	outline_mat.set_shader_parameter("outline_alpha", 1.0)
	sprite.material = outline_mat

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 2. Colored Aura Circle เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	var aura_node: Node2D = Node2D.new()
	aura_node.position = sprite.position
	aura_node.z_index = sprite.z_index - 1
	add_child(aura_node)

	var gradient_tex: GradientTexture2D = GradientTexture2D.new()
	gradient_tex.width = 128
	gradient_tex.height = 128
	gradient_tex.fill = GradientTexture2D.FILL_RADIAL
	gradient_tex.fill_from = Vector2(0.5, 0.5)
	gradient_tex.fill_to = Vector2(0.5, 0.0)
	var grad: Gradient = Gradient.new()
	var aura_col: Color = skill_color
	aura_col.a = 0.7
	var aura_col_transparent: Color = skill_color
	aura_col_transparent.a = 0.0
	grad.colors = [aura_col, aura_col_transparent]
	grad.offsets = [0.0, 1.0]
	gradient_tex.gradient = grad

	var aura_sprite: Sprite2D = Sprite2D.new()
	aura_sprite.texture = gradient_tex
	aura_sprite.scale = Vector2(0.5, 0.5)
	aura_node.add_child(aura_sprite)

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 3. Dual-Layer Radial Particle Burst เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	# Layer 1: เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ข skill_color เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย Hero
	var big_count: int = randi_range(10, 14)
	var sc_bright: Color = skill_color
	sc_bright.a = 1.0
	var sc_mid: Color = skill_color
	sc_mid.a = 0.7

	for i in big_count:
		var p_size: float = randf_range(5.0, 10.0)
		var p_tex: GradientTexture2D = GradientTexture2D.new()
		p_tex.width = 32
		p_tex.height = 32
		p_tex.fill = GradientTexture2D.FILL_RADIAL
		p_tex.fill_from = Vector2(0.5, 0.5)
		p_tex.fill_to = Vector2(0.5, 0.0)
		var p_grad: Gradient = Gradient.new()
		# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย เน€เธยเธขยเนโฌย เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธยเธขยเนโฌย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย
		p_grad.colors = [Color(1.0, 1.0, 1.0, 1.0), sc_bright, Color(sc_mid.r, sc_mid.g, sc_mid.b, 0.0)]
		p_grad.offsets = [0.0, 0.35, 1.0]
		p_tex.gradient = p_grad

		var particle: Sprite2D = Sprite2D.new()
		particle.texture = p_tex
		particle.scale = Vector2(p_size / 32.0, p_size / 32.0)
		particle.position = sprite.position
		particle.z_index = sprite.z_index + 1
		add_child(particle)

		var angle: float = (TAU / big_count) * i + randf_range(-0.3, 0.3)
		var dist: float = randf_range(80.0, 160.0)
		var end_pos: Vector2 = particle.position + Vector2(cos(angle), sin(angle)) * dist
		var duration: float = randf_range(0.35, 0.6)
		var delay: float = randf_range(0.0, 0.06)

		var p_tw: Tween = create_tween()
		p_tw.tween_property(particle, "position", end_pos, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		p_tw.parallel().tween_property(particle, "scale", Vector2(0.0, 0.0), duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay)
		p_tw.parallel().tween_property(particle, "modulate", Color(1, 1, 1, 0), duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(delay + duration * 0.4)
		p_tw.tween_callback(particle.queue_free)

	# Layer 2: เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย Glitters (The "Golden Touch")
	var glitter_count: int = randi_range(12, 16)
	for i in glitter_count:
		var g_size: float = randf_range(2.0, 4.5)
		var g_tex: GradientTexture2D = GradientTexture2D.new()
		g_tex.width = 16
		g_tex.height = 16
		g_tex.fill = GradientTexture2D.FILL_RADIAL
		g_tex.fill_from = Vector2(0.5, 0.5)
		g_tex.fill_to = Vector2(0.5, 0.0)
		var g_grad: Gradient = Gradient.new()
		# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌย เน€เธยเธขยเนโฌย เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย เน€เธยเธขยเนโฌย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย
		g_grad.colors = [Color(1.0, 1.0, 0.85, 1.0), Color(1.0, 0.85, 0.25, 0.9), Color(1.0, 0.7, 0.1, 0.0)]
		g_grad.offsets = [0.0, 0.4, 1.0]
		g_tex.gradient = g_grad

		var glitter: Sprite2D = Sprite2D.new()
		glitter.texture = g_tex
		glitter.scale = Vector2(g_size / 16.0, g_size / 16.0)
		glitter.position = sprite.position
		glitter.z_index = sprite.z_index + 2
		glitter.rotation = randf() * TAU
		add_child(glitter)

		var g_angle: float = randf() * TAU
		var g_dist: float = randf_range(50.0, 130.0)
		var g_end: Vector2 = glitter.position + Vector2(cos(g_angle), sin(g_angle)) * g_dist
		var g_dur: float = randf_range(0.25, 0.5)
		var g_delay: float = randf_range(0.02, 0.12)

		var g_tw: Tween = create_tween()
		g_tw.tween_property(glitter, "position", g_end, g_dur) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(g_delay)
		g_tw.parallel().tween_property(glitter, "rotation", glitter.rotation + randf_range(1.5, 4.0), g_dur) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(g_delay)
		g_tw.parallel().tween_property(glitter, "scale", Vector2(0.0, 0.0), g_dur) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(g_delay)
		g_tw.parallel().tween_property(glitter, "modulate", Color(1, 1, 1, 0), g_dur * 0.8) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(g_delay + g_dur * 0.5)
		g_tw.tween_callback(glitter.queue_free)

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 4. Tween Sequence เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	_skill_vfx_tween = create_tween()

	# Scale hero UP (pop effect)
	_skill_vfx_tween.tween_property(sprite, "scale", pop_scale, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Aura expands
	_skill_vfx_tween.parallel().tween_property(aura_sprite, "scale", Vector2(3.0, 3.0), 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Aura fades out
	_skill_vfx_tween.parallel().tween_property(aura_sprite, "modulate", Color(1, 1, 1, 0), 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Golden outline fades out (tween shader uniform)
	_skill_vfx_tween.parallel().tween_method(
		func(val: float): outline_mat.set_shader_parameter("outline_alpha", val),
		1.0, 0.0, 0.5
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.15)

	# Hold at peak briefly, then scale back down
	_skill_vfx_tween.tween_property(sprite, "scale", original_scale, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.12)

	# Clean up: remove shader + temp nodes
	_skill_vfx_tween.tween_callback(func():
		sprite.material = _old_sprite_material
		_old_sprite_material = null
		aura_node.queue_free()
	)

# Called by child scripts when the skill animation/sequence completely finishes
func start_cooldown() -> void:
	is_skill_active = false
	current_cooldown = _get_effective_skill_cooldown()

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	# คูณ heal_power (1.0 = ปกติ, 1.5 = ฮีล +50%)
	var actual_heal: int = max(1, int(float(amount) * heal_power))
	current_hp = mini(current_hp + actual_heal, max_hp)
	hp_updated.emit(current_hp, max_hp)
	_spawn_heal_number(actual_heal)


func apply_blood_shield(amount: int, duration: float) -> void:
	if is_dead or amount <= 0 or duration <= 0.0:
		return
	_blood_shield_hp = maxi(_blood_shield_hp, amount)
	_blood_shield_duration_left = duration


func get_blood_shield_hp() -> int:
	return _blood_shield_hp


func _tick_blood_shield(delta: float) -> void:
	if _blood_shield_duration_left <= 0.0:
		return
	_blood_shield_duration_left -= delta
	if _blood_shield_duration_left <= 0.0:
		_blood_shield_duration_left = 0.0
		_blood_shield_hp = 0


func _spawn_heal_number(amount: int) -> void:
	var damage_num_scene = preload("res://shared/ui/scenes/damage_number.tscn")
	if damage_num_scene:
		var heal_num = damage_num_scene.instantiate()
		heal_num.amount = amount
		heal_num.is_crit = false
		heal_num.is_heal = true
		heal_num.global_position = global_position
		get_tree().current_scene.add_child(heal_num)


# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ Healing Aura (Fountain Regen VFX) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
var _healing_aura_node: Node2D = null
var _healing_aura_pulse_tween: Tween = null
var _healing_aura_particles: Array[Sprite2D] = []
var _healing_aura_time: float = 0.0

func show_healing_aura() -> void:
	if _healing_aura_node != null:
		return  # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ข aura เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย

	_healing_aura_node = Node2D.new()
	_healing_aura_node.position = sprite.position + Vector2(0, 10)
	_healing_aura_node.z_index = 200        # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย Sprite เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย
	_healing_aura_node.z_as_relative = false # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย z_index เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€“เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย parent
	add_child(_healing_aura_node)

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 1. Green Radial Glow (เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธย) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	var glow_tex: GradientTexture2D = GradientTexture2D.new()
	glow_tex.width = 128
	glow_tex.height = 128
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(0.5, 0.0)
	var grad: Gradient = Gradient.new()
	grad.colors = [
		Color(0.3, 1.0, 0.4, 0.45),   # เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย
		Color(0.2, 0.9, 0.3, 0.25),   # เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขย
		Color(0.1, 0.8, 0.2, 0.0),    # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย
	]
	grad.offsets = [0.0, 0.5, 1.0]
	glow_tex.gradient = grad

	var glow_sprite: Sprite2D = Sprite2D.new()
	glow_sprite.name = "GlowSprite"
	glow_sprite.texture = glow_tex
	glow_sprite.scale = Vector2(1.8, 1.2)  # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย
	_healing_aura_node.add_child(glow_sprite)

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 2. Pulsing Animation (เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ เน€เธโฌเน€เธยเธขย) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	_start_aura_pulse(glow_sprite)

	# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ 3. Floating Particles (เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€“เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
	_healing_aura_time = 0.0
	set_meta("_heal_aura_active", true)


func hide_healing_aura() -> void:
	set_meta("_heal_aura_active", false)

	if _healing_aura_pulse_tween and _healing_aura_pulse_tween.is_valid():
		_healing_aura_pulse_tween.kill()
		_healing_aura_pulse_tween = null

	if _healing_aura_node != null:
		# Fade out เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธย เน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ข
		var fade_tw: Tween = create_tween()
		var aura_ref = _healing_aura_node
		fade_tw.tween_property(aura_ref, "modulate:a", 0.0, 0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fade_tw.tween_callback(aura_ref.queue_free)
		_healing_aura_node = null

	_healing_aura_particles.clear()


func _start_aura_pulse(glow: Sprite2D) -> void:
	if _healing_aura_pulse_tween and _healing_aura_pulse_tween.is_valid():
		_healing_aura_pulse_tween.kill()

	var base_scale: Vector2 = glow.scale
	var pulse_scale: Vector2 = base_scale * 1.15

	_healing_aura_pulse_tween = create_tween()
	_healing_aura_pulse_tween.set_loops()  # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌย
	_healing_aura_pulse_tween.tween_property(glow, "scale", pulse_scale, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_healing_aura_pulse_tween.tween_property(glow, "scale", base_scale, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process_healing_aura(delta: float) -> void:
	# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€“เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย Hero
	if _healing_aura_node == null:
		return

	_healing_aura_time += delta
	# spawn เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย ~0.2 เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ข
	if _healing_aura_time >= 0.2:
		_healing_aura_time -= 0.2
		_spawn_aura_particle()


func _spawn_aura_particle() -> void:
	if _healing_aura_node == null or not is_instance_valid(_healing_aura_node):
		return

	var p_tex: GradientTexture2D = GradientTexture2D.new()
	p_tex.width = 16
	p_tex.height = 16
	p_tex.fill = GradientTexture2D.FILL_RADIAL
	p_tex.fill_from = Vector2(0.5, 0.5)
	p_tex.fill_to = Vector2(0.5, 0.0)
	var p_grad: Gradient = Gradient.new()
	p_grad.colors = [
		Color(0.6, 1.0, 0.7, 0.9),   # เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย
		Color(0.3, 1.0, 0.4, 0.5),   # เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌย
		Color(0.2, 0.9, 0.3, 0.0),   # เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย
	]
	p_grad.offsets = [0.0, 0.4, 1.0]
	p_tex.gradient = p_grad

	var particle: Sprite2D = Sprite2D.new()
	particle.texture = p_tex
	var p_size: float = randf_range(2.0, 4.5)
	particle.scale = Vector2(p_size / 16.0, p_size / 16.0)

	# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเธขย เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย Hero
	var offset_x: float = randf_range(-35.0, 35.0)
	var offset_y: float = randf_range(-5.0, 15.0)
	particle.position = Vector2(offset_x, offset_y)
	particle.z_index = 0  # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌย z_index 200 เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย _healing_aura_node เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย
	_healing_aura_node.add_child(particle)

	# เน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€“เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย fade out
	var end_y: float = particle.position.y - randf_range(40.0, 70.0)
	var drift_x: float = randf_range(-10.0, 10.0)
	var dur: float = randf_range(0.6, 1.0)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(particle, "position:y", end_y, dur) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(particle, "position:x", particle.position.x + drift_x, dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(particle, "scale", Vector2(0.0, 0.0), dur * 0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(dur * 0.6)
	tw.tween_property(particle, "modulate:a", 0.0, dur * 0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(dur * 0.7)
	tw.chain().tween_callback(particle.queue_free)


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var damage_num_scene = preload("res://shared/ui/scenes/damage_number.tscn")
	if damage_num_scene:
		var damage_num = damage_num_scene.instantiate()
		damage_num.amount = amount
		damage_num.is_crit = is_crit
		damage_num.is_hero_damage = true
		damage_num.global_position = global_position
		get_tree().current_scene.add_child(damage_num)


# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ Ground Mode Functions เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
func toggle_ground_mode(slot_index: int = 0) -> void:
	set_ground_mode(!is_ground_mode, slot_index)

func set_ground_mode(enabled: bool, slot_index: int = 0) -> void:
	if is_ground_mode == enabled:
		return
	is_ground_mode = enabled
	
	if is_ground_mode:
		z_index = 100 + slot_index # เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ขเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธย index เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย (100, 101, 102)
	else:
		z_index = 0
		
	ground_mode_changed.emit(is_ground_mode)
	if not is_ground_mode:
		_warp_to_base()

func _warp_to_base() -> void:
	ground_is_attacking = false
	ground_target = null
	velocity = Vector2.ZERO
	# เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€ข
	global_position = base_position
	sprite.play("idle")


# เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ Shared Patrol Helpers (เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย Hero) เน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธเน€เธยเนโฌยเนยเธ
# เน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ Hero เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเนโฌเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€”เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขย
func is_outside_patrol_range() -> bool:
	return global_position.distance_to(base_position) > max_patrol_range

# เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเนโฌยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขย เน€เธยเนยเธเนโฌย เน€เธโฌเน€เธยเนยเธเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย run_ground เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเน€เธโ€ข, เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขย idle
func move_back_to_base(speed: float) -> void:
	if global_position.distance_to(base_position) <= 12.0:
		# เน€เธโฌเน€เธยเนโฌโ€เน€เธโฌเน€เธยเน€เธโ€“เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€เน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธโ€ฆเน€เธโฌเน€เธยเธขยเน€เธโฌเน€เธยเน€เธย
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
			sprite.play("idle")
		return
	var dir = (base_position - global_position).normalized()
	sprite.flip_h = dir.x < 0
	if sprite.sprite_frames.has_animation("run_ground") and sprite.animation != "run_ground":
		sprite.play("run_ground")
	elif not sprite.sprite_frames.has_animation("run_ground") and sprite.animation != "idle":
		sprite.play("idle")
	velocity = dir * speed
	move_and_slide()


# ─── Progression (Phase 5 & 6) ─────────────────────────────────────────
# PASSIVE_SCHEDULE: Map level -> card_id per hero_id
const PASSIVE_SCHEDULE := {
	"pig": {
		2: "pig_hemobloom_lv1",
		4: "pig_hemobloom_lv2",
		6: "pig_hemobloom_lv3"
	},
	"rabbit": {
		2: "rabbit_black_bullet_passive_lv1",
		4: "rabbit_black_bullet_passive_lv2",
		6: "rabbit_black_bullet_passive_lv3"
	},
	"lion": {
		2: "lion_passive_lv1",
		4: "lion_passive_lv2"
	}
}

func gain_xp(amount: int) -> void:
	if current_level >= max_level:
		return
	current_xp += amount
	check_level_up()

func _get_xp_threshold_for_level(level: int) -> int:
	if level >= 1 and level - 1 < XP_THRESHOLDS.size():
		return XP_THRESHOLDS[level - 1]
	return -1


func check_level_up() -> void:
	while current_level < max_level:
		var threshold := _get_xp_threshold_for_level(current_level)
		if threshold < 0 or current_xp < threshold:
			break
		current_level += 1
		leveled_up.emit(current_level)


func force_level_up() -> void:
	if current_level >= max_level:
		return
	
	var range_xp := 0
	var threshold := _get_xp_threshold_for_level(current_level)
	if threshold > 0:
		var prev_threshold := 0
		if current_level > 1:
			prev_threshold = _get_xp_threshold_for_level(current_level - 1)
		range_xp = threshold - prev_threshold
	
	if range_xp > 0:
		gain_xp(range_xp)
	else:
		# Fallback just in case thresholds are misconfigured
		current_level += 1
		leveled_up.emit(current_level)


func _on_leveled_up(new_level: int) -> void:
	_spawn_golden_aura_effect()

	var hid := ""
	if has_method("get_hero_id"):
		hid = String(get_hero_id())
	else:
		hid = name.to_lower()

	if PASSIVE_SCHEDULE.has(hid):
		var hero_passives: Dictionary = PASSIVE_SCHEDULE[hid]
		if hero_passives.has(new_level):
			var card_id: String = hero_passives[new_level]
			var cm = _get_card_manager()
			if cm and cm.has_method("force_apply_card"):
				cm.force_apply_card(card_id, self)


func _clear_level_up_vfx() -> void:
	if _level_up_vfx_tween and _level_up_vfx_tween.is_valid():
		_level_up_vfx_tween.kill()
	_level_up_vfx_tween = null

	if _level_up_vfx_root != null and is_instance_valid(sprite):
		sprite.material = _level_up_original_material

	_level_up_original_material = null

	if _level_up_vfx_root != null:
		_level_up_vfx_root.queue_free()
		_level_up_vfx_root = null


func _spawn_golden_aura_effect() -> void:
	if not is_inside_tree() or not is_instance_valid(sprite):
		return
	_clear_level_up_vfx()
	var original_scale: Vector2 = sprite.scale
	_level_up_original_material = sprite.material

	# ── VFX Root: ใช้ z_index สูงเลย เพื่อให้อยู่เหนือทุกอย่างรวม TileMap ──
	_level_up_vfx_root = Node2D.new()
	_level_up_vfx_root.position = sprite.position
	_level_up_vfx_root.z_index = 10
	add_child(_level_up_vfx_root)

	# ── Golden Outline Shader บน Sprite ──
	var golden_mat := ShaderMaterial.new()
	golden_mat.shader = _outline_shader
	golden_mat.set_shader_parameter("outline_color", Color(1.0, 0.85, 0.1, 1.0))
	golden_mat.set_shader_parameter("outline_width", 5.0)
	golden_mat.set_shader_parameter("outline_alpha", 1.0)
	sprite.material = golden_mat

	# ── Golden Aura Glow (วงกลมสีทอง) ──
	var aura_tex := GradientTexture2D.new()
	aura_tex.width = 128
	aura_tex.height = 128
	aura_tex.fill = GradientTexture2D.FILL_RADIAL
	aura_tex.fill_from = Vector2(0.5, 0.5)
	aura_tex.fill_to = Vector2(0.5, 0.0)
	var aura_grad := Gradient.new()
	aura_grad.colors = [Color(1.0, 0.9, 0.2, 0.75), Color(1.0, 0.75, 0.0, 0.0)]
	aura_grad.offsets = [0.0, 1.0]
	aura_tex.gradient = aura_grad
	var aura_sprite := Sprite2D.new()
	aura_sprite.texture = aura_tex
	aura_sprite.scale = Vector2(0.5, 0.5)
	_level_up_vfx_root.add_child(aura_sprite)

	# ── Burst Particles ──
	_spawn_level_up_particles(sprite.position)

	# ── Main Tween — ใช้ TWEEN_PAUSE_PROCESS เพื่อให้เล่นแม้เกม pause ──
	_level_up_vfx_tween = create_tween()
	_level_up_vfx_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Pop scale up
	_level_up_vfx_tween.tween_property(sprite, "scale", original_scale * 1.25, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Aura expand + fade
	_level_up_vfx_tween.parallel().tween_property(aura_sprite, "scale", Vector2(3.5, 3.5), 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_level_up_vfx_tween.parallel().tween_property(aura_sprite, "modulate:a", 0.0, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Golden outline fade
	_level_up_vfx_tween.parallel().tween_method(
		func(v: float): golden_mat.set_shader_parameter("outline_alpha", v),
		1.0, 0.0, 0.55
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.15)
	# Pop scale back
	_level_up_vfx_tween.tween_property(sprite, "scale", original_scale, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.1)
	# Cleanup
	_level_up_vfx_tween.tween_callback(_clear_level_up_vfx)


func _spawn_level_up_particles(center: Vector2) -> void:
	var gold_mid := Color(1.0, 0.65, 0.0, 0.0)

	for i in randi_range(10, 14):
		var p_size := randf_range(6.0, 11.0)
		var p_tex := _make_soft_disc_texture(32, Color(1.0, 1.0, 0.9, 1.0), gold_mid)
		var particle := Sprite2D.new()
		particle.texture = p_tex
		particle.scale = Vector2(p_size / 32.0, p_size / 32.0)
		particle.position = center
		particle.z_index = 11
		add_child(particle)

		var angle := randf() * TAU
		var dist := randf_range(70.0, 140.0)
		var end_pos := center + Vector2(cos(angle), sin(angle)) * dist
		var dur := randf_range(0.35, 0.6)
		var dly := randf_range(0.0, 0.06)
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(particle, "position", end_pos, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(dly)
		tw.parallel().tween_property(particle, "scale", Vector2.ZERO, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(dly)
		tw.parallel().tween_property(particle, "modulate", Color(1, 1, 1, 0), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(dly + dur * 0.4)
		tw.tween_callback(particle.queue_free)

	for i in randi_range(14, 20):
		var g_size := randf_range(2.0, 4.5)
		var g_tex := _make_soft_disc_texture(16, Color(1.0, 1.0, 0.85, 1.0), Color(1.0, 0.7, 0.1, 0.0))
		var glitter := Sprite2D.new()
		glitter.texture = g_tex
		glitter.scale = Vector2(g_size / 16.0, g_size / 16.0)
		glitter.position = center
		glitter.z_index = 12
		glitter.rotation = randf() * TAU
		add_child(glitter)

		var g_angle := randf() * TAU
		var g_dist := randf_range(40.0, 120.0)
		var g_end := center + Vector2(cos(g_angle), sin(g_angle)) * g_dist
		var g_dur := randf_range(0.3, 0.6)
		var g_dly := randf_range(0.0, 0.1)
		var g_tw := create_tween()
		g_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		g_tw.tween_property(glitter, "position", g_end, g_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(g_dly)
		g_tw.parallel().tween_property(glitter, "rotation", glitter.rotation + randf_range(1.5, 4.0), g_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(g_dly)
		g_tw.parallel().tween_property(glitter, "scale", Vector2.ZERO, g_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(g_dly)
		g_tw.parallel().tween_property(glitter, "modulate", Color(1, 1, 1, 0), g_dur * 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(g_dly + g_dur * 0.5)
		g_tw.tween_callback(glitter.queue_free)
