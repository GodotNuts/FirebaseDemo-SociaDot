class_name ChatNode
extends PanelContainer

signal show_profile(user_id, user_name)
signal message_received(chat_node)

onready var history_messages : VBoxContainer = $ChatContainer/History/Messages

var received_message_scene : PackedScene = preload("res://main/scn/message_node/received_message.tscn")
var send_message_scene : PackedScene = preload("res://main/scn/message_node/send_message.tscn")

var chat_id : String

var user : UsersManager.User
var user_id : String
var user_name : String
var user_avatar : ImageTexture

var db_reference : FirebaseDatabaseReference

var collapsed : bool = false
var received_messages : int

var unread_messages : Array


func _connect_signals():
    db_reference.connect("new_data_update", self, "_on_db_data")
#    db_reference.connect("patch_data_update", self, "_on_db_data")
    connect("visibility_changed", self, "_on_visibility_changed")
    connect("show_profile", Activities.home, "_on_show_user_profile")
    connect("message_received", Activities.home.friend_list, "_on_message_received")
    
    $ChatContainer/Header.connect("gui_input", self, "_on_Header_gui_input")
    $ChatContainer/Header/User.connect("pressed", self, "_on_User_pressed")
    $ChatContainer/Header/SettingsBtn.connect("pressed", self, "_on_SettingsBtn_pressed")
    $ChatContainer/Header/CloseBtn.connect("pressed", self, "_on_CloseBtn_pressed")
    $ChatContainer/Box.connect("text_entered", self, "_on_Box_text_entered")
    $Settings/ColorRect/VBoxContainer/TransparencySlider.connect("value_changed", self, "_on_TransparencySlider_value_changed")
    


# Called when the node enters the scene tree for the first time.
func _ready():
    _connect_signals()
    $Settings.hide()
    set_collapsed(false)


func create_chat(document : FirestoreDocument):
    set_user_id(document.doc_name)
    set_user_name(document.doc_fields.username)
    user = UsersManager.get_user_by_id(document.doc_name)
    if not user.is_connected("update_picture", self, "set_user_avatar"):
        user.connect("update_picture", self, "set_user_avatar")
    set_user_avatar(user.picture)
    # If friend doesn't have a chat with me and 
    if not document.doc_fields.chats.has(UserData.user_id):
        # If I don't have a chat with friend
        if not UserData.user_chats.has(document.doc_fields):
            RequestsManager.create_chat(document.doc_name)
        # If I have a chat with my friend
        else:
            pass
    # If friend has a chat with me but I don't
    else:
        # If I don't have a chat with friend
        if not UserData.user_chats.has(document.doc_fields):
            RequestsManager.create_friend_chat(document)
        # If I have a chat with my friend
        else:
            pass
    db_reference = Firebase.Database.get_database_reference("sociadot/chats/"+UserData.user_chats[document.doc_name]) 
    chat_id = UserData.user_chats[document.doc_name]

func set_user_id(id : String):
    name = id
    user_id = id

func set_user_name(_name : String):
    user_name = _name
    $ChatContainer/Header/User.set_text(user_name)

func set_user_avatar(_avatar : ImageTexture):
    user_avatar = _avatar
    $ChatContainer/Header/Avatar.set_texture(user_avatar)

func _on_Box_text_entered(new_text : String):
    RequestsManager.add_message(new_text, db_reference)
    $ChatContainer/Box.clear()

func add_message(key : String, message : Dictionary) -> Label:
    var lbl
    if message.sender == UserData.user_id:
        lbl = send_message_scene.instance()
    else:
        lbl = received_message_scene.instance()
    history_messages.add_child(lbl)
    lbl.set_text(message.content)
    lbl.set_name(key)
    yield(get_tree(), "idle_frame")
    lbl.show()
    yield(get_tree(), "idle_frame")
    $ChatContainer/History.scroll_vertical = $ChatContainer/History.get_v_scrollbar().max_value
    return lbl

func _on_db_data(resource : FirebaseResource):
    if typeof(resource.data) == TYPE_BOOL:
        return
    if resource.data.message.sender != UserData.user_id:
        if not resource.data.message.read:
            if (collapsed or not visible):
                received_messages+=1
                emit_signal("message_received", self)
                unread_messages.append(resource)
            else:
                RequestsManager.read_message(resource, db_reference)
    add_message(resource.key, resource.data.message)


func _on_CloseBtn_pressed():
    hide()


func _on_Header_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            set_collapsed(not collapsed)


func set_collapsed(is_collapsed : bool):
    collapsed = is_collapsed
    $ChatContainer/History.visible = not collapsed
    $ChatContainer/Box.visible = not collapsed
    if not collapsed:
        received_messages = 0
        emit_signal("message_received", self)
        clear_received_messages()

func _on_visibility_changed():
    if visible:
        received_messages = 0
        emit_signal("message_received", self)
        clear_received_messages()
        yield(get_tree(), "idle_frame")
        $ChatContainer/History.scroll_vertical = $ChatContainer/History.get_v_scrollbar().max_value

func clear_received_messages():
    for message in unread_messages:
        RequestsManager.read_message(message, db_reference)
        unread_messages.erase(message)

func _on_SettingsBtn_pressed():
    $Settings.visible = not $Settings.visible

func _on_TransparencySlider_value_changed(value):
    $Settings/ColorRect/VBoxContainer/Transparency.set_text(value as String)
    modulate.a = value*0.01


func _on_User_pressed():
    emit_signal("show_profile", user_id, user_name)
