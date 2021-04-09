extends VBoxContainer


onready var list : VBoxContainer = $FriendList/List

var friend_button_scene : PackedScene = preload("res://main/scn/friend_button/friend_button.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
    pass

func load_friend_list():
    list.hide()
    for friend in list.get_children():
        friend.queue_free()
    for friend in UserData.friend_list:
        if UsersManager.has_user(friend):
            add_friend(UsersManager.get_user_by_id(friend))
        else:
            var user_friend : UsersManager.User = UsersManager.add_user(
                friend, 
                RequestsManager.get_user(friend), 
                RequestsManager.get_profile_picture(friend))
            add_friend(user_friend)
    list.show()

func add_friend(friend : UsersManager.User):
    var friend_button : FriendButton = friend_button_scene.instance()
    list.add_child(friend_button)
    friend_button.load_friend_from_obj(friend)

func remove_friend(friend_obj : UsersManager.User):
    for friend in list.get_children():
        if friend.friend_id == friend_obj.id:
            ChatsManager.remove_chat(friend.friend_id)
            friend.queue_free()
            return


func _on_message_received(on_chat : ChatNode):
    for friend_button in list.get_children():
        if friend_button.friend_id == on_chat.user_id:
            friend_button.set_received_messages(on_chat.received_messages)
            return
