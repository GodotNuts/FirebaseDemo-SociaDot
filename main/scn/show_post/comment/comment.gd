class_name CommentContainer
extends HBoxContainer

onready var avatar : TextureRect = $Avatar
onready var username : LinkButton = $ContentContainer/Box/Username
onready var content : RichTextLabel = $ContentContainer/Box/Content

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass

func build_comment(user_id : String, _username : String, comment : String):
    content.set_bbcode(Utilities.parse_content(comment))
    username.set_text(_username)
    if UsersManager.has_user(user_id):
        var user : UsersManager.User = UsersManager.get_user_by_id(user_id)
        avatar.set_texture(user.picture)
        user.connect("update_picture", self, "set_avatar")
    else:
        var user : UsersManager.User = UsersManager.add_user(user_id,
        RequestsManager.get_user(user_id),
        RequestsManager.get_profile_picture(user_id))
        user.connect("update_picture", self, "set_avatar")
        set_avatar(user.picture)

func load_comment(comment : Dictionary):
    build_comment(comment.user, comment.username, comment.content)

func set_avatar(image : ImageTexture):
    avatar.set_texture(image)
