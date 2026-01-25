shader_type spatial;
render_mode specular_schlick_ggx;

//// =========================
//// TEXTURES
//// =========================
uniform sampler2D detail_tex : repeat_enable; // <-- USE YOUR GRAY TEXTURE HERE

//// =========================
//// BASE COLOR (PAINT)
//// =========================
uniform vec3 base_color = vec3(0.92, 0.92, 0.92);

//// =========================
//// ROUGHNESS
//// =========================
uniform float roughness_base = 0.85;
uniform float roughness_strength = 0.45;

//// =========================
//// DIRT / AGE
//// =========================
uniform float dirt_strength = 0.5;
uniform float edge_dirt_strength = 0.65;

//// =========================
//// NORMAL FAKE
//// =========================
uniform float normal_strength = 0.35;

void fragment() {

    vec2 uv = UV;

    // --- DETAIL SAMPLE ---
    float d = texture(detail_tex, uv * 2.0).r;

    // --- EDGE MASK (TOP + BOTTOM STRIP DIRT) ---
    float edge = abs(uv.y - 0.5) * 2.0;
    edge = pow(edge, 1.6);

    // --- ALBEDO ---
    vec3 color = base_color;

    // dirt from texture
    color *= mix(1.0, 0.75, d * dirt_strength);

    // edge accumulation
    color *= mix(1.0, 1.0 - edge_dirt_strength, edge);

    // micro shadow (THIS IS BIG)
    color *= mix(1.0, 0.82, d);

    ALBEDO = color;

    // --- ROUGHNESS (TEXTURE-DRIVEN) ---
    float rough = roughness_base + d * roughness_strength;
    ROUGHNESS = clamp(rough, 0.7, 1.0);

    // --- SPECULAR KILL ---
    SPECULAR = 0.04;

    // --- FAKE NORMAL (TEXTURE PUSH) ---
    NORMAL = normalize(vec3(
        (d - 0.5) * normal_strength,
        (edge - 0.5) * normal_strength * 0.6,
        1.0
    ));
}
