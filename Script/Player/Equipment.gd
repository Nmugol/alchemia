@icon("res://addons/at-icons/node/pouch.svg")
extends Node

var gameObjects: Dictionary[GameObject, int] = {}
var rawMaterials: Dictionary[RawMaterials.Materials, float] = {}

func add_game_object(game_object: GameObject, count: int = 1):
	if game_object in gameObjects:
		gameObjects[game_object] += count
	else:
		gameObjects[game_object] = count

func remove_game_object(game_object: GameObject, count: int = 1):
	if game_object in gameObjects:
		gameObjects[game_object] -= count
		if gameObjects[game_object] <= 0:
			gameObjects.erase(game_object)

func add_raw_material(raw_material: RawMaterials.Materials, count: float = 1.0):
	if raw_material in rawMaterials:
		rawMaterials[raw_material] += count
	else:
		rawMaterials[raw_material] = count

func remove_raw_material(raw_material: RawMaterials.Materials, count: float = 1.0) -> bool:
	if raw_material in rawMaterials:
		if rawMaterials[raw_material] >= count:
			rawMaterials[raw_material] -= count
			return true
		else:
			GlobalSignals.emit_signal("NotEnoughResources")
			return false
	else:
		GlobalSignals.emit_signal("NotEnoughResources")
		return false

func has_raw_material(raw_material: RawMaterials.Materials, count: float = 1.0) -> bool:
	return raw_material in rawMaterials and rawMaterials[raw_material] >= count

func to_json() -> Dictionary:
	var game_objects_data: Array[Dictionary] = []
	for game_obj in gameObjects:
		if is_instance_valid(game_obj):
			var res_path: String = game_obj.resource_path if (game_obj.resource_path != "" and not game_obj.resource_path.contains("::")) else ""
			game_objects_data.append({
				"resource_path": res_path,
				"game_object": game_obj._to_json(),
				"count": gameObjects[game_obj]
			})

	var raw_materials_data: Dictionary = {}
	for mat in rawMaterials:
		raw_materials_data[int(mat)] = rawMaterials[mat]

	return {
		"gameObjects": game_objects_data,
		"rawMaterials": raw_materials_data
	}

func from_json(data: Variant) -> void:
	if data is String:
		var json: JSON = JSON.new()
		var error: Error = json.parse(data)
		if error != OK:
			return
		data = json.data

	if not data is Dictionary:
		return

	gameObjects.clear()
	var objects_data = data.get("gameObjects", data.get("game_objects", []))
	if objects_data is Array:
		for item in objects_data:
			if not item is Dictionary:
				continue
			var count: int = int(item.get("count", 1))
			var res_path: String = str(item.get("resource_path", ""))
			var obj: GameObject = null

			if res_path != "" and not res_path.contains("::") and ResourceLoader.exists(res_path):
				obj = load(res_path) as GameObject

			if obj == null and item.has("game_object"):
				obj = GameObject.new()
				obj._from_json(item.get("game_object"))

			if obj != null:
				gameObjects[obj] = count

	rawMaterials.clear()
	var raw_data = data.get("rawMaterials", data.get("raw_materials", {}))
	if raw_data is Dictionary:
		for mat_key in raw_data:
			var enum_val: RawMaterials.Materials = int(mat_key) as RawMaterials.Materials
			rawMaterials[enum_val] = float(raw_data[mat_key])
