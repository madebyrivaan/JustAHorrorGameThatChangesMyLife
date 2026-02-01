shader_type spatial;
render_mode unshaded;

uniform float noise_speed = 8.0;
uniform float flicker = 0.4;
uniform float line_strength = 0.25;

float rand(vec2 uv){
	return fract(sin(dot(uv, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Moving noise
	float n = rand(vec2(uv.y * 200.0, TIME * noise_speed));

	// Horizontal scanlines
	float lines = sin(uv.y * 800.0) * line_strength;

	// Flicker
	float f = sin(TIME * 20.0) * flicker;

	float col = n + lines + f;

	col = clamp(col,0.0,1.0);

	ALBEDO = vec3(col);
}
