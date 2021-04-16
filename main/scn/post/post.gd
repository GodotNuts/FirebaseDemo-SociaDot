class_name PostContainer
extends PanelContainer

signal open_post(post)
signal show_user_profile(user_id, user_name)

onready var post_image : TextureRect = $PostContainer/Image
onready var comments_container : PanelContainer = $PostContainer/Container
onready var comments_btn : Button = $PostContainer/ActionButtons/CommentsBtn
onready var comments_list : VBoxContainer = $PostContainer/Container/CommentsContainer/CommentsList
onready var menu_popup : PopupMenu = $PostContainer/Header/Menu.get_popup()

var id : String                     setget set_post_id      # generated by firestore
var user_name : String              setget set_user_name         # user name
var user_id : String                setget set_user_id      # user id (localid)
var user_picture : ImageTexture     setget set_user_picture
var description : String            setget set_description  # description
var image : ImageTexture            setget set_image        # id + extension
var timestamp : int                 setget set_timestamp
var likes : Array = []              setget set_likes
var comments : int
var post : PostsManager.Post        setget set_post
var user : UsersManager.User        

var db_reference : FirebaseDatabaseReference

func _connect_signals():
    post_image.connect("gui_input", self, "_on_Image_gui_input")
    $PostContainer/Header/Username.connect("pressed", self, "_on_Username_pressed")
    $PostContainer/ActionButtons/LikeBtn.connect("pressed", self, "_on_LikeBtn_pressed")
    comments_btn.connect("pressed", self, "_on_CommentsBtn_pressed")
    connect("open_post", Activities.home, "_on_open_post")
    $PostContainer/Container/CommentsContainer/LoadOtherComments.connect("pressed", self, "_on_load_other_comments")
    $PostContainer/Container/CommentsContainer/Comment/CommentText.connect("text_entered", self, "_on_text_entered")
    menu_popup.connect("id_pressed", self, "_on_id_pressed")
    

func _ready():
    _connect_signals()
    $PostContainer/Container/CommentsContainer/Comment/Avatar.set_texture(UserData.user_picture)

func set_post(p) -> void:
    post = p
    post.connect("update_image", self, "set_image")

func load_post(post : PostsManager.Post) -> void:
    set_post(post)
    set_post_id(post.id)
    set_user_id(post.user_id)
    set_user_picture(user.picture)
    set_user_name(post.user)
    set_description(post.description)
    set_timestamp(post.timestamp)
    set_menu(post.user_id)
    if post.image_name == "":
        set_image(null)
    else:
        if post.image != null:
            set_image(post.image)
    
    if not PostsManager.has_post_container(post.id):
        PostsManager.add_post_scene(self)


func set_menu(user : String) -> void:
    if user == UserData.user_id:
        menu_popup.add_icon_item(load("res://main/res/icons/delete_outline_white_24dp.svg"), "Delete", 0)

func set_post_id(p : String):
    id = p
    name = p
    db_reference = Firebase.Database.get_database_reference("sociadot/posts/"+p)
    db_reference.connect("new_data_update", self, "_on_db_data")
    db_reference.connect("patch_data_update", self, "_on_db_data")

func set_user_id(id : String):
    user_id = id
    if UsersManager.has_user(user_id):
        user = UsersManager.get_user_by_id(user_id)
    else:
        RequestsManager.get_user(user_id)
        user = UsersManager.add_user(user_id, RequestsManager.get_user(user_id), RequestsManager.get_profile_picture(user_id))
    user.connect("update_picture", self, "set_user_picture")
    user.connect("update_user", self, "_on_update_user")
    

func _on_update_user(user : UsersManager.User) -> void:
    set_user_name(user.username)

# Load user picture from a StorageTask
func load_user_image(user_id : String):
    set_user_picture(user.picture)

# Load post image from Storage
func load_image(img : String):
    var img_tex : ImageTexture
    var image_task : StorageTask = RequestsManager.get_post_image(user_id, id, img)
    yield(image_task, "task_finished")
    img_tex = Utilities.task2image(image_task)
    set_image(img_tex)

func set_likes(l : Array):
    likes = l
    $PostContainer/ActionButtons/LikeBtn.set_text(likes.size() as String)
    $PostContainer/ActionButtons/LikeBtn.activated = likes.has(UserData.user_id)

func set_comments(_comments : Dictionary):
    for _comment in _comments.keys():
        var dict : Dictionary
        dict[_comment] = _comments.get(_comment)
        post.add_comment(dict)
    comments_btn.set_text(post.comments.size() as String)
    for _comment in post.comments:
        if _comment.values()[0].user == UserData.user_id:
            comments_btn.set_activated(true)


func set_user_picture(picture : ImageTexture):
    user_picture = picture
    if picture == null:
        return
    $PostContainer/Header/Avatar.set_normal_texture(picture)
    $PostContainer/Header.show()

func set_user_name(u : String):
    user_name = u
    $PostContainer/Header/Username.set_text(user_name)

func set_description(d : String):
    description = d
    $PostContainer/Text.set_bbcode(Utilities.parse_content(description))
    $PostContainer/Text.show()


func set_image(img : ImageTexture):
    if not post_image:
        return
    image = img
    if img == null:
        post_image.material = null
        post_image.hide()
        return
    else:
        post_image.show()
    post_image.set_texture(img)
    if img.get_size().y < 100:
        post_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    else :
        post_image.rect_min_size.y = 300
        post_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    post_image.material = null

func set_timestamp(t : int):
    timestamp = t
    $PostContainer/Header/Timestamp.set_text(Utilities.get_human_time(t))

func _on_LikeBtn_pressed():
    if likes.has(UserData.user_id):
        likes.erase(UserData.user_id)
    else:
        likes.append(UserData.user_id)
        var love_particle : CPUParticles2D = Activities.love_particle_scene.instance()
        love_particle.add_to_control($PostContainer/ActionButtons/LikeBtn)
        RequestsManager.send_notification(UserData.user_id, user_id, "like", {post_id = id})
    RequestsManager.update_post_likes(likes, db_reference)


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


func _on_Username_pressed():
    emit_signal("show_user_profile", user_id, user_name)

func _on_CommentsBtn_pressed():
    comments_container.visible = not comments_container.visible
    if comments_container.visible:
        if comments_list.get_child_count() == 0 and not post.comments.empty():
            add_comment(post.comments[0].values()[0])

func add_comment(_comment : Dictionary):
    var comment : CommentContainer = Activities.comment_container.instance()
    comments_list.add_child(comment)
    comment.load_comment(_comment)
    return comment

func _on_load_other_comments():
    comments += 1
    if comments < post.comments.size():
        add_comment(post.comments[comments].values()[0])
    else:
        $PostContainer/Container/CommentsContainer/LoadOtherComments.hide()

func _on_text_entered(_comment : String):
    RequestsManager.add_post_comment({user = UserData.user_id, username = UserData.user_name, content = _comment}, 
    Firebase.Database.get_database_reference("sociadot/posts/"+id+"/comments"))
    $PostContainer/Container/CommentsContainer/Comment/CommentText.clear()
    var comment : CommentContainer =add_comment({user = UserData.user_id, username = UserData.user_name, content = _comment})
    comments_list.move_child(comment, 0)

func _on_Image_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            emit_signal("open_post", post)

func _on_id_pressed(id : int):
    match id:
        0:
            var result = yield(RequestsManager.delete_post(self.id), "delete_document")
            result = yield(RequestsManager.delete_post_image(self.user_id, self.id), "task_finished")
            PostsManager.remove_post(self.id)
