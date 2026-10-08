shader_type canvas_item;

uniform float danger = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float edge = smoothstep(0.45, 1.15, r) * danger;
	vec3 col = mix(vec3(0.7, 0.85, 1.0), vec3(1.0, 0.25, 0.2), danger);
	COLOR = vec4(col, edge * 0.72);
}
