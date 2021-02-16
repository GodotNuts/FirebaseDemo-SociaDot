extends Node

signal show_chat(chat_node)


class Chat:
    
    var id : String
    var node : ChatNode
    
    func _init(user_document : FirestoreDocument):
        node = Activities.chat_node_scene.instance()
        node.create_chat(user_document)
        id = user_document.doc_name


var chats : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func create_chat(document : FirestoreDocument):
    var chat_obj : Chat = Chat.new(document)
    if chats.size() == 0:
        chat_obj.node.size_flags_horizontal
    chats.append(chat_obj)

func open_chat(document : FirestoreDocument):
    var chat_to_open : ChatNode
    if has_chat(document.doc_name):
        get_chat(document.doc_name).node.create_chat(document)
        chat_to_open = get_chat(document.doc_name).node
    else:
        var chat_obj : Chat = Chat.new(document)
        chats.append(chat_obj)
        chat_to_open = chat_obj.node
    emit_signal("show_chat", chat_to_open)

func has_chat(id : String) -> bool:
    for chat in chats:
        if chat.id == id:
            return true
    return false

func get_chat(id : String) -> Chat:
    for chat in chats:
        if chat.id == id:
            return chat
    return null

func remove_chat(user_id : String):
    for chat in chats:
        if chat.id == user_id:
            chat.node.queue_free()
            chats.erase(chat)
            return

func count_visible_chats() -> int:
    var _count : int = 0
    for chat in chats:
        if chat.node.visible:
            _count +=1
    return _count

func get_visible_chats() -> Array:
    var _chats : Array = []
    for chat in chats:
        if chat.node.visible:
            _chats.append(chat.node)
    return _chats
