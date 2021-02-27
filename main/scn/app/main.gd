extends Control

const version : String = "0.1"

onready var activities : Control = $Main/Activities
onready var topbar : HBoxContainer = $TopBar
onready var loading : Control = $Main/Loading
onready var error_lbl : Label = $Main/ERROR

onready var user_id_lbl : Label = $Main/AppInfo/UserId
onready var version_lbl : Label = $Main/AppInfo/Version

onready var animator : Tween = $Main/Tween

func _title():
    OS.set_window_title("socia.dot v%s"%version)
    $TopBar/Name.set_text("socia.dot")
    version_lbl.set_text("v%s"%version)

func _ready():
    _title()
    _connect_signals()
    get_tree().get_root().set_transparent_background(true)
    if OS.get_name() in ["Android", "iOS"]:
        for child in topbar.get_children():
            if child is Control: child.hide()
    if OS.get_name() in ["HTML5"]:
        topbar.hide()
    loading.set_loading(false)
    Activities.signin = Activities.signin_scene.instance()
    activities.add_child(Activities.signin)
    Activities.signin.connect("sign_in", self, "_on_signin_completed")
    Activities.connect("loading", loading, "set_loading")
    Activities.connect("show_error", self, "_on_show_error")

func _connect_signals():
    topbar.connect("close", self, "_on_TopBar_close",[],CONNECT_DEFERRED)
    topbar.connect("minimize", self, "_on_TopBar_minimize",[],CONNECT_DEFERRED)
    topbar.connect("resize", self, "_on_TopBar_resize",[],CONNECT_DEFERRED)
    topbar.connect("moving_from_pos", self, "_on_TopBar_moving_from_pos",[],CONNECT_DEFERRED)

func _on_signin_completed():
    user_id_lbl.set_text(UserData.user_id)
    Activities.signin.hide()
    loading.set_loading(false)
    Activities.home = Activities.home_scene.instance()
    activities.add_child(Activities.home)

func _on_show_error(error : String):
    error_lbl.set_text(error)
    error_lbl.rect_size = error_lbl.rect_min_size
    animator.interpolate_property(error_lbl, "rect_position", 
    Vector2(rect_size.x/2 - error_lbl.rect_size.x/2, rect_size.y + 10), 
    Vector2(rect_size.x/2 - error_lbl.rect_size.x/2, rect_size.y - error_lbl.rect_size.y - 50), 
    0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
    animator.start()
    yield(get_tree().create_timer(8), "timeout")
    animator.interpolate_property(error_lbl, "rect_position", 
    error_lbl.rect_position, 
    Vector2(rect_size.x/2 - error_lbl.rect_size.x/2, rect_size.y + 10), 
    0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
    animator.start()

# ..... top bar signals
func _on_TopBar_close():
    get_tree().quit()

func _on_TopBar_minimize():
    OS.set_window_minimized(not OS.is_window_minimized())

func _on_TopBar_resize():
    if OS.get_window_size().x <= 1024:
        OS.set_window_size(OS.get_screen_size(0) - Vector2(0, 50))
        OS.set_window_position(Vector2.ZERO)
    else:
        OS.set_window_size(Vector2(1024, 600))
        OS.set_window_position(OS.get_screen_size(0)/2 - OS.get_window_size()/2)        

func _on_TopBar_moving_from_pos(event_pos : Vector2, offset : Vector2):
    if OS.get_window_size().x > 1024:
        OS.set_window_size(Vector2(1024, 600))
    OS.set_window_position(OS.get_window_position() + event_pos - offset)
