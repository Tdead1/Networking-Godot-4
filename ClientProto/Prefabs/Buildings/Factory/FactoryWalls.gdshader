shader_type spatial;
uniform vec4 albedo : source_color;
instance uniform float lightness = 0.0;

void fragment() {
	ALBEDO = albedo.rgb;
	ALBEDO.b += lightness;
}
