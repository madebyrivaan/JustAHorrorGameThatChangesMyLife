shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// --- SETTINGS --- //
uniform vec4 base_color : source_color = vec4(0.4, 0.42, 0.38, 1.0); // Sickly Green
uniform vec4 grime_color : source_color = vec4(0.1, 0.08, 0.06, 1.0); // Dark dirt
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;

uniform float uv_scale = 4.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float normal_strength : hint_range(0.1, 5.0) = 1.0;
uniform float contrast : hint_range(0.0, 3.0) = 1.5;

void fragment() {
	vec2 uv = UV * uv_scale;

	// 1. SINGLE TEXTURE FETCH (Performance Saver)
	// We get all our data from just ONE read of the texture.
	float n = texture(noise_tex, uv).r;

	// 2. CHEAP CONTRAST
	// Makes the noise sharper without complex math.
	float mask = clamp((n - 0.5) * contrast + 0.5, 0.0, 1.0);

	// 3. COLOR & ROUGHNESS
	// Mix base and grime.
	ALBEDO = mix(grime_color.rgb, base_color.rgb, mask);

	// Invert mask for roughness: Darker areas (grime) are rougher, lighter areas slightly smoother
	ROUGHNESS = clamp(roughness + (1.0 - mask) * 0.2, 0.1, 1.0);

	// 4. HARDWARE NORMALS (The Magic Trick)
	// Instead of calculating normals manually, we ask the GPU:
	// "How much does the color change between this pixel and the next?"
	// This creates a bump map instantly with zero extra cost.
	float height = n;
	float d_x = dFdx(height);
	float d_y = dFdy(height);

	// Construct the normal vector
	NORMAL = normalize(vec3(-d_x * normal_strength * 20.0, -d_y * normal_strength * 20.0, 1.0));
}