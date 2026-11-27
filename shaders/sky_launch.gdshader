shader_type sky;
// Kalkış gökyüzü: space = 0 -> yerde şafak (turuncu ufuk, lacivert tepe, kahverengi yer),
//                 space = 1 -> uzay (siyah, yıldızlar). Kalkışta 0'dan 1'e kayar.
uniform float space : hint_range(0.0, 1.0) = 0.0;
uniform vec3 horizon : source_color = vec3(0.95, 0.48, 0.22);
uniform vec3 zenith : source_color = vec3(0.12, 0.2, 0.42);
uniform vec3 ground : source_color = vec3(0.16, 0.11, 0.08);

float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

void sky() {
	vec3 d = normalize(EYEDIR);
	// Yerde: ufukta sıcak şafak, yukarı doğru lacivert; ufkun altı toprak
	float up = clamp(d.y, 0.0, 1.0);
	vec3 dawn = mix(horizon, zenith, pow(up, 0.45));
	float sun = pow(max(dot(d, normalize(vec3(-0.6, 0.12, 0.8))), 0.0), 40.0);
	dawn += vec3(1.0, 0.75, 0.45) * sun * 1.5;
	dawn = mix(dawn, ground, smoothstep(0.0, -0.04, d.y));
	// Uzayda: yıldızlar
	vec3 g = floor(d * 420.0);
	float star = step(0.9975, hash(g)) * (0.4 + 0.6 * hash(g + 3.1));
	vec3 night = vec3(0.006, 0.008, 0.016) + vec3(star) * vec3(0.9, 0.95, 1.0);
	// Geçişte önce tepe kararır, ufuk en son
	float s = clamp(space * 1.4 - (1.0 - up) * 0.4, 0.0, 1.0);
	// Gri ara ton olmasın: şafak -> koyu gök mavisi -> uzay siyahı
	vec3 deep = mix(vec3(0.05, 0.12, 0.32), vec3(0.02, 0.04, 0.12), up) + vec3(0.25, 0.12, 0.05) * pow(1.0 - up, 6.0);
	vec3 col = s < 0.5 ? mix(dawn, deep, s * 2.0) : mix(deep, night, (s - 0.5) * 2.0);
	COLOR = col;
}
