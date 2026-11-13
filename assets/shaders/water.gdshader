shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// Stylized water for rivers and lakes (owner, 13/11: "os lagos estão feios"). The mesh is a
// smooth ribbon (GameMap._water_ribbon): UV.x goes 0..1 across the water, UV.y is metres
// along it. Deep blue in the middle, clear turquoise shallows at the banks, a soft foam
// line at the edge that fades into the ground, slow ripples and sparkles. Cheap enough
// for phones (no screen or depth textures).

uniform vec4 deep_color : source_color = vec4(0.10, 0.38, 0.72, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.36, 0.80, 0.82, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform vec2 flow = vec2(0.0, 0.25);
uniform float ripple_scale = 0.55;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 0 at the banks, 1 in the middle.
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float depth = smoothstep(0.0, 0.75, across);
	vec2 p = world_pos.xz * ripple_scale + flow * TIME;
	float n1 = noise(p * 1.3 + vec2(TIME * 0.21, -TIME * 0.17));
	float n2 = noise(p * 2.7 - vec2(TIME * 0.13, TIME * 0.24));
	float ripples = n1 * 0.6 + n2 * 0.4;
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, depth);
	// Soft light bands on the surface.
	col += vec3(0.10, 0.14, 0.16) * smoothstep(0.55, 0.85, ripples) * (0.4 + depth * 0.6);
	// Little sparkles.
	float sparkle = smoothstep(0.93, 0.99, noise(world_pos.xz * 3.1 + vec2(TIME * 0.6, TIME * 0.45)));
	col += vec3(0.9) * sparkle * 0.6;
	// Foam line wobbling along the bank, then the edge fades into the ground.
	float edge = across + (n2 - 0.5) * 0.08;
	float foam = smoothstep(0.03, 0.09, edge) * (1.0 - smoothstep(0.10, 0.20, edge));
	col = mix(col, foam_color.rgb, foam * 0.75);
	ALBEDO = col;
	ALPHA = smoothstep(0.0, 0.05, edge);
	ROUGHNESS = 0.18;
	SPECULAR = 0.65;
}
