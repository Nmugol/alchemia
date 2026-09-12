extends GutTest

var marging: Marging

func before_each():
	marging = Marging.new()
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()
	Player.current_focus = 200

func after_each():
	marging.free()
	marging = null
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()
	Player.current_focus = Player.max_focus

func test_margin_removes_single_material():
	Equipment.add_raw_material(RawMaterials.Materials.ROCK, 10.0)

	var to_remove: Dictionary[RawMaterials.Materials, float] = {
		RawMaterials.Materials.ROCK: 4.0
	}
	marging.margin(to_remove)

	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.ROCK], 6.0)

func test_margin_removes_multiple_materials():
	Equipment.add_raw_material(RawMaterials.Materials.FLUID, 20.0)
	Equipment.add_raw_material(RawMaterials.Materials.PLANT, 15.0)
	Equipment.add_raw_material(RawMaterials.Materials.METAL, 8.0)

	var to_remove: Dictionary[RawMaterials.Materials, float] = {
		RawMaterials.Materials.FLUID: 5.0,
		RawMaterials.Materials.PLANT: 10.0,
		RawMaterials.Materials.METAL: 8.0
	}
	marging.margin(to_remove)

	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.FLUID], 15.0)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.PLANT], 5.0)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.METAL], 0.0)

func test_margin_empty_dictionary():
	Equipment.add_raw_material(RawMaterials.Materials.DUST, 10.0)

	var to_remove: Dictionary[RawMaterials.Materials, float] = { }
	marging.margin(to_remove)

	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.DUST], 10.0)

func test_margin_creates_object_and_deducts_focus():
	Equipment.add_raw_material(RawMaterials.Materials.METAL, 10.0)

	var sword: GameObject = GameObject.new()
	sword.name = "Iron Sword"
	sword.level = 1

	marging.objet_to_create = sword
	marging.amout_to_create = 1

	var to_remove: Dictionary[RawMaterials.Materials, float] = {
		RawMaterials.Materials.METAL: 5.0
	}
	marging.margin(to_remove)

	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.METAL], 5.0)
	assert_true(Equipment.gameObjects.has(sword))
	assert_eq(Equipment.gameObjects[sword], 1)
	assert_eq(Player.current_focus, 180, "Marging level 1 item should deduct 20 focus")
