shader_type canvas_item;
render_mode blend_add;

uniform float speed = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float lines = pow(abs(sin(a * 28.0)), 22.0);
	float mask = smoothstep(0.25, 1.05, r) * lines * speed;
	COLOR = vec4(0.75, 0.88, 1.0, mask * 0.45);
}
