class_name LoadingScreen
extends CanvasLayer
## Full-screen loading card shown when the game starts and on every map change:
## an illustration of the place the hero is going to, its name, a tip and a bar.
## It lives under the tree root (not inside a scene), so it survives the change from
## the title screen to Main and covers the freeze while the scene loads.
##   var ls := LoadingScreen.open(get_tree(), "qaressa")
##   await ls.shown          # fully covering the screen
##   ...build the map...
##   await ls.close()        # bar fills, card fades out and frees itself
## Art: assets/loading/load_<map>.webp (or the map's "loading" field), made from the
## Meshy images in assets/_inbox/loading by scripts/tools/story_prepare.gd.

signal shown

const ART_DIR: String = "res://assets/loading/"
const FALLBACK_ART: String = "load_pradoluz"
const FADE: float = 0.25
## The card stays at least this long, so the art and the tip can be seen.
const MIN_TIME: float = 1.3
const TIP_COUNT: int = 12

static var _current: LoadingScreen = null

var map_id: String = ""
var _root: Control
var _bar: FramedBar
var _opened_at: float = 0.0
var _is_shown: bool = false


## Opens the card for `map_id` (or returns the one already open, e.g. title -> Main).
static func open(tree: SceneTree, target_map: String) -> LoadingScreen:
	if is_instance_valid(_current) and not _current.is_queued_for_deletion():
		if _current.map_id != target_map:
			_current._set_map(target_map)
		return _current
	var ls := LoadingScreen.new()
	ls.map_id = target_map
	_current = ls
	tree.root.add_child.call_deferred(ls)
	return ls


static func is_open() -> bool:
	return is_instance_valid(_current) and not _current.is_queued_for_deletion()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = GameTheme.get_theme()
	_root.modulate.a = 0.0
	add_child(_root)
	_build()
	_set_map(map_id)
	_opened_at = Time.get_ticks_msec() / 1000.0
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, FADE)
	tw.tween_callback(func() -> void:
		# One more frame so the card is really on screen before the heavy work starts.
		await get_tree().process_frame
		await get_tree().process_frame
		_is_shown = true
		shown.emit())


## Waits until the card covers the screen (returns at once when it already does).
func wait_shown() -> void:
	if not _is_shown:
		await shown


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#120c06")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var art := TextureRect.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_root.add_child(art)

	# Dark band at the bottom so the name, tip and bar read over any picture.
	var shade := TextureRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.85))
	grad.add_point(0.55, Color(0, 0, 0, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	shade.texture = gt
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)

	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 60
	box.offset_right = -60
	box.offset_top = -190
	box.offset_bottom = -26
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 8)
	_root.add_child(box)

	var title := Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_color", Color("#ffe6a8"))
	box.add_child(title)

	var tip := Label.new()
	tip.name = "Tip"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 21)
	tip.add_theme_constant_override("outline_size", 6)
	box.add_child(tip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	_bar = FramedBar.new()
	_bar.custom_minimum_size = Vector2(0, 44)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.fill_color = Color("#f2c14e")
	_bar.max_value = 1.0
	_bar.value = 0.0
	row.add_child(_bar)
	var loading := Label.new()
	loading.text = tr("LOAD_LOADING")
	loading.add_theme_font_size_override("font_size", 20)
	loading.add_theme_constant_override("outline_size", 6)
	row.add_child(loading)


func _set_map(id: String) -> void:
	map_id = id
	if _root == null:
		return
	(_root.get_node("Art") as TextureRect).texture = _art_for(id)
	var data: Dictionary = GameMap.load_data(id) if id != "" else {}
	(_root.find_child("Title", true, false) as Label).text = tr(str(data.get("name", ""))) if data.has("name") else ""
	var n: int = randi_range(1, TIP_COUNT)
	(_root.find_child("Tip", true, false) as Label).text = tr("LOAD_TIP_%d" % n)


static func _art_for(id: String) -> Texture2D:
	var names: Array[String] = ["load_" + id]
	var data: Dictionary = GameMap.load_data(id) if id != "" else {}
	if data.has("loading"):
		names.push_front(str(data["loading"]))
	names.append(FALLBACK_ART)
	for n: String in names:
		var path: String = ART_DIR + n + ".webp"
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func set_progress(v: float) -> void:
	if _bar:
		create_tween().tween_property(_bar, "value", clampf(v, 0.0, 1.0), 0.15)


## Fills the bar, keeps the card up for MIN_TIME in total, fades out and frees it.
func close() -> void:
	await wait_shown()
	var left: float = MIN_TIME - (Time.get_ticks_msec() / 1000.0 - _opened_at)
	var tw := create_tween()
	tw.tween_property(_bar, "value", 1.0, maxf(0.25, left))
	tw.tween_interval(0.1)
	tw.tween_property(_root, "modulate:a", 0.0, FADE)
	await tw.finished
	if _current == self:
		_current = null
	queue_free()
