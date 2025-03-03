extends ColorRect 

var _max_y = 240

func _ready():
	global_position.y = 80

func _physics_process(delta: float) -> void:
	if (global_position.y < _max_y):
		position.y += 8
