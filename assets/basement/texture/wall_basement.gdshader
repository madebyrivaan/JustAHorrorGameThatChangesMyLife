shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color;
uniform sampler2D normal_tex : hint_normal;
uniform sampler2D roughness_tex;

uniform sampler2D noise_tex : repeat_enable;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform float grime_strength = 0.4;
uniform float roughness_boost = 0.15;
uniform float normal_strength = 1.0;

void fragment() {
    vec2 uv = UV;

    // Base textures
    vec3 base_col = texture(albedo_tex, uv).rgb;
    float base_rough = texture(roughness_tex, uv).r;
    vec3 base_normal = texture(normal_tex, uv).rgb * 2.0 - 1.0;

    // Noise for breakup
    float noise = texture(noise_tex, uv * 3.0).r;

    // Color
    ALBEDO = base_col * tint_color.rgb;
    ALBEDO *= mix(1.0, 0.7, noise * grime_strength);

    // Roughness (MADiSON-style uneven wall)
    ROUGHNESS = clamp(
        base_rough + noise * roughness_boost,
        0.3,
        1.0
    );

    // Normal control
    NORMAL = normalize(mix(vec3(0.0, 0.0, 1.0), base_normal, normal_strength));
}
