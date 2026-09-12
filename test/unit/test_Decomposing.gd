extends GutTest

var decomposing: Decomposing
var game_object: GameObject

func before_each():
	decomposing = Decomposing.new()
	game_object = GameObject.new()
	game_object.level = 1
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()
	Player.current_focus = 200

func after_each():
	decomposing.free()
	decomposing = null
	game_object = null
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()
	Player.current_focus = Player.max_focus

func test_decompose_empty_game_object():
	Equipment.add_game_object(game_object, 1)

	decomposing.decompose(game_object)

	assert_true(Equipment.rawMaterials.is_empty(), "Equipment rawMaterials should remain empty when decomposing an object without materials")
	assert_false(Equipment.gameObjects.has(game_object), "GameObject should be removed from Equipment")
	assert_eq(Player.current_focus, 180, "Decomposing level 1 item should deduct 20 focus")

func test_decompose_single_material():
	game_object.name = "Stone"
	game_object.level = 1
	game_object.raw_material[RawMaterials.Materials.ROCK] = 10.0
	Equipment.add_game_object(game_object, 1)

	decomposing.decompose(game_object)

	assert_eq(Equipment.rawMaterials.size(), 1, "Equipment should have 1 raw material")
	assert_true(Equipment.rawMaterials.has(RawMaterials.Materials.ROCK), "Equipment should contain ROCK")
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.ROCK], 10.0, "ROCK quantity should match GameObject raw material quantity")
	assert_false(Equipment.gameObjects.has(game_object), "GameObject should be removed from Equipment")
	assert_eq(Player.current_focus, 180, "Focus should decrease by 20 for level 1")

func test_decompose_multiple_materials():
	game_object.name = "Health Potion"
	game_object.level = 2
	game_object.raw_material[RawMaterials.Materials.FLUID] = 25.5
	game_object.raw_material[RawMaterials.Materials.PLANT] = 10.0
	game_object.raw_material[RawMaterials.Materials.CRYSTAL] = 2.0
	Equipment.add_game_object(game_object, 1)

	decomposing.decompose(game_object)

	assert_eq(Equipment.rawMaterials.size(), 3, "Equipment should have 3 raw materials")
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.FLUID], 25.5)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.PLANT], 10.0)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.CRYSTAL], 2.0)
	assert_false(Equipment.gameObjects.has(game_object), "GameObject should be removed from Equipment")
	assert_eq(Player.current_focus, 175, "Focus should decrease by 25 for level 2")

func test_decompose_removes_single_item_stack():
	Equipment.add_game_object(game_object, 1)
	assert_true(Equipment.gameObjects.has(game_object))

	decomposing.decompose(game_object)

	assert_false(Equipment.gameObjects.has(game_object), "Single item should be completely removed from equipment")

func test_decompose_decrements_stack_count():
	Equipment.add_game_object(game_object, 3)
	assert_eq(Equipment.gameObjects.get(game_object), 3)

	decomposing.decompose(game_object)

	assert_true(Equipment.gameObjects.has(game_object), "Item should still be in equipment if stack > 1")
	assert_eq(Equipment.gameObjects.get(game_object), 2, "Stack count should decrease by 1")

func test_decompose_preserves_other_game_objects():
	var other_object: GameObject = GameObject.new()
	other_object.name = "Other Item"
	Equipment.add_game_object(game_object, 1)
	Equipment.add_game_object(other_object, 5)

	decomposing.decompose(game_object)

	assert_false(Equipment.gameObjects.has(game_object), "Decomposed object should be removed")
	assert_true(Equipment.gameObjects.has(other_object), "Other object should remain in equipment")
	assert_eq(Equipment.gameObjects.get(other_object), 5, "Other object count should not change")

func test_decompose_accumulates_existing_material():
	Equipment.add_raw_material(RawMaterials.Materials.METAL, 5.0)

	game_object.name = "Iron Shield"
	game_object.level = 1
	game_object.raw_material[RawMaterials.Materials.METAL] = 50.0
	Equipment.add_game_object(game_object, 1)

	decomposing.decompose(game_object)

	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.METAL], 55.0, "Equipment raw material should accumulate decomposed value")
	assert_false(Equipment.gameObjects.has(game_object))

func test_decompose_preserves_unrelated_existing_materials():
	Equipment.add_raw_material(RawMaterials.Materials.DUST, 15.0)

	game_object.name = "Wooden Stick"
	game_object.level = 1
	game_object.raw_material[RawMaterials.Materials.PLANT] = 8.0
	Equipment.add_game_object(game_object, 1)

	decomposing.decompose(game_object)

	assert_eq(Equipment.rawMaterials.size(), 2, "Equipment should contain both existing and new materials")
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.DUST], 15.0, "Existing DUST should remain untouched")
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.PLANT], 8.0, "PLANT should be added")
	assert_false(Equipment.gameObjects.has(game_object))

func test_decompose_all_material_types():
	var materials: Array = [
		RawMaterials.Materials.FLUID,
		RawMaterials.Materials.ROCK,
		RawMaterials.Materials.DUST,
		RawMaterials.Materials.PLANT,
		RawMaterials.Materials.LIFE,
		RawMaterials.Materials.METAL,
		RawMaterials.Materials.CRYSTAL,
		RawMaterials.Materials.SALT,
		RawMaterials.Materials.OIL,
		RawMaterials.Materials.ALCOHOL,
		RawMaterials.Materials.LEATHER
	]

	for i in range(materials.size()):
		var mat = materials[i]
		game_object.raw_material[mat] = float(i + 1) * 1.5

	Equipment.add_game_object(game_object, 1)

	decomposing.decompose(game_object)

	assert_eq(Equipment.rawMaterials.size(), materials.size(), "Equipment should have all materials")
	for i in range(materials.size()):
		var mat = materials[i]
		assert_eq(Equipment.rawMaterials[mat], float(i + 1) * 1.5)
	assert_false(Equipment.gameObjects.has(game_object))

func test_focus_cost_scaling_by_level():
	var expected_costs: Dictionary = {
		1: 20,
		2: 25,
		3: 41,
		4: 67,
		5: 104,
		6: 152
	}

	for lvl in expected_costs:
		Player.current_focus = 200
		game_object.level = lvl
		Equipment.add_game_object(game_object, 1)
		decomposing.decompose(game_object)
		var expected_remaining: int = 200 - expected_costs[lvl]
		assert_eq(Player.current_focus, expected_remaining, "Focus for level %d should decrease by %d" % [lvl, expected_costs[lvl]])
		assert_false(Equipment.gameObjects.has(game_object))
