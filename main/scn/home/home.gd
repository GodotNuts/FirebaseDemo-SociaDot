extends PanelContainer

signal show_error()
signal loading()

onready var sections_container : VBoxContainer = $HomeContainer/Sections
onready var posts_section : VBoxContainer = sections_container.get_node("Posts")
onready var users_list_section : VBoxContainer = sections_container.get_node("UsersList")
onready var settings_section : VBoxContainer = sections_container.get_node("Settings")
onready var profile_section : VBoxContainer = sections_container.get_node("Profile")
onready var notifications_section : VBoxContainer = sections_container.get_node("Notifications")

onready var post_box : VBoxContainer = posts_section.get_node("ScrollPost/PostContainer")
onready var profile_post_container : VBoxContainer = profile_section.get_node("ScrollPost/PostContainer")

onready var menu : VBoxContainer = $HomeContainer/Menu
onready var side_bar : VBoxContainer = $HomeContainer/SideBar
onready var friend_list : VBoxContainer = side_bar.get_node("FriendList")

onready var notification_lbl : Label = $HomeContainer/Menu/NotificationsBtn/Notification

onready var chat_container : GridContainer = $AspectRatioContainer/ChatContainer

onready var show_post : Control = $ShowPost


var fr_posts : FirestoreCollection = Firebase.Firestore.collection("posts")

var friend_posts : Array = []

var posts_db_reference : FirebaseDatabaseReference 
var notifications_db_reference : FirebaseDatabaseReference

var window_size : Vector2

func _connect_signals():
    connect("item_rect_changed", self, "_on_Home_item_rect_changed")
    $ShareSomethingContainer.connect("share_post", self, "add_shared_post")
    users_list_section.connect("show_user_profile", self, "_on_show_user_profile")
    ChatsManager.connect("show_chat", self, "_on_show_chat")
    
    $HomeContainer/Menu/Header/Name.connect("pressed", self, "_on_Name_pressed")
    $HomeContainer/Menu/HomeBtn.connect("pressed", self, "_on_HomeBtn_pressed")
    $HomeContainer/Menu/ShareBtn.connect("pressed", self, "_on_ShareBtn_pressed")
    $HomeContainer/Menu/UsersListBtn.connect("pressed", self, "_on_UsersListBtn_pressed")
    $HomeContainer/Menu/NotificationsBtn.connect("pressed", self, "_on_NotificationsBtn_pressed")
    $HomeContainer/Menu/SettingsBtn.connect("pressed", self, "_on_SettingsBtn_pressed")
    
    notifications_section.connect("visibility_changed", self, "_on_notification_section_visibility")

func _ready():
    _connect_signals()
    if AppSettings.get_screen_orientation():
        menu.hide()
        side_bar.hide()
    profile_section.hide()
    users_list_section.hide()
    settings_section.hide()
    rect_position = Vector2(-rect_size.x, 0)
    $HomeContainer/Menu/Header.load_main_user()
    animate_Home(true)
    load_posts()
    connect_posts()
    connect_notifications()
    friend_list.load_friend_list()

