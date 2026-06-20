extends Node

# persistent stats
var total_kills := 0
var total_glory := 0
var spent_glory := 0
var current_glory: int:
	get: return total_glory - spent_glory

# upgradable stats
var max_health: int:
	get: return 100 + berserk_trance.value
var pierce: int:
	get: return 1 + axe_bite.value
var knockback: float:
	get: return 0.1 + brute_force.value


class Upgrade:
	var level := 1
	var base_cost: int
	var value		# int or float
	var step_value  # increase per level
	var max_level: int
	
	func _init(_base_cost: int, _start_val, _step, _max: int = 9999):
		base_cost = _base_cost
		value = _start_val
		step_value = _step
		max_level = _max
	
	var cost: int:
		get: return base_cost * level
	
	var is_maxed: bool:
		get: return level >= max_level

var berserk_trance = Upgrade.new(10, 0, 20)
var axe_bite = Upgrade.new(25, 0, 1)
var brute_force = Upgrade.new(5, 0, 0.05, 10)

func can_afford(upgrade: Upgrade) -> bool:
	return current_glory > upgrade.cost

func attempt_purchase(upgrade: Upgrade) -> bool:
	if can_afford(upgrade) and not upgrade.is_maxed:
		spent_glory += upgrade.cost
		upgrade.level += 1
		upgrade.value += upgrade.step_value
		return true
	return false
