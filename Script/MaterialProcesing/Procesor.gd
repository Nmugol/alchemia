@icon ("res://addons/at-icons/node/cpu.svg")
class_name Procesor
extends Node

signal processing_finished(is_success: bool)
signal not_enough_resources()

@export var valid_recipes: Array[Recipe] = []
@export var failed_objects: GameObject = null

var input_raw_materials: Dictionary[RawMaterials.Materials, float] = {}
var input_game_objects: Dictionary[GameObject, int] = {}
var catalyst: GameObject = null

var active_recipe: Recipe = null
var output_raw_materials: Dictionary[RawMaterials.Materials, float] = {}
var output_game_object: GameObject
var output_game_object_count: int = 1

var is_time_based: bool = false
var time_cost: float = 0.0
var focus_cost: float = 0.0
var success_chance: float = 1.0

func _find_matching_recipe() -> Recipe:
	for recipe in valid_recipes:
		if _matches_recipe(recipe):
			return recipe
	return null

func _matches_recipe(recipe: Recipe) -> bool:
	if recipe.input_game_objects != input_game_objects:
		return false
	if recipe.input_raw_materials != input_raw_materials:
		return false
	if recipe.required_catalyst != null:
		if catalyst == null:
			return false
		if catalyst != recipe.required_catalyst and catalyst.name != recipe.required_catalyst.name:
			return false
	return true

func _input_is_valid() -> bool:
	var recipe: Recipe = _find_matching_recipe()
	if recipe != null:
		active_recipe = recipe
		output_raw_materials = recipe.output_raw_materials
		output_game_object = recipe.output_game_object
		output_game_object_count = recipe.output_game_object_count
		is_time_based = recipe.is_time_based
		time_cost = recipe.time_cost
		focus_cost = recipe.focus_cost
		success_chance = _calculate_success_chance(recipe)
		return true
	return false

func _has_sufficient_resources(recipe: Recipe) -> bool:
	# Check raw materials in Equipment
	for mat in recipe.input_raw_materials:
		var required_amount: float = recipe.input_raw_materials[mat]
		if not Equipment.has_raw_material(mat, required_amount):
			return false

	# Check input game objects in Equipment
	for obj in recipe.input_game_objects:
		var required_count: int = recipe.input_game_objects[obj]
		var found_count: int = 0
		for eq_obj in Equipment.gameObjects:
			if eq_obj == obj or (eq_obj != null and obj != null and eq_obj.name == obj.name):
				found_count += Equipment.gameObjects[eq_obj]
		if found_count < required_count:
			return false

	# Check catalyst in Equipment if required
	if recipe.required_catalyst != null:
		var catalyst_available: bool = false
		if catalyst != null and (catalyst == recipe.required_catalyst or catalyst.name == recipe.required_catalyst.name):
			catalyst_available = true
		else:
			for eq_obj in Equipment.gameObjects:
				if eq_obj == recipe.required_catalyst or (eq_obj != null and eq_obj.name == recipe.required_catalyst.name):
					catalyst_available = true
					break
		if not catalyst_available:
			return false

	# Check Time or Focus
	if recipe.is_time_based:
		var cost: int = _calculate_time_cost(recipe.output_game_object, recipe.time_cost)
		if GameManager.current_time < cost:
			return false
	else:
		var cost: int = _calculate_focus_cost(recipe.output_game_object, 1, recipe.focus_cost)
		if Player.current_focus < cost:
			return false

	return true

func _calculate_success_chance(recipe: Recipe) -> float:
	var chance: float = recipe.base_success_chance
	var player_level: int = Player.level if "level" in Player else 1
	var level_bonus: float = maxf(0.0, float(player_level - 1) * 0.02)
	chance += level_bonus
	return clampf(chance, 0.05, 1.0)

func _calculate_focus_cost(object: GameObject, amount: int, base_focus_cost: float) -> int:
	if object == null:
		return int(base_focus_cost)
	const multiplier_base = 5.2
	return floor(base_focus_cost + (multiplier_base + amount / 10.0) * pow(object.level - 1, 2))

func _calculate_time_cost(object: GameObject, base_time_cost: float) -> int:
	if object == null:
		return int(base_time_cost)
	const multiplier_base = 5.2
	return floor(base_time_cost + (multiplier_base * pow(object.level - 1, 2)))

func _consume_inputs(recipe: Recipe) -> void:
	for mat in recipe.input_raw_materials:
		Equipment.remove_raw_material(mat, recipe.input_raw_materials[mat])

	for obj in recipe.input_game_objects:
		var needed: int = recipe.input_game_objects[obj]
		for eq_obj in Equipment.gameObjects.keys():
			if eq_obj == obj or (eq_obj != null and obj != null and eq_obj.name == obj.name):
				var available: int = Equipment.gameObjects[eq_obj]
				var to_remove: int = mini(needed, available)
				Equipment.remove_game_object(eq_obj, to_remove)
				needed -= to_remove
				if needed <= 0:
					break

	if recipe.is_time_based:
		var cost: int = _calculate_time_cost(recipe.output_game_object, recipe.time_cost)
		GameManager.current_time -= cost
	else:
		var cost: int = _calculate_focus_cost(recipe.output_game_object, 1, recipe.focus_cost)
		Player.current_focus -= cost

func _processing() -> bool:
	var recipe: Recipe = _find_matching_recipe()
	if recipe == null:
		if failed_objects != null:
			Equipment.add_game_object(failed_objects, 1)
		processing_finished.emit(false)
		return false

	active_recipe = recipe
	output_raw_materials = recipe.output_raw_materials
	output_game_object = recipe.output_game_object
	output_game_object_count = recipe.output_game_object_count
	is_time_based = recipe.is_time_based
	time_cost = recipe.time_cost
	focus_cost = recipe.focus_cost
	success_chance = _calculate_success_chance(recipe)

	if not _has_sufficient_resources(recipe):
		GlobalSignals.emit_signal("NotEnoughResources")
		not_enough_resources.emit()
		return false

	_consume_inputs(recipe)

	var roll: float = randf()
	var is_success: bool = roll <= success_chance

	if is_success:
		for material in output_raw_materials:
			Equipment.add_raw_material(material, output_raw_materials[material])

		if output_game_object != null:
			Equipment.add_game_object(output_game_object, output_game_object_count)
	else:
		if failed_objects != null:
			Equipment.add_game_object(failed_objects, 1)

	processing_finished.emit(is_success)
	return is_success
