@icon ("res://addons/at-icons/node/list_unordered.svg")
class_name Recipe
extends Resource

@export var output_game_object: GameObject
@export var output_game_object_count: int = 1
@export var output_raw_materials: Dictionary[RawMaterials.Materials, float] = {}

@export var input_game_objects: Dictionary[GameObject, int] = {}
@export var input_raw_materials: Dictionary[RawMaterials.Materials, float] = {}

@export var required_catalyst: GameObject = null
@export_range(0.0, 1.0, 0.01) var base_success_chance: float = 1.0

@export var is_time_based: bool = false
@export var time_cost: float = 0.0
@export var focus_cost: float = 0.0