func animate_Home(display : bool):
    if display:
        $Tween.interpolate_property(self, "rect_position", Vector2(-rect_size.x, 0), Vector2(), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property(self, "modulate", Color(1,1,1,0), Color(1,1,1,1), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
    else:
        $Tween.interpolate_property(self, "rect_position", Vector2(), Vector2(-rect_size.x, 0), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
        $Tween.interpolate_property(self, "modulate", Color(1,1,1,1), Color(1,1,1,0), 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
    $Tween.start()

func sort_posts(post_a : FirestoreDocument, post_b : FirestoreDocument):
    if post_a.doc_fields.timestamp > post_b.doc_fields.timestamp:
        return true
    return false

func load_posts():
    if not UserData.friend_list.empty():
        posts_section.get_node("NoFriends").hide()
        var posts : Array = yield(RequestsManager.get_all_posts(), "listed_documents")
        for post_doc in posts:
            if post_doc.doc_fields.user_id in (UserData.friend_list + [UserData.user_id]) \
            and not check_friend_posts_list(post_doc):
                friend_posts.append(post_doc)
        
        friend_posts.sort_custom(self, "sort_posts")
        
        if friend_posts.empty():
            pass
        else:
            for post_idx in range(0, friend_posts.size()):
                var post_container : PostContainer = check_post_routine(friend_posts[post_idx])
                post_box.move_child(post_container, post_idx)
    else:
        for post in post_box.get_children():
            if post is PostContainer: post.queue_free()
        posts_section.get_node("NoFriends").show()
    
func connect_posts() -> void:
    posts_db_reference = Firebase.Database.get_database_reference("sociadot/posts")
    posts_db_reference.connect("new_data_update", self, "_on_new_post")
    
func connect_notifications() -> void:
    notifications_db_reference = Firebase.Database.get_database_reference("sociadot/notifications/"+UserData.user_id)
    notifications_db_reference.connect("new_data_update", self, "_on_new_notification")

func _on_new_notification(notification : FirebaseResource):
    notifications_section.manage_notification(notification)
    if not notification.data.viewed:
        notification_lbl.show()

func check_friend_posts_list(post_doc : FirestoreDocument) -> bool:
    for post in friend_posts:
        if post.doc_name == post_doc.doc_name:
            return true
    return false

func check_post_routine(post_doc : FirestoreDocument) -> PostContainer:
    var post_container : PostContainer
    if PostsManager.has_post(post_doc.doc_name):
        if PostsManager.has_post_container(post_doc.doc_name):
            post_container = PostsManager.get_post_container_by_id(post_doc.doc_name)
            add_post(post_container)
        else:
            post_container = Activities.post_container_scene.instance()
            add_post(post_container)
            post_container.load_post(PostsManager.get_post_by_id(post_doc.doc_name))
    else:
        post_container = Activities.post_container_scene.instance()
        var post_obj : PostsManager.Post = PostsManager.add_post_from_doc(post_doc.doc_name, post_doc)
        add_post(post_container)
        post_container.load_post(post_obj)
    return post_container


func _on_new_post(post : FirebaseResource):
    if not post.data.user in UserData.friend_list:
        return
    if PostsManager.has_post(post.key):
        return
    var post_doc : FirestoreDocument = yield(RequestsManager.get_post_doc(post.key), "get_document")
    check_post_routine(post_doc)

func remove_post(post : PostContainer):
    post_box.remove_child(post)

func remove_posts_from_user(user : UsersManager.User):
    for post in friend_posts:
        if post.doc_fields.user_id == user.id:
            friend_posts.erase(post)
    for post in post_box.get_children():
        if post.user_id == user.id:
            remove_post(post)

func add_post(post : PostContainer):
    posts_section.get_node("NoFriends").hide()
    post_box.show()
    # Check if @post is not already been added to the PostBox
    for post_child in post_box.get_children():
        if post.id == post_child.id:
            return
    post_box.add_child(post)
    if not post.is_connected("show_user_profile", self, "_on_show_user_profile"):
        post.connect("show_user_profile", self, "_on_show_user_profile")


func add_shared_post(post_id : String, document : FirestoreDocument, image : ImageTexture):
    friend_posts.append(document)
    var post : PostContainer = Activities.post_container_scene.instance()
    add_post(post)
    post.load_post(PostsManager.add_shared_post(post_id, document, image))
    post_box.move_child(post, 0)


func add_profile_post(post : PostContainer):
    profile_post_container.add_child(post)


func _on_show_user_profile(user_id : String, user_name : String):
    $ShowPost.hide()
    if user_id == profile_section.user_id:
        return
    emit_signal("loading", true)
    show_section(profile_section)
    profile_section.load_profile(user_id, user_name)
    emit_signal("loading", false)


func _on_ShareBtn_pressed():
    $ShareSomethingContainer.show()


func _on_HomeBtn_pressed():
    load_posts()
    show_section(posts_section)


func _on_FriendList_open_chat(friend_id, friend_name):
    pass # Replace with function body.

func _on_show_chat(chat_node : ChatNode):
    if chat_node in chat_container.get_children():
        if ChatsManager.count_visible_chats() == chat_container.columns:
            ChatsManager.get_visible_chats()[0].set_visible(false)
        chat_node.set_visible(true)
    else:
        chat_container.add_child(chat_node)
        chat_node.set_visible(true)
    

func show_section(section : Control) -> void:
    for _section in sections_container.get_children():
        _section.hide()
    section.show()

func _on_SettingsBtn_pressed() -> void:
    settings_section.load_user_data()
    show_section(settings_section)

func _on_UsersListBtn_pressed():
    users_list_section.load_users_list()
    show_section(users_list_section)


func _on_new_connection(user : UsersManager.User, button : Button):
    friend_list.add_friend(user)
    var connect_particle : CPUParticles2D = Activities.connect_particle_scene.instance()
    connect_particle.add_to_control(button)

func _on_removed_connection(user : UsersManager.User):
    friend_list.remove_friend(user)
    remove_posts_from_user(user)


func _on_Name_pressed():
    _on_show_user_profile(UserData.user_id, UserData.user_name)

func _on_open_post(post : PostsManager.Post):
    show_post.show_post(post, UsersManager.get_user_by_id(post.user_id))
    
func _on_NotificationsBtn_pressed():
    show_section(notifications_section)
    notification_lbl.hide()

func _on_notification_section_visibility():
    if not notifications_section.visible:
        notifications_section.view_notifications()

func _on_Home_item_rect_changed():
    update_chat_container()

func update_chat_container():
    if chat_container == null:
        return
    chat_container.set_columns(floor(rect_size.x / 300))
    var visible_chats : Array = ChatsManager.get_visible_chats()
    if visible_chats.size() > chat_container.columns:
        for chat_idx in range(0, visible_chats.size()):
            if chat_idx > chat_container.columns-1:
                visible_chats[chat_idx].node.hide()
