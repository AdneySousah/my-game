extends SceneTree
## Shrinks the textures embedded in GLB files (Meshy delivers 2048 px) to a maximum
## size, rewriting the GLB in place. Run it on new downloads BEFORE copying them into
## assets/ so the repository (Git LFS) and the game stay small.
##   godot --headless --path . --script res://scripts/tools/glb_shrink.gd -- [--max 1024] <a.glb> [b.glb ...]
## Prints the size before and after. Geometry, skeleton and animations are untouched.

const GLB_MAGIC: int = 0x46546C67
const CHUNK_JSON: int = 0x4E4F534A
const CHUNK_BIN: int = 0x004E4942


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var max_px: int = 1024
	var files: Array[String] = []
	var i: int = 0
	while i < args.size():
		if args[i] == "--max" and i + 1 < args.size():
			max_px = int(args[i + 1])
			i += 2
			continue
		files.append(args[i])
		i += 1
	for f: String in files:
		var before: int = FileAccess.get_file_as_bytes(f).size()
		var ok: bool = shrink(f, max_px)
		var after: int = FileAccess.get_file_as_bytes(f).size()
		print("%s: %s  %.2f MB -> %.2f MB" % [f.get_file(), "ok" if ok else "sem mudança", before / 1e6, after / 1e6])
	quit()


## Returns true when the file was rewritten.
static func shrink(path: String, max_px: int) -> bool:
	var data: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if data.size() < 20 or data.decode_u32(0) != GLB_MAGIC:
		push_error("glb_shrink: %s não é GLB" % path)
		return false
	var json_len: int = data.decode_u32(12)
	if data.decode_u32(16) != CHUNK_JSON:
		return false
	var gltf: Dictionary = JSON.parse_string(data.slice(20, 20 + json_len).get_string_from_utf8())
	var bin_start: int = 20 + json_len
	if bin_start + 8 > data.size() or data.decode_u32(bin_start + 4) != CHUNK_BIN:
		return false
	var bin_len: int = data.decode_u32(bin_start)
	var bin: PackedByteArray = data.slice(bin_start + 8, bin_start + 8 + bin_len)

	var views: Array = gltf.get("bufferViews", [])
	var replaced: Dictionary = {}  # bufferView index -> new bytes
	for img: Dictionary in gltf.get("images", []):
		if not img.has("bufferView"):
			continue
		var vi: int = int(img["bufferView"])
		var v: Dictionary = views[vi]
		var start: int = int(v.get("byteOffset", 0))
		var bytes: PackedByteArray = bin.slice(start, start + int(v["byteLength"]))
		var mime: String = str(img.get("mimeType", "image/png"))
		var image := Image.new()
		var err: int = image.load_jpg_from_buffer(bytes) if mime == "image/jpeg" else image.load_png_from_buffer(bytes)
		if err != OK or maxi(image.get_width(), image.get_height()) <= max_px:
			continue
		var k: float = float(max_px) / maxi(image.get_width(), image.get_height())
		image.resize(roundi(image.get_width() * k), roundi(image.get_height() * k), Image.INTERPOLATE_LANCZOS)
		replaced[vi] = image.save_jpg_to_buffer(0.9) if mime == "image/jpeg" else image.save_png_to_buffer()
	if replaced.is_empty():
		return false

	# Rebuild the binary chunk view by view (4-byte aligned), with the new images.
	var out_bin := PackedByteArray()
	for vi: int in views.size():
		var v: Dictionary = views[vi]
		var start: int = int(v.get("byteOffset", 0))
		var bytes: PackedByteArray = replaced[vi] if replaced.has(vi) else bin.slice(start, start + int(v["byteLength"]))
		while out_bin.size() % 4 != 0:
			out_bin.append(0)
		v["byteOffset"] = out_bin.size()
		v["byteLength"] = bytes.size()
		out_bin.append_array(bytes)
	while out_bin.size() % 4 != 0:
		out_bin.append(0)
	(gltf["buffers"] as Array)[0]["byteLength"] = out_bin.size()

	var json_bytes: PackedByteArray = JSON.stringify(gltf).to_utf8_buffer()
	while json_bytes.size() % 4 != 0:
		json_bytes.append(0x20)
	var out := PackedByteArray()
	out.resize(12)
	out.encode_u32(0, GLB_MAGIC)
	out.encode_u32(4, 2)
	out.encode_u32(8, 12 + 8 + json_bytes.size() + 8 + out_bin.size())
	var head := PackedByteArray()
	head.resize(8)
	head.encode_u32(0, json_bytes.size())
	head.encode_u32(4, CHUNK_JSON)
	out.append_array(head)
	out.append_array(json_bytes)
	head.encode_u32(0, out_bin.size())
	head.encode_u32(4, CHUNK_BIN)
	out.append_array(head)
	out.append_array(out_bin)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(out)
	f.close()
	return true
