shader_type spatial;
// Stylized river water: two blues with soft moving light bands (world-space, so
// every river segment lines up). Cheap enough for mobile.

uniform vec4 deep_color : source_color = vec4(0.16, 0.50, 0.86, 1.0);
uniform vec4 light_color : source_color = vec4(0.55, 0.85, 1.0, 1.0);
uniform vec2 flow = vec2(0.0, 1.2);
uniform float band_scale = 0.45;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * band_scale + flow * TIME * 0.35;
	float w = sin(p.y * 3.0 + sin(p.x * 2.0 + TIME * 0.8) * 1.2);
	float glints = smoothstep(0.75, 1.0, w);
	ALBEDO = mix(deep_color.rgb, light_color.rgb, glints * 0.7);
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
