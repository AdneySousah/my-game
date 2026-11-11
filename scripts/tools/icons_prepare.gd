extends SceneTree
## Cuts the Meshy item icon sheets (4x4 icons on a dark background, assets/_inbox/icons)
## into one transparent 128x128 PNG per item in assets/ui/items/<id>.png.
##   godot --headless --path . --script res://scripts/tools/icons_prepare.gd [-- <output dir>]
## ItemIcon uses assets/ui/items/<id>.png automatically when the file exists.

const SRC: String = "res://assets/_inbox/icons/"
const DST: String = "res://assets/ui/items/"
const SIZE: int = 128
const GRID: int = 4
## Margin around the item inside the final square (fraction of the side).
const MARGIN: float = 0.07
## How close (0..1 RGB distance) a pixel must be to a background color to be removed.
const BG_TOLERANCE: float = 0.05
## Glow brighter than the background up to this much becomes partly transparent.
const GLOW_RANGE: float = 0.32
## A glow changes slowly from pixel to pixel; a bigger jump is the item's edge.
const GLOW_STEP: float = 0.03

## Sheet -> item ids, row by row (left to right). Ids that are not items yet are kept
## for the next stages (gems, Act 2 materials, equipment).
const SHEETS: Dictionary = {
	"ui_itens_consumiveis": [
		"pot_vida_p", "pot_vida_m", "pot_vida_g", "pot_folego_p",
		"pot_folego_m", "pot_folego_g", "pot_forca", "pot_pedra",
		"pot_vento", "trevo", "trevo_real", "broca",
		"broca_real", "amuleto", "pergaminho_retorno", "caixa_presente",
	],
	"ui_itens_materiais": [
		"gema_rubi", "gema_safira", "gema_esmeralda", "gema_topazio",
		"gema_ametista", "mat_couro_orc", "mat_osso_velho", "mat_fragmento_pedra",
		"mat_palha_dourada", "mat_cristal_areia", "mat_seda_deserto", "mat_fragmento_ruina",
		"mat_escama_duna", "mat_lingote_aco", "ouro", "chave_bronze",
	],
	"ui_itens_equip_1": [
		"eq_espada_comum", "eq_elmo_comum", "eq_peitoral_comum", "eq_luvas_comum",
		"eq_calca_comum", "eq_botas_comum", "eq_pulseira_comum", "eq_cinto_comum",
		"eq_espada_raro", "eq_elmo_raro", "eq_peitoral_raro", "eq_luvas_raro",
		"eq_calca_raro", "eq_botas_raro", "eq_pulseira_raro", "eq_cinto_raro",
	],
	"ui_itens_equip_2": [
		"eq_espada_epico", "eq_elmo_epico", "eq_peitoral_epico", "eq_luvas_epico",
		"eq_calca_epico", "eq_botas_epico", "eq_pulseira_epico", "eq_cinto_epico",
		"eq_espada_lendario", "eq_elmo_lendario", "eq_peitoral_lendario", "eq_luvas_lendario",
		"eq_calca_lendario", "eq_botas_lendario", "eq_pulseira_lendario", "eq_cinto_lendario",
	],
}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path(DST)
	DirAccess.make_dir_recursive_absolute(out)
	var made: int = 0
	for sheet: String in SHEETS:
		var path: String = ProjectSettings.globalize_path(SRC + sheet + ".png")
		if not FileAccess.file_exists(path):
			push_warning("missing sheet " + path)
			continue
		var img: Image = Image.load_from_file(path)
		img.convert(Image.FORMAT_RGBA8)
		var ids: Array = SHEETS[sheet]
		var cw: int = img.get_width() / GRID
		var ch: int = img.get_height() / GRID
		for i: int in ids.size():
			var cell: Image = img.get_region(Rect2i((i % GRID) * cw, (i / GRID) * ch, cw, ch))
			var icon: Image = _cut(cell)
			icon.save_png(out.path_join(str(ids[i]) + ".png"))
			made += 1
	print("ICONS_OK %d -> %s" % [made, out])
	quit()


