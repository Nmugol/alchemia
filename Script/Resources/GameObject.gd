@icon ("res://addons/at-icons/node/script.svg")
class_name GameObject
extends Resource

@export
var name: String

@export_range(0, 6)
var level: int

@export
var raw_material: Dictionary[RawMaterials.Materials, float] = {}

@export
var icon: CompressedTexture2D

func _to_json() -> Dictionary:
	var raw_mat_dict: Dictionary = {}
	for mat in raw_material:
		raw_mat_dict[int(mat)] = raw_material[mat]

	var icon_path: String = ""
	if icon and icon.resource_path != "" and not icon.resource_path.contains("::"):
		icon_path = icon.resource_path

	return {
		"name": name,
		"level": level,
		"raw_material": raw_mat_dict,
		"icon": icon_path,
	}

func _from_json(data: Variant) -> void:
	if data is String:
		var json: JSON = JSON.new()
		var error: Error = json.parse(data)
		if error != OK:
			return
		data = json.data

	if not data is Dictionary:
		return

	name = str(data.get("name", ""))
	level = int(data.get("level", 0))

	raw_material.clear()
	var raw_data = data.get("raw_material", {})
	if raw_data is Dictionary:
		for mat_key in raw_data:
			var enum_val: RawMaterials.Materials = int(mat_key) as RawMaterials.Materials
			raw_material[enum_val] = float(raw_data[mat_key])

	var icon_path = data.get("icon", "")
	if icon_path is String and icon_path != "" and not icon_path.contains("::") and ResourceLoader.exists(icon_path):
		icon = load(icon_path) as CompressedTexture2D
	else:
		icon = null
