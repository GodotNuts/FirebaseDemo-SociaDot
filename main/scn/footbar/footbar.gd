extends HBoxContainer

onready var animator : Tween = $Tween

var tp_color : Color = Color(1,1,1,0.2)

func _connect_signals():
    connect("mouse_entered", self, "_on_FootBar_mouse_entered")
    connect("mouse_exited", self, "_on_FootBar_mouse_exited")
    $GodotNuts.connect("pressed", self, "_on_GodotNuts_pressed")
    $developer.connect("pressed", self, "_on_developer_pressed")
    $About.connect("pressed", self, "_on_About_pressed")


func _ready():
    _connect_signals()
    modulate = tp_color


func _on_FootBar_mouse_entered():
    animator.interpolate_property(self, "modulate", modulate, Color.white, 0.3, Tween.TRANS_QUAD)
    animator.start()

func _on_FootBar_mouse_exited():
    animator.interpolate_property(self, "modulate", modulate, tp_color, 0.3, Tween.TRANS_QUAD)
    animator.start()

func _on_GodotNuts_pressed():
    OS.shell_open("https://github.com/GodotNuts")

func _on_developer_pressed():
    OS.shell_open("https://twitter.com/fenixhub")

func _on_About_pressed():
    get_parent().show_about()
