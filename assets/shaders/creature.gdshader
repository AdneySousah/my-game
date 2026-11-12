shader_type spatial;
// Toon look + simple body motion for the animals, which have no skeleton (the Meshy rig
// only takes humanoids). Works in the model's own space before scaling: the animal faces +Z,
// its length along Z is about 1; Meshy centres the model, so base_y says where the feet are.
// Four-legged animals: legs swing in a diagonal gait, the tail wags, legs fold to sit or lie.
// Birds (is_bird): the wings (far from the body along X) flap or fold against the body.
render_mode diffuse_toon, specular_toon;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_texture = true;
uniform float rim = 0.35;
uniform float rim_tint = 0.4;

uniform bool is_bird = false;
// Four legs.
uniform float walk = 0.0;          // 0 stopped .. 1 walking
uniform float step_speed = 9.0;    // leg swings per second (radians)
uniform float leg_height = 0.3;    // top of the legs (model units)
uniform float stride = 0.09;       // how far a foot moves forward/back
uniform float tail_start = -0.36;  // the tail is behind this Z
uniform float wag = 0.0;           // tail sweep (model units)
uniform float wag_speed = 8.0;
uniform float fold_front = 0.0;    // 0 standing .. 1 front legs folded (lying)
uniform float fold_back = 0.0;     // 0 standing .. 1 back legs folded (sitting / lying)
uniform float phase = 0.0;         // per animal, so a herd does not move in step
uniform float base_y = 0.0;        // height of the feet in model space
// Bird.
uniform float body_half = 0.17;    // half the body width (X); beyond it are the wings
uniform float flap = 0.0;          // 0 still .. 1 flapping
uniform float flap_speed = 22.0;
uniform float wing_fold = 0.0;     // 0 open .. 1 folded on the back

void vertex() {
	vec3 v = VERTEX;
	float t = TIME + phase;
	if (is_bird) {
		float ax = abs(v.x);
		if (ax > body_half) {
			float out_d = ax - body_half;
			float s = sign(v.x);
			v.y += sin(t * flap_speed) * flap * out_d * 0.9;
			float folded = body_half + out_d * 0.18;
			v.x = s * mix(ax, folded, wing_fold);
			v.y -= wing_fold * out_d * 0.15;
			v.z -= wing_fold * out_d * 0.35;
		}
	} else {
		float y = v.y - base_y;
		float h = clamp(1.0 - y / max(leg_height, 0.01), 0.0, 1.0);
		if (h > 0.0) {
			float front = step(0.0, v.z);
			float left = step(0.0, v.x);
			float ph = t * step_speed + front * 3.14159 + left * 3.14159;
			v.z += sin(ph) * stride * walk * h;
			v.y += max(0.0, cos(ph)) * stride * 0.5 * walk * h;
			float fold = mix(fold_back, fold_front, front);
			// Folding: the foot rises to the belly and the leg tucks in.
			v.y = mix(v.y, base_y + leg_height * 0.85, fold * h);
		}
		// The whole body sinks as the legs fold.
		float sink = leg_height * 0.7 * mix(fold_back, fold_front, step(0.0, v.z));
		v.y -= sink * (1.0 - h);
		if (v.z < tail_start && y > leg_height * 0.6) {
			v.x += sin(t * wag_speed) * wag * (tail_start - v.z) * 4.0;
		}
		// Breathing / trotting bob.
		v.y += sin(t * step_speed * 2.0) * 0.012 * walk * (1.0 - h);
	}
	VERTEX = v;
}

void fragment() {
	vec4 c = albedo_color;
	if (use_texture) {
		c *= texture(albedo_tex, UV);
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	RIM = rim;
	RIM_TINT = rim_tint;
}
