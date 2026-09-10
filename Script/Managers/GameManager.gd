extends Node

class_name GameManager

var state: GameState.State = GameState.State.RUN
var time_of_day: GameState.TimeOfDay = GameState.TimeOfDay.MORNING

func _ready():
    GlobalSignals.ChangeState.connect(func(s: GameState.State):
        self.state = s
        _updateState()
    )

    GlobalSignals.ChangeTimeOfDay.connect(func(t: GameState.TimeOfDay):
        self.time_of_day = t
        _updateTimeOfDay()
    )

func _updateState():
    match self.state:
        GameState.State.RUN:
            pass
        GameState.State.PAUSE:
            pass
        GameState.State.SAVED:
            pass
        GameState.State.EXIT:
            pass

func _updateTimeOfDay():
    match self.time_of_day:
        GameState.TimeOfDay.MORNING:
            pass
        GameState.TimeOfDay.NOON:
            pass
        GameState.TimeOfDay.AFTERNOON:
            pass
        GameState.TimeOfDay.EVENING:
            pass
        GameState.TimeOfDay.NIGHT:
            pass
