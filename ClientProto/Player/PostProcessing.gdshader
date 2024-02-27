shader_type spatial;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
 	POSITION = vec4(VERTEX, 1.0);
}

vec3 reconstructPosition(vec2 uv, float z, mat4 InvVP)
{
  float x = uv.x * 2.0f - 1.0f;
  float y = (1.0 - uv.y) * 2.0f - 1.0f;
  vec4 position_s = vec4(x, y, z, 1.0f);
  vec4 position_v = InvVP * position_s;
  return position_v.xyz / position_v.w;
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	float size = 0.001;
	
	float depth_left = texture(depth_texture, SCREEN_UV + vec2(-size, 0)).r;
	float depth_right = texture(depth_texture, SCREEN_UV + vec2(size, 0)).r;
	float depth_down = texture(depth_texture, SCREEN_UV + vec2(0, -size)).r;
	float depth_up = texture(depth_texture, SCREEN_UV + vec2(0, size)).r;
	
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth); // normalized device coordinates, -1 -> 1 for x, 0 -> 1 for z (vulkan)
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	vec3 ndc_left = vec3(SCREEN_UV * 2.0 - 1.0, depth_left);
	vec4 view_left = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_left.xyz /= view.w;
	float linear_depth_left = -view_left.z;
	
	vec3 ndc_right = vec3(SCREEN_UV * 2.0 - 1.0, depth_right);
	vec4 view_right = INV_PROJECTION_MATRIX * vec4(ndc_right, 1.0);
	view_right.xyz /= view_right.w;
	float linear_depth_right = -view_right.z;
	
	vec3 ndc_down = vec3(SCREEN_UV * 2.0 - 1.0, depth_down);
	vec4 view_down = INV_PROJECTION_MATRIX * vec4(ndc_down, 1.0);
	view_down.xyz /= view_down.w;
	float linear_depth_down = -view_down.z;
	
	vec3 ndc_up = vec3(SCREEN_UV * 2.0 - 1.0, depth_up);
	vec4 view_up = INV_PROJECTION_MATRIX * vec4(ndc_up, 1.0);
	view_up.xyz /= view_up.w;
	float linear_depth_up = -view_up.z;
	
	float depth_diff = abs(depth_left - depth_right);
	depth_diff += abs(depth_up - depth_down);
	
	float linear_depth_diff = abs(linear_depth_left - linear_depth_right);
	linear_depth_diff += abs(linear_depth_up - linear_depth_down);
	
	vec3 P = reconstructPosition(SCREEN_UV, depth, INV_PROJECTION_MATRIX);
	vec3 normal = normalize(cross(dFdx(P), dFdy(P)));
	
	// This needs to use the pixel forward not the camera forward
	float dot_angle = dot(normal, INV_PROJECTION_MATRIX[3].xyz);
	float angle = acos(clamp(dot_angle, -1.0, 1.0));// / (2.0*PI);
	//if (angle > (0.75 * PI))
	//{
	//	angle = 1.0;
	//}
	//else
	//{
	//	angle = 0.0;
	//}
	//if (depth_diff > 0.001) {
	if ((0.5 < (angle - 0.5*PI) * 2.0) && linear_depth_diff > (linear_depth * 0.01)) {
		ALBEDO = vec3(0.0,0.0,0.0);
	} else {
		ALBEDO = texture(screen_texture, SCREEN_UV).xyz; // black
	}
	//ALBEDO = vec3((angle - 0.5*PI) * 2.0);
}