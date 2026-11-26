shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
// Görüntülü arama hologramı: tek renk mavi, tarama çizgileri, çerçeve, titreşim.

uniform sampler2D feed : source_color, filter_linear;
uniform vec3 tint : source_color = vec3(0.35, 0.85, 1.0);
uniform float time_offset = 0.0;

void vertex() {
	// Her zaman kameraya dön
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float t = TIME + time_offset;
	vec2 uv = UV;
	// Arada bir yatay kayma (sinyal bozulması)
	float glitch = step(0.985, fract(sin(floor(t * 7.0)) * 43758.5)) * 0.02;
	uv.x += glitch * sin(uv.y * 80.0);
	vec4 c = texture(feed, uv);
	float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	float scan = 0.65 + 0.35 * sin(uv.y * 260.0 - t * 6.0);
	// Çerçeve
	float edge = max(step(uv.x, 0.025) + step(0.975, uv.x), step(uv.y, 0.02) + step(0.98, uv.y));
	float a = c.a * (0.55 + 0.45 * lum) * scan + edge * 0.9;
	a *= 0.85 + 0.15 * sin(t * 21.0);
	ALBEDO = tint * (lum * 1.6 + edge * 1.2 + 0.15 * c.a);
	ALPHA = clamp(a, 0.0, 1.0);
}
