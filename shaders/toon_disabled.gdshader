shader_type spatial;
render_mode cull_disabled, specular_disabled;
// Çizgi roman / Telltale tarzı basamaklı gölgeleme.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_tex = false;
uniform vec3 emission : source_color = vec3(0.0);
uniform sampler2D emission_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_emission_tex = false;
uniform float mid_tone = 0.55;      // orta tonun parlaklığı
uniform float rim_strength = 0.35;  // kenar parıltısı

void fragment() {
	vec4 c = albedo;
	if (use_albedo_tex) {
		c *= texture(albedo_tex, UV);
	}
	ALBEDO = c.rgb;
	vec3 e = emission;
	if (use_emission_tex) {
		e *= texture(emission_tex, UV).rgb;
	}
	EMISSION = e;
	ROUGHNESS = 1.0;
}

void light() {
	// Basamaklar yalnızca ışık açısına uygulanır; uzaklıkla azalma ve gölge yumuşak kalır.
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float band = mid_tone * smoothstep(0.04, 0.09, ndl) + (1.0 - mid_tone) * smoothstep(0.42, 0.48, ndl);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * rim_strength * step(0.05, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * (band * 0.8 + rim) * ATTENUATION;
}
