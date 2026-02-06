shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// ================= BASE =================
uniform vec4 base_color : source_color = vec4(0.55, 0.58, 0.55, 1.0);
uniform float base_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float texture_scale = 3.0;

// ================= GRIME =================
uniform vec4 grime_color : source_color = vec4(0.15, 0.12, 0.1, 1.0);
uniform float grime_amount : hint_range(0.0, 1.0) = 0.5;
uniform float grime_spread : hint_range(0.0, 4.0) = 2.0;

// ================= DETAILS =================
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float bump_strength : hint_range(0.0, 3.0) = 1.2;

void fragment() {

	vec2 uv = UV * texture_scale;

	// === SINGLE NOISE SAMPLE (core optimization)
	float n = texture(noise_tex, uv).r;

	// === Sharpen mask cheaply (replaces pow)
	float decay = clamp((n - 0.5) * grime_spread + 0.5, 0.0, 1.0);

	// === COLOR
	vec3 albedo = mix(base_color.rgb, grime_color.rgb, decay * grime_amount);

	// === Vertical dirt gradient (AAA feel, free)
	float vertical = smoothstep(0.0, 1.0, UV.y);
	albedo *= mix(0.8, 1.05, vertical);

	ALBEDO = albedo;

	// === ROUGHNESS (no extra texture fetch)
	float dynamic_rough = mix(base_roughness, 1.0, decay);
	ROUGHNESS = clamp(dynamic_rough + n * 0.08, 0.1, 1.0);

	// === HARDWARE NORMALS (super cheap bump)
	float dx = dFdx(n);
	float dy = dFdy(n);

	NORMAL = normalize(vec3(
		-dx * bump_strength * 15.0,
		-dy * bump_strength * 15.0,
		1.0
	));

	// === CHEAP AO FROM DECAY
	AO = clamp(1.0 - decay * 0.7, 0.3, 1.0);
	AO_LIGHT_AFFECT = 1.0;
}
