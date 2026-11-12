class_name SkillVfx
extends RefCounted
## Visual effects of the hero's skills: slash arcs, shockwaves, cracks, earth spikes, sparks,
## light pillars, shield shards... All built in code (meshes, materials, CPUParticles3D and
## tweens), short-lived and self-freeing. Only visuals: no gameplay here.
## Angles on the ground: 0 = -Z (the node's forward), positive = turning left (like rotation.y).

const SPARK_WHITE: Color = Color(1.0, 0.97, 0.88)
const ROCK: Color = Color(0.66, 0.55, 0.43)
const DUST: Color = Color(0.62, 0.52, 0.4, 0.75)

static var _mesh_cache: Dictionary = {}
static var _dot_tex: ImageTexture


# --- Building blocks ----------------------------------------------------------------------

## Unshaded effect material. Colours come from vertex colours times `color`.
static func fx_material(color: Color, additive: bool = false, priority: int = 0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	m.render_priority = priority
	return m


## Ground direction for an angle (see the header).
static func dir_at(a: float) -> Vector3:
	return Vector3(-sin(a), 0.0, -cos(a))


## Flat band on the XZ plane around the origin, radius `r` (+-`half_w`), from angle a0 to a1.
## taper: thin pointed ends, thickest near the head (a crescent). fade_tail: transparent at a0.
## soft: edges fade out (glow); otherwise a crisp band.
static func arc_mesh(r: float, half_w: float, a0: float, a1: float, segs: int, taper: bool, fade_tail: bool, soft: bool) -> ArrayMesh:
	var key: String = "arc_%.3f_%.3f_%.3f_%.3f_%d_%s_%s_%s" % [r, half_w, a0, a1, segs, taper, fade_tail, soft]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var offs: Array[float] = [-1.0, 1.0]
	var alphas: Array[float] = [1.0, 1.0]
	if soft:
		offs = [-1.0, -0.55, 0.55, 1.0]
		alphas = [0.0, 1.0, 1.0, 0.0]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: int = offs.size()
	for i: int in segs + 1:
		var t: float = float(i) / float(segs)
		var a: float = lerpf(a0, a1, t)
		var profile: float = pow(sin(pow(t, 1.8) * PI), 0.7) if taper else 1.0
		var head: float = smoothstep(0.0, 0.75, t) if fade_tail else 1.0
		for j: int in rows:
			st.set_color(Color(1, 1, 1, alphas[j] * head))
			st.set_uv(Vector2(t, float(j) / float(rows - 1)))
			st.add_vertex(dir_at(a) * (r + offs[j] * half_w * maxf(profile, 0.02)))
	for i: int in segs:
		for j: int in rows - 1:
			var v0: int = i * rows + j
			var v1: int = v0 + rows
			st.add_index(v0)
			st.add_index(v1)
			st.add_index(v0 + 1)
			st.add_index(v0 + 1)
			st.add_index(v1)
			st.add_index(v1 + 1)
	var mesh: ArrayMesh = st.commit()
	_mesh_cache[key] = mesh
	return mesh


## Soft ring of radius 1 (scale it), band width +-`half_w`.
static func ring_mesh(half_w: float = 0.12) -> ArrayMesh:
	return arc_mesh(1.0, half_w, 0.0, TAU, 48, false, false, true)


## Round soft dot (for particles), white with alpha.
static func dot_texture() -> ImageTexture:
	if _dot_tex == null:
		var size: int = 32
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y: int in size:
			for x: int in size:
				var d: float = Vector2(x + 0.5 - size * 0.5, y + 0.5 - size * 0.5).length() / (size * 0.5)
				var a: float = clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
		_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex


static func spawn(parent: Node, mesh: Mesh, mat: Material, at: Vector3, yaw: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = at
	mi.rotation.y = yaw
	return mi


## Fades the node's material to clear in `time` (after `delay`) and frees it.
static func fade_out(mi: GeometryInstance3D, time: float, delay: float = 0.0) -> Tween:
	var mat: StandardMaterial3D = mi.material_override
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(mat, "albedo_color:a", 0.0, time).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return tw


## Expanding ring on the ground (shockwave).
static func shockwave(parent: Node, at: Vector3, radius: float, color: Color, time: float = 0.4, width: float = 0.12, delay: float = 0.0) -> void:
	var mi := spawn(parent, ring_mesh(width), fx_material(color, false, 1), at + Vector3(0, 0.06, 0))
	mi.scale = Vector3.ONE * radius * 0.25
	mi.visible = delay <= 0.0
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
		tw.tween_callback(mi.show)
	tw.tween_property(mi, "scale", Vector3.ONE * radius, time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fade_out(mi, time * 0.8, delay + time * 0.3)
	# White inner edge so the ring reads on bright grass.
	var core := spawn(parent, ring_mesh(width * 0.35), fx_material(Color(SPARK_WHITE, 0.9), true, 2), at + Vector3(0, 0.07, 0))
	core.scale = mi.scale
	core.visible = mi.visible
	var tc := core.create_tween()
	if delay > 0.0:
		tc.tween_interval(delay)
		tc.tween_callback(core.show)
	tc.tween_property(core, "scale", Vector3.ONE * radius * 0.98, time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fade_out(core, time * 0.6, delay + time * 0.3)


## Disc that grows and fades on the ground: the bright "flash" under an impact.
static func ground_flash(parent: Node, at: Vector3, radius: float, color: Color, time: float = 0.3) -> void:
	var mi := spawn(parent, arc_mesh(0.5, 0.5, 0.0, TAU, 40, false, false, true), fx_material(Color(color, 0.8), true, 0), at + Vector3(0, 0.05, 0))
	mi.scale = Vector3.ONE * radius * 0.6
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * radius * 1.1, time).set_ease(Tween.EASE_OUT)
	fade_out(mi, time)


## One-shot burst of glowing dots.
## up: 0 = all directions on the ground plane, 1 = straight up. gravity pulls them down.
static func burst(parent: Node, at: Vector3, color: Color, amount: int, speed: float, life: float = 0.5,
		size: float = 0.18, up: float = 0.5, gravity: float = -9.0, spread: float = 0.3, additive: bool = false) -> CPUParticles3D:
	var p := particles(color, amount, speed, life, size, up, gravity, spread, additive)
	p.one_shot = true
	p.explosiveness = 0.95
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(life * 1.5 + 0.1)
	tw.tween_callback(p.queue_free)
	return p


## Glowing dots, configured but not in the tree and not emitting (see burst()).
static func particles(color: Color, amount: int, speed: float, life: float = 0.5, size: float = 0.18,
		up: float = 0.5, gravity: float = -9.0, spread: float = 0.3, additive: bool = false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.randomness = 0.5
	p.lifetime_randomness = 0.4
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = dot_texture()
	mat.render_priority = 3
	quad.material = mat
	p.mesh = quad
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread
	if up >= 0.5:
		p.direction = Vector3.UP
		p.spread = lerpf(90.0, 15.0, (up - 0.5) * 2.0)
	else:
		p.direction = Vector3(1, up, 0).normalized()
		p.spread = 180.0
		p.flatness = 1.0 - up * 2.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, gravity, 0)
	p.damping_min = speed * 0.6
	p.damping_max = speed * 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0.15))
	p.scale_amount_curve = curve
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	ramp.colors = PackedColorArray([Color(SPARK_WHITE.lerp(color, 0.35), color.a), Color(color, color.a), Color(color, 0.0)])
	p.color_ramp = ramp
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## Small spark burst where a skill hits an enemy.
static func hit_sparks(parent: Node, at: Vector3, color: Color, amount: int = 8) -> void:
	burst(parent, at + Vector3(0, 1.0, 0), color, amount, 7.0, 0.35, 0.16, 0.45, -6.0, 0.2)


## Dust puff on the ground (alpha, not additive, so it reads as dust).
static func dust(parent: Node, at: Vector3, amount: int = 10, radius: float = 0.6, speed: float = 3.0) -> void:
	burst(parent, at + Vector3(0, 0.2, 0), DUST, amount, speed, 0.7, 0.55, 0.25, 0.5, radius, false)


## A glowing ribbon arc that sweeps around `at` (slash). yaw = centre direction of the arc.
## sweep > 0 sweeps counter-clockwise seen from above. tilt rolls the arc around its centre line.
static func slash_arc(parent: Node, at: Vector3, yaw: float, radius: float, span: float, color: Color,
		time: float = 0.22, sweep: float = 0.0, tilt: float = 0.0, width: float = 0.35) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = at
	root.rotation = Vector3(0, yaw, 0)
	var holder := Node3D.new()
	holder.rotation.z = tilt
	root.add_child(holder)
	var layers: Array[MeshInstance3D] = blade_layers(holder, radius, width, span, color, true)
	var glow: MeshInstance3D = layers[1]
	var core: MeshInstance3D = layers[2]
	var rim: MeshInstance3D = layers[0]
	if sweep < 0.0:
		# Head of the crescent is at +span/2: mirror so it leads the clockwise sweep.
		holder.scale.x = -1.0
	var tw := root.create_tween().set_parallel(true)
	if sweep != 0.0:
		tw.tween_property(root, "rotation:y", yaw + sweep, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(holder, "scale", Vector3(holder.scale.x * 1.12, 1.0, 1.12), time)
	tw.tween_property(glow.material_override, "albedo_color:a", 0.0, time * 0.7).set_delay(time * 0.45)
	tw.tween_property(rim.material_override, "albedo_color:a", 0.0, time * 0.6).set_delay(time * 0.4)
	tw.tween_property(core.material_override, "albedo_color:a", 0.0, time * 0.6).set_delay(time * 0.4)
	tw.chain().tween_callback(root.queue_free)
	return root


## The three layers of a glowing blade crescent (rim, glow, core) as children of `holder`:
## a darker rim so it reads on bright grass, the coloured glow and a thin white-hot edge.
static func blade_layers(holder: Node3D, radius: float, width: float, span: float, color: Color, fade_tail: bool) -> Array[MeshInstance3D]:
	var specs: Array = [
		[radius, width * 1.12, Color(color.darkened(0.45), 0.55), false, false, 3],
		[radius, width, Color(color, 1.0), false, true, 4],
		[radius + width * 0.3, width * 0.16, Color(SPARK_WHITE, 1.0), true, false, 5]]
	var out: Array[MeshInstance3D] = []
	for l: Array in specs:
		var mi := MeshInstance3D.new()
		mi.mesh = arc_mesh(l[0], l[1], -span * 0.5, span * 0.5, 32, true, fade_tail, l[4])
		mi.material_override = fx_material(l[2], l[3], l[5])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		out.append(mi)
	return out


## Charging: a ring that closes in on `at` with gathering light.
static func charge(parent: Node, at: Vector3, color: Color, time: float, radius: float = 1.6) -> void:
	var mi := spawn(parent, ring_mesh(0.1), fx_material(Color(color, 0.0), true, 1), at + Vector3(0, 0.06, 0))
	mi.scale = Vector3.ONE * radius
	var mat: StandardMaterial3D = mi.material_override
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.35, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(mat, "albedo_color:a", 1.0, time * 0.6)
	tw.chain().tween_callback(mi.queue_free)
	var p := burst(parent, at + Vector3(0, 0.9, 0), color, 14, 0.0, time, 0.16, 1.0, 0.0, radius * 0.9)
	p.explosiveness = 0.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	p.radial_accel_min = -18.0
	p.radial_accel_max = -12.0
	p.damping_min = 0.0
	p.damping_max = 0.0


## Jagged glowing cracks on the ground from `at`, `count` branches spread over `span` around `yaw`.
static func cracks(parent: Node, at: Vector3, yaw: float, length: float, span: float, count: int, color: Color, life: float = 1.6) -> void:
	var dark := SurfaceTool.new()
	var glow := SurfaceTool.new()
	dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: int in count:
		var a: float = (float(b) / maxf(count - 1, 1) - 0.5) * span if span < TAU - 0.01 else float(b) / count * TAU
		a += randf_range(-0.12, 0.12)
		var p: Vector3 = dir_at(a) * 0.35
		var seg: int = 5
		var w: float = 0.24
		var branch_len: float = length * randf_range(0.7, 1.0)
		for i: int in seg:
			a += randf_range(-0.35, 0.35)
			var q: Vector3 = p + dir_at(a) * branch_len / seg
			var w2: float = w * 0.72
			_crack_quad(dark, p, q, w * 1.9, w2 * 1.9)
			_crack_quad(glow, p, q, w * 0.7, w2 * 0.7)
			if i == 2 and randf() < 0.7:
				var side: float = a + (0.7 if randf() < 0.5 else -0.7)
				var r: Vector3 = q + dir_at(side) * branch_len * 0.22
				_crack_quad(dark, q, r, w2 * 1.6, 0.02)
				_crack_quad(glow, q, r, w2 * 0.6, 0.01)
			p = q
			w = w2
	var base: Vector3 = at + Vector3(0, 0.045, 0)
	var dark_mi := spawn(parent, dark.commit(), fx_material(Color(0.12, 0.07, 0.04, 0.8), false, 0), base, yaw)
	var glow_mi := spawn(parent, glow.commit(), fx_material(Color(color.lerp(SPARK_WHITE, 0.25), 1.0), true, 1), base + Vector3(0, 0.005, 0), yaw)
	fade_out(dark_mi, life * 0.5, life * 0.5)
	fade_out(glow_mi, life * 0.45, life * 0.15)


static func _crack_quad(st: SurfaceTool, a: Vector3, b: Vector3, wa: float, wb: float) -> void:
	var d: Vector3 = b - a
	var side: Vector3 = Vector3(-d.z, 0.0, d.x).normalized()
	var v: Array[Vector3] = [a - side * wa * 0.5, a + side * wa * 0.5, b - side * wb * 0.5, b + side * wb * 0.5]
	st.set_color(Color.WHITE)
	for i: int in [0, 2, 1, 1, 2, 3]:
		st.add_vertex(v[i])


## Rock chunks thrown up and falling back.
static func debris(parent: Node, at: Vector3, count: int, reach: float, height: float = 2.2) -> void:
	if not _mesh_cache.has("rock"):
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 0.22, 0.26)
		var mat := StandardMaterial3D.new()
		_rock_look(mat, ROCK)
		box.material = mat
		_mesh_cache["rock"] = box
	for i: int in count:
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_cache["rock"]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		var a: float = randf() * TAU
		var from: Vector3 = at + dir_at(a) * randf_range(0.2, 0.8)
		var to: Vector3 = at + dir_at(a) * randf_range(reach * 0.5, reach)
		var h: float = randf_range(height * 0.5, height)
		var s: float = randf_range(0.6, 1.4)
		mi.global_position = from
		mi.scale = Vector3.ONE * s
		var time: float = randf_range(0.5, 0.75)
		var spin: Vector3 = Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
		var tw := mi.create_tween()
		tw.tween_method(func(t: float) -> void:
			mi.global_position = from.lerp(to, t) + Vector3(0, 4.0 * h * t * (1.0 - t), 0)
			mi.rotation = spin * t, 0.0, 1.0, time)
		tw.tween_interval(0.25)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 0.25)
		tw.tween_callback(mi.queue_free)


