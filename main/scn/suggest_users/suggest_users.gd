extends PanelContainer

signal show_user_profile(user_id, user)

var user_id : String
var user_name : String
var user_picture : ImageTexture

# Called when the node enters the scene tree for the first time.
func _ready():
    pass


func suggest_user(user : String):
    var query : FirestoreTask = Utilities.get_user_by_username(user)
    var result : Array = yield(query, "query_result")
    if result[0].has("error"):
        Activities.show_error(JSON.print(result[0].error))
    else:
        for user in result:
            var user_doc : FirestoreDocument = FirestoreDocument.new(user.document)
            self.user_id = user_doc.doc_name
            self.user_name = user_doc.doc_fields.username
            self.user_picture = PostsManager.has_post_creator(user_doc.doc_name)
            if user_picture != null:
                $UsersBox/UserHeader/Picture.set_texture(user_picture)
            else:
                var profile_task : StorageTask = Utilities.get_profile_picture(user_doc.doc_name)
                PostsManager.add_profile(profile_task)
                yield(profile_task, "task_finished")
                if typeof(profile_task.data) != TYPE_RAW_ARRAY:
                    print(profile_task.data)
                $UsersBox/UserHeader/Picture.set_texture(Utilities.byte2image(profile_task.data))
            $UsersBox/UserHeader/Name.set_text(user_name)
            check_friend(user_id)

func check_friend(user_id : String):
    get_node("UsersBox/UserHeader/ConnecBtn").visible = not (user_id == UserData.user_id)
    get_node("UsersBox/UserHeader/ConnecBtn").activated = (user_id in UserData.friend_list)
    get_node("UsersBox/UserHeader/ConnecBtn").set_text("Connected" if (user_id in UserData.friend_list) else "Conect")
    self.user_id = user_id

func _on_Name_pressed():
    emit_signal("show_user_profile", user_id, user_name)


func _on_ConnecBtn_pressed():
    Utilities.update_friend_list(user_id)
    check_friend(user_id)
