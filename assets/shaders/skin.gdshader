shader_type spatial;
// Re-tones the Quaternius skin atlas: keeps shading detail from luminance,
// recolours to skin_tone, and paints lips inside an elliptical UV region.
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform sampler2D nrm : hint_normal, filter_linear_mipmap;
uniform vec3 skin_tone : source_color = vec3(0.93, 0.76, 0.62);
uniform vec3 lip_color : source_color = vec3(0.72, 0.32, 0.3);
uniform float lip_amt = 0.0;
uniform vec4 lip_rect = vec4(0.186, 0.266, 0.033, 0.011);
uniform float ref_lum = 0.5;
uniform float hue_keep = 0.35;
uniform vec3 flash = vec3(0.0);

void fragment() {
	vec3 c = texture(tex, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 base = skin_tone * (l / ref_lum);
	vec3 hue = c / max(l, 0.001) * 0.85;
	vec3 col = mix(base, base * hue, hue_keep);
	vec2 d = (UV - lip_rect.xy) / lip_rect.zw;
	float m = smoothstep(1.0, 0.55, length(d)) * lip_amt;
	col = mix(col, lip_color * clamp(l / ref_lum, 0.6, 1.3), m);
	ALBEDO = col;
	NORMAL_MAP = texture(nrm, UV).rgb;
	ROUGHNESS = 0.62;
	RIM = 0.35;
	RIM_TINT = 0.4;
	EMISSION = flash;
}
