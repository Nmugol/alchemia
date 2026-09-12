extends GutTest

var game_object: GameObject

func before_each():
	game_object = GameObject.new()

func after_each():
	game_object = null

func test_default_values():
	assert_eq(game_object.name, "", "Default name should be empty")
	assert_eq(game_object.level, 0, "Default level should be 0")
	assert_true(game_object.raw_material.is_empty(), "Default raw_material dictionary should be empty")
	assert_null(game_object.icon, "Default icon should be null")

func test_to_json_default():
	var json_data: Dictionary = game_object._to_json()
	assert_eq(json_data.get("name"), "", "Serialized default name should be empty string")
	assert_eq(json_data.get("level"), 0, "Serialized default level should be 0")
	assert_true(json_data.get("raw_material").is_empty(), "Serialized raw_material should be empty")
	assert_eq(json_data.get("icon"), "", "Serialized default icon path should be empty string")

func test_to_json_populated():
	game_object.name = "Health Potion"
	game_object.level = 3
	game_object.raw_material[RawMaterials.Materials.FLUID] = 25.5
	game_object.raw_material[RawMaterials.Materials.PLANT] = 10.0

	var json_data: Dictionary = game_object._to_json()
	assert_eq(json_data.get("name"), "Health Potion")
	assert_eq(json_data.get("level"), 3)
	assert_eq(json_data.get("raw_material").get(int(RawMaterials.Materials.FLUID)), 25.5)
	assert_eq(json_data.get("raw_material").get(int(RawMaterials.Materials.PLANT)), 10.0)
	assert_eq(json_data.get("icon"), "")

func test_to_json_with_embedded_icon():
	var tex = ImageTexture.new()
	tex.resource_path = "res://scenes/level.tscn::Texture_123"
	game_object.icon = tex as CompressedTexture2D

	var json_data: Dictionary = game_object._to_json()
	assert_eq(json_data.get("icon"), "", "Embedded icon path with '::' should not be saved")

func test_from_json_with_dictionary():
	var data: Dictionary = {
		"name": "Iron Sword",
		"level": 2,
		"raw_material": {
			str(int(RawMaterials.Materials.METAL)): 15.0,
			str(int(RawMaterials.Materials.ROCK)): 5.5
		},
		"icon": ""
	}

	game_object._from_json(data)

	assert_eq(game_object.name, "Iron Sword")
	assert_eq(game_object.level, 2)
	assert_eq(game_object.raw_material.size(), 2)
	assert_eq(game_object.raw_material.get(RawMaterials.Materials.METAL), 15.0)
	assert_eq(game_object.raw_material.get(RawMaterials.Materials.ROCK), 5.5)
	assert_null(game_object.icon)

func test_from_json_with_embedded_icon():
	var data: Dictionary = {
		"name": "Magic Ring",
		"level": 4,
		"raw_material": {},
		"icon": "res://scenes/level.tscn::Texture_456"
	}

	game_object._from_json(data)
	assert_eq(game_object.name, "Magic Ring")
	assert_null(game_object.icon, "Embedded icon path should be safely handled as null")

func test_from_json_with_json_string():
	var json_string: String = JSON.stringify({
		"name": "Elixir",
		"level": 5,
		"raw_material": {
			str(int(RawMaterials.Materials.FLUID)): 50.0,
			str(int(RawMaterials.Materials.CRYSTAL)): 20.0
		},
		"icon": ""
	})

	game_object._from_json(json_string)

	assert_eq(game_object.name, "Elixir")
	assert_eq(game_object.level, 5)
	assert_eq(game_object.raw_material.get(RawMaterials.Materials.FLUID), 50.0)
	assert_eq(game_object.raw_material.get(RawMaterials.Materials.CRYSTAL), 20.0)

func test_from_json_with_invalid_data():
	game_object.name = "Original"
	game_object.level = 1

	game_object._from_json("invalid json string {:")
	assert_eq(game_object.name, "Original", "Invalid JSON should not change name")

	game_object._from_json(12345)
	assert_eq(game_object.name, "Original", "Non-dict/non-string should not change name")

func test_from_json_clears_previous_raw_materials():
	game_object.raw_material[RawMaterials.Materials.FLUID] = 100.0

	var data: Dictionary = {
		"name": "Dry Rock",
		"level": 1,
		"raw_material": {
			str(int(RawMaterials.Materials.ROCK)): 5.0
		}
	}

	game_object._from_json(data)

	assert_false(game_object.raw_material.has(RawMaterials.Materials.FLUID), "Old materials should be cleared")
	assert_true(game_object.raw_material.has(RawMaterials.Materials.ROCK), "New material should be present")
	assert_eq(game_object.raw_material[RawMaterials.Materials.ROCK], 5.0)

func test_roundtrip_serialization_and_deserialization():
	game_object.name = "Philosopher Stone"
	game_object.level = 6
	game_object.raw_material[RawMaterials.Materials.CRYSTAL] = 99.9
	game_object.raw_material[RawMaterials.Materials.LIFE] = 42.0

	var serialized: Dictionary = game_object._to_json()
	var json_text: String = JSON.stringify(serialized)

	var restored_object: GameObject = GameObject.new()
	restored_object._from_json(json_text)

	assert_eq(restored_object.name, game_object.name)
	assert_eq(restored_object.level, game_object.level)
	assert_eq(restored_object.raw_material.size(), game_object.raw_material.size())
	assert_eq(restored_object.raw_material[RawMaterials.Materials.CRYSTAL], 99.9)
	assert_eq(restored_object.raw_material[RawMaterials.Materials.LIFE], 42.0)
	assert_null(restored_object.icon)

func test_icon_handling_empty_and_missing():
	var data: Dictionary = {
		"name": "Test Item",
		"level": 1,
		"raw_material": {},
		"icon": "res://non_existent_texture_12345.png"
	}

	game_object._from_json(data)
	assert_null(game_object.icon, "Non-existent texture path should result in null icon")
