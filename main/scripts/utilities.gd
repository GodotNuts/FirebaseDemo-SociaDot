extends Node

func get_image_name(image_path : String) -> String:
	return (image_path.split("/") as Array).back() if image_path != "" else image_path

func task2image(task : StorageTask) -> ImageTexture:
	var new_image := Image.new()
	match typeof(task.data):
		TYPE_RAW_ARRAY:
			var data : PoolByteArray = task.data
			if data.size()>1:
				match data.subarray(0,1).hex_encode():
					"ffd8":
						new_image.load_jpg_from_buffer(data)
					"8950":
						new_image.load_png_from_buffer(data)
			else: 
				return null
		TYPE_DICTIONARY:
			Activities.show_error("ERROR %s: could not find image requested" % task.data.error.code)
			return null
	var new_texture := ImageTexture.new()
	new_texture.create_from_image(new_image)
	return new_texture

func get_time() -> int:
	return OS.get_unix_time()

func get_human_time(t : int) -> String:
	var date : Dictionary = OS.get_datetime_from_unix_time(t)
	return ("{day}/{month}/{year}\n{hour}:{minute}").format({
		hour = date.hour,
		minute = ("0%s"%[date.minute] if str(date.minute).length() < 2 else (date.minute)),
		day = date.day,
		month = date.month,
		year = date.year
		})

func parse_content(_content : String):
	var parsed_content : String = _content
	var regex : RegEx = RegEx.new()
	var result : Array
	
	# ----- Custom cheatsheet -----
	
	# Wave
	regex.compile("(w\\:)(.*?)(\\:w)")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{open}{case}{close}").format({open = group.get_string(1), case = group.get_string(2), close = group.get_string(3)}),
				("[wave amp=20 freq=5]{case}[/wave]").format({case = group.get_string(2)})
				)

	# Rainbow
	regex.compile("(r\\:)(.*?)(\\:r)")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{open}{case}{close}").format({open = group.get_string(1), case = group.get_string(2), close = group.get_string(3)}),
				("[rainbow freq=0.2]{case}[/rainbow]").format({case = group.get_string(2)})
				)
	
	# Fade
	regex.compile("(f\\:)(.*?)(\\:f)")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{open}{case}{close}").format({open = group.get_string(1), case = group.get_string(2), close = group.get_string(3)}),
				("[fade start=4 length=14]{case}[/fade]").format({case = group.get_string(2)})
				)
		
	# Shake
	regex.compile("(s\\:)(.*?)(\\:s)")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{open}{case}{close}").format({open = group.get_string(1), case = group.get_string(2), close = group.get_string(3)}),
				("[shake rate=15 level=10]{case}[/shake]").format({case = group.get_string(2)})
				)
	
	# ---- Markdown support ----
	
	# Bold
	regex.compile("(\\*\\*|__)(.*?)\\1")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{code}{case}{code}").format({code = group.get_string(1), case = group.get_string(2)}),
				("[b]{case}[/b]").format({case = group.get_string(2)})
				)
	
	# Italics
	regex.compile("(\\*|_)(.*?)\\1")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{code}{case}{code}").format({code = group.get_string(1), case = group.get_string(2)}),
				("[i]{case}[/i]").format({case = group.get_string(2)})
				)
	
	# Strikethrough
	regex.compile("(\\~\\~)(.*?)\\1")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{code}{case}{code}").format({code = group.get_string(1), case = group.get_string(2)}),
				("[s]{case}[/s]").format({case = group.get_string(2)})
				)
		
	# Strikethrough
	regex.compile("(\\`)(.*?)\\1")
	result = regex.search_all(parsed_content)
	if result:
		for group in result:
			parsed_content = parsed_content.replace(
				("{code}{case}{code}").format({code = group.get_string(1), case = group.get_string(2)}),
				("[code]{case}[/code]").format({case = group.get_string(2)})
				)
	
	return parsed_content
