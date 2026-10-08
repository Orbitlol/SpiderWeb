shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec4 web_color : source_color = vec4(0.86, 0.93, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(0.55, 0.75, 1.0, 1.0);
uniform float glow = 1.6;
uniform float braid_scale = 22.0;
uniform float scroll_speed = 1.4;
uniform int strands = 2;

void fragment() {
	float along = UV.x;
	float around = fract(UV.y * float(max(strands, 1)) + TIME * scroll_speed);
	float braid = sin(along * braid_scale - TIME * scroll_speed * 3.0 + around * 6.28318);
	float mask = smoothstep(-0.2, 0.85, braid);
	vec3 col = mix(web_color.rgb, accent_color.rgb, mask);
	ALBEDO = col;
	EMISSION = col * glow * (0.55 + 0.45 * mask);
	ALPHA = web_color.a;
}