static func _rock_look(mat: StandardMaterial3D, c: Color) -> void:
	mat.albedo_color = c
	mat.roughness = 1.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.rim_enabled = true
	mat.rim = 0.4
	mat.emission_enabled = true
	mat.emission = c * 0.25


## Rock spikes bursting out of the ground, one after the other along `path`.
static func earth_spikes(parent: Node, points: Array[Vector3], color: Color, step_delay: float = 0.035) -> void:
	if not _mesh_cache.has("spike"):
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.38
		cone.height = 1.3
		cone.radial_segments = 5
		cone.rings = 1
		var mat := StandardMaterial3D.new()
		_rock_look(mat, ROCK.lightened(0.08))
		cone.material = mat
		_mesh_cache["spike"] = cone
	for i: int in points.size():
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_cache["spike"]
		parent.add_child(mi)
		var at: Vector3 = points[i]
		var s: float = randf_range(0.75, 1.25)
		mi.scale = Vector3(s, s * randf_range(0.9, 1.3), s)
		mi.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
		var low: Vector3 = at + Vector3(0, -0.9 * mi.scale.y, 0)
		var high: Vector3 = at + Vector3(0, 0.45 * mi.scale.y, 0)
		mi.global_position = low
		mi.visible = false
		var delay: float = i * step_delay
		var tw := mi.create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(mi.show)
		tw.tween_callback(dust.bind(parent, at, 4, 0.3, 2.0))
		tw.tween_callback(ground_flash.bind(parent, at, 0.9, color, 0.25))
		tw.tween_property(mi, "global_position", high, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.45)
		tw.tween_property(mi, "global_position", low, 0.3).set_ease(Tween.EASE_IN)
		tw.tween_callback(mi.queue_free)


