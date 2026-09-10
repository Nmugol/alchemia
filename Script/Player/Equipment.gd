extends Node

class_name Equipment

var gameObjects: Dictionary[GameObject, int] = {}
var rawMaterials: Dictionary[RawMaterials.Materials, int] = {}

func add_game_object(game_object: GameObject, count: int):
    gameObjects[game_object] = count

func remove_game_object(game_object: GameObject):
    if game_object in gameObjects:
        gameObjects[game_object] -= 1
        if gameObjects[game_object] <= 0:
            gameObjects.erase(game_object)

func add_raw_material(raw_material: RawMaterials.Materials, count: int):
    rawMaterials[raw_material] = count

func remove_raw_material(raw_material: RawMaterials.Materials):
    if raw_material in rawMaterials:
        rawMaterials[raw_material] -= 1
        if rawMaterials[raw_material] <= 0:
            rawMaterials[raw_material] = 0
            GlobalSignals.emit_signal("NotEnoughResources")
