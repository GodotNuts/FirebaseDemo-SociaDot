extends VBoxContainer

signal show_user_profile(user_id, user_name)

var user_header_scene : PackedScene = preload("res://main/scn/header/interactive/interactive_header.tscn")

onready var list_container : VBoxContainer = $ScrollUsers/UsersList

var users_list : Array

# Called when the node enters the scene tree for the first time.
func _ready():
#    load_users_list()
    pass

func load_users_list():
    list_container.hide()
    var all_users_task : FirestoreTask = RequestsManager.get_all_users()
    var list : Array = yield(all_users_task, "listed_documents")
    for user_document in list:
        if user_document.doc_name == UserData.user_id:
            continue
        if user_document.doc_name in users_list:
            continue
        if UsersManager.has_user(user_document.doc_name):
            var user_header : InteractiveHeader = user_header_scene.instance()
            user_header.load_from_user(UsersManager.get_user_by_id(user_document.doc_name))
            list_container.add_child(user_header)
            user_header.connect("show_user_profile", self, "_on_show_user_profile")
        else:
            var user_obj : UsersManager.User = UsersManager.add_user_doc(user_document.doc_name, user_document, RequestsManager.get_profile_picture(user_document.doc_name))
            var user_header : InteractiveHeader = user_header_scene.instance()
            user_header.load_from_user(user_obj)
            list_container.add_child(user_header)
            user_header.connect("show_user_profile", self, "_on_show_user_profile")
        users_list.append(user_document.doc_name)
    list_container.show()

func _on_show_user_profile(user_id : String, user_name : String):
    emit_signal("show_user_profile", user_id, user_name)


