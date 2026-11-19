shader_type spatial;
// Cường hóa glow of the unarmed sects (Cái Bang, Vovinam): the body mesh drawn
// again as an additive shell (material_overlay), but only on the wrist guards
// (hộ thủ): the forearm segment just above each wrist, given in world space by
// Avatar every frame. Same look as the weapon aura (aura.gdshader).
render_mode blend_add, unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 col : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float strength = 1.0;
uniform float thick = 0.01;      // halo thickness in metres
uniform vec3 r_a;                // right wrist (world)
uniform vec3 r_b;                // right forearm, a hand's length up
uniform vec3 l_a;
uniform vec3 l_b;
uniform float radius = 0.08;     // metres around the segment

varying float wgt;
varying float along;

float seg_d(vec3 p, vec3 a, vec3 b, out float t) {
	vec3 ab = b - a;
	t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
	return length(p - (a + ab * t));
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float tr; float tl;
	float dr = seg_d(wp, r_a, r_b, tr);
	float dl = seg_d(wp, l_a, l_b, tl);
	float d = min(dr, dl);
	along = dr < dl ? tr : tl;
	wgt = 1.0 - smoothstep(radius * 0.6, radius, d);
	// UV2.x = share of the forearm / hand bones (Avatar._arm_masked): only
	// the arm glows, not a belt the hand happens to rest on
	wgt *= smoothstep(0.25, 0.6, UV2.x);
	float s = max(length(MODEL_MATRIX[0].xyz), 1e-4);
	VERTEX += NORMAL * thick * wgt / s;
}

void fragment() {
	if (wgt < 0.02) {
		discard;
	}
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.5);
	float pulse = 0.75 + 0.25 * sin(TIME * 3.0);
	float band = smoothstep(0.8, 1.0, sin(along * 9.0 - TIME * 5.0));
	ALBEDO = col.rgb * (0.45 + fres * 1.6 + band * 1.0) * pulse * strength * wgt;
}
