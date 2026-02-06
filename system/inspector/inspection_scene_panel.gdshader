shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(0.05, 0.05, 0.05, 0.8); // Dark Grey/Black tint
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0; // Blur intensity
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform sampler2D noise_texture; // Yahan ek NoiseTexture2D daalna inspector se
uniform float noise_opacity : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    // 1. Background Blur Logic
    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    
    // 2. Mix with Dark Tint (Base Color)
    color = mix(color, base_color, 0.6);
    
    // 3. Add Subtle Noise (Grime/Dust effect)
    vec4 noise = texture(noise_texture, UV + vec2(TIME * 0.02, TIME * 0.01)); // Slow moving fog
    color = mix(color, noise, noise_opacity);

    // 4. Vignette (Darker corners for the Panel)
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    color.rgb *= (1.0 - dist * vignette_intensity);

    COLOR = color;
}