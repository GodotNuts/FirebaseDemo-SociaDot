extends PanelContainer


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    $VBoxContainer/RichTextLabel.connect("meta_clicked", self, "_on_meta_clicked")
    $VBoxContainer/HBoxContainer/BackBtn.connect("pressed", self, "hide")

func _on_meta_clicked(meta : String):
    OS.shell_open(meta)