## Open cylinder of radius 1 and height 1 (centred), vertex alpha 1 at the bottom and
## `top_alpha` at the top.
static func tube_mesh(top_alpha: float) -> ArrayMesh:
	var key: String = "tube_%.2f" % top_alpha
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 24
	for i: int in segs + 1:
		var d: Vector3 = dir_at(float(i) / segs * TAU)
		st.set_color(Color(1, 1, 1, 1))
		st.add_vertex(d + Vector3(0, -0.5, 0))
		st.set_color(Color(1, 1, 1, top_alpha))
		st.add_vertex(d + Vector3(0, 0.5, 0))
	for i: int in segs:
		var v: int = i * 2
		for k: int in [v, v + 1, v + 2, v + 2, v + 1, v + 3]:
			st.add_index(k)
	var mesh: ArrayMesh = st.commit()
	_mesh_cache[key] = mesh
	return mesh


## Beam of light: an open cylinder that fades upwards. drop: comes down from the sky first.
static func light_pillar(parent: Node, at: Vector3, radius: float, height: float, color: Color, time: float = 0.5, drop: bool = false, fade: bool = true) -> void:
	var tube: ArrayMesh = tube_mesh(0.0 if fade else 0.7)
	for layer: int in 2:
		var mat := fx_material(Color(color, 0.85) if layer == 0 else Color(SPARK_WHITE, 0.9), layer == 1, 2 + layer)
		var mi := MeshInstance3D.new()
		mi.mesh = tube
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		var sx: float = radius * (1.0 if layer == 0 else 0.45)
		mi.global_position = at + Vector3(0, height * 0.5, 0)
		mi.scale = Vector3(sx, height, sx)
		var tw := mi.create_tween()
		if drop:
			mi.scale = Vector3(sx * 0.3, height, sx * 0.3)
			mi.global_position = at + Vector3(0, height * 1.5, 0)
			tw.tween_property(mi, "global_position", at + Vector3(0, height * 0.5, 0), 0.08)
			tw.tween_property(mi, "scale", Vector3(sx * 1.25, height, sx * 1.25), 0.08)
		tw.tween_property(mi, "scale", Vector3(sx * 0.15, height, sx * 0.15), time).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, time).set_ease(Tween.EASE_IN)
		tw.tween_callback(mi.queue_free)


