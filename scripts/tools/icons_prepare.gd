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

## Sheets that are not items go to their own folder (menu shortcuts: assets/ui/menu).
const OTHER_DST: Dictionary = {"ui_menu": "res://assets/ui/menu/"}
## Sheets whose icons sit on a raised dark tile with a black rim: the tile goes too.
const TILED: Array[String] = ["ui_menu"]

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
	"ui_itens_equip_3": [
		"eq_espada_mitico", "eq_elmo_mitico", "eq_peitoral_mitico", "eq_luvas_mitico",
		"eq_calca_mitico", "eq_botas_mitico", "eq_pulseira_mitico", "eq_cinto_mitico",
		"eq_espada_celestial", "eq_elmo_celestial", "eq_peitoral_celestial", "eq_luvas_celestial",
		"eq_calca_celestial", "eq_botas_celestial", "eq_pulseira_celestial", "eq_cinto_celestial",
	],
	# Act 3-5 materials; the rest are kept for later (thorn, feather, ember, star, decree,
	# root, key, mushroom, weight).
	"ui_itens_materiais_2": [
		"mat_pele_neve", "mat_cristal_gelo", "mat_escama_pantano", "mat_seiva_amarga",
		"mat_selo_lei", "mat_corrente", "mat_insignia_chefe", "",
		"", "", "", "",
		"", "", "", "",
	],
	# Post-game (6.6): the Infernal Essence; the rest is kept for later (horn, lava stone,
	# rune, burning feather, hourglass, skull ember, red chain, star, feather, sky crystal,
	# pearl, void shard, key, sun and moon medals).
	"ui_itens_materiais_3": [
		"mat_essencia_infernal", "", "", "",
		"", "", "", "",
		"", "", "", "",
		"", "", "", "",
	],
	# 13/11: MP potions, the quest board and the wanted poster (icons for the boards);
	# the herbs and the mortar are kept for the herb gathering planned for later.
	"ui_itens_pocoes_mp": [
		"pot_mana_p", "pot_mana_m", "pot_mana_g", "ui_quadro",
		"ui_procurado", "ui_trofeu", "ui_extrema", "",
		"", "", "", "",
		"", "", "", "",
	],
	# 13/11: the extra backpacks and the special shop's looks.
	# Fase 8B: the five boss sets (two per sheet, weapon/helmet/chest/gloves then
	# pants/boots/bracelet/belt), their shards and essences, the lair license, the six
	# skill runes (8C) and seven fish (8D).
	"ui_itens_covis_1": [
		"eq_arma_gorvan", "eq_elmo_gorvan", "eq_peitoral_gorvan", "eq_luvas_gorvan",
		"eq_calca_gorvan", "eq_botas_gorvan", "eq_pulseira_gorvan", "eq_cinto_gorvan",
		"eq_arma_sahra", "eq_elmo_sahra", "eq_peitoral_sahra", "eq_luvas_sahra",
		"eq_calca_sahra", "eq_botas_sahra", "eq_pulseira_sahra", "eq_cinto_sahra",
	],
	"ui_itens_covis_2": [
		"eq_arma_brannoc", "eq_elmo_brannoc", "eq_peitoral_brannoc", "eq_luvas_brannoc",
		"eq_calca_brannoc", "eq_botas_brannoc", "eq_pulseira_brannoc", "eq_cinto_brannoc",
		"eq_arma_velyra", "eq_elmo_velyra", "eq_peitoral_velyra", "eq_luvas_velyra",
		"eq_calca_velyra", "eq_botas_velyra", "eq_pulseira_velyra", "eq_cinto_velyra",
	],
	"ui_itens_covis_3": [
		"eq_arma_vaelor", "eq_elmo_vaelor", "eq_peitoral_vaelor", "eq_luvas_vaelor",
		"eq_calca_vaelor", "eq_botas_vaelor", "eq_pulseira_vaelor", "eq_cinto_vaelor",
		"mat_frag_gorvan", "mat_ess_gorvan", "mat_frag_sahra", "mat_ess_sahra",
		"mat_frag_brannoc", "mat_ess_brannoc", "mat_frag_velyra", "mat_ess_velyra",
	],
	"ui_itens_covis_4": [
		"mat_frag_vaelor", "mat_ess_vaelor", "licenca_covil", "runa_fogo",
		"runa_gelo", "runa_raio", "runa_sangue", "runa_luz",
		"runa_eco", "peixe_tilapia", "peixe_truta", "peixe_lua",
		"peixe_bagre", "peixe_carpa", "peixe_gelo", "peixe_sol",
	],
	# Fase 8D: ingredients, the cooking pot, the nine meals; and the bestiary book, the
	# mastery star and the house key for 8E/8F.
	"ui_itens_comidas": [
		"erva_silvestre", "carne_crua", "cogumelo", "ui_panela",
		"comida_peixe_assado", "comida_espeto_carne", "comida_sopa_cogumelo", "comida_ensopado_peixe",
		"comida_truta_ervas", "comida_bagre_picante", "comida_peixe_lua", "comida_sopa_gelo",
		"comida_banquete_sol", "ui_bestiario", "ui_maestria", "ui_chave_casa",
	],
	"ui_itens_eventos": [
		"mat_fragmento_estelar", "ui_ev_horde", "ui_ev_caravan", "ui_ev_errant",
		"ui_ev_stars", "ui_bless_mana", "ui_bless_vampiro", "ui_bless_furia",
		"ui_bless_escudo", "ui_bless_vento", "ui_bless_tempo", "ui_bless_critico",
		"ui_bless_vida", "ui_bless_ouro", "ui_bless_combo", "ui_fenda",
	],
	"ui_itens_mochilas": [
		"mochila_couro", "mochila_real", "ui_skin_anjo", "ui_skin_sol",
		"ui_skin_tempestade", "", "", "",
		"", "", "", "",
		"", "", "", "",
	],
	# "" = not used yet (map, options, skills, attributes, equipment, achievements,
	# travel, gift, title, forge, portal); the anvil and the portal need a better cut.
	"ui_menu": [
		"store", "routine", "bag", "quests",
		"talk", "", "", "",
		"", "", "", "",
		"", "", "forge", "",
	],
}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var custom_out: String = args[0] if args.size() > 0 else ""
	var made: int = 0
	var out: String = ""
	for sheet: String in SHEETS:
		out = custom_out if custom_out != "" else ProjectSettings.globalize_path(str(OTHER_DST.get(sheet, DST)))
		DirAccess.make_dir_recursive_absolute(out)
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
			if str(ids[i]) == "":
				continue
			var cell: Image = img.get_region(Rect2i((i % GRID) * cw, (i / GRID) * ch, cw, ch))
			var icon: Image = _cut(cell, sheet in TILED)
			icon.save_png(out.path_join(str(ids[i]) + ".png"))
			made += 1
	print("ICONS_OK %d -> %s" % [made, out])
	quit()


