extends Panel

signal share_post(id, description, image, timestamp)

onready var post_image : TextureRect = $Post/PostContainer/Image
onready var post_description : Label = $Post/PostContainer/Container/Description
onready var timestamp : Label = $Post/PostContainer/Container/Timestamp
onready var header : InteractiveHeader = $Post/PostContainer/Container/Header


var user : UsersManager.User
var description : String
var image : ImageTexture

var y_limit : int = 300
var x_limit : int = 400

func _ready():
    hide()

func show_post(post : PostsManager.Post, usr : UsersManager.User):
    if not post.is_connected("update_image", self, "set_image"):
        post.connect("update_image", self, "set_image")
    set_image(post.image)
    set_description(post.description)
    set_timestamp(Utilities.get_human_time(post.timestamp))
    set_user(usr)
    show()

func set_image(img : ImageTexture):
    image = img
    if img != null:
        post_image.set_texture(image)
    
func set_description(desc : String):
    description = desc
    post_description.set_text(description)

func set_user(usr):
    user = usr
    header.load_from_user(usr)
    
func set_timestamp(time : String):
    timestamp.set_text(time)

func _on_ShowPost_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            hide()
            header.set_picture(load("res://main/res/imgs/Nuovo progetto.svg"))

