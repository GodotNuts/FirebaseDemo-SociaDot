class_name FriendButton
extends PanelContainer

onready var online_lbl : Label = $Header/Picture/Online

var friend : UsersManager.User

var friend_id : String                      setget set_friend_id
var friend_name : String                    setget set_friend_name
var friend_picture : ImageTexture           setget set_friend_picture
var friend_document : FirestoreDocument     setget set_friend_document


func _connect_signals():
    connect("gui_input", self, "_on_FriendButton_gui_input")

# Called when the node enters the scene tree for the first time.
func _ready():
    _connect_signals()
    hide()


func load_friend(id : String, _name : String, picture : ImageTexture):
    set_friend_id(id)
    set_friend_name(_name)
    set_friend_picture(picture)
    show()


func load_friend_from_obj(user : UsersManager.User):
    friend = user
    set_friend_id(user.id)
    set_friend_name(user.username)
    set_friend_picture(user.picture)
    set_friend_document(user.document)
    set_online(user.is_logged)
    friend.connect("update_picture", self, "set_friend_picture")
    friend.connect("update_document", self, "load_friend_from_document")
    show()


func load_friend_from_document(document : FirestoreDocument):
    set_friend_document(document)
    set_friend_name(document.doc_fields.username)
    set_online(document.doc_fields.is_logged)
    show()


func set_friend_id(id : String):
    friend_id = id

func set_friend_name(_name : String):
    friend_name = _name
    $Header/Name.set_text(friend_name)
    
func set_friend_picture(picture : ImageTexture):
    if picture == null:
        return
    $Header/Picture.set_texture(picture)

func set_friend_document(f_doc : FirestoreDocument):
    friend_document = f_doc

func set_received_messages(messages : int):
    if messages == 0:
        $Header/Messages.hide()
    else:
        $Header/Messages.show()
        $Header/Messages.set_text(messages as String)

func _on_FriendButton_pressed():
    ChatsManager.open_chat(friend_document)
#    UsersManager.get_new_user_doc(friend_id)


func set_online(online : bool) -> void:
    online_lbl.visible = online

func _on_FriendButton_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            _on_FriendButton_pressed()
