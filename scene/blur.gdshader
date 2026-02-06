shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;
uniform float radius : hint_range(0.0, 10.0) = 4.0;

void fragment() {
	vec2 uv = SCREEN_UV;

	// textureSize returns ivec2 → must cast to vec2
	vec2 px = 1.0 / vec2(textureSize(screen_tex, 0));

	vec4 col = vec4(0.0);
	float total = 0.0;

	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			vec2 fxy = vec2(float(x), float(y));

			vec2 offset = fxy * px * radius;

			// length MUST be float vec2, not int vec2
			float w = 1.0 - length(fxy) / 6.0;
			w = max(w, 0.0);

			col += texture(screen_tex, uv + offset) * w;
			total += w;
		}
	}

	COLOR = col / total;
}
