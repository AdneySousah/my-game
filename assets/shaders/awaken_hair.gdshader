shader_type spatial;
// Awakening (Fase 8): the same toon look as ToonStyle, but the hair turns to glowing gold.
// "Hair" = everything above the neck that is not skin and not too dark (pupils, brows
// outlines stay). The neck height comes from the Head bone every frame (CharacterModel).
render_mode diffuse_toon, specular_toon;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_texture = true;
uniform float alpha_scissor = 0.0;
uniform float rim = 0.35;
uniform float rim_tint = 0.4;
// Height of the neck in the mesh's own space, and the glow.
uniform float neck_y = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.86, 0.35, 1.0);
uniform float strength = 1.0;
uniform float pulse = 0.0;

varying float v_y;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void vertex() {
	v_y = VERTEX.y;
}

void fragment() {
	vec4 c = albedo_color;
	if (use_texture) {
		c *= texture(albedo_tex, UV);
	}
	vec3 hsv = rgb2hsv(c.rgb);
	float skin = step(0.0, hsv.x) * step(hsv.x, 0.11) * step(0.12, hsv.y) * step(hsv.y, 0.62) * step(0.42, hsv.z);
	float above = smoothstep(neck_y - 0.02, neck_y + 0.03, v_y);
	float k = above * (1.0 - skin) * smoothstep(0.18, 0.32, hsv.z) * strength;
	// Keep the hair's light and shade, in gold.
	vec3 gold = glow_color.rgb * (0.5 + 0.45 * hsv.z);
	ALBEDO = mix(c.rgb, gold, k);
	EMISSION = glow_color.rgb * k * (0.18 + 0.12 * pulse);
	if (alpha_scissor > 0.0 && c.a < alpha_scissor) {
		discard;
	}
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	RIM = rim;
	RIM_TINT = rim_tint;
}
