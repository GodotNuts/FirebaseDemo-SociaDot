extends Node

signal update_user_name(user_name)
signal update_user_picture(user_picture)

var user_id : String                setget set_user_id
var user_email : String             setget set_user_email
var user_name : String              setget set_user_name
var user_picture : ImageTexture     setget set_user_picture
var friend_list : Array             setget set_friend_list
var user_chats : Dictionary = {}    setget set_user_chats
var last_logged : Dictionary = {}   setget set_last_logged
var is_logged : bool                setget set_is_logged

func set_user_id(id : String):
    user_id = id
#    print(user_id)

func set_user_email(email : String):
    user_email = email
#    print(user_email)

func set_user_name(_name : String):
    user_name = _name
    emit_signal("update_user_name", _name)
#    print(user_name)

func set_user_picture(picture : ImageTexture):
    user_picture = picture
    emit_signal("update_user_picture", picture)
#    print(user_picture)

func set_friend_list(list : Array):
    friend_list = list

func set_user_chats(chats : Dictionary):
    user_chats = chats

func map_user(doc : FirestoreDocument, picture : ImageTexture):
    set_user_id(doc.doc_name)
    set_user_email(doc.doc_fields.email)
    set_user_name(doc.doc_fields.username)
    set_user_picture(picture)
    set_friend_list(doc.doc_fields.friend_list)
    set_user_chats(doc.doc_fields.chats)
    set_last_logged(OS.get_datetime())
    set_is_logged(true)

func erase_friend(id : String):
    friend_list.erase(id)
    user_chats.erase(id)

func add_friend(id : String):
    friend_list.append(id)

func add_chat(id : String) -> String:
    if user_chats.has(id):
        pass
    else:
        user_chats[id] = user_id+id
    return user_chats[id]

func add_friend_chat(id : String, chat_id : String) -> String:
    if user_chats.has(id):
        pass
    else:
        user_chats[id] = chat_id
    return user_chats[id]    

func set_last_logged(dict : Dictionary) -> void:
    last_logged = dict

func set_is_logged(logged : bool) -> void:
    is_logged = logged
