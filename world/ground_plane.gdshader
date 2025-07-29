shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float gridlines_in_mesh = 1000.0;
uniform vec2 fine_width = vec2(0.0000001, 0.0000001);

float circle(vec2 uv, float radius, float feather) {
    return smoothstep(radius, radius + feather, length(uv));
}

float line_x(vec2 uv) {
    float thick_width = fwidth(uv.y);
    float feather = fwidth(uv.y);
    float lineUV = abs(uv.y * 2.0);
    return smoothstep(thick_width + feather, thick_width - feather, lineUV);
}

float line_y(vec2 uv) {
    float thick_width = fwidth(uv.x);
    float feather = fwidth(uv.x);
    float lineUV = abs(uv.x * 2.0);
    return smoothstep(thick_width + feather, thick_width - feather, lineUV);
}

float grid(vec2 uv) {
    vec2 feather = fwidth(uv);
    vec2 lineUV = 1.0 - abs(fract(uv * gridlines_in_mesh) / (2.0 * gridlines_in_mesh) - 1.0);
    vec2 grid2 = smoothstep(fine_width + feather, fine_width - feather, lineUV);
    return mix(grid2.x, 1.0, grid2.y);
}

void fragment() {
    vec2 uv = UV - 0.5;
    vec3 color;
    float alpha;
    float x_axis = line_x(uv);
    float y_axis = line_y(uv);
    if (x_axis > 0.1 || y_axis > 0.1) {
        color = vec3(x_axis, 0, 0) + vec3(0, y_axis, 0);
        alpha = x_axis + y_axis;
    } else {
        float grid_value = grid(uv);
        color = vec3(grid_value) * 0.5;
        alpha = grid_value * 0.5;
    }
    ALBEDO.rgb = clamp(color, vec3(0), vec3(1));
	ALPHA = clamp(alpha - circle(uv, 0.2, 0.3), 0, 1);
}
