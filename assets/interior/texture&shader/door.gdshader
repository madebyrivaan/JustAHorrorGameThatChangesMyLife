shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

uniform vec3 base_white : source_color = vec3(0.85, 0.85, 0.83);
uniform vec3 dirty_gray : source_color = vec3(0.55, 0.56, 0.55);

uniform float noise_scale = 6.0;
uniform float dirt_strength = 0.45;
uniform float roughness_base = 0.75;
uniform float flicker_strength = 0.04; // keep LOW

// simple hash noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV * noise_scale;

    float n = noise(uv);

    // Base uneven paint
    vec3 color = mix(base_white, dirty_gray, n);

    // Panel cavity dirt (VERY IMPORTANT)
    float panel_mask = smoothstep(0.15, 0.45, fract(UV.y * 4.0)) *
                       smoothstep(0.15, 0.45, fract(UV.x * 2.0));

    color -= panel_mask * dirt_strength * 0.12;

    // Edge aging (door borders)
    float edge = smoothstep(0.0, 0.08, UV.x) +
                 smoothstep(0.92, 1.0, UV.x) +
                 smoothstep(0.0, 0.08, UV.y) +
                 smoothstep(0.92, 1.0, UV.y);

    color -= edge * dirt_strength * 0.25;

    // Subtle horror flicker (keep tiny)
    float flicker = sin(TIME * 0.5 + n * 8.0) * flicker_strength;
    color += flicker;

    ALBEDO = color;
    ROUGHNESS = roughness_base + n * 0.2;
    SPECULAR = 0.12;
}

