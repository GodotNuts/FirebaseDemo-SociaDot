extends CenterContainer

signal sign_in()
signal loading(is_loading)
signal show_error(error)

onready var update_username : LineEdit = $UpdateProfile/VBox/UpdateUsername
onready var update_picture : TextureRect = $UpdateProfile/VBox/UpdatePicture

var extension : String
var profile_picture : String

var task : int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
    yield(get_tree(), "idle_frame")
    $UpdateProfile.hide()
    animate_SignContainer(true)
    yield(get_tree(), "idle_frame")
#    return
    Firebase.Auth.load_auth()
    if not Firebase.Auth.auth.empty():
        Activities.loading( true)
        yield(Firebase.Auth, "token_refresh_succeeded")
        _on_SignContainer_logged(Firebase.Auth.auth)

func animate_SignContainer(show : bool):
    if show:
        $Tween.interpolate_property($SignContainer, "rect_position", Vector2($SignContainer.rect_position.x, -40), $SignContainer.rect_position, 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($SignContainer, "modulate", Color(1,1,1,0), Color(1,1,1,1), 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
    else:
        $Tween.interpolate_property($SignContainer, "rect_position", $SignContainer.rect_position, Vector2($SignContainer.rect_position.x, -40), 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($SignContainer, "modulate", Color(1,1,1,1), Color(1,1,1,0), 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
    $Tween.start()

func animate_UpdateProfile(show : bool):
    if show:
        $Tween.interpolate_property($UpdateProfile, "rect_position", 
        rect_size/2 - $UpdateProfile.rect_size/2 - Vector2(0, 40), rect_size/2 - $UpdateProfile.rect_size, 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($UpdateProfile, "modulate", Color(1,1,1,0), Color(1,1,1,1), 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
    else:
        $Tween.interpolate_property($UpdateProfile, "rect_position", 
        rect_size/2 - $UpdateProfile.rect_size, rect_size/2 - $UpdateProfile.rect_size/2 - Vector2(0, 40), 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property($UpdateProfile, "modulate", Color(1,1,1,1), Color(1,1,1,0), 0.8, Tween.TRANS_QUAD, Tween.EASE_OUT)
    $Tween.start()

func _on_SignContainer_error(message):
    Activities.show_error( message)
    Activities.loading( false)


func _on_SignContainer_logged(login):
    Firebase.Auth.save_auth(login)
    var firestore_task : FirestoreTask = Utilities.get_user(login.localid)
    var user_doc : FirestoreDocument = yield(firestore_task, "get_document")
    var picture_task : StorageTask = Utilities.get_profile_picture(user_doc.doc_name)
    yield(picture_task,"task_finished")
    var user_picture : ImageTexture = Utilities.byte2image(picture_task.data)
    Activities.loading( false)
    UserData.map_user(user_doc, user_picture)
    emit_signal("sign_in")

func _on_SignContainer_signed(signup):
    Firebase.Auth.save_auth(signup)
    UserData.user_id = signup.localid
    UserData.user_email = signup.email
    var user_task : FirestoreTask = Utilities.add_user(UserData.user_id, UserData.user_email)
    yield(user_task, "add_document")
    Activities.loading( false)
    animate_SignContainer(false)
    animate_UpdateProfile(true)
    $UpdateProfile.show()


func _on_error(code, status, message):
    Activities.show_error( message)
    Activities.loading( false)


func _on_CameraIcon_pressed():
    $ChosePicture.popup()


func _on_ChosePicture_file_selected(path):
    profile_picture = path
    extension = path.get_extension()
    var texture : ImageTexture = ImageTexture.new()
    texture.load(path)
    update_picture.texture = texture
    UserData.user_picture = texture


func _on_ConfirmBtn_pressed():
    if update_picture.texture != null and not update_username.get_text() in [""," "]:
        Activities.loading( true)
        UserData.user_name = update_username.get_text()
        var update_task : FirestoreTask = Utilities.update_user()
        yield(update_task, "update_document" )
        var put_file : StorageTask = Utilities.update_user_picture(profile_picture)
        yield(put_file, "task_finished")
        animate_UpdateProfile(false)
        Activities.loading( false)
        emit_signal("sign_in")

func _on_SignContainer_logging():
    Activities.loading( true)


