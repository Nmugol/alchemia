@icon ("res://addons/at-icons/node/unwrap.svg")
class_name Decomposing
extends Node

const BASE_FOCUS_COST: int = 20
var amout_to_decomposing: int = 1

func decompose(object: GameObject) -> void:
	if object == null or _calculate_focus_cost(object) > Player.current_focus:
		return

	for material in object.raw_material:
		Equipment.add_raw_material(material, object.raw_material[material] * amout_to_decomposing)

	Equipment.remove_game_object(object, amout_to_decomposing)
	Player.current_focus -= _calculate_focus_cost(object)

func _calculate_focus_cost(object: GameObject) -> int:
	if object == null:
		return 0
	const multiplier_base = 5.2
	return floor(BASE_FOCUS_COST + (multiplier_base + amout_to_decomposing / 10.0) * pow(object.level - 1, 2))
