extends Node

class Post:
    var id : String
    var user : String
    var user_id : String
    var user_picture : ImageTexture
    var description : String
    var image_name : String
    var image : ImageTexture
    var image_task : StorageTask
    var timestamp : int
    var likes : Array
    var comments : Dictionary
    var document_task : FirestoreTask
    var document : FirestoreDocument

    signal update_image(image)
    signal update_document(document)
    signal update_post(post)

    func _init(id : String, doc_task : FirestoreTask = null, img_task : StorageTask = null):
        self.id = id
        if doc_task != null:
            document_task = doc_task
            document_task.connect("get_document", self, "_on_get_document")
        if img_task != null:
            image_task = img_task
            image_task.connect("task_finished", self, "_on_image_received")
            
    func _on_get_document(doc : FirestoreDocument):
        emit_signal("update_document", doc)
        document = doc
        user = doc.doc_fields.user
        user_id = doc.doc_fields.user_id
        description = doc.doc_fields.description
        timestamp = doc.doc_fields.timestamp
        image_name = doc.doc_fields.image
        emit_signal("update_post", self)

    func _on_image_received():
        if typeof(image_task.data) == TYPE_RAW_ARRAY:
            image = Utilities.byte2image(image_task.data)
            emit_signal("update_image", image)
        else:
            if image_task.data.has("error") or image_name == "":
                image = null
                emit_signal("update_image", image)

var posts : Array = []
var post_containers : Array = []

func _ready():
    pass # Replace with function body.

func add_post(id : String, document_task : FirestoreTask = null, image_task : StorageTask = null) -> Post:
    var post : Post = Post.new(id, document_task, image_task)
    posts.append(post)
    return post

func add_post_from_doc(id : String, doc : FirestoreDocument, image_task : StorageTask = null) -> Post:
    var post : Post
    if image_task == null:
        if doc.doc_fields.image != "":
            image_task = Utilities.get_post_image(doc.doc_fields.user_id, id, doc.doc_fields.image)
            post = Post.new(id, null, image_task)
        else:
            post = Post.new(id)
    post._on_get_document(doc)
    posts.append(post)
    return post

func add_shared_post(id : String, doc : FirestoreDocument, image : ImageTexture) -> Post:
    var post : Post = Post.new(id)
    post._on_get_document(doc)
    post.image = image
    posts.append(post)
    return post

func has_post(id : String) -> bool:
    for post in posts:
        if post.id == id:
            return true
    return false

func get_post_by_id(id : String) -> Post:
    for post in posts:
        if post.id == id:
            return post
    return null



func add_post_scene(post_scene : PanelContainer):
    post_containers.append(post_scene)

func has_post_container(id : String) -> bool:
    for post in post_containers:
        if post.id == id:
            return true
    return false

func get_post_container_by_id(id : String) -> PanelContainer:
    for post in post_containers:
        if post.id == id:
            return post
    return null
