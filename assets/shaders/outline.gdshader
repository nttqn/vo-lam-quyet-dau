shader_type spatial;
// Inverted-hull ink outline (used as next_pass on character materials).
render_mode unshaded, cull_front, depth_draw_opaque;
uniform vec4 color : source_color = vec4(0.06, 0.04, 0.04, 1.0);
uniform float width = 0.006;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = color.rgb;
}
