extends Node
## Builds the Google Play pictures from the Meshy art in assets/_inbox/store (needs a window):
##   godot --path . res://tests/store_art.tscn -- <output_dir>
## Saves icone_512.png (store icon), destaque_pt.png / destaque_en.png (1024x500 feature
## graphic with the game name) and the Android launcher icons app_icon_192.png,
## app_icon_bg_432.png, app_icon_fg_432.png (copied to assets/app/ as icon_*.png).

const ICON_SRC: String = "res://assets/_inbox/store/loja_icone.png"
const BANNER_SRC: String = "res://assets/_inbox/store/loja_destaque.png"
## The Meshy icon came with its own rounded corners: cut them off (full square for Play).
const ICON_INSET: float = 0.047
## Part of the banner (height, from the top) kept when cutting it to 1024x500.
const BANNER_TOP: float = 0.08

var _out: String = ""


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/store_art"
	DirAccess.make_dir_recursive_absolute(_out)
	_icons()
	for lang: String in ["pt_BR", "en"]:
		await _banner(lang)
	print("STORE_ART_OK -> " + _out)
	get_tree().quit()


func _load(path: String) -> Image:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img


func _icons() -> void:
	var src: Image = _load(ICON_SRC)
	var inset: int = roundi(src.get_width() * ICON_INSET)
	var side: int = src.get_width() - inset * 2
	var sq: Image = src.get_region(Rect2i(inset, inset, side, side))
	var store: Image = sq.duplicate()
	# Play asks for a 32-bit PNG (with alpha) for the store icon.
	store.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	store.save_png(_out + "/icone_512.png")
	var main: Image = sq.duplicate()
	main.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	main.save_png(_out + "/app_icon_192.png")
	# Adaptive icon: the launcher shows only the middle ~2/3 of the 432 square. The
	# picture (foreground, also used by the splash screen) goes in at 340 px; the
	# background is a blurred copy that fills the hidden border.
	var bg: Image = sq.duplicate()
	bg.resize(24, 24, Image.INTERPOLATE_BILINEAR)
	bg.resize(432, 432, Image.INTERPOLATE_BILINEAR)
	bg.convert(Image.FORMAT_RGB8)
	bg.save_png(_out + "/app_icon_bg_432.png")
	var mid: Image = sq.duplicate()
	mid.resize(340, 340, Image.INTERPOLATE_LANCZOS)
	var fg := Image.create_empty(432, 432, false, Image.FORMAT_RGBA8)
	fg.blit_rect(mid, Rect2i(0, 0, 340, 340), Vector2i(46, 46))
	fg.save_png(_out + "/app_icon_fg_432.png")


func _banner(lang: String) -> void:
	TranslationServer.set_locale(lang)
	var src: Image = _load(BANNER_SRC)
	var w: int = src.get_width()
	var h: int = roundi(w * 500.0 / 1024.0)
	var top: int = mini(roundi(src.get_height() * BANNER_TOP), src.get_height() - h)
	var cut: Image = src.get_region(Rect2i(0, top, w, h))
	cut.resize(1024, 500, Image.INTERPOLATE_LANCZOS)
	var vp := SubViewport.new()
	vp.size = Vector2i(1024, 500)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var pic := TextureRect.new()
	pic.texture = ImageTexture.create_from_image(cut)
	pic.size = Vector2(1024, 500)
	vp.add_child(pic)
	var title := Label.new()
	title.text = tr("TITLE_GAME")
	title.position = Vector2(540, 150)
	title.size = Vector2(460, 200)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_constant_override("line_spacing", -12)
	title.add_theme_color_override("font_color", Color("#ffd86b"))
	title.add_theme_color_override("font_outline_color", Color("#3b2410"))
	title.add_theme_constant_override("outline_size", 20)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title.add_theme_constant_override("shadow_offset_y", 6)
	vp.add_child(title)
	for i: int in 4:
		await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(_out + "/destaque_%s.png" % ("pt" if lang == "pt_BR" else "en"))
	vp.queue_free()
