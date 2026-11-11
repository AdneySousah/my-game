extends SceneTree
## Puts several PNGs side by side in one image (on a checker so transparency shows).
##   godot --headless --path . --script res://tests/image_grid.gd -- <out.png> <cell_px> <cols> <a.png> <b.png> ...


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	var cell: int = int(args[1])
	var cols: int = int(args[2])
	var files: PackedStringArray = args.slice(3)
	var rows: int = ceili(float(files.size()) / cols)
	var sheet := Image.create(cell * cols, cell * rows, false, Image.FORMAT_RGBA8)
	for y: int in sheet.get_height():
		for x: int in sheet.get_width():
			var dark: bool = ((x / 16) + (y / 16)) % 2 == 0
			sheet.set_pixel(x, y, Color(0.35, 0.35, 0.4) if dark else Color(0.5, 0.5, 0.55))
	for i: int in files.size():
		var img := Image.load_from_file(files[i])
		if img == null:
			continue
		img.convert(Image.FORMAT_RGBA8)
		var s: float = float(cell) / maxf(img.get_width(), img.get_height())
		img.resize(maxi(1, int(img.get_width() * s)), maxi(1, int(img.get_height() * s)))
		var pos := Vector2i((i % cols) * cell + (cell - img.get_width()) / 2, (i / cols) * cell + (cell - img.get_height()) / 2)
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
		print("%s %dx%d" % [files[i].get_file(), Image.load_from_file(files[i]).get_width(), Image.load_from_file(files[i]).get_height()])
	sheet.save_png(out)
	quit()
