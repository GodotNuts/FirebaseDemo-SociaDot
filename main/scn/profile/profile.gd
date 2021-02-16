extends VBoxContainer

signal connected(document, button)
signal disconnect(document)

onready var post_container_box : VBoxContainer = $ScrollPost/PostContainer

var user_id : String
var user : UsersManager.User

func _ready():
    connect("connected", Activities.home, "_on_new_connection")
    connect("disconnect", Activities.home, "_on_removed_connection")

func load_profile(_id : String, user_name : String):
    if UsersManager.has_user(_id): 
        var user : UsersManager.User = UsersManager.get_user_by_id(_id)
        self.user = user
        user.connect("update_picture", self, "set_user_avatar")
        set_user_avatar(user.picture)
        set_user_name(user.username)
        var result = yield(Utilities.get_user_posts(user.id), "task_finished")
        if typeof(result) == TYPE_ARRAY:
            load_user_posts(result)
    else:
        var user_obj : UsersManager.User = UsersManager.add_user(UserData.user_id, Utilities.get_user(UserData.user_id), null)
        user_obj.picture = UserData.user_picture 
        self.user = user_obj
        set_user_avatar(user_obj.picture)
        set_user_name(UserData.user_name)
        var result = yield(Utilities.get_user_posts(UserData.user_id), "task_finished")
        if typeof(result) == TYPE_ARRAY:
            load_user_posts(result)
    check_friend(_id)
    show()

func check_friend(user_id : String) -> bool:
    get_node("Header/ConnecBtn").visible = not (user_id == UserData.user_id)
    get_node("Header/ConnecBtn").activated = (user_id in UserData.friend_list)
    get_node("Header/ConnecBtn").set_text("Connected" if (user_id in UserData.friend_list) else "Conect")
    self.user_id = user_id
    return (user_id in UserData.friend_list)

func set_user_avatar(avatar : ImageTexture):
    if avatar == null:
        return
    get_node("Header/Picture").set_texture(avatar)

func set_user_name(user_name : String):
    get_node("Header/Name").set_text(user_name)


func load_user_posts(user_posts : Array):
    $ScrollPost.hide()
    for post in post_container_box.get_children():
        post.queue_free()
    for post in user_posts:
        if not post.has("document"):
            continue
        var post_info : FirestoreDocument = FirestoreDocument.new(post.document)
        if PostsManager.has_post(post_info.doc_name):
            if PostsManager.has_post_container(post_info.doc_name):
                post_container_box.add_child(PostsManager.get_post_container_by_id(post_info.doc_name).duplicate())
            else:
                var post_container : PostContainer = Activities.post_container_scene.instance()
                post_container.load_post(PostsManager.add_post_from_doc(post_info.doc_name, post_info))
                post_container_box.add_child(post_container)
        else:
            var post_obj : PostsManager.Post = PostsManager.add_post_from_doc(
                post_info.doc_name, 
                post_info,
                Utilities.get_post_image(post_info.doc_fields.user_id, post_info.doc_name, post_info.doc_fields.image))
            var post_container : PostContainer = Activities.post_container_scene.instance()
            post_container.load_post(post_obj)
            post_container_box.add_child(post_container)
    $ScrollPost.show()

func _on_ConnecBtn_pressed():
    var update_task :FirestoreTask = Utilities.update_friend_list(user_id)
    yield(update_task, "update_document")
    if check_friend(user_id):
        emit_signal("connected", user, $Header/ConnecBtn)
    else:
        emit_signal("disconnect", user)


func _on_Profile_visibility_changed():
    if not visible :
        user_id = ""
