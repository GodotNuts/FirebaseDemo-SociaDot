class_name InteractiveHeader
extends HBoxContainer

signal show_user_profile(user_id, user_name)
signal connected(document, button)
signal disconnect(document)

var user : UsersManager.User
var user_id : String
var user_name : String
var user_picture : ImageTexture
var user_document : FirestoreDocument

func _connect_signals():
    connect("connected", Activities.home, "_on_new_connection")
    connect("disconnect", Activities.home, "_on_removed_connection")
    connect("show_user_profile", Activities.home, "_on_show_user_profile")
    $Name.connect("pressed", self, "_on_Name_pressed")
    $ConnecBtn.connect("pressed", self, "_on_ConnecBtn_pressed")

# Called when the node enters the scene tree for the first time.
func _ready():
    _connect_signals()

func load_from_user(user_obj : UsersManager.User):
    user = user_obj
    user_document = user_obj.document
    if not user_obj.is_connected("update_picture", self, "set_picture"):
        user_obj.connect("update_picture", self, "set_picture")
    set_picture(user_obj.picture)
    set_user_name(user_obj.username)
    check_friend(user_obj.id)

func load_from_document(document : FirestoreDocument):
    user_document = document
    set_user_name(document.doc_fields.username)
    check_friend(document.doc_name)

func set_picture(picture : ImageTexture):
    user_picture = picture
    if picture == null:
        return
    $Picture.set_texture(picture)
    
func set_user_name(_name : String):
    user_name = _name
    $Name.set_text(_name)

func check_friend(user_id : String) -> bool:
    self.user_id = user_id
    $ConnecBtn.visible = not (user_id == UserData.user_id)
    $ConnecBtn.activated = (user_id in UserData.friend_list)
    $ConnecBtn.set_text("Connected" if (user_id in UserData.friend_list) else "Conect")
    return (user_id in UserData.friend_list)

func _on_ConnecBtn_pressed():
    var friend_task : FirestoreTask = RequestsManager.update_friend_list(user_id)
    yield(friend_task, "update_document")
    if check_friend(user_id):
        emit_signal("connected", user, $ConnecBtn)
    else:
        emit_signal("disconnect", user)


func _on_Name_pressed():
    emit_signal("show_user_profile", user_id, user_name)
