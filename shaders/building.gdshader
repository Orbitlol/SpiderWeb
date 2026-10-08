shader_type spatial;

uniform vec4 wall_color : source_color = vec4(0.18, 0.19, 0.22, 1.0);
uniform vec4 accent_color : source_color = vec4(0.32, 0.35, 0.4, 1.0);
uniform vec4 window_color : source_color = vec4(1.0, 0.82, 0.55, 1.0);
uniform float time_of_day = 0.6;
uniform float wetness = 0.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 uv = vec2(local_pos.x + local_pos.z, local_pos.y);
	uv *= vec2(0.55, 0.42);
	vec2 cell = fract(uv);
	float window = step(0.18, cell.x) * step(cell.x, 0.82) * step(0.16, cell.y) * step(cell.y, 0.78);
	float lit = step(0.42, fract(sin(dot(floor(uv), vec2(12.9898, 78.233))) * 43758.5453));
	float night = 1.0 - clamp(time_of_day, 0.0, 1.0);
	vec3 albedo = mix(wall_color.rgb, accent_color.rgb, window * 0.35);
	albedo = mix(albedo, window_color.rgb * 0.35, window * lit * 0.5);
	albedo = mix(albedo, albedo * vec3(0.55, 0.62, 0.7), wetness);
	ALBEDO = albedo;
	ROUGHNESS = mix(0.86, 0.35, wetness);
	METALLIC = 0.04;
	EMISSION = window_color.rgb * window * lit * night * 1.35;
}
