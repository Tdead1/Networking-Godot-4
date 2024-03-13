// NOTE: Shader automatically converted from Godot Engine 4.3.dev's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
instance uniform float lightness;

void fragment() {
	ALBEDO = lightness * 0.1 * albedo.rgb;
}
