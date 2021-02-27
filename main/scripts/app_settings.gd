extends Node

var screen_size : Vector2

# TRUE = portrait
var orientation : bool

func _ready():
    get_screen_orientation()

func get_screen_orientation() -> bool:
    screen_size = get_viewport().get_visible_rect().size
    orientation = screen_size.y > screen_size.x
    return orientation
