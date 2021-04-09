extends Label


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass


func _on_Message_draw() -> void:
    if rect_size.x >= 280:
        autowrap = true
        rect_min_size.x = 280