## Expanding open cylinder (war-cry blast wall).
static func blast_wall(parent: Node, at: Vector3, radius: float, height: float, color: Color, time: float = 0.45) -> void:
	var mat := fx_material(Color(color, 0.75), false, 1)
	var mi := MeshInstance3D.new()
	mi.mesh = tube_mesh(0.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = at + Vector3(0, height * 0.5, 0)
	mi.scale = Vector3(0.6, height, 0.6)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(radius, height * 0.35, radius), time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "global_position:y", at.y + height * 0.175, time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, time * 0.7).set_delay(time * 0.3)
	tw.chain().tween_callback(mi.queue_free)


## A crystal shield in front of an enemy that shatters into shards (guard broken).
static func shield_shatter(parent: Node, at: Vector3, facing: Vector3, color: Color) -> void:
	if not _mesh_cache.has("shard"):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var a0: float = -PI / 6.0
		var a1: float = PI / 6.0
		st.set_color(Color(1, 1, 1, 0.55))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(1, 1, 1, 1))
		st.add_vertex(Vector3(sin(a0), cos(a0), 0) * 0.75)
		st.add_vertex(Vector3(sin(a1), cos(a1), 0) * 0.75)
		_mesh_cache["shard"] = st.commit()
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = at + Vector3(0, 1.1, 0)
	var f: Vector3 = facing
	f.y = 0.0
	if f.length_squared() < 0.001:
		f = Vector3.FORWARD
	root.rotation.y = atan2(f.x, f.z)
	root.scale = Vector3.ONE * 1.3
	var mat := fx_material(Color(color.lightened(0.15), 1.0), false, 4)
	for i: int in 6:
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_cache["shard"]
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		var ang: float = i * TAU / 6.0
		mi.rotation.z = -ang
		var out: Vector3 = Vector3(sin(ang), cos(ang), 0.0)
		var to: Vector3 = out * randf_range(1.0, 1.6) + Vector3(0, -0.6, randf_range(0.4, 1.0))
		var tw := mi.create_tween()
		tw.tween_interval(0.1)
		tw.tween_property(mi, "position", to, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(mi, "rotation", Vector3(randf_range(-6, 6), randf_range(-6, 6), mi.rotation.z + randf_range(-4, 4)), 0.45)
		tw.parallel().tween_property(mi, "scale", Vector3.ONE * 0.4, 0.45)
	var flash := MeshInstance3D.new()
	flash.mesh = arc_mesh(0.8, 0.1, 0.0, TAU, 24, false, false, true)
	flash.material_override = fx_material(Color(SPARK_WHITE, 1.0), true, 5)
	flash.rotation.x = PI * 0.5
	root.add_child(flash)
	var tf := flash.create_tween().set_parallel(true)
	tf.tween_property(flash, "scale", Vector3.ONE * 2.0, 0.25)
	tf.tween_property(flash.material_override, "albedo_color:a", 0.0, 0.25)
	var tw := root.create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(root.queue_free)
	burst(parent, at + Vector3(0, 1.1, 0), color, 10, 6.0, 0.4, 0.15, 0.4, -8.0, 0.3)


## Sword trail on the hero's blade while a skill animates.
static func sword_trail(model: CharacterModel, color: Color, seconds: float, width_mult: float = 1.0) -> void:
	if model == null:
		return
	var trail := SwordTrail.new()
	trail.color = color
	trail.duration = seconds
	trail.width_mult = width_mult
	if trail.bind_to(model):
		model.add_child(trail)


# --- One function per skill ---------------------------------------------------------------

## Corte Giratório: a full spinning crescent around the hero, a ring on the ground, sparks.
static func spin(parent: Node, at: Vector3, yaw: float, radius: float, color: Color, hit_index: int) -> void:
	var start: float = yaw + PI * 0.5 + hit_index * PI
	slash_arc(parent, at + Vector3(0, 0.75, 0), start, radius * 0.72, deg_to_rad(290), color, 0.24, -TAU * 0.55, 0.0, 0.42)
	slash_arc(parent, at + Vector3(0, 0.35, 0), start + 1.4, radius * 0.95, deg_to_rad(200), color, 0.2, -TAU * 0.4, 0.0, 0.25)
	shockwave(parent, at, radius, color, 0.32, 0.1)
	var p := burst(parent, at + Vector3(0, 0.6, 0), color, 12, 9.0, 0.35, 0.16, 0.05, -2.0, radius * 0.6)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = radius * 0.6
	p.emission_ring_inner_radius = radius * 0.5
	p.emission_ring_height = 0.2


## Investida: dust at the start, a golden streak that stretches behind the hero with speed
## lines, then a flash where the charge ends.
static func dash(parent: Node, player: Node3D, dir: Vector3, duration: float, width: float, color: Color) -> void:
	var from: Vector3 = player.global_position
	var yaw: float = atan2(-dir.x, -dir.z)
	dust(parent, from, 10, 0.5, 3.5)
	shockwave(parent, from, 1.6, color, 0.25, 0.1)
	# Streak: unit quad from z=0 back to z=+1 (local), stretched to the distance travelled.
	if not _mesh_cache.has("streak"):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cols: Array[float] = [-1.0, -0.4, 0.4, 1.0]
		var col_a: Array[float] = [0.0, 1.0, 1.0, 0.0]
		for row: int in 2:
			for c: int in 4:
				st.set_color(Color(1, 1, 1, col_a[c] * (1.0 if row == 0 else 0.0)))
				st.add_vertex(Vector3(cols[c] * 0.5, 0, float(row)))
		for c: int in 3:
			for i: int in [c, c + 4, c + 1, c + 1, c + 4, c + 5]:
				st.add_index(i)
		_mesh_cache["streak"] = st.commit()
	var streaks: Array[MeshInstance3D] = []
	var layers: Array = [[0.05, width * 1.6, Color(color.darkened(0.45), 0.5), false], [0.06, width * 1.2, Color(color, 0.95), false],
		[0.07, width * 0.4, Color(SPARK_WHITE, 0.9), true], [0.7, 0.12, Color(SPARK_WHITE, 0.8), true],
		[1.2, 0.1, Color(color.lightened(0.3), 0.9), true], [1.6, 0.08, Color(SPARK_WHITE, 0.7), true]]
	var sides: Array[float] = [0.0, 0.0, 0.0, 0.45, -0.5, 0.2]
	for i: int in layers.size():
		var l: Array = layers[i]
		var right: Vector3 = Vector3(-dir.z, 0, dir.x) * sides[i]
		var mi := spawn(parent, _mesh_cache["streak"], fx_material(l[2], l[3], 2 + i), from + right + Vector3(0, l[0], 0), yaw)
		mi.scale = Vector3(l[1], 1, 0.01)
		streaks.append(mi)
	var root: MeshInstance3D = streaks[0]
	var tw := root.create_tween()
	tw.tween_method(func(_t: float) -> void:
		if not is_instance_valid(player):
			return
		var travelled: float = maxf((player.global_position - from).dot(dir), 0.01)
		for k: int in streaks.size():
			var s: MeshInstance3D = streaks[k]
			var right2: Vector3 = Vector3(-dir.z, 0, dir.x) * sides[k]
			s.global_position = from + right2 + dir * travelled + Vector3(0, s.global_position.y - from.y, 0)
			s.scale.z = travelled * (1.0 if k < 3 else 0.6), 0.0, 1.0, duration)
	tw.tween_callback(func() -> void:
		if is_instance_valid(player):
			var end: Vector3 = player.global_position
			slash_arc(parent, end + Vector3(0, 0.9, 0), yaw, 1.1, deg_to_rad(150), color, 0.2, 0.0, 0.0, 0.3)
			ground_flash(parent, end + dir * 0.6, 1.4, color, 0.25)
			burst(parent, end + dir * 0.8 + Vector3(0, 0.9, 0), color, 10, 7.0, 0.35, 0.15, 0.3, -6.0, 0.3))
	for s: MeshInstance3D in streaks:
		fade_out(s, 0.3, duration)


## Golpe Sísmico: the ground cracks in a cone, rock spikes burst out in a wave, dust and a
## cone-shaped shockwave.
static func seismic(parent: Node, at: Vector3, yaw: float, radius: float, angle_deg: float, color: Color) -> void:
	var span: float = deg_to_rad(angle_deg)
	cracks(parent, at, yaw, radius * 0.95, span, 5, color, 1.8)
	var points: Array[Vector3] = []
	var rows: int = 4
	for r: int in rows:
		var dist: float = lerpf(1.2, radius * 0.92, float(r) / (rows - 1))
		var n: int = 1 + r
		for k: int in n:
			var a: float = yaw + ((float(k) + 0.5) / n - 0.5) * span * 0.85 + randf_range(-0.08, 0.08)
			points.append(at + dir_at(a) * (dist + randf_range(-0.3, 0.3)))
	earth_spikes(parent, points, color, 0.025)
	# Cone shockwave: an arc band growing outwards.
	var wave := spawn(parent, arc_mesh(1.0, 0.12, -span * 0.5, span * 0.5, 24, false, false, true), fx_material(Color(color, 0.95), false, 1), at + Vector3(0, 0.07, 0), yaw)
	wave.scale = Vector3.ONE * 0.6
	var tw := wave.create_tween()
	tw.tween_property(wave, "scale", Vector3.ONE * radius, 0.35).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fade_out(wave, 0.3, 0.15)
	ground_flash(parent, at + dir_at(yaw) * 0.8, 1.8, color, 0.3)
	dust(parent, at + dir_at(yaw) * 0.8, 12, 1.0, 4.0)
	debris(parent, at + dir_at(yaw) * 1.2, 6, 2.5, 1.8)


## Quebra-Guarda: a heavy diagonal red slash in front of the hero.
static func guard_break(parent: Node, at: Vector3, yaw: float, radius: float, angle_deg: float, color: Color) -> void:
	var span: float = deg_to_rad(angle_deg) * 1.2
	slash_arc(parent, at + Vector3(0, 1.0, 0), yaw, radius * 0.7, span, color, 0.26, -span * 0.5, deg_to_rad(28), 0.5)
	slash_arc(parent, at + Vector3(0, 0.6, 0), yaw + 0.2, radius * 0.55, span * 0.8, color.darkened(0.2), 0.22, -span * 0.4, deg_to_rad(-12), 0.25)
	# Red scar on the ground where the blade passed.
	var scar := spawn(parent, arc_mesh(radius * 0.75, 0.22, -span * 0.5, span * 0.5, 24, true, false, true), fx_material(Color(color, 0.9), false, 1), at + Vector3(0, 0.05, 0), yaw)
	fade_out(scar, 0.4, 0.3)
	burst(parent, at + dir_at(yaw) * radius * 0.6 + Vector3(0, 0.9, 0), color, 8, 6.0, 0.3, 0.14, 0.4, -6.0, 0.5)


## Brado de Guerra: blast wall and double ring from the hero, a column of embers.
static func war_cry(parent: Node, at: Vector3, radius: float, color: Color) -> void:
	blast_wall(parent, at, radius, 1.8, color, 0.5)
	shockwave(parent, at, radius, color, 0.45, 0.14)
	shockwave(parent, at, radius * 0.7, color.lightened(0.2), 0.4, 0.1, 0.12)
	ground_flash(parent, at, 2.2, color, 0.35)
	var p := burst(parent, at + Vector3(0, 0.3, 0), color, 26, 6.0, 0.9, 0.2, 1.0, 1.0, 0.8)
	p.spread = 30.0


## Weakened enemy: dark wisps going down around it.
static func weaken_mark(parent: Node, at: Vector3, color: Color) -> void:
	var p := burst(parent, at + Vector3(0, 1.8, 0), color.darkened(0.45), 8, 2.0, 0.6, 0.22, 0.5, -5.0, 0.5, false)
	p.direction = Vector3.DOWN


## Salto Devastador: dust at takeoff and a trail in the air (see SkillRunner), then a crater:
## cracks all around, rocks, a pillar of light and two shockwaves.
static func leap_takeoff(parent: Node, at: Vector3, color: Color) -> void:
	dust(parent, at, 10, 0.5, 3.0)
	shockwave(parent, at, 1.5, color, 0.25, 0.1)


## Glowing particles that follow `target` for `seconds` (the hero in the air).
static func follow_trail(target: Node3D, color: Color, seconds: float) -> void:
	var p := particles(color, 30, 0.6, 0.45, 0.42, 1.0, 0.0, 0.4, true)
	p.local_coords = false
	p.position = Vector3(0, 0.9, 0)
	target.add_child(p)
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(seconds)
	tw.tween_callback(func() -> void: p.emitting = false)
	tw.tween_interval(0.5)
	tw.tween_callback(p.queue_free)


static func leap_landing(parent: Node, at: Vector3, radius: float, color: Color) -> void:
	cracks(parent, at, 0.0, radius * 0.9, TAU, 7, color, 1.8)
	shockwave(parent, at, radius, color, 0.4, 0.16)
	shockwave(parent, at, radius * 1.25, color.lightened(0.25), 0.5, 0.08, 0.08)
	light_pillar(parent, at, 1.1, 4.0, color, 0.35)
	ground_flash(parent, at, radius * 0.8, color, 0.3)
	debris(parent, at, 9, radius, 2.4)
	dust(parent, at, 14, 1.2, 4.5)
	burst(parent, at + Vector3(0, 0.5, 0), color, 16, 9.0, 0.45, 0.18, 0.25, -6.0, 0.6)


## Julgamento: light gathers during the wind-up, then a beam falls on the target with a
## cross slash. execute: below the HP threshold, everything is bigger.
static func judgment(parent: Node, at: Vector3, color: Color, execute: bool) -> void:
	var s: float = 1.4 if execute else 1.0
	light_pillar(parent, at, 0.7 * s, 12.0, color, 0.45, true, false)
	var cam: Camera3D = parent.get_viewport().get_camera_3d() if parent.is_inside_tree() else null
	var face: float = cam.global_rotation.y if cam else 0.0
	for k: int in 2:
		var root := Node3D.new()
		parent.add_child(root)
		root.global_position = at + Vector3(0, 1.1, 0)
		root.rotation = Vector3(0, face, 0)
		var holder := Node3D.new()
		holder.rotation = Vector3(PI * 0.5, 0, (0.75 if k == 0 else -0.75))
		root.add_child(holder)
		var slash := slash_arc(holder, root.global_position, 0.0, 2.0 * s, deg_to_rad(110), color, 0.3, 0.0, 0.0, 0.36 * s)
		slash.position = Vector3(0, 0, 1.6 * s)
		slash.rotation = Vector3.ZERO
		var tw := root.create_tween()
		tw.tween_interval(0.5)
		tw.tween_callback(root.queue_free)
	shockwave(parent, at, 2.4 * s, color, 0.35, 0.12)
	ground_flash(parent, at, 1.8 * s, color, 0.35)
	burst(parent, at + Vector3(0, 1.0, 0), color, 18 if execute else 12, 8.0, 0.5, 0.18, 0.6, -7.0, 0.3)
	if execute:
		shockwave(parent, at, 3.6, SPARK_WHITE, 0.45, 0.08, 0.1)
		cracks(parent, at, 0.0, 1.8, TAU, 6, color, 1.2)


## Onda de Corte: glowing crescent mesh for the projectile (child of the wave node), plus
## a soft copy on the ground `height` below so its path reads from above.
static func wave_blade(holder: Node3D, width: float, color: Color, height: float) -> void:
	var r: float = width * 1.05
	var span: float = deg_to_rad(150)
	for mi: MeshInstance3D in blade_layers(holder, r, width * 0.5, span, color, false):
		mi.position.z = r * 0.75
	var ground := MeshInstance3D.new()
	ground.mesh = arc_mesh(r, width * 0.6, -span * 0.5, span * 0.5, 24, true, false, true)
	ground.material_override = fx_material(Color(color.darkened(0.2), 0.45), false, 2)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.position = Vector3(0, 0.05 - height, r * 0.75)
	holder.add_child(ground)
