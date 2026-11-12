shader_type spatial;
// Toon look (same as ToonStyle) + wind sway, for trees, bushes, flowers, reeds and crops.
// The ground is at y = 0 in every map, so a vertex's height above the ground decides how
// much it moves: the base stays put, the top sways. Wind direction and strength are global
// (project settings > shader globals), set per map by DayNight/GameMap.
render_mode diffuse_toon, specular_toon, world_vertex_coords;

global uniform vec2 wind_dir;
global uniform float wind_strength;

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
	ALBEDO = c.rgb;
	if (alpha_scissor > 0.0 && c.a < alpha_scissor) {
		discard;
	}
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	RIM = rim;
	RIM_TINT = rim_tint;
}
