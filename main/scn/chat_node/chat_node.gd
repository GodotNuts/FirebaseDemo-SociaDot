class_name ChatNode
extends PanelContainer

signal show_profile(user_id, user_name)
signal message_received(chat_node)

onready var history_messages : VBoxContainer = $ChatContainer/History/Messages

var received_message_scene : PackedScene = preload("res://main/scn/message_node/received_message.tscn")
var send_message_scene : PackedScene = preload("res://main/scn/message_node/send_message.tscn")

var chat_id : String

var user_id : String
var user_name : String

var db_reference : FirebaseDatabaseReference

var collapsed : bool = false
var received_messages : int

var unread_messages : Array

# Called when the node enters the scene tree for the first time.
func _ready():
    $Settings.hide()
    db_reference.connect("new_data_update", self, "_on_db_data")
    db_reference.connect("patch_data_update", self, "_on_db_data")
    connect("visibility_changed", self, "_on_visibility_changed")
    connect("show_profile", Activities.home, "_on_show_user_profile")
    connect("message_received", Activities.home.friend_list, "_on_message_received")


func create_chat(document : FirestoreDocument):
    set_user_id(document.doc_name)
    set_user_name(document.doc_fields.username)
    # If friend doesn't have a chat with me and 
    if not document.doc_fields.chats.has(UserData.user_id):
        # If I don't have a chat with friend
        if not UserData.user_chats.has(document.doc_fields):
            Utilities.create_chat(document.doc_name)
        # If I have a chat with my friend
        else:
            pass
    # If friend has a chat with me but I don't
    else:
        # If I don't have a chat with friend
        if not UserData.user_chats.has(document.doc_fields):
            Utilities.create_friend_chat(document)
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

func _on_Box_text_entered(new_text : String):
    Utilities.add_message(new_text, db_reference)
    $ChatContainer/Box.set_text("")
    yield(db_reference, "push_successful")


func _on_db_data(resource : FirebaseResource):
    if typeof(resource.data) == TYPE_BOOL:
        return
    var lbl : Label
    if resource.data.message.sender == UserData.user_id:
        lbl = send_message_scene.instance()
    else:
        lbl = received_message_scene.instance()
        if not resource.data.message.read:
            if (collapsed or not visible):
                received_messages+=1
                emit_signal("message_received", self)
                unread_messages.append(resource)
            else:
                Utilities.read_message(resource, db_reference)
    history_messages.add_child(lbl)
    lbl.set_text(resource.data.message.content)
    lbl.set_name(resource.key)
    yield(get_tree(), "idle_frame")
    $ChatContainer/History.scroll_vertical = $ChatContainer/History.get_v_scrollbar().max_value


func _on_CloseBtn_pressed():
    hide()


func _on_Header_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            collapsed = not collapsed
            $ChatContainer/History.visible = not $ChatContainer/History.visible
            $ChatContainer/Box.visible = not $ChatContainer/Box.visible
            if not collapsed:
                received_messages = 0
                emit_signal("message_received", self)
                clear_received_messages()


func _on_visibility_changed():
    if visible:
        received_messages = 0
        emit_signal("message_received", self)
        clear_received_messages()

func clear_received_messages():
    for message in unread_messages:
        Utilities.read_message(message, db_reference)
        unread_messages.erase(message)

func _on_SettingsBtn_pressed():
    $Settings.visible = not $Settings.visible

func _on_TransparencySlider_value_changed(value):
    $Settings/ColorRect/VBoxContainer/Transparency.set_text(value as String)
    modulate.a = value*0.01


func _on_User_pressed():
    emit_signal("show_profile", user_id, user_name)
