extends Area2D

signal hp_changed(current: int, maximum: int)
signal destroyed

@export var max_hp: int = 500
@export var heal_per_tick: int = 2            # HP เธฎเธตเธฅเธ•เนเธญ tick เธ•เนเธญ Hero (เน€เธฅเนเธ เน เน€เธซเธกเธทเธญเธ Fountain)
@export var heal_tick_interval: float = 0.15  # เธงเธดเธเธฒเธ—เธตเธฃเธฐเธซเธงเนเธฒเธ tick (เนเธซเธฅเธฅเธทเนเธเนเธเธ ROV)
@export var min_hp_percent: float = 0.10      # เธซเนเธฒเธกเธฎเธตเธฅเธ–เนเธฒ Heart HP โค 10%

var current_hp: int

# โ”€โ”€ Fountain Healing State โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€
var _is_healing: bool = false
var _heal_targets: Array[Node] = []  # Hero เธ—เธฑเนเธเธซเธกเธ”เธ—เธตเนเน€เธเนเธฒเธฃเนเธงเธก
var _tick_timer: float = 0.0         # เธเธฑเธเน€เธงเธฅเธฒเธชเธณเธซเธฃเธฑเธ tick เธ–เธฑเธ”เนเธ


func _ready() -> void:
	current_hp = max_hp
	add_to_group("crystal_heart")
	hp_changed.emit(current_hp, max_hp)


func _process(delta: float) -> void:
	if not _is_healing:
		return

	# โ”€โ”€ Safety Limit: Heart HP เธ•เนเธญเธเนเธกเนเธ•เนเธณเธเธงเนเธฒ 10% โ”€โ”€
	var minimum_heart_hp: int = int(max_hp * min_hp_percent)
	if current_hp <= minimum_heart_hp:
		stop_healing()
		return

	# โ”€โ”€ เธเธฑเธเน€เธงเธฅเธฒ tick โ”€โ”€
	_tick_timer += delta
	if _tick_timer < heal_tick_interval:
		return
	_tick_timer -= heal_tick_interval

	# โ”€โ”€ Fountain Heal: เธฎเธตเธฅเธ—เธธเธเธเธเธเธฃเนเธญเธกเธเธฑเธ โ”€โ”€
	var healed_anyone: bool = false

	for hero in _heal_targets:

		if not _is_valid_heal_target(hero):
			continue

		var missing_hp: int = hero.max_hp - hero.current_hp
		var actual_heal: int = mini(heal_per_tick, missing_hp)

		if actual_heal <= 0:
			continue

		healed_anyone = true

		# Hero เน€เธฃเธดเธกเธฃเธฑเธ HP
		hero.heal(actual_heal)

	# เธญเธฑเธเน€เธ”เธ— HP bar เธเธฃเธฑเนเธเน€เธ”เธตเธขเธงเธ•เนเธญ tick (เนเธกเนเธ•เนเธญเธ emit เธ—เธธเธ hero)
	if healed_anyone:
		hp_changed.emit(current_hp, max_hp)

	# โ”€โ”€ เธ–เนเธฒเนเธกเนเธกเธตเนเธเธฃเธ•เนเธญเธเธฎเธตเธฅเนเธฅเนเธง โ’ เธซเธขเธธเธ” โ”€โ”€
	if not healed_anyone:
		# เน€เธเนเธเธญเธตเธเธ—เธตเธงเนเธฒเธเธฃเธดเธ เน เนเธกเนเธกเธตเนเธเธฃเธเธฒเธ” HP
		var anyone_needs_heal: bool = false
		for hero in _heal_targets:
			if _is_valid_heal_target(hero):
				anyone_needs_heal = true
				break
		if not anyone_needs_heal:
			stop_healing()


func _is_valid_heal_target(hero: Node) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if not (("is_dead" in hero) and ("current_hp" in hero) and ("max_hp" in hero)):
		return false
	return not bool(hero.get("is_dead")) and int(hero.get("current_hp")) < int(hero.get("max_hp"))


# โ”€โ”€ เน€เธฃเธดเนเธก Fountain Heal เธฃเธฐเธซเธงเนเธฒเธ Wave โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€
func start_healing(heroes: Array[Node]) -> void:
	var minimum_heart_hp: int = int(max_hp * min_hp_percent)
	if current_hp <= minimum_heart_hp:
		return

	_heal_targets = heroes
	_tick_timer = 0.0
	_is_healing = false

	# เน€เธเนเธเธงเนเธฒเธกเธตเนเธเธฃเธ•เนเธญเธเธฎเธตเธฅเนเธซเธก โ’ เน€เธเธดเธ” Aura เนเธซเน Hero เธ—เธตเนเธขเธฑเธเธกเธตเธเธตเธงเธดเธ•
	for hero in _heal_targets:
		if _is_valid_heal_target(hero):
			_is_healing = true


# โ”€โ”€ เธซเธขเธธเธ”เธฎเธตเธฅเธ—เธฑเธเธ—เธตเน€เธกเธทเนเธญ Wave เนเธซเธกเนเน€เธฃเธดเนเธก โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€โ”€
func stop_healing() -> void:
	# เธเธดเธ” Aura เธเธญเธ Hero เธ—เธธเธเธ•เธฑเธง
	for hero in _heal_targets:
		if hero != null and is_instance_valid(hero):
			if hero.has_method("hide_healing_aura"):
				hero.hide_healing_aura()

	_is_healing = false
	_heal_targets.clear()
	_tick_timer = 0.0


func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)

	_spawn_damage_number(amount, false)

	# Flash
	modulate = Color(1.0, 0.5, 0.5)
	var tween: Tween = create_tween()
	tween.tween_property(self , "modulate", Color.WHITE, 0.2)

	if current_hp <= 0:
		destroyed.emit()

func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var damage_num_scene = preload("res://shared/ui/scenes/damage_number.tscn")
	if damage_num_scene:
		var damage_num = damage_num_scene.instantiate()
		damage_num.amount = amount
		damage_num.is_crit = is_crit
		damage_num.global_position = global_position
		get_tree().current_scene.add_child(damage_num)


