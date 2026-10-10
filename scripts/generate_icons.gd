extends SceneTree

func _init() -> void:
	print("Generating high-resolution launcher and store assets...")
	_generate_launcher_icon("res://assets/icons/app_icon.png", 512, 512)
	_generate_adaptive_foreground("res://assets/icons/adaptive_foreground.png", 432, 432)
	_generate_adaptive_background("res://assets/icons/adaptive_background.png", 432, 432)
	_generate_feature_graphic("res://assets/icons/feature_graphic.png", 1024, 500)
	print("Asset generation complete!")
	quit(0)

func _generate_launcher_icon(path: String, width: int, height: int) -> void:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var bg_color := Color("#11151c")
	var tile_color := Color("#3a86ff")
	var border_color := Color("#4cc9f0")
	img.fill(bg_color)
	
	# Draw rounded rectangle in center
	var pad := 64
	for y in range(pad, height - pad):
		for x in range(pad, width - pad):
			# Simple distance check for rounded corners
			var rx := float(x - pad)
			var ry := float(y - pad)
			var w := float(width - pad * 2)
			var h := float(height - pad * 2)
			var r := 48.0
			var is_corner := false
			if rx < r and ry < r and Vector2(rx - r, ry - r).length() > r:
				is_corner = true
			elif rx > (w - r) and ry < r and Vector2(rx - (w - r), ry - r).length() > r:
				is_corner = true
			elif rx < r and ry > (h - r) and Vector2(rx - r, ry - (h - r)).length() > r:
				is_corner = true
			elif rx > (w - r) and ry > (h - r) and Vector2(rx - (w - r), ry - (h - r)).length() > r:
				is_corner = true
			
			if not is_corner:
				# Border check
				if rx < 8 or rx >= (w - 8) or ry < 8 or ry >= (h - 8):
					img.set_pixel(x, y, border_color)
				else:
					img.set_pixel(x, y, tile_color)
	
	img.save_png(ProjectSettings.globalize_path(path))

func _generate_adaptive_foreground(path: String, width: int, height: int) -> void:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Transparent
	var center := Vector2(width / 2.0, height / 2.0)
	var box_radius := 110.0
	
	for y in range(height):
		for x in range(width):
			var pt := Vector2(x, y)
			if absf(pt.x - center.x) <= box_radius and absf(pt.y - center.y) <= box_radius:
				img.set_pixel(x, y, Color("#3a86ff"))
	
	img.save_png(ProjectSettings.globalize_path(path))

func _generate_adaptive_background(path: String, width: int, height: int) -> void:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color("#11151c"))
	img.save_png(ProjectSettings.globalize_path(path))

func _generate_feature_graphic(path: String, width: int, height: int) -> void:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	# Smooth gradient background
	for y in range(height):
		var frac := float(y) / float(height)
		var col := Color("#11151c").lerp(Color("#1c2333"), frac)
		for x in range(width):
			img.set_pixel(x, y, col)
	
	img.save_png(ProjectSettings.globalize_path(path))
