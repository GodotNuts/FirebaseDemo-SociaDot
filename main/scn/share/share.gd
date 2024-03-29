extends Panel

signal share_post(id, description, image, timestamp)

onready var post_image : TextureRect = $ShareSomething/Container/Image
onready var post_description : TextEdit = $ShareSomething/Container/Description

var image_path : String
var image : ImageTexture = null

var y_limit : int = 400
var x_limit : int = 500

func _connect_signals():
    connect("gui_input", self, "_on_ShareSomethingContainer_gui_input")
    post_description.connect("text_changed", self, "_on_Description_text_changed")
    $ShareSomething/Container/AddImageBtn.connect("pressed", self, "_on_AddImageBtn_pressed")
    $ShareSomething/Container/ShareBtn.connect("pressed", self, "_on_ShareBtn_pressed")
    $FileDialog.connect("file_selected", self, "_on_FileDialog_file_selected")
    $ShareSomething/Container/Image/Cancel.connect("pressed", self, "_on_cancel_pressed")

func _ready():
    _connect_signals()
    $ShareSomething/Container/Header/Picture.set_texture(UserData.user_picture)
    $ShareSomething/Container/Header/Name.set_text(UserData.user_name)
    get_tree().connect("files_dropped", self, "_on_files_dropped")
    hide()


func _on_files_dropped(files : PoolStringArray, screen : int):
    for file_dropped in files:
        if not file_dropped.get_extension() in ["png","jpg"]:
            return
        set_texture(file_dropped)
        set_image(file_dropped)

func set_texture(file_dropped : String):
    var img : Image = Image.new()
    img.load(file_dropped)
#    resize_image(img)
    var texture : ImageTexture = ImageTexture.new()
    texture.create_from_image(img)
    post_image.set_texture(texture)
    image = texture

func resize_image(img : Image) -> void:
    var y_img : float = img.get_size().y
    var x_img : float = img.get_size().x
    if y_img > x_img:
        if y_img > y_limit:
            var aspect_ration : float = y_limit/y_img
            img.resize(x_img*aspect_ration, y_limit)
    else:
        if x_img > x_limit:
            var aspect_ratio : float = x_limit/x_img
            img.resize(x_limit, y_img*aspect_ratio)


func _on_AddImageBtn_pressed():
    $FileDialog.popup()

func _on_ShareBtn_pressed():
    Activities.loading(true)
    var share_task : FirestoreTask = RequestsManager.add_post_doc(post_description.get_text(), image_path)
    var post_doc : FirestoreDocument = yield(share_task, "task_finished")
    if image != null:
        var image_task : StorageTask = RequestsManager.add_post_image(post_doc.doc_name, image_path, image.get_data().save_png_to_buffer())
        yield(image_task, "task_finished")
    emit_signal("share_post", post_doc.doc_name, post_doc, image)
    hide()
    clear()
    Activities.loading(false)
    

func _on_FileDialog_file_selected(path : String):
    set_texture(path)
    set_image(path)
        
func set_image(file_path : String):
    image_path = file_path
    if image_path.count("\\") > 0:
        image_path = image_path.replacen("\\","/")
    post_image.show()
    post_image.size_flags_vertical = SIZE_EXPAND_FILL
    post_description.size_flags_vertical = SIZE_FILL
    $ShareSomething/Container/AddImageBtn.hide()
#    if image.get_data().get_size().y > post_image.rect_size.y :
#        post_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
#    else:
#        post_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    

func _on_Description_text_changed():
    if post_description.get_text().length():
        $ShareSomething/Container/ShareBtn.disabled = false
    else:
        $ShareSomething/Container/ShareBtn.disabled = true


func _on_ShareSomethingContainer_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_LEFT:
            hide()

func clear():
    _on_cancel_pressed()
    post_description.set_text("")
    $ShareSomething/Container/ShareBtn.disabled = true

func _on_cancel_pressed():
    image = null
    post_image.set_texture(null)
    post_image.hide()
    $ShareSomething/Container/AddImageBtn.show()
    post_description.size_flags_vertical = SIZE_EXPAND_FILL
