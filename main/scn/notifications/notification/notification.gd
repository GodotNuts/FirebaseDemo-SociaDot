extends PanelContainer
class_name Notification

signal header_pressed(user_id, user_name)
signal show_post(post)
signal show_post_comment(post, comment_id)

export (Dictionary) var actions : Dictionary = {}

onready var content_lbl : Label = $Container/Header/Content
onready var icon : TextureRect = $Container/Icon
onready var user_header : HBoxContainer = $Container/Header/UserHeader
onready var go_to : ToolButton = $Container/GoTo

var id : String
var user_id : String
var action : String
var viewed : bool       setget set_viewed
var source : Dictionary

func _connect_signals() -> void:
    user_header.connect("pressed", self, "_on_header_pressed")
    go_to.connect("pressed", self, "goto_pressed")

func _ready() -> void:
    hide()
    _connect_signals()

func load_notification(resource : FirebaseResource) -> void:
    self.id = resource.key
    self.user_id = resource.data.user
    self.action = resource.data.action
    if resource.data.has("source"):
        self.source = resource.data.source
        go_to.show()
    set_viewed(resource.data.viewed)
    var user : UsersManager.User = UsersManager.get_user_by_id(user_id)
    if user == null:
        user = UsersManager.add_user(user_id, RequestsManager.get_user(user_id), RequestsManager.get_profile_picture(user_id))
    user_header.load_from_user(user)
    icon.set_texture(actions[action])
    content_lbl.set_text(action2content(action))
    show()

func set_viewed(v : bool) -> void:
    viewed = v
    $Container/Notification.visible = not viewed
    modulate.a = 1 - (int(viewed) - 0.7)

func action2content(action : String) -> String:
    match action:
        "connect":
            icon.modulate = Color.royalblue
            return "Wants to connect with you!"
        "comment":
            icon.modulate = Color.cadetblue
            return "Commented your post!"
        "like":
            icon.modulate = Color.mediumvioletred
            return "Liked your post!"
        _:
            return ""

func _on_header_pressed(user_id : String, user_name : String):
    emit_signal("header_pressed", user_id, user_name)

func goto_pressed():
    match action:
        "like":
            var post : PostsManager.Post = PostsManager.get_post_by_id(source.post_id)
            if post == null:
                post = PostsManager.add_post_from_doc(source.post_id, yield(RequestsManager.get_post_doc(source.post_id), "get_document"))
            emit_signal("show_post", post)
        "comment":
            emit_signal("show_post_comment", source.post_id, source.comment_id)
