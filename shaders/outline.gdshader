shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
// Ters kabuk kontur: model normaller boyunca ekran uzayında şişirilir.
// Kalınlık piksel cinsindendir ve ekran yüksekliğine göre ölçeklenir.

uniform vec4 outline_color : source_color = vec4(0.04, 0.035, 0.05, 1.0);
uniform float thickness = 2.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 clip_normal = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	if (length(clip_normal) > 0.0001) {
		clip_normal = normalize(clip_normal);
	}
	float px = thickness * VIEWPORT_SIZE.y / 720.0;
	clip.xy += clip_normal * px * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
