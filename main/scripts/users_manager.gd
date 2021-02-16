extends Node

class User:
    var id : String
    var username : String
    var email : String
    var chats : Dictionary
    var friend_list : Array
    var picture : ImageTexture
    var document : FirestoreDocument
    var picture_task : StorageTask
    var document_task : FirestoreTask

    signal update_picture(picture)
    signal update_document(document)
    signal update_user(user)

    func _init(id : String, doc_task : FirestoreTask = null, pic_task : StorageTask = null):
            self.id = id
            if doc_task != null:
                document_task = doc_task
                document_task.connect("get_document", self, "_on_get_document")
            if pic_task != null:
                picture_task = pic_task
                picture_task.connect("task_finished", self, "_on_picture_received")

    func update_document():
        document_task = Utilities.get_user(id)
#        document_task.connect("get_document", self, "_on_get_document")

    func _on_get_document(doc : FirestoreDocument):
        emit_signal("update_document", doc)
        document = doc
        username = doc.doc_fields.username
        email = doc.doc_fields.email
        chats = doc.doc_fields.chats
        friend_list = doc.doc_fields.friend_list
        emit_signal("update_user", self)

    func _on_picture_received():
        if typeof(picture_task.data) == TYPE_RAW_ARRAY:
            picture = Utilities.byte2image(picture_task.data)
            emit_signal("update_picture", picture)

var users : Array = []

func _ready():
    pass # Replace with function body.

func add_user(id : String, firestore_task : FirestoreTask = null, picture_task : StorageTask = null) -> User:
    var user : User = User.new(id, firestore_task, picture_task)
    users.append(user)
    return user

func add_user_doc(id : String, document : FirestoreDocument, picture_task : StorageTask = null) -> User:
    var user : User = User.new(id, null, picture_task)
    user._on_get_document(document)
    users.append(user)
    return user

func has_user(id : String) -> bool:
    for user in users:
        if user.id == id:
            return true
    return false

func get_user_by_id(id : String) -> User:
    for user in users:
        if user.id == id:
#            print("found ", id)
            return user
    return null
