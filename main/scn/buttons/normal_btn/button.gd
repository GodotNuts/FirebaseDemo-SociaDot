tool
extends Button

export (StreamTexture) var texture_active : StreamTexture
export (StreamTexture) var texture_inactive : StreamTexture
export (Color) var color : Color = Color.white

var activated : bool = false        setget set_activated

func _connect_signals():
    connect("mouse_entered", self, "_on_Btn_mouse_entered")
    connect("mouse_exited", self, "_on_Btn_mouse_exited")

func _ready():
    _connect_signals()

func _on_Btn_mouse_entered():
    if not activated:
        $Tween.interpolate_property(self, "modulate", Color.white, color, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.start()

func _on_Btn_mouse_exited():
    if not activated:
        $Tween.interpolate_property(self, "modulate", color, Color.white, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.start()

func set_activated(active : bool):
    activated = active
    if activated:
        modulate = color
        icon = texture_active
    else:
        modulate = Color.white
        icon = texture_inactive
