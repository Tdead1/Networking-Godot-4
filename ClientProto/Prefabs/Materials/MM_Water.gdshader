shader_type spatial;

uniform sampler2D NOISE_PATTERN;

const vec4 color = vec4(0.3,0.6,0.8, 0.6);
const float wave_count = 24.0;
const float frequency = 24.0;
const float speed = 0.2;

void vertex() 
{
	float water_height = 0.0;
	float x = UV.x; 
	float y = UV.y;

	vec2 wind = vec2(1,0);
	for (float wave_index = 0.0; wave_index < wave_count; wave_index++)
	{
		wind.x = cos(wave_index * PI * 1.1723 + TIME * PI * 0.073);
		wind.y = sin(wave_index * PI * 1.1723 + TIME * PI * 0.073);
		
		float modifier = sqrt(wave_index);
		float phase = speed * (frequency + modifier);
		float amplitude = 40000000000.0 * (exp(- frequency - modifier));
		water_height += (amplitude * (wind.x * cos(x * (frequency + modifier) + TIME * phase))  			+ sqrt(amplitude)) / (wave_count * 2.0);
		water_height += (amplitude * (wind.y * sin(y * (frequency + modifier) + TIME * phase))  			+ sqrt(amplitude)) / (wave_count * 2.0);
		
	}
	VERTEX.y += water_height;
}

void fragment() 
{
	float water_height = 0.0;
	float x = UV.x; 
	float y = UV.y;

	vec2 wind = vec2(1,0);
	for (float wave_index = 0.0; wave_index < wave_count; wave_index++)
	{
		wind.x = cos(wave_index * PI * 1.1723 + TIME * PI * 0.073);
		wind.y = sin(wave_index * PI * 1.1723 + TIME * PI * 0.073);
		
		float modifier = sqrt(wave_index);
		float phase = speed * (frequency + modifier);
		float amplitude = 40000000000.0 * (exp(- frequency - modifier));
		water_height += (amplitude * (wind.x * cos(x * (frequency + modifier) + TIME * phase))  			+ sqrt(amplitude)) / (wave_count * 2.0);
		water_height += (amplitude * (wind.y * sin(y * (frequency + modifier) + TIME * phase))  			+ sqrt(amplitude)) / (wave_count * 2.0);
	}
	
	ALBEDO = vec3(water_height);
	ALBEDO.b += 0.2;
	ALBEDO.g += 0.1;
	//if (water_height > 0.4)
	//	ALBEDO = vec3(1.0,1.0,1.0);
	//else
	//	ALBEDO = color.xyz;
	//ALBEDO = vec3((water_height + 0.4) * 0.4, (water_height + 0.6) * 0.6, (water_height + 0.5) * 1.4);
	//ALBEDO.b = water_height;
	METALLIC = 0.7;
	ROUGHNESS = 0.0;
	ALPHA = 0.5;//color.a + (water_height * 0.3);
}