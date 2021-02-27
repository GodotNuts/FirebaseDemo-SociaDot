extends Node

onready var users_collection : FirestoreCollection = Firebase.Firestore.collection("sociadot/340b3IJqqSEK1kMijHCC/users")
onready var posts_collection : FirestoreCollection = Firebase.Firestore.collection("sociadot/340b3IJqqSEK1kMijHCC/posts")
onready var posts_query : FirestoreQuery = FirestoreQuery.new().from("posts").order_by("timestamp", FirestoreQuery.DIRECTION.DESCENDING)
onready var users_query : FirestoreQuery = FirestoreQuery.new().from("users")

# Called when the node enters the scene tree for the first time.
func _ready():
    users_collection.connect("error", self, "_show_error")
    posts_collection.connect("error", self, "_show_error")

func _show_error(error : Dictionary):
    Activities.show_error(JSON.print(error))

func get_all_users() -> FirestoreTask:
    return Firebase.Firestore.list("sociadot/340b3IJqqSEK1kMijHCC/users")

# Get the user Document by id
func get_user(user_id : String) -> FirestoreTask:
    return users_collection.get("{user_id}".format({user_id = user_id}))

func get_user_by_username(username : String) -> FirestoreTask:
    users_query.where("username", FirestoreQuery.OPERATOR.EQUAL, username)
    return Firebase.Firestore.query(users_query)
    

func get_user_posts(user_id : String) -> FirestoreTask:
    posts_query.where("user_id", FirestoreQuery.OPERATOR.EQUAL, user_id)
    print(posts_query)
    return Firebase.Firestore.query(posts_query)

func get_all_posts() -> FirestoreTask:
    return Firebase.Firestore.list("sociadot/340b3IJqqSEK1kMijHCC/posts")

# Get user image from Storage by id ( image == id )
func get_profile_picture(user_id : String) -> StorageTask:
    return Firebase.Storage.ref("sociadot/users/profile_pictures/{user_id}".format({user_id = user_id})).get_data()

# Add a new user Document
func add_user(user_id : String, user_mail : String) -> FirestoreTask:
    return users_collection.add(user_id, {
        email = user_mail, 
        localid = user_id, 
        username = "", 
        friend_list = [],
        chats = {},
        })

# Update a user profile picture
func update_user_picture(picture_path : String) -> StorageTask:
    return Firebase.Storage.ref("sociadot/users/profile_pictures/{user_id}".format({user_id = UserData.user_id})).put_file(picture_path)

# Update a user Document
func update_user() -> FirestoreTask:
    return users_collection.update(UserData.user_id, { 
        username = UserData.user_name , 
        localid = UserData.user_id, 
        email = UserData.user_email,
        friend_list = UserData.friend_list,
        chats = UserData.user_chats
        })

# Update user friend list
func update_friend_list(friend_id : String) -> FirestoreTask:
    if friend_id in UserData.friend_list:
        UserData.erase_friend(friend_id)
    else: 
        UserData.add_friend(friend_id)
    return users_collection.update(UserData.user_id, { 
        friend_list = UserData.friend_list
        })

# Get a single post document by ID
func get_post_doc(post_id : String) -> FirestoreTask:
    return posts_collection.get(post_id)

# Get a post's Image from Storage
func get_post_image(user_id : String, post_id : String, post_image : String) -> StorageTask:
    return Firebase.Storage.ref("sociadot/posts/{user_id}/{post_id}/{post_image}".format({user_id = user_id, post_id = post_id, post_image = post_image})).get_data()

# Add a new post Document
func add_post_doc(description : String, image_path : String, timestamp : int = RequestsManager.get_time()) -> FirestoreTask:
    var add_post_task : FirestoreTask = posts_collection.add("", {
        user = UserData.user_name,
        user_id = UserData.user_id,
        description = description,
        image = RequestsManager.get_image_name(image_path),
        timestamp = timestamp
       })
    add_post_task.connect("add_document", self, "_on_post_added")
    return add_post_task

func _on_post_added(post_doc : FirestoreDocument):
    Firebase.Database.get_database_reference("sociadot/posts").update(post_doc.doc_name, { user = post_doc.doc_fields.user_id })

# Add a post image to Storage
func add_post_image(post_id : String, image_path : String, image : PoolByteArray) -> StorageTask:
    return Firebase.Storage.ref("sociadot/posts/{user_id}/{post_id}/{image_path}".format({
        user_id = UserData.user_id, 
        post_id = post_id, 
        image_path = RequestsManager.get_image_name(image_path)
        })).put_data(image)


func update_post_likes(likes : Array, post_db : FirebaseDatabaseReference) -> void:
    post_db.update("", {likes = likes})

func add_post_comment(comment : Dictionary, post_db : FirebaseDatabaseReference) -> void:
    post_db.push({ 
        user = comment.user, 
        username = comment.username,
        content = comment.content 
        })

func create_chat(friend_id : String) -> FirestoreTask:
    var chat_id : String = UserData.add_chat(friend_id)
    return users_collection.update(UserData.user_id, {chats = UserData.user_chats})

func create_friend_chat(friend : FirestoreDocument) -> FirestoreTask:
    var chat_id : String = UserData.add_friend_chat(friend.doc_name, friend.doc_fields.chats[UserData.user_id])
    return users_collection.update(UserData.user_id, {chats = UserData.user_chats})


func add_message(message : String, chat_db : FirebaseDatabaseReference) -> void:
    chat_db.push({ message = { sender = UserData.user_id, content = message, read = false }})

func read_message(message : FirebaseResource, chat_db : FirebaseDatabaseReference) -> void:
    message.data.message["read"] = true
    chat_db.update(message.key, message.data)

func get_friends_posts() -> FirestoreTask:
    return Firebase.Firestore.query(
                FirestoreQuery.new() \
                .from("posts") \
                .where("user_id", FirestoreQuery.OPERATOR.IN, UserData.friend_list) \
                .order_by("timestamp", FirestoreQuery.DIRECTION.DESCENDING)
            )
