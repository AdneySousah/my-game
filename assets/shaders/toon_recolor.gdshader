shader_type spatial;
// Toon look (same as ToonStyle) with the clothes and hair turned to another colour, so the
// same villager model looks like a different person. Skin tones are left alone.
render_mode diffuse_toon, specular_toon;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_texture = true;
uniform float alpha_scissor = 0.0;
uniform float rim = 0.35;
uniform float rim_tint = 0.4;
// 0..1 turn of the colour wheel, and a saturation multiplier.
uniform float hue_shift = 0.0;
uniform float sat_mult = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 c = albedo_color;
	if (use_texture) {
		c *= texture(albedo_tex, UV);
	}
	vec3 hsv = rgb2hsv(c.rgb);
	// Skin: warm hue, medium saturation, fairly bright. Greys have no colour to turn.
	float skin = step(0.0, hsv.x) * step(hsv.x, 0.11) * step(0.12, hsv.y) * step(hsv.y, 0.62) * step(0.42, hsv.z);
	float colourful = smoothstep(0.08, 0.2, hsv.y);
	float k = colourful * (1.0 - skin);
	vec3 turned = hsv2rgb(vec3(fract(hsv.x + hue_shift), clamp(hsv.y * sat_mult, 0.0, 1.0), hsv.z));
	ALBEDO = mix(c.rgb, turned, k);
	if (alpha_scissor > 0.0 && c.a < alpha_scissor) {
		discard;
	}
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	RIM = rim;
	RIM_TINT = rim_tint;
}
