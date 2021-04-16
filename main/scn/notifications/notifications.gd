extends VBoxContainer


onready var notifications_list : VBoxContainer = $ScrollNotifications/NotificationsContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

func manage_notification(resource : FirebaseResource) -> void:
    var notification_node : Notification = Activities.notification_node_scene.instance()
    notification_node.connect("header_pressed", Activities.home, "_on_show_user_profile")
    notification_node.connect("show_post", Activities.home, "_on_open_post")
    notifications_list.add_child(notification_node)
#    notifications_list.move_child(notification_node, 0)
    notification_node.load_notification(resource)

func view_notifications() -> void:
    for notification in notifications_list.get_children():
        if not notification.viewed:
            notification.set_viewed(true)
            RequestsManager.view_notification(notification.id)
