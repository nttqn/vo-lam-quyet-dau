shader_type spatial;
// Tints the saturated iris of the eye texture.
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 iris : source_color = vec3(0.35, 0.2, 0.1);
uniform vec3 flash = vec3(0.0);

void fragment() {
	vec3 c = texture(tex, UV).rgb;
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 0.001);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float m = smoothstep(0.15, 0.4, sat);
	ALBEDO = mix(c, iris * (l * 2.2), m);
	ROUGHNESS = 0.2;
	SPECULAR = 0.8;
	EMISSION = flash;
}
