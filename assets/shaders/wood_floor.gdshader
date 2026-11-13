shader_type spatial;
// Wooden plank floor for the rooms inside houses (owner, 13/11: "o chão é terroso").
// Planks run along X; each one gets its own shade and a staggered end joint.

uniform vec3 base_color : source_color = vec3(0.55, 0.35, 0.2);
uniform float plank_width = 0.42;
uniform float plank_length = 2.4;

varying vec3 world_pos;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float row = floor(world_pos.z / plank_width);
	float along = world_pos.x / plank_length + hash(row) * 3.0;
	float plank = floor(along);
	float shade = 0.82 + 0.3 * hash(row * 7.0 + plank * 13.0);
	// Grain: thin streaks along the plank.
	float grain = 0.94 + 0.06 * sin(world_pos.x * 9.0 + hash(row) * 20.0 + sin(world_pos.z * 31.0) * 1.5);
	vec3 col = base_color * shade * grain;
	// Dark seams between rows and at the plank ends.
	float fz = fract(world_pos.z / plank_width);
	float fx = fract(along);
	float seam = smoothstep(0.0, 0.05, fz) * smoothstep(1.0, 0.95, fz);
	seam *= smoothstep(0.0, 0.012, fx) * smoothstep(1.0, 0.988, fx);
	col *= mix(0.45, 1.0, seam);
	ALBEDO = col;
	ROUGHNESS = 0.85;
}
