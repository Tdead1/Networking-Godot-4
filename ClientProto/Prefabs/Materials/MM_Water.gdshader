shader_type spatial;

const vec4 color = vec4(0.3,0.6,0.8, 0.6);
const float wave_count = 150.0;
const float frequency = 6.0;
const float speed = 0.15;
const float wave_scale = 6.0; 
varying float water_height_varying;

float calculate_water_height_cool(float x, float y)
{
	float water_height = 0.0;
	x *= wave_scale;
	y *= wave_scale;
	vec2 wind = vec2(1,0);
	
	for (float wave_index = 0.0; wave_index < wave_count; wave_index++)
	{
		wind.x = cos(wave_index * PI * 1.1723 + TIME * PI * 0.035);
		wind.y = sin(wave_index * PI * 1.1723 + TIME * PI * 0.035);
		
		float modifier = wave_index;
		float phase = speed * (frequency + modifier);
		float amplitude = 1800.0 * (exp(- frequency - modifier));
		water_height += (amplitude * (cos(wind.x * x * (frequency + modifier) + TIME * phase)) + amplitude) / (wave_count * 2.0);
		water_height += (amplitude * (sin(wind.y * y * (frequency + modifier) + TIME * phase)) + amplitude) / (wave_count * 2.0);
	}
	return water_height;
}

vec4 calculate_water_height_and_derivative(vec2 uv)
{
	vec2 water_displacement = vec2(0.0,0.0);
	vec2 derivative = vec2(0.0,0.0);
	float wave_total = 100.1;
	uv += 1.0;
	for (float wave_index = 1.0; wave_index < 2.0; wave_index += 1.0 / wave_total)
	{
		float time_wave_x = cos(TIME * 0.03 + wave_index * 2.0*PI);
		float time_wave_y = sin(TIME * 0.03 + wave_index * 2.0*PI);
		
		vec2 wind = vec2(time_wave_x,time_wave_y);
		float uv_multiplier = pow(1.0 + wave_index / wave_total, 200.0);
		float amplitude_multiplier = wave_index * 0.3;
		water_displacement += sin(uv_multiplier * wind * uv + TIME) * amplitude_multiplier;
		derivative += uv_multiplier * wind * cos(uv_multiplier * wind * uv + TIME) * amplitude_multiplier;
	}
	water_displacement *= 1.0 / wave_total;
	derivative *= 1.0 / wave_total;
	return vec4(water_displacement.x, water_displacement.y, derivative.x, derivative.y);
}

void vertex() 
{
	vec4 height_and_derivative = calculate_water_height_and_derivative(UV);
	
	VERTEX.y += height_and_derivative.x;
	VERTEX.y += height_and_derivative.y;
	water_height_varying = VERTEX.y;
	NORMAL = normalize(cross(vec3(1.0,height_and_derivative.z,0.0), vec3(0.0,height_and_derivative.w,1.0))); 
}

void fragment() 
{
	//float x = UV.x; 
	//float y = UV.y;
	//float water_height = calculate_water_height(x, y);
	ALBEDO.b = 0.95;// + water_height_varying;
	ALBEDO.g = 0.6;
	ALBEDO.r = 0.6;
	ROUGHNESS = 0.50;
	SPECULAR = 1.0;
	ALPHA = 0.4;
}