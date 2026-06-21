shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

// Colors to rapidly flash between
uniform vec4 color1 : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White

// How fast it alternates (higher = faster strobe)
uniform float flash_speed = 30.0;

void fragment() {
    // 1. Calculate distance from the exact center of the screen (0.5, 0.5)
    float dist = distance(UV, vec2(0.5, 0.5));
    
    // 2. Create the vignette ring based on radius and softness
    float vignette = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);

    // 3. Create the strobe effect
    // fract() loops from 0.0 to 1.0 based on TIME * speed. 
    // step(0.5, ...) turns that smooth loop into a hard 0 or 1 snap!
    float flash_mix = step(0.5, fract(TIME * flash_speed));

    // 4. Snap between Red and White based on the strobe
    vec4 flash_color = mix(color1, color2, flash_mix);

    // 5. Apply the colors, masked by the vignette and the tweened intensity
    COLOR = vec4(flash_color.rgb, flash_color.a * vignette * intensity);
}