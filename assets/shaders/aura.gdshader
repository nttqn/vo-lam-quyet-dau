shader_type spatial;
// Enchant aura on a +7..+15 weapon (material_overlay): the mesh is drawn again
// as a slightly inflated additive shell -> a soft halo around the blade, with
// a slow pulse and a light band running along it.
render_mode blend_add, unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 col : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float strength = 1.0;
uniform float thick = 0.01;   // halo thickness in metres

varying vec3 lpos;

void vertex() {
	lpos = VERTEX;
	// inflate in world units whatever the mesh's import scale
	float s = max(length(MODEL_MATRIX[0].xyz), 1e-4);
	VERTEX += NORMAL * thick / s;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.5);
	float pulse = 0.75 + 0.25 * sin(TIME * 3.0);
	float band = smoothstep(0.8, 1.0, sin(lpos.y * 9.0 - TIME * 5.0));
	ALBEDO = col.rgb * (0.45 + fres * 1.6 + band * 1.0) * pulse * strength;
}
