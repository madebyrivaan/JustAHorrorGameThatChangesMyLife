shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float dust_density = 0.35;
uniform float dust_size = 18.0;
uniform float movement_speed = 0.01;

uniform vec3 dust_color : source_color = vec3(0.3,0.6,1.0);
uniform float glow_strength = 2.0;

float hash(vec2 p){
    p = fract(p * vec2(123.34,456.21));
    p += dot(p,p+45.32);
    return fract(p.x*p.y);
}

void fragment(){

    vec2 uv = UV * dust_size;

    uv += vec2(TIME * movement_speed, TIME * movement_speed * 0.6);

    vec2 id = floor(uv);
    vec2 gv = fract(uv) - 0.5;

    float rnd = hash(id);

    float size = mix(0.05,0.25,rnd);

    float d = length(gv);

    float particle = smoothstep(size, size * 0.5, d);

    float dust = particle * step(0.92, rnd);

    dust *= dust_density;

    vec3 color = dust_color * glow_strength;

    ALBEDO = color;
    EMISSION = color;

    ALPHA = dust * 0.35;
}