extends Control

const version : String = "1.5"

onready var activities : Control = $Main/Activities
onready var topbar : HBoxContainer = $TopBar
onready var footbar : HBoxContainer = $FootBar
onready var loading : Control = $Main/Loading
onready var error_lbl : Label = $Main/ERROR

onready var user_id_lbl : Label = $Main/AppInfo/UserId
onready var version_lbl : Label = $Main/AppInfo/Version

onready var animator : Tween = $Main/Tween

onready var about : PanelContainer = $Main/AboutPage

func _title():
	OS.set_window_title("socia.dot v%s"%version)
	$TopBar/Name.set_text("socia.dot")
	version_lbl.set_text("v%s"%version)
	about.hide()

func _ready():
	_title()
	_connect_signals()
	match OS.get_name():
		"Android", "iOS":
			for child in topbar.get_children():
				if child is Control: child.hide()
		"HTML5":
			topbar.hide()
			get_parent().rect_position = Vector2(0,0)
			get_parent().rect_size = OS.window_size
			get_parent().rect_clip_content = true
		_:
			get_tree().get_root().set_transparent_background(true)
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
	animator.stop_all()
	error_lbl.set_size(Vector2())
	error_lbl.set_text(error)
	animator.interpolate_property(error_lbl, "rect_position", 
	Vector2(rect_size.x/2 - error_lbl.rect_size.x/2, rect_size.y + 10), 
	Vector2(rect_size.x/2 - error_lbl.rect_size.x/2, rect_size.y - $Main.rect_position.y - error_lbl.rect_size.y - 20), 
	0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	animator.start()
	yield(get_tree().create_timer(5), "timeout")
	animator.interpolate_property(error_lbl, "rect_position", 
	error_lbl.rect_position, 
	Vector2(rect_size.x/2 - error_lbl.rect_size.x/2, rect_size.y + 10), 
	0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	animator.start()


func show_about():
	about.show()

# ..... top bar signals
func _on_TopBar_close():
	if UserData.is_logged:
		UserData.is_logged = false
		UserData.last_logged = OS.get_datetime()
		loading.set_loading(true)
		yield(RequestsManager.update_user(), "task_finished")
	get_tree().quit()

func _on_TopBar_minimize():
	OS.set_window_minimized(not OS.is_window_minimized())

func _on_TopBar_resize():
	if OS.get_window_size().x <= 1024:
		get_tree().get_root().set_transparent_background(false)
		get_parent().rect_position = Vector2(0,0)
		OS.set_window_position(Vector2.ZERO)
		get_parent().rect_size+=Vector2(8,8)*2
		OS.set_window_size(OS.get_screen_size(0) - Vector2(0, 50))
	else:
		get_tree().get_root().set_transparent_background(true)
		get_parent().rect_position = Vector2(8,8)
		OS.set_window_position(OS.get_screen_size(0)/2 - OS.get_window_size()/2)        
		get_parent().rect_size-=Vector2(8,8)*2
		OS.set_window_size(Vector2(1024, 600))

func _on_TopBar_moving_from_pos(event_pos : Vector2, offset : Vector2):
	if OS.get_window_size().x > 1024:
		_on_TopBar_resize()
	OS.set_window_position(OS.get_window_position() + event_pos - offset)
