shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.1, 2.0) = 0.6;
uniform float roundness : hint_range(0.5, 2.0) = 1.2;

void fragment() {

	vec2 uv = UV - vec2(0.5);

	// Slight vertical stretch (less perfect circle)
	uv.y *= roundness;

	float dist = length(uv) * 2.0;

	// Sharper inner falloff
	float vignette = smoothstep(softness, 1.0, pow(dist, 1.8));

	COLOR = vec4(0.0, 0.0, 0.0, vignette * intensity);
}