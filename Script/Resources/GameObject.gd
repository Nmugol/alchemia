extends Resource

class_name GameObject

@export
var name: String

@export_range(0, 6)
var level: int

@export
var raw_material: Dictionary[RawMaterials.Materials, float] = {}

@export
var icon: CompressedTexture2D
