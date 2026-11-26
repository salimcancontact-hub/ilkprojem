shader_type sky;
// Uzay: seyrek yıldızlar ve hafif bir samanyolu bandı. Ucuz (her pikselde tek karma).
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 g = floor(d * 420.0);
	float h = hash(g);
	float star = step(0.9975, h) * (0.4 + 0.6 * hash(g + 3.1));
	float band = exp(-pow(dot(d, normalize(vec3(0.3, 0.9, 0.2))) * 3.2, 2.0));
	COLOR = vec3(0.006, 0.008, 0.016) + vec3(0.05, 0.05, 0.08) * band + vec3(star) * vec3(0.9, 0.95, 1.0);
}
