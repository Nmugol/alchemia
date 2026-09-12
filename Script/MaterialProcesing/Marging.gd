@icon ("res://addons/at-icons/node/git_merge.svg")
class_name Marging
extends Node

const BASE_FOCUS_COST: float = 20

var objet_to_create: GameObject
var amout_to_create: int = 1

func margin(materials: Dictionary[RawMaterials.Materials, float]):
	if _calculate_focus_cost(objet_to_create) > Player.current_focus:
		return

	for m in materials:
		Equipment.remove_raw_material(m, materials[m] * amout_to_create)

	if is_instance_valid(objet_to_create):
		Equipment.add_game_object(objet_to_create, amout_to_create)

	Player.current_focus -= _calculate_focus_cost(objet_to_create)

func _calculate_focus_cost(object: GameObject) -> int:
	if object == null:
		return 0
	const multiplier_base = 5.2
	return floor(BASE_FOCUS_COST + (multiplier_base + amout_to_create / 10.0) * pow(object.level - 1, 2))
