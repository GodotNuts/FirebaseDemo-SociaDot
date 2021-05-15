extends Panel

onready var post_image : TextureRect = $Post/PostContainer/Image
onready var post_description : RichTextLabel = $Post/PostContainer/Content/Container/Description
onready var timestamp : Label = $Post/PostContainer/Content/Container/Header/Timestamp
onready var header : InteractiveHeader = $Post/PostContainer/Content/Container/Header
onready var comments_container : ScrollContainer = $Post/PostContainer/Content/Container/CommentsContainer
onready var comments_list : VBoxContainer = comments_container.get_node("CommentsList")
onready var comment_container : HBoxContainer = $Post/PostContainer/Content/Container/NewCommentContainer
onready var comment : LineEdit = comment_container.get_node("Comment")


onready var like_btn : Button = $Post/PostContainer/Content/Container/ActionButtons/LikeBtn
onready var comments_btn : Button = $Post/PostContainer/Content/Container/ActionButtons/CommentsBtn

var id : String
var post : PostsManager.Post
var user : UsersManager.User
var description : String
var image : ImageTexture
var likes : Array
var comments : Dictionary

var db_reference : FirebaseDatabaseReference

var y_limit : int = 300
var x_limit : int = 400

func _connect_signals():
    connect("gui_input", self, "_on_ShowPost_gui_input")
    comment.connect("text_entered", self , "_on_comment_entered")
    like_btn.connect("pressed", self, "_on_like_pressed")
    comments_btn.connect("pressed", self, "_on_comment_pressed")

func _ready():
    _connect_signals()
    hide()

func show_post(post : PostsManager.Post, usr : UsersManager.User):
    if not post.is_connected("update_image", self, "set_image"):
        post.connect("update_image", self, "set_image")
    set_user(usr)
    set_post(post)
    set_id(post.id)
    set_image(post.image)
    set_description(post.description)
    set_timestamp(Utilities.get_human_time(post.timestamp))
    show()

func set_id(_id : String):
    id = _id
    db_reference = Firebase.Database.get_database_reference("sociadot/posts/"+id)
    db_reference.connect("new_data_update", self, "_on_db_data")
    db_reference.connect("patch_data_update", self, "_on_db_data")

func set_image(img : ImageTexture):
    image = img
    if image == null:
        return
    post_image.material = null
    post_image.set_texture(image)
    var stretch_mode : int
    var expand : bool
    if img.get_size().x >= post_image.get_rect().size.x or img.get_size().y >= post_image.get_rect().size.y :
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        expand = true
    else:
        stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
        expand = false
    post_image.stretch_mode = stretch_mode
    post_image.expand = expand
    
func set_description(desc : String):
    description = desc
    if desc == "":
        post_description.hide()
    post_description.set_bbcode(Utilities.parse_content(description))

func set_user(usr):
    user = usr
    header.load_from_user(usr)
    
func set_post(_post):
    post = _post

func set_timestamp(time : String):
    timestamp.set_text(time)

func set_likes(_likes : Array):
    post.likes = _likes
    like_btn.set_text(post.likes.size() as String)
    like_btn.activated = post.likes.has(UserData.user_id)

func add_comment(_comment : Dictionary):
    var comment_container : CommentContainer = Activities.comment_container.instance()
    comments_list.add_child(comment_container)
    comment_container.build_comment(_comment.user, _comment.username, _comment.content)
    comments_container.scroll_vertical = comments_container.get_v_scrollbar().max_value

func set_comments(_comments : Dictionary):
    for _comment in _comments.keys():
        var dict : Dictionary
        dict[_comment] = _comments.get(_comment)
        post.add_comment(dict)
        add_comment(_comments[_comment])
    comments_btn.set_text(post.comments.size() as String)
    for _comment in post.comments:
        if _comment.values()[0].user == UserData.user_id:
            comments_btn.set_activated(true)

func _on_comment_entered(_comment : String) -> void:
    RequestsManager.add_post_comment({user = UserData.user_id, username = UserData.user_name, content = _comment}, 
    Firebase.Database.get_database_reference("sociadot/posts/"+id+"/comments"))
    comment.clear()
    

func _on_like_pressed() -> void:
    if post.add_like(UserData.user_id):
        var love_particle : CPUParticles2D = Activities.love_particle_scene.instance()
        love_particle.add_to_control(like_btn)
    RequestsManager.update_post_likes(post.likes, db_reference)


func _on_db_data(resource : FirebaseResource):
    match resource.key:
        "likes":
            set_likes(resource.data)
        "comments":
            set_comments(resource.data)
        ""," ":
            if resource.data.has("comments"):
                set_comments(resource.data.comments if resource.data.comments != null else [])
            elif resource.data.has("likes"):
                set_likes(resource.data.likes if resource.data.likes != null else [])
        var sub_index :
            if sub_index.begins_with("comments/"):
                var comment : Dictionary
                comment[sub_index.lstrip("comments/")] = resource.data
                set_comments(comment)

func _on_comment_pressed() -> void:
    comment_container.visible = not comment_container.visible

func _on_ShowPost_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            hide()
            header.set_picture(load("res://main/res/imgs/avatar.svg"))
            db_reference.disconnect("new_data_update", self, "_on_db_data")
            db_reference.disconnect("patch_data_update", self, "_on_db_data")
            clear_comments()
            clear_likes()

func clear_likes():
    like_btn.set_text(str(0))

func clear_comments():
    comments_btn.set_text(str(0))
    for comment in comments_list.get_children():
        comment.queue_free()

