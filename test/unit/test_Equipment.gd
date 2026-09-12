extends GutTest

func before_each():
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()

func after_each():
	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()

func test_default_values():
	assert_true(Equipment.gameObjects.is_empty(), "gameObjects should be empty initially")
	assert_true(Equipment.rawMaterials.is_empty(), "rawMaterials should be empty initially")

func test_add_and_remove_game_object():
	var obj: GameObject = GameObject.new()
	obj.name = "Potion"

	Equipment.add_game_object(obj, 2)
	assert_eq(Equipment.gameObjects.get(obj), 2)

	Equipment.remove_game_object(obj)
	assert_eq(Equipment.gameObjects.get(obj), 1)

	Equipment.remove_game_object(obj)
	assert_false(Equipment.gameObjects.has(obj))

func test_add_and_remove_raw_material():
	Equipment.add_raw_material(RawMaterials.Materials.ROCK, 2.0)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.ROCK), 2.0)

	var removed = Equipment.remove_raw_material(RawMaterials.Materials.ROCK)
	assert_true(removed)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.ROCK), 1.0)

	removed = Equipment.remove_raw_material(RawMaterials.Materials.ROCK)
	assert_true(removed)
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.ROCK), 0.0)

func test_remove_raw_material_insufficient_and_missing():
	Equipment.add_raw_material(RawMaterials.Materials.METAL, 1.0)

	var removed_excessive = Equipment.remove_raw_material(RawMaterials.Materials.METAL, 5.0)
	assert_false(removed_excessive, "Should return false when trying to remove more than available")
	assert_eq(Equipment.rawMaterials.get(RawMaterials.Materials.METAL), 1.0)

	var removed_missing = Equipment.remove_raw_material(RawMaterials.Materials.CRYSTAL, 1.0)
	assert_false(removed_missing, "Should return false when material is not present")

func test_has_raw_material():
	Equipment.add_raw_material(RawMaterials.Materials.DUST, 5.0)
	assert_true(Equipment.has_raw_material(RawMaterials.Materials.DUST, 5.0))
	assert_true(Equipment.has_raw_material(RawMaterials.Materials.DUST, 2.0))
	assert_false(Equipment.has_raw_material(RawMaterials.Materials.DUST, 10.0))
	assert_false(Equipment.has_raw_material(RawMaterials.Materials.LIFE, 1.0))

func test_to_json_empty():
	var json_data: Dictionary = Equipment.to_json()
	assert_true(json_data.has("gameObjects"))
	assert_true(json_data.has("rawMaterials"))
	assert_true(json_data["gameObjects"].is_empty())
	assert_true(json_data["rawMaterials"].is_empty())

func test_to_json_populated():
	var obj: GameObject = GameObject.new()
	obj.name = "Gold Coin"
	obj.level = 1

	Equipment.add_game_object(obj, 5)
	Equipment.add_raw_material(RawMaterials.Materials.METAL, 10.0)

	var json_data: Dictionary = Equipment.to_json()
	assert_eq(json_data["gameObjects"].size(), 1)
	assert_eq(json_data["gameObjects"][0]["count"], 5)
	assert_eq(json_data["gameObjects"][0]["game_object"]["name"], "Gold Coin")
	assert_eq(json_data["rawMaterials"][int(RawMaterials.Materials.METAL)], 10.0)

func test_to_json_with_embedded_resource():
	var obj: GameObject = GameObject.new()
	obj.name = "Embedded Dagger"
	obj.resource_path = "res://scenes/level.tscn::GameObject_1"
	Equipment.add_game_object(obj, 2)

	var json_data: Dictionary = Equipment.to_json()
	assert_eq(json_data["gameObjects"].size(), 1)
	assert_eq(json_data["gameObjects"][0]["resource_path"], "", "Embedded resource path with '::' should not be stored as resource_path")
	assert_eq(json_data["gameObjects"][0]["game_object"]["name"], "Embedded Dagger")

func test_from_json_with_dictionary():
	var data: Dictionary = {
		"gameObjects": [
			{
				"count": 3,
				"resource_path": "",
				"game_object": {
					"name": "Herb",
					"level": 1,
					"raw_material": {},
					"icon": ""
				}
			}
		],
		"rawMaterials": {
			str(int(RawMaterials.Materials.PLANT)): 20.0
		}
	}

	Equipment.from_json(data)

	assert_eq(Equipment.gameObjects.size(), 1)
	var found_obj: GameObject = Equipment.gameObjects.keys()[0]
	assert_eq(found_obj.name, "Herb")
	assert_eq(Equipment.gameObjects[found_obj], 3)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.PLANT], 20.0)

func test_from_json_with_embedded_resource_path():
	var data: Dictionary = {
		"gameObjects": [
			{
				"count": 2,
				"resource_path": "res://scenes/level.tscn::GameObject_99",
				"game_object": {
					"name": "Embedded Shield",
					"level": 3,
					"raw_material": {},
					"icon": ""
				}
			}
		],
		"rawMaterials": {}
	}

	Equipment.from_json(data)

	assert_eq(Equipment.gameObjects.size(), 1)
	var obj: GameObject = Equipment.gameObjects.keys()[0]
	assert_eq(obj.name, "Embedded Shield")
	assert_eq(obj.level, 3)
	assert_eq(Equipment.gameObjects[obj], 2)

func test_from_json_with_json_string():
	var json_str: String = JSON.stringify({
		"gameObjects": [
			{
				"count": 1,
				"resource_path": "",
				"game_object": {
					"name": "Amulet",
					"level": 4,
					"raw_material": {},
					"icon": ""
				}
			}
		],
		"rawMaterials": {
			str(int(RawMaterials.Materials.CRYSTAL)): 7.0
		}
	})

	Equipment.from_json(json_str)

	assert_eq(Equipment.gameObjects.size(), 1)
	var obj: GameObject = Equipment.gameObjects.keys()[0]
	assert_eq(obj.name, "Amulet")
	assert_eq(obj.level, 4)
	assert_eq(Equipment.gameObjects[obj], 1)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.CRYSTAL], 7.0)

func test_from_json_invalid_data():
	Equipment.add_raw_material(RawMaterials.Materials.LIFE, 5.0)

	Equipment.from_json("invalid json {:")
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.LIFE], 5.0, "Invalid json should not modify state")

	Equipment.from_json(999)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.LIFE], 5.0, "Invalid type should not modify state")

func test_roundtrip_serialization_and_deserialization():
	var obj: GameObject = GameObject.new()
	obj.name = "Magic Dust"
	obj.level = 2
	obj.raw_material[RawMaterials.Materials.DUST] = 12.0

	Equipment.add_game_object(obj, 4)
	Equipment.add_raw_material(RawMaterials.Materials.DUST, 15.0)
	Equipment.add_raw_material(RawMaterials.Materials.FLUID, 8.0)

	var json_data: Dictionary = Equipment.to_json()
	var json_str: String = JSON.stringify(json_data)

	Equipment.gameObjects.clear()
	Equipment.rawMaterials.clear()
	Equipment.from_json(json_str)

	assert_eq(Equipment.gameObjects.size(), 1)
	var restored_obj: GameObject = Equipment.gameObjects.keys()[0]
	assert_eq(restored_obj.name, "Magic Dust")
	assert_eq(restored_obj.level, 2)
	assert_eq(restored_obj.raw_material[RawMaterials.Materials.DUST], 12.0)
	assert_eq(Equipment.gameObjects[restored_obj], 4)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.DUST], 15.0)
	assert_eq(Equipment.rawMaterials[RawMaterials.Materials.FLUID], 8.0)
