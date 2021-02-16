tool
extends RichTextEffect

var bbcode : String = "jump"
var freq = 8.0
var amp = 8.0

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
    var sined_time =  max(0, sin(pow(char_fx.absolute_index,5)+char_fx.elapsed_time * freq) )
    var y_off = sined_time * amp
    char_fx.offset = Vector2(0, -50 - y_off)
    return true
