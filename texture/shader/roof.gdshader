shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// -------- TEXTURES -------- //
uniform sampler2D albedo_tex  : repeat_enable, filter_linear_mipmap;
uniform sampler2D roughness_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D height_tex : repeat_enable, filter_linear_mipmap;

// -------- CONTROLS -------- //
uniform float uv_scale = 4.0;
uniform float roughness_strength : hint_range(0.0, 2.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.25;
uniform float height_contrast : hint_range(0.5, 4.0) = 1.5;

void fragment() {

    // ---- STABLE UVs ----
    vec2 uv = UV * uv_scale;

    vec2 uv_dx = dFdx(uv);
    vec2 uv_dy = dFdy(uv);

    // ---- ALBEDO (NO COLOR, PURE IMAGE) ----
    vec3 albedo = textureGrad(albedo_tex, uv, uv_dx, uv_dy).rgb;
    ALBEDO = albedo;

    // ---- ROUGHNESS FROM IMAGE ----
    float r = textureGrad(roughness_tex, uv, uv_dx, uv_dy).r;
    ROUGHNESS = clamp(r * roughness_strength, 0.05, 1.0);

    SPECULAR = 0.2;

    // ---- HEIGHT → NORMAL (STABLE, NO SWIMMING) ----
    float h = textureGrad(height_tex, uv, uv_dx, uv_dy).r;
    h = clamp((h - 0.5) * height_contrast + 0.5, 0.0, 1.0);

    const float e = 0.005;

    float h_dx = textureGrad(height_tex, uv + vec2(e, 0.0), uv_dx, uv_dy).r - h;
    float h_dy = textureGrad(height_tex, uv + vec2(0.0, e), uv_dx, uv_dy).r - h;

    NORMAL = normalize(vec3(
        -h_dx * normal_strength * 40.0,
        -h_dy * normal_strength * 40.0,
        1.0
    ));
}
