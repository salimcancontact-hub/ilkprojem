shader_type canvas_item;
// Tehlike anında ekran kenarlarından yayılan kırmızılık (TWD tarzı).

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse = 0.0;

void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.0, 0.8));
	float edge = smoothstep(0.18, 0.72, d);
	float a = edge * intensity * (0.85 + 0.15 * sin(pulse));
	COLOR = vec4(0.65, 0.02, 0.02, clamp(a, 0.0, 0.9));
}
