shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_never, blend_mix;

uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);
uniform float wind_speed = 0.4;
uniform float strength = 1.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = noise(world.xz * 0.01 + vec2(TIME * wind_speed, 0.0));
	VERTEX.y += (n - 0.5) * strength;
}

void fragment() {
	vec2 uv = UV * 4.0 + vec2(TIME * wind_speed * 0.05, 0.0);
	float n = noise(uv);
	float puff = smoothstep(0.42, 0.72, n);
	ALBEDO = cloud_color.rgb;
	ALPHA = cloud_color.a * puff;
}
