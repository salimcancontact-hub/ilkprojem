shader_type sky;
// Uzay gökyüzü: yıldızlar, hafif bulutsu ve yıldız (güneş) diski.

uniform vec3 nebula_color : source_color = vec3(0.10, 0.06, 0.18);
uniform vec3 nebula_color2 : source_color = vec3(0.02, 0.08, 0.14);
uniform float star_density = 0.9965;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 col = vec3(0.003, 0.005, 0.010);
	// Bulutsu: birkaç katman gürültü
	float n = noise(d * 3.0) * 0.6 + noise(d * 7.0) * 0.3 + noise(d * 15.0) * 0.1;
	float band = pow(max(0.0, 1.0 - abs(d.y + 0.15) * 1.6), 2.0);
	col += mix(nebula_color2, nebula_color, n) * band * smoothstep(0.35, 0.85, n) * 1.4;
	// Yıldızlar
	vec3 g = floor(d * 380.0);
	float h = hash(g);
	float star = step(star_density, h) * (0.4 + 0.6 * hash(g + 7.0));
	vec3 tint = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.7), hash(g + 3.0));
	col += tint * star * 2.5;
	// Güneş diski ve halesi
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += LIGHT0_COLOR * (pow(sd, 2000.0) * 40.0 + pow(sd, 60.0) * 0.25);
	COLOR = col;
}
