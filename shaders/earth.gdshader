shader_type spatial;
render_mode unshaded, cull_back;
// 2526 Dünyası: eşdikdörtgen doku + güneş aydınlatması + atmosfer halesi (ucuz, mobil için)
uniform sampler2D surface : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 sun_dir = vec3(0.4, 0.35, 0.85);
uniform vec3 atmo_color : source_color = vec3(0.35, 0.6, 1.0);
uniform float spin = 0.0;
varying vec3 n_obj;
varying vec3 n_view;
void vertex() {
	n_obj = normalize(VERTEX);
	n_view = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 n = normalize(n_obj);
	float lon = atan(n.z, n.x) + spin;
	float lat = asin(clamp(n.y, -1.0, 1.0));
	vec2 uv = vec2(fract(lon / 6.2831853 + 0.5), 0.5 - lat / 3.1415927);
	vec3 col = texture(surface, uv).rgb;
	float l = clamp(dot(n, normalize(sun_dir)), 0.0, 1.0);
	float day = smoothstep(-0.05, 0.35, dot(n, normalize(sun_dir)));
	vec3 night = col * 0.04 + vec3(0.9, 0.55, 0.2) * 0.05 * step(0.5, col.r - col.b);  // yanan şehir ışıkları
	col = mix(night, col * (0.35 + 0.85 * l), day);
	float rim = pow(1.0 - clamp(dot(normalize(n_view), vec3(0.0, 0.0, 1.0)), 0.0, 1.0), 3.0);
	col += atmo_color * rim * (0.25 + 0.9 * day);
	ALBEDO = col;
}
