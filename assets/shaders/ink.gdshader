shader_type canvas_item;
// Thủy mặc (ink wash) look over the rendered frame for the finishing blow:
// stepped ink tones on rice paper, brushed outlines, red kept as cinnabar,
// ragged dark edges. `amt` fades it in and out.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amt : hint_range(0.0, 1.0) = 0.0;
uniform vec3 paper = vec3(0.92, 0.87, 0.76);
uniform vec3 ink = vec3(0.07, 0.06, 0.06);
uniform vec3 cinnabar = vec3(0.72, 0.1, 0.07);

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float L(vec2 uv) { return lum(texture(screen_tex, uv).rgb); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	if (amt <= 0.001) {
		COLOR = vec4(c, 1.0);
	} else {
		// wobble the sampling a little so lines look hand-drawn
		vec2 wob = (vec2(noise(uv * 90.0), noise(uv * 90.0 + 7.3)) - 0.5) * SCREEN_PIXEL_SIZE * 3.0;
		vec2 px = SCREEN_PIXEL_SIZE * 1.6;
		vec2 u = uv + wob;
		float tl = L(u + px * vec2(-1.0, -1.0));
		float t = L(u + px * vec2(0.0, -1.0));
		float tr = L(u + px * vec2(1.0, -1.0));
		float l = L(u + px * vec2(-1.0, 0.0));
		float r = L(u + px * vec2(1.0, 0.0));
		float bl = L(u + px * vec2(-1.0, 1.0));
		float b = L(u + px * vec2(0.0, 1.0));
		float br = L(u + px * vec2(1.0, 1.0));
		float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
		float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
		float edge = smoothstep(0.12, 0.45, length(vec2(gx, gy)));

		// three wash tones with a bleeding, grainy boundary
		float y = lum(c);
		float wash = smoothstep(0.04, 0.7, y) * 3.0 + (noise(uv * 40.0) - 0.5) * 0.45 + (noise(uv * 300.0) - 0.5) * 0.15;
		wash = clamp(floor(wash) / 3.0 + 0.12, 0.0, 1.0);
		vec3 col = mix(ink, paper, wash);
		col = mix(col, ink, edge * 0.85);

		// cinnabar survives: saturated warm reds (blood, sparks, lacquer)
		float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
		float red = smoothstep(0.3, 0.55, sat) * smoothstep(0.05, 0.25, c.r - max(c.g, c.b));
		col = mix(col, cinnabar, red * 0.85);

		// rice-paper fibres and blotches
		col *= 1.0 - (noise(uv * vec2(1100.0, 620.0)) * 0.07 + noise(uv * 18.0) * 0.08);

		// ragged ink frame
		vec2 d = (uv - 0.5) * vec2(1.0, 1.25);
		float frame = smoothstep(0.42, 0.62, length(d) + (noise(uv * 7.0) - 0.5) * 0.18);
		col = mix(col, ink * 1.4, frame * 0.9);

		COLOR = vec4(mix(c, col, amt), 1.0);
	}
}