## Removes the background around the item (flood fill from the cell border, so dark
## parts inside the item stay), softens glows, trims and fits it into SIZE x SIZE.
func _cut(cell: Image, tiled: bool = false) -> Image:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var palette: Array[Color] = _background_palette(cell)
	if tiled:
		_add_tile_colors(cell, palette)
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
	_drop_edge_specks(cell, bg_ref, tiled)
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
func _drop_edge_specks(cell: Image, bg_ref: Color, tiled: bool = false) -> void:
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
			# Tiled sheets: the light bevel of the tile is left as a long thin line.
			var thin_line: bool = tiled and maxi(bb.size.x, bb.size.y) >= w / 4 					and (mini(bb.size.x, bb.size.y) <= 10 or density < 0.2)
			# ...and bits of it in the outer band of the cell (the tile edge).
			var band: float = 0.24
			var in_band: bool = bb.end.y < h * band or bb.position.y > h * (1.0 - band) 					or bb.end.x < w * band or bb.position.x > w * (1.0 - band)
			if tiled and in_band and comp.size() < small:
				thin_line = true
			if thin_line or (touches and (comp.size() < small or density < 0.12)):
				for p: Vector2i in comp:
					cell.set_pixelv(p, Color(bg_ref, 0.0))


## Walks in from the middle of each side and keeps every dark grey on the way (the gap,
## the tile's black rim and the tile itself) until the picture starts.
func _add_tile_colors(cell: Image, palette: Array[Color]) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var walks: Array = [[Vector2i(0, h / 2), Vector2i.RIGHT], [Vector2i(w - 1, h / 2), Vector2i.LEFT],
		[Vector2i(w / 2, 0), Vector2i.DOWN], [Vector2i(w / 2, h - 1), Vector2i.UP]]
	for walk: Array in walks:
		var p: Vector2i = walk[0]
		var d: Vector2i = walk[1]
		# Only the outer part of the cell: the gap, the rim and the tile's light bevel.
		for i: int in int(w * 0.22):
			var c: Color = cell.get_pixelv(p)
			# Chroma, not HSV saturation: near-black pixels have a meaningless saturation.
			var chroma: float = maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			if c.get_luminance() >= 0.36 or chroma > 0.1:
				break
			if not _is_background(c, palette):
				palette.append(c)
			p += d


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
