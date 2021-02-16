extends HBoxContainer
class_name TopBar

onready var name_lbl : Label = $Name

signal close()
signal resize()
signal minimize()
signal moving_from_pos(event_pos, offset)

var offset : Vector2 
var dragging : bool = false

func _ready():
    connect("mouse_entered", self, "_on_TopBar_mouse_entered")
    connect("mouse_exited", self, "_on_TopBar_mouse_exited")
    $MinimizeBtn.connect("pressed", self, "_on_minimize_pressed")
    $ResizeBtn.connect("pressed", self, "_on_resize_pressed")
    $ExitBtn.connect("pressed", self, "_on_close_pressed")
    _on_TopBar_mouse_exited()

func set_window_name(_name : String):
    name_lbl.set_text(_name)

func _on_close_pressed():
    _on_TopBar_mouse_exited()
    emit_signal("close")

func _on_minimize_pressed():
    _on_TopBar_mouse_exited()
    emit_signal("minimize")

func _on_resize_pressed():
    _on_TopBar_mouse_exited()
    emit_signal("resize")

func _on_Name_gui_input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            offset = get_global_mouse_position()
        else:
            offset = Vector2()
    if event is InputEventMouseMotion and offset != Vector2():
        emit_signal("moving_from_pos", get_global_mouse_position(), offset)


func _on_TopBar_mouse_entered():
    for button in get_children(): if button is Button: $Tween.interpolate_property(button,"self_modulate",button.get_self_modulate(),Color(1,1,1,1),0.2,Tween.TRANS_QUAD,Tween.EASE_OUT)
    $Tween.start()

func _on_TopBar_mouse_exited():
    for button in get_children(): if button is Button: $Tween.interpolate_property(button,"self_modulate",button.get_self_modulate(),Color(1,1,1,0.1),0.2,Tween.TRANS_QUAD,Tween.EASE_OUT)
    $Tween.start()
