shader_type spatial;
render_mode cull_disabled, blend_mix;

uniform vec4 deep_color : source_color = vec4(0.02, 0.08, 0.12, 0.92);
uniform vec4 shallow_color : source_color = vec4(0.05, 0.22, 0.28, 0.85);

void fragment() {
	float shift = sin(UV.x * 28.0 + TIME * 0.8) * 0.5 + 0.5;
	float ripple = sin(UV.y * 40.0 - TIME * 1.3) * 0.5 + 0.5;
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, shift * 0.6 + ripple * 0.2);
	ALBEDO = col;
	ROUGHNESS = 0.18;
	METALLIC = 0.05;
	ALPHA = deep_color.a;
}
