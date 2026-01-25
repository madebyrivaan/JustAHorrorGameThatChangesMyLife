shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.353, 0.416, 0.369, 1.0); // #5A6A5E
uniform float roughness_base = 0.85;
uniform float roughness_variation = 0.25;
uniform float grime_strength = 0.35;
uniform float normal_strength = 0.4;

uniform sampler2D noise_tex : repeat_enable;

void fragment() {
    vec2 uv = UV * 2.5;

    // Noise sampling
    float n1 = texture(noise_tex, uv).r;
    float n2 = texture(noise_tex, uv * 4.0).g;

    // Base wall color with subtle variation
    ALBEDO = base_color.rgb * mix(0.9, 1.05, n1);

    // MADiSON-style roughness breakup
    ROUGHNESS = clamp(
        roughness_base + (n1 * roughness_variation),
        0.45,
        1.0
    );

    // Dirt / age darkening
    ALBEDO *= mix(1.0, 0.75, n2 * grime_strength);

    // Fake surface unevenness (cheap but effective)
    NORMAL = normalize(vec3(
        (n1 - 0.5) * normal_strength,
        (n2 - 0.5) * normal_strength,
        1.0
    ));
}
