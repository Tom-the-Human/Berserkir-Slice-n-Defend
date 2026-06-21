shader_type canvas_item;

// We will now treat 1.0 as the START of the effect, and 0.0 as the END.
uniform float drip_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 blood_color : source_color = vec4(0.6, 0.0, 0.0, 1.0);

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // 1. Create a 10x10 grid of invisible cells
    vec2 grid_uv = UV * vec2(10.0, 10.0); 
    vec2 cell_id = floor(grid_uv);
    vec2 cell_uv = fract(grid_uv);
    
    // 2. Fixed 30% chance for a cell to contain a drop
    float drop_chance = random(cell_id);
    
    if (drop_chance < 0.1) {
        
        vec2 drop_pos = vec2(0.5, 0.2); // Start near the top of the cell
        drop_pos.x += (random(cell_id + vec2(1.0)) - 0.5) * 0.5; // Random horizontal offset
        
        // 3. Drive the falling animation using drip_amount instead of TIME
        // As drip_amount goes from 1.0 -> 0.0, fall_progress increases
        float fall_speed = 1.0 + random(cell_id + vec2(2.0)) * 2.0;
        float fall_progress = (1.0 - drip_amount) * fall_speed;
        
        // Offset the UV to push the drop downwards
        vec2 animated_uv = cell_uv;
        animated_uv.y -= fall_progress; 
        
        // 4. Stretch the drop vertically so it looks like a falling tear
        animated_uv.y *= 0.5;
        drop_pos.y *= 0.5;
        
        float dist = distance(animated_uv, drop_pos);
        float drop_size = 0.1 + (random(cell_id) * 0.05); // Randomize radius
        
        // Soft edge
        float edge = smoothstep(drop_size, drop_size - 0.02, dist);
        
        // 5. Fade out the opacity as drip_amount reaches 0
        float alpha = edge * drip_amount * blood_color.a;
        
        COLOR = vec4(blood_color.rgb, alpha);
        
    } else {
        COLOR = vec4(0.0); // Empty cell
    }
}