## Removes the background around the item (flood fill from the cell border, so dark
## parts inside the item stay), softens glows, trims and fits it into SIZE x SIZE.
func _cut(cell: Image) -> Image:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var palette: Array[Color] = _background_palette(cell)
	var bg_lum: float = 0.0
	for c: Color in palette:
		bg_lum = maxf(bg_lum, c.get_luminance())
	var bg_ref: Color = palette[0]
	# 0 = item, 1 = background, 2 = glow (partly transparent)
	var kind := PackedByteArray()
	kind.resize(w * h)
	# Each entry: [pixel, luminance of the pixel it came from]
	var stack: Array = []
	for x: int in w:
		stack.append([Vector2i(x, 0), bg_lum])
		stack.append([Vector2i(x, h - 1), bg_lum])
	for y: int in h:
		stack.append([Vector2i(0, y), bg_lum])
		stack.append([Vector2i(w - 1, y), bg_lum])
	while not stack.is_empty():
		var e: Array = stack.pop_back()
		var p: Vector2i = e[0]
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or kind[p.y * w + p.x] != 0:
			continue
		var c: Color = cell.get_pixelv(p)
		var lum: float = c.get_luminance()
		if _is_background(c, palette):
			kind[p.y * w + p.x] = 1
		elif lum > bg_lum and lum - bg_lum < GLOW_RANGE and absf(lum - float(e[1])) < GLOW_STEP:
			kind[p.y * w + p.x] = 2
		else:
			continue
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			stack.append([p + d, lum])
	var box := Rect2i()
	var any: bool = false
	for y: int in h:
		for x: int in w:
			var k: int = kind[y * w + x]
			var c: Color = cell.get_pixel(x, y)
			if k == 1:
				cell.set_pixel(x, y, Color(bg_ref, 0.0))
				continue
			if k == 2:
				var a: float = smoothstep(0.0, GLOW_RANGE, c.get_luminance() - bg_lum)
				if a < 0.04:
					cell.set_pixel(x, y, Color(bg_ref, 0.0))
					continue
				# Undo the blend with the background so the glow keeps its colour.
				var col: Color = bg_ref + (c - bg_ref) / a
				cell.set_pixel(x, y, Color(clampf(col.r, 0, 1), clampf(col.g, 0, 1), clampf(col.b, 0, 1), a))
	_drop_edge_specks(cell, bg_ref)
	for y: int in h:
		for x: int in w:
			if cell.get_pixel(x, y).a > 0.04:
				var r := Rect2i(x, y, 1, 1)
				box = r if not any else box.merge(r)
				any = true
	if not any:
		box = Rect2i(0, 0, w, h)
	var side: int = int(ceil(maxf(box.size.x, box.size.y) / (1.0 - MARGIN * 2.0)))
	var square := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	square.fill(Color(bg_ref, 0.0))
	var at := Vector2i((side - box.size.x) / 2, (side - box.size.y) / 2)
	square.blit_rect(cell, box, at)
	square.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return square


## Clears small loose bits that touch the cell edges (the rounded tile borders of
## the sheet). Sparkles near the item are kept because they do not reach the edge.
func _drop_edge_specks(cell: Image, bg_ref: Color) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var edge: int = 10
	var small: int = int(w * h * 0.02)
	for sy: int in h:
		for sx: int in w:
			if seen[sy * w + sx] != 0 or cell.get_pixel(sx, sy).a <= 0.04:
				continue
			var comp: Array[Vector2i] = []
			var touches: bool = false
			var stack: Array[Vector2i] = [Vector2i(sx, sy)]
			seen[sy * w + sx] = 1
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				comp.append(p)
				if p.x < edge or p.y < edge or p.x >= w - edge or p.y >= h - edge:
					touches = true
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var q: Vector2i = p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or seen[q.y * w + q.x] != 0:
						continue
					if cell.get_pixelv(q).a > 0.04:
						seen[q.y * w + q.x] = 1
						stack.append(q)
			var bb := Rect2i(comp[0], Vector2i.ONE)
			for p: Vector2i in comp:
				bb = bb.expand(p)
			var density: float = float(comp.size()) / float(maxi(1, bb.size.x * bb.size.y))
			if touches and (comp.size() < small or density < 0.12):
				for p: Vector2i in comp:
					cell.set_pixelv(p, Color(bg_ref, 0.0))


## Background colours: the cell border (gap between tiles) and the tile corner.
func _background_palette(cell: Image) -> Array[Color]:
	var out: Array[Color] = []
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	for p: Vector2i in [Vector2i(1, 1), Vector2i(w - 2, h - 2), Vector2i(w / 2, 1), Vector2i(1, h / 2),
			Vector2i(24, 24), Vector2i(w - 25, 24), Vector2i(24, h - 25), Vector2i(w - 25, h - 25)]:
		var c: Color = cell.get_pixelv(p)
		if c.get_luminance() < 0.2 and not _is_background(c, out):
			out.append(c)
	if out.is_empty():
		out.append(Color(0.08, 0.08, 0.07))
	return out


func _is_background(c: Color, palette: Array[Color]) -> bool:
	for b: Color in palette:
		var d: float = Vector3(c.r - b.r, c.g - b.g, c.b - b.b).length()
		if d < BG_TOLERANCE:
			return true
	return false
