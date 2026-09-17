extends GutTest

var procesor: Procesor
var recipe: Recipe
var sample_object: GameObject
var catalyst_item: GameObject

func before_each():
	procesor = Procesor.new()
	recipe = Recipe.new()
	
	sample_object = GameObject.new()
	sample_object.name = "Test Item"
	sample_object.level = 1
	
	catalyst_item = GameObject.new()
	catalyst_item.name = "Test Catalyst"
	catalyst_item.level = 2

	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()
	GameManager.current_time = GameManager.MAX_TIME
	Player.current_focus = 200

func after_each():
	procesor.free()
	procesor = null
	recipe = null
	sample_object = null
	catalyst_item = null
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()

func test_processing_invalid_recipe():
	var failed_obj: GameObject = GameObject.new()
	failed_obj.name = "Failed Result"
	procesor.failed_objects = failed_obj

	var success = procesor._processing()

	assert_false(success)
	assert_true(Equipment.gameObjects.has(failed_obj))
	assert_eq(Equipment.gameObjects.get(failed_obj), 1)

func test_processing_insufficient_materials():
	recipe.input_raw_materials = {
		RawMaterials.Materials.ROCK: 10.0
	}
	recipe.output_raw_materials = {
		RawMaterials.Materials.DUST: 10.0
	}
	recipe.base_success_chance = 1.0
	procesor.valid_recipes.append(recipe)
	procesor.input_raw_materials = {
		RawMaterials.Materials.ROCK: 10.0
	}

	# Equipment only has 5.0 (not enough)
	Equipment.add_raw_material(RawMaterials.Materials.ROCK, 5.0)

	var success = procesor._processing()

	assert_false(success)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.ROCK), 5.0)
	assert_false(Equipment.rawMaterials.has(RawMaterials.Materials.DUST))

func test_processing_valid_recipe_consumes_and_outputs():
	recipe.input_raw_materials = {
		RawMaterials.Materials.ROCK: 10.0
	}
	recipe.output_raw_materials = {
		RawMaterials.Materials.DUST: 10.0
	}
	recipe.is_time_based = false
	recipe.focus_cost = 20.0
	recipe.base_success_chance = 1.0

	procesor.valid_recipes.append(recipe)
	procesor.input_raw_materials = {
		RawMaterials.Materials.ROCK: 10.0
	}

	Equipment.add_raw_material(RawMaterials.Materials.ROCK, 10.0)

	var success = procesor._processing()

	assert_true(success)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.ROCK), 0.0)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.DUST), 10.0)
	assert_eq(Player.current_focus, 180)

func test_processing_requires_catalyst():
	recipe.input_raw_materials = {
		RawMaterials.Materials.FLUID: 20.0
	}
	recipe.output_game_object = sample_object
	recipe.required_catalyst = catalyst_item
	recipe.base_success_chance = 1.0

	procesor.valid_recipes.append(recipe)
	procesor.input_raw_materials = {
		RawMaterials.Materials.FLUID: 20.0
	}
	Equipment.add_raw_material(RawMaterials.Materials.FLUID, 20.0)

	# Missing catalyst on processor -> recipe match fails
	var success_no_cat = procesor._processing()
	assert_false(success_no_cat)
	assert_false(Equipment.gameObjects.has(sample_object))

	# With catalyst set and available
	procesor.catalyst = catalyst_item
	Equipment.add_game_object(catalyst_item, 1)

	var success_with_cat = procesor._processing()
	assert_true(success_with_cat)
	assert_true(Equipment.gameObjects.has(sample_object))

func test_processing_chance_bonus_from_player_level():
	recipe.base_success_chance = 0.50
	Player.level = 6 # (6 - 1) * 0.02 = +0.10 -> 0.60
	var calculated = procesor._calculate_success_chance(recipe)
	assert_almost_eq(calculated, 0.60, 0.001)

func test_processing_failed_chance_consumes_materials_and_gives_failed_object():
	recipe.input_raw_materials = {
		RawMaterials.Materials.METAL: 10.0
	}
	recipe.output_game_object = sample_object
	recipe.base_success_chance = 0.0 # 0% chance guaranteed fail

	var failed_obj = GameObject.new()
	failed_obj.name = "Slag"
	procesor.failed_objects = failed_obj
	procesor.valid_recipes.append(recipe)
	procesor.input_raw_materials = {
		RawMaterials.Materials.METAL: 10.0
	}
	Equipment.add_raw_material(RawMaterials.Materials.METAL, 10.0)

	var success = procesor._processing()

	assert_false(success)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.METAL), 0.0, "Inputs should be lost on failure")
	assert_false(Equipment.gameObjects.has(sample_object), "Output item should not be created")
	assert_true(Equipment.gameObjects.has(failed_obj), "Failed item should be added")
