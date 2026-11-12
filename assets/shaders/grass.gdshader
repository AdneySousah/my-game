shader_type spatial;
// Grass tufts drawn in one MultiMesh per map: dark at the root, light at the tip,
// bending with the global wind (same waves as toon_wind.gdshader).
render_mode diffuse_toon, specular_disabled, cull_disabled, world_vertex_coords;

global uniform vec2 wind_dir;
global uniform float wind_strength;

uniform vec4 root_color : source_color = vec4(0.30, 0.55, 0.22, 1.0);
uniform vec4 tip_color : source_color = vec4(0.62, 0.86, 0.38, 1.0);
uniform float blade_height = 0.45;
uniform float sway = 0.16;

varying float tip;

void vertex() {
	tip = clamp(VERTEX.y / blade_height, 0.0, 1.0);
	vec2 d = normalize(wind_dir + vec2(0.0001));
	float phase = dot(VERTEX.xz, d) * 0.28;
	float gust = 0.6 + 0.4 * sin(TIME * 0.45 - phase * 0.35) * sin(TIME * 0.17 + phase * 0.12);
	float wave = sin(TIME * 1.7 - phase) * 0.65 + sin(TIME * 2.9 - phase * 1.6 + 1.3) * 0.25;
	float push = (0.55 + wave * 0.45) * gust * wind_strength * sway * tip * tip;
	VERTEX += vec3(d.x, 0.0, d.y) * push;
	VERTEX.y -= push * 0.35;
	// Normals point up so the tufts light like the ground, not like flat cards.
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	ALBEDO = mix(root_color.rgb, tip_color.rgb, tip);
	ROUGHNESS = 1.0;
}
