shader_type spatial;
render_mode unshaded;

uniform float alpha = 0.55;

void fragment() {
	ALBEDO.rgb = vec3(round(mod(UV.y * 0.5, 1)));
    ALPHA = alpha;
}
