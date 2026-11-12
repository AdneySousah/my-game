shader_type spatial;
// Toon look (same as ToonStyle) + wind sway, for trees, bushes, flowers, reeds and crops.
// Also the biome look of a map (global biome_dry / biome_snow / biome_moss, 0..1): leaves turn
// to straw, snow settles on top faces, moss grows on grey stone. Props with sway = 0 use it too
// in maps that have a biome (ToonStyle.biome_props).
// The ground is at y = 0 in every map, so a vertex's height above the ground decides how
// much it moves: the base stays put, the top sways. Wind direction and strength are global
// (project settings > shader globals), set per map by DayNight/GameMap.
render_mode diffuse_toon, specular_toon, world_vertex_coords;

global uniform vec2 wind_dir;
global uniform float wind_strength;
global uniform float biome_dry;
global uniform float biome_snow;
global uniform float biome_moss;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_texture = true;
uniform float alpha_scissor = 0.0;
uniform float rim = 0.35;
uniform float rim_tint = 0.4;
// Metres the top of the plant moves in a normal breeze.
uniform float sway = 0.1;
// Height (metres) of the plant: at this height the sway is full.
uniform float sway_height = 3.0;
// Quick small shaking of leaves / ears (metres).
uniform float flutter = 0.0;

void vertex() {
	float h = clamp(VERTEX.y / max(sway_height, 0.1), 0.0, 1.2);
	h = h * h;
	vec2 d = normalize(wind_dir + vec2(0.0001));
	// Waves travel across the map along the wind; gusts come and go slowly.
	float phase = dot(VERTEX.xz, d) * 0.28;
	float gust = 0.6 + 0.4 * sin(TIME * 0.45 - phase * 0.35) * sin(TIME * 0.17 + phase * 0.12);
	float wave = sin(TIME * 1.7 - phase) * 0.65 + sin(TIME * 2.9 - phase * 1.6 + 1.3) * 0.25;
	float push = (0.55 + wave * 0.45) * gust * wind_strength * sway * h;
	vec3 off = vec3(d.x, 0.0, d.y) * push;
	// Sideways wobble so it is not a stiff back-and-forth.
	off += vec3(-d.y, 0.0, d.x) * sin(TIME * 1.3 - phase * 1.2 + VERTEX.x) * 0.25 * push;
	float f = flutter * wind_strength * h;
	off += vec3(sin(TIME * 7.0 + VERTEX.x * 4.0 + VERTEX.y * 3.0), 0.4 * sin(TIME * 9.0 + VERTEX.z * 4.0), cos(TIME * 6.5 + VERTEX.y * 4.0)) * f;
	VERTEX += off;
}

void fragment() {
	vec4 c = albedo_color;
	if (use_texture) {
		c *= texture(albedo_tex, UV);
	}
	vec3 col = c.rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float up = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
	if (biome_dry > 0.0) {
		// Green (leaves, grass, moss) turns to straw and ochre; the rest keeps its colour.
		float leafy = clamp((col.g - max(col.r, col.b)) * 5.0, 0.0, 1.0);
		vec3 straw = mix(vec3(0.62, 0.42, 0.18), vec3(0.93, 0.76, 0.38), clamp(lum * 1.6, 0.0, 1.0));
		col = mix(col, straw, leafy * biome_dry);
	}
	if (biome_moss > 0.0) {
		// Grey stone and wood facing up get a damp green coat.
		float grey = 1.0 - clamp((max(col.r, max(col.g, col.b)) - min(col.r, min(col.g, col.b))) * 4.0, 0.0, 1.0);
		float top = smoothstep(0.1, 0.7, up);
		col = mix(col, vec3(0.30, 0.46, 0.18) * (0.6 + lum), grey * top * biome_moss);
	}
	if (biome_snow > 0.0) {
		// Snow lies on faces that look up; everything else gets a light frost.
		float top = smoothstep(0.3, 0.75, up);
		col = mix(col, vec3(0.93, 0.96, 1.0), clamp(top * biome_snow * 1.15 + biome_snow * 0.12, 0.0, 1.0));
	}
	ALBEDO = col;
	if (alpha_scissor > 0.0 && c.a < alpha_scissor) {
		discard;
	}
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	RIM = rim;
	RIM_TINT = rim_tint;
}
