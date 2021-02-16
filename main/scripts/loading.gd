extends Control

var front : bool = false

func set_loading(is_loading : bool):
    visible = is_loading
    if is_loading:
        $Timer.start()
    else:
        $Timer.stop()
        $Tween.stop_all()
        front = false



func _on_Timer_timeout():
    front = not front
    if front:
        $Tween.interpolate_property($Logo, "rect_scale", Vector2(.7, .7), Vector2(1, 1), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($Logo, "modulate", Color(1,1,1,0.2), Color(1,1,1,1), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($Logo, "rect_rotation", 0, 180, 0.7, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
    else:
        $Tween.interpolate_property($Logo, "rect_scale", Vector2(1, 1), Vector2(.7, .7), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($Logo, "modulate", Color(1,1,1,1), Color(1,1,1,0.2), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($Logo, "rect_rotation", 180, 360, 0.7, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
    $Tween.start()
