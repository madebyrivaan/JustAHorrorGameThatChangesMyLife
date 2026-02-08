shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// --- SETTINGS --- //
uniform vec4 base_color : source_color = vec4(0.4, 0.42, 0.38, 1.0);
uniform vec4 grime_color : source_color = vec4(0.1, 0.08, 0.06, 1.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float uv_scale = 4.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float normal_strength : hint_range(0.1, 5.0) = 0.2;
uniform float contrast : hint_range(0.0, 3.0) = 1.5;

void fragment() {
    // ---- STABLE UVs ----
    vec2 uv = UV * uv_scale;
    
    // Explicit UV gradients (Keep these for textureGrad to prevent aliasing)
    vec2 uv_dx = dFdx(uv);
    vec2 uv_dy = dFdy(uv);
    
    // Stable noise sampling
    float n = textureGrad(noise_tex, uv, uv_dx, uv_dy).r;
    
    // Contrast
    float mask = clamp((n - 0.5) * contrast + 0.5, 0.0, 1.0);
    
    // Color
    ALBEDO = mix(grime_color.rgb, base_color.rgb, mask);
    
    // Roughness
    ROUGHNESS = clamp(roughness + (1.0 - mask) * 0.2, 0.1, 1.0);
    SPECULAR = 0.2;
    
    // ---- STABLE HARDWARE NORMALS FIX ----
    // We define a FIXED offset (epsilon) in texture space. 
    // This stops the swimming because the sample distance never changes.
    const float e = 0.005; 
    
    // Sample height using the FIXED offset 'e' for position, 
    // but keep 'uv_dx/dy' for the mipmap calculation to prevent performance loss/grain.
    float h_dx = textureGrad(noise_tex, uv + vec2(e, 0.0), uv_dx, uv_dy).r - n;
    float h_dy = textureGrad(noise_tex, uv + vec2(0.0, e), uv_dx, uv_dy).r - n;
    
    // Recalculate Normal
    // Note: Since 'e' is constant, the strength is now consistent at all distances.
    // I adjusted the multiplier slightly to maintain your intended "AAA" look 
    // given the new fixed step size.
    NORMAL = normalize(vec3(
        -h_dx * normal_strength * 50.0,
        -h_dy * normal_strength * 50.0,
        1.0
    ));
}