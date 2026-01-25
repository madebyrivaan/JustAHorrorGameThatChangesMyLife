shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color;
uniform sampler2D roughness_tex;
uniform sampler2D noise_tex : repeat_enable;

uniform float roughness_boost = 0.05;
uniform float center_darkening = 0.3;
uniform float center_falloff = 0.55;
uniform float grime_strength = 0.25;

void fragment() {
    vec2 uv = UV;

    // Base textures
    vec3 base_col = texture(albedo_tex, uv).rgb;
    float base_rough = texture(roughness_tex, uv).r;

    // Noise
    float n = texture(noise_tex, uv * 2.0).r;

    // Center mask (ceiling pressure)
    vec2 centered_uv = abs(uv - vec2(0.5));
    float dist = length(centered_uv);
    float center_mask = smoothstep(center_falloff, 0.0, dist);

    // Albedo
    ALBEDO = base_col;
    ALBEDO *= mix(1.0, 0.8, n * grime_strength); // dirt breakup
    ALBEDO *= mix(1.0, 1.0 - center_darkening, center_mask); // dark center

    // Roughness (very matte ceiling)
    ROUGHNESS = clamp(
        base_rough + roughness_boost + n * 0.05,
        0.7,
        1.0
    );
}
