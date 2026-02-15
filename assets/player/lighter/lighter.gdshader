shader_type spatial;

render_mode blend_add, cull_disabled, unshaded;

uniform sampler2D flame_tex : source_color;

uniform float speed : hint_range(0.1, 5.0) = 1.5;
uniform float distortion_strength : hint_range(0.0, 0.2) = 0.04;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.15;
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;

void fragment() {

    vec2 uv = UV;

    float t = TIME * speed;

    // 🔥 upward distortion
    float wave = sin((uv.y * 8.0) - t * 5.0) * distortion_strength;
    uv.x += wave * uv.y;

    vec4 tex = texture(flame_tex, uv);

    // 🔥 flicker
    float flicker = 1.0 + sin(TIME * 25.0) * flicker_strength;

    // 🔥 vertical shaping
    float mask = smoothstep(0.0, 0.1, uv.y) * (1.0 - smoothstep(0.8, 1.0, uv.y));

    vec3 col = tex.rgb * flicker * glow_intensity;

    ALBEDO = col;
    ALPHA = tex.a * mask;
    EMISSION = col * 2.0;
}
