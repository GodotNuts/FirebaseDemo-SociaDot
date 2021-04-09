extends HBoxContainer

var user_name : String
var user_picture : ImageTexture

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

func load_main_user():
    UserData.connect("update_user_name", self, "set_user_name")
    UserData.connect("update_user_picture", self, "set_picture")
    set_user_name(UserData.user_name)
    set_picture(UserData.user_picture)

func load_from_user(user_obj : UsersManager.User):
    if not user_obj.is_connected("update_document", self, "load_from_document"):
        user_obj.connect("update_document", self, "load_from_document")
    if not user_obj.is_connected("update_picture", self, "set_picture"):
        user_obj.connect("update_picture", self, "set_picture")
    set_picture(user_obj.picture)
    set_user_name(user_obj.username)

func load_from_document(document : FirestoreDocument):
    set_user_name(document.doc_fields.username)

func set_picture(picture : ImageTexture):
    user_picture = picture
    if picture == null:
        return
    $Picture.set_texture(picture)
    
func set_user_name(_name : String):
    user_name = _name
    $Name.set_text(_name)
