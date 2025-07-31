shader_type spatial;
render_mode unshaded;


void fragment() {
	ALBEDO.rgb = vec3(round(mod(UV.y * 0.5, 1)));
    ALPHA = 0.5;
}

