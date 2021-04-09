extends VBoxContainer
class_name Settings

onready var id_edit : LineEdit = $ScrollSettings/SettingsList/Profile/Id/IdEdit
onready var email_edit : LineEdit = $ScrollSettings/SettingsList/Profile/Email/EmailEdit
onready var name_edit : LineEdit = $ScrollSettings/SettingsList/Profile/Name/NameEdit
onready var avatar_texture : TextureRect = $ScrollSettings/SettingsList/Profile/Avatar/UpdatePicture

var profile_picture : String = ""

func _connect_signals() -> void:
    $ScrollSettings/SettingsList/Profile/Avatar/UpdatePicture/CameraIcon.connect("pressed", self, "_on_chose_pressed")
    $ScrollSettings/SettingsList/Profile/ChosePicture.connect("file_selected", self, "_on_file_selected")
    $ScrollSettings/SettingsList/SaveSettingsBtn.connect("pressed", self, "_on_save_settings")

func _ready() -> void:
    _connect_signals()
    load_user_data()

func load_user_data():
    profile_picture = ""
    id_edit.set_text(UserData.user_id)
    email_edit.set_text(UserData.user_email)
    name_edit.set_text(UserData.user_name)
    avatar_texture.set_texture(UserData.user_picture)

func _on_chose_pressed():
    $ScrollSettings/SettingsList/Profile/ChosePicture.popup()

func _on_file_selected(path : String):
    profile_picture = path
    var texture : ImageTexture = ImageTexture.new()
    texture.load(path)
    avatar_texture.texture = texture

func _on_save_settings():
    Activities.loading(true)
    if name_edit.get_text() != UserData.user_name:
        UserData.user_name = name_edit.get_text()
        var new_doc : FirestoreDocument = yield(RequestsManager.update_user(), "update_document")
        UsersManager.update_user(UserData.user_id, new_doc)
    if profile_picture != "":
        UserData.user_picture = avatar_texture.texture
        yield(RequestsManager.update_user_picture(profile_picture), "task_finished")
        UsersManager.update_user(UserData.user_id, null, avatar_texture.texture)
    profile_picture = ""
    Activities.loading(false)
        
