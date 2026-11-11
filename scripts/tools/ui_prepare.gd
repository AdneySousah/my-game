extends SceneTree
## Turns the raw Meshy UI images (assets/_inbox/ui) into game-ready textures in assets/ui:
## crops transparent borders, resizes for mobile, and cuts skill icons into circles.
##   godot --headless --path . --script res://scripts/tools/ui_prepare.gd

const SRC: String = "res://assets/_inbox/ui/"
const DST: String = "res://assets/ui/"

## name -> target width in pixels (height keeps the aspect ratio).
const FRAMES: Dictionary = {
	"ui_painel": 256,
	"ui_dialogo": 640,
	"ui_botao": 280,
	"ui_botao_redondo": 256,
	"ui_barra": 420,
	"ui_moldura_minimapa": 320,
}
const ICONS: Array[String] = [
	"corte_giratorio", "investida", "golpe_sismico", "quebra_guarda",
	"brado_de_guerra", "onda_de_corte", "salto_devastador", "julgamento",
]
const ICON_SIZE: int = 160
## Portraits: square region around the face (in the 1024 px source) -> circle.
const PORTRAITS: Dictionary = {
	"ui_retrato_lio": Rect2i(190, 110, 680, 680),
}
const PORTRAIT_SIZE: int = 192


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	for name: String in FRAMES:
		var img: Image = _load(SRC + name + ".png")
		img = img.get_region(_bounds(img, 0.35))
		var w: int = int(FRAMES[name])
		img.resize(w, maxi(1, roundi(float(img.get_height()) * w / img.get_width())), Image.INTERPOLATE_LANCZOS)
		img.save_png(ProjectSettings.globalize_path(DST + name + ".png"))
		print("%s -> %dx%d" % [name, img.get_width(), img.get_height()])
		if name == "ui_moldura_minimapa":
			_measure_hole(img)
	for icon: String in ICONS:
		var img: Image = _load(SRC + "icon_" + icon + ".png")
		img.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_LANCZOS)
		_circle_mask(img, ICON_SIZE * 0.5 - 1.0)
		img.save_png(ProjectSettings.globalize_path(DST + "icon_" + icon + ".png"))
	print("icons -> %d x %dpx" % [ICONS.size(), ICON_SIZE])
	for name: String in PORTRAITS:
		var img: Image = _load(SRC + name + ".png")
		img = img.get_region(PORTRAITS[name])
		img.resize(PORTRAIT_SIZE, PORTRAIT_SIZE, Image.INTERPOLATE_LANCZOS)
		_circle_mask(img, PORTRAIT_SIZE * 0.5 - 1.0)
		img.save_png(ProjectSettings.globalize_path(DST + name + ".png"))
		print("%s -> %dpx" % [name, PORTRAIT_SIZE])
	quit()


## Bounding box of pixels more opaque than `threshold` (ignores soft shadows).
func _bounds(img: Image, threshold: float) -> Rect2i:
	var min_p := Vector2i(img.get_width(), img.get_height())
	var max_p := Vector2i(-1, -1)
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a > threshold:
				min_p = Vector2i(mini(min_p.x, x), mini(min_p.y, y))
				max_p = Vector2i(maxi(max_p.x, x), maxi(max_p.y, y))
	return Rect2i(min_p, max_p - min_p + Vector2i.ONE)


func _load(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img


func _circle_mask(img: Image, radius: float) -> void:
	var c := Vector2(img.get_width(), img.get_height()) * 0.5
	for y: int in img.get_height():
		for x: int in img.get_width():
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > radius:
				var col: Color = img.get_pixel(x, y)
				col.a *= clampf(1.0 - (d - radius), 0.0, 1.0)
				img.set_pixel(x, y, col)


## Prints the radius of the empty hole in the minimap frame, as a fraction of its width.
func _measure_hole(img: Image) -> void:
	var cy: int = img.get_height() / 2
	var cx: int = img.get_width() / 2
	var x: int = cx
	while x < img.get_width() and img.get_pixel(x, cy).a < 0.5:
		x += 1
	print("minimap hole radius = %d px of %d (%.3f of width)" % [x - cx, img.get_width(), float(x - cx) / img.get_width()])
