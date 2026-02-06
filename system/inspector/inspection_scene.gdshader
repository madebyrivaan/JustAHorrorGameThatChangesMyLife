shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	float d = length(uv);

	float vignette = smoothstep(0.4, 1.0, d);

	COLOR = vec4(0.0, 0.0, 0.0, vignette * strength);
}
