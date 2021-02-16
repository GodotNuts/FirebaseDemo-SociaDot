extends CPUParticles2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func add_to_control(control : Control):
    control.add_child(self)
    self.set_position(control.rect_size/2)
    emitting = true
    yield(get_tree().create_timer(lifetime), "timeout")
    queue_free()
