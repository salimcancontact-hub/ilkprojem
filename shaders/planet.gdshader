shader_type spatial;
render_mode fog_disabled;
// Gezegen yüzeyi: gürültü dokusundan renk, kenarda atmosfer parıltısı.

uniform sampler2D noise_tex;
uniform vec3 color_low : source_color = vec3(0.22, 0.2, 0.2);
uniform vec3 color_high : source_color = vec3(0.72, 0.46, 0.28);
uniform vec3 atmosphere : source_color = vec3(1.0, 0.6, 0.35);
uniform float atmosphere_strength = 0.8;

void fragment() {
	float n = texture(noise_tex, UV * vec2(2.0, 1.0)).r;
	ALBEDO = mix(color_low, color_high, smoothstep(0.3, 0.75, n));
	ROUGHNESS = 1.0;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = atmosphere * fres * atmosphere_strength;
}
