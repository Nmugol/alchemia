extends Node

const MAX_LEVEL: int = 10
var level: int = 1

var max_focus: int = 100
var current_focus: int = 0

var experience: int = 0

func _ready():
    current_focus = max_focus

func to_json():
    return {
        "level": level,
        "max_focus": max_focus,
        "current_focus": current_focus,
        "experience": experience,
    }

func from_json(data):
    level = data["level"]
    max_focus = data["max_focus"]
    current_focus = data["current_focus"]
    experience = data["experience"]
