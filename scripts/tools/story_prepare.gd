extends SceneTree
## Turns the raw Meshy story panels (assets/_inbox/story/*.png) into game images
## in assets/story: trims the paper border some panels come with, crops to 16:9 and
## saves a 1280x720 WebP (small files for mobile).
##   godot --headless --path . --script res://scripts/tools/story_prepare.gd

const SRC: String = "res://assets/_inbox/story/"
const DST: String = "res://assets/story/"
const OUT_SIZE: Vector2i = Vector2i(1280, 720)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	for f: String in DirAccess.get_files_at(SRC):
		if not f.ends_with(".png"):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + f))
		img.convert(Image.FORMAT_RGB8)
		var r: Rect2i = _trim_border(img)
		r = _fit_16_9(r)
		img = img.get_region(r)
		img.resize(OUT_SIZE.x, OUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var out: String = DST + f.get_basename() + ".webp"
		img.save_webp(ProjectSettings.globalize_path(out), true, 0.88)
		print("%s -> border %s -> %s" % [f, r, out])
	quit()


## Shrinks the rect while the outer row/column is bright paper (light and flat).
func _trim_border(img: Image) -> Rect2i:
	var r := Rect2i(Vector2i.ZERO, img.get_size())
	for i: int in 80:
		var changed: bool = false
		if _is_paper_row(img, r.position.y, r):
			r.position.y += 1; r.size.y -= 1; changed = true
		if _is_paper_row(img, r.end.y - 1, r):
			r.size.y -= 1; changed = true
		if _is_paper_col(img, r.position.x, r):
			r.position.x += 1; r.size.x -= 1; changed = true
		if _is_paper_col(img, r.end.x - 1, r):
			r.size.x -= 1; changed = true
		if not changed:
			break
	# A little extra so no paper fringe is left.
	return r.grow(-6) if r.size != img.get_size() else r


func _is_paper_row(img: Image, y: int, r: Rect2i) -> bool:
	var bright: int = 0
	var n: int = 0
	for x: int in range(r.position.x, r.end.x, 8):
		n += 1
		if img.get_pixel(x, y).get_luminance() > 0.8:
			bright += 1
	return float(bright) / n > 0.7


func _is_paper_col(img: Image, x: int, r: Rect2i) -> bool:
	var bright: int = 0
	var n: int = 0
	for y: int in range(r.position.y, r.end.y, 8):
		n += 1
		if img.get_pixel(x, y).get_luminance() > 0.8:
			bright += 1
	return float(bright) / n > 0.7


## Largest centred 16:9 rect inside r.
func _fit_16_9(r: Rect2i) -> Rect2i:
	var w: int = r.size.x
	var h: int = roundi(w * 9.0 / 16.0)
	if h > r.size.y:
		h = r.size.y
		w = roundi(h * 16.0 / 9.0)
	return Rect2i(r.position + (r.size - Vector2i(w, h)) / 2, Vector2i(w, h))
