shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Parámetros de color y absorción por profundidad
uniform vec4 albedo_shallow : source_color = vec4(0.08, 0.38, 0.52, 0.88);
uniform vec4 albedo_deep : source_color = vec4(0.015, 0.065, 0.16, 0.98);
uniform vec4 foam_color : source_color = vec4(0.92, 0.96, 1.0, 1.0);

uniform float wave_speed : hint_range(0.1, 3.0) = 0.95;
uniform float wave_amplitude : hint_range(0.0, 1.5) = 0.22;
uniform float depth_distance : hint_range(0.5, 20.0) = 5.5;
uniform float foam_distance : hint_range(0.05, 3.0) = 0.85;

uniform float roughness : hint_range(0.0, 1.0) = 0.06;
uniform float metallic : hint_range(0.0, 1.0) = 0.10;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wave_normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 world_pos;
varying vec3 vertex_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Ondas sinusoidales superpuestas para desplazamiento físico de vértices
	float wave1 = sin(world_pos.x * 0.12 + TIME * wave_speed * 1.1) * cos(world_pos.z * 0.10 + TIME * wave_speed * 0.8);
	float wave2 = sin(world_pos.x * 0.28 - TIME * wave_speed * 0.9) * sin(world_pos.z * 0.22 + TIME * wave_speed * 1.2);
	float wave3 = cos((world_pos.x + world_pos.z) * 0.06 + TIME * wave_speed * 0.7);
	
	float total_displacement = (wave1 * 0.55 + wave2 * 0.30 + wave3 * 0.15) * wave_amplitude;
	VERTEX.y += total_displacement;
	vertex_normal = NORMAL;
}

void fragment() {
	// Reconstrucción de profundidad lineal en Godot 4
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float linear_depth = -view_pos.z;
	float water_depth = max(0.0, linear_depth - (-VERTEX.z));

	// Dos capas de normales animadas en diferentes direcciones angulares
	vec2 uv_scroll_1 = world_pos.xz * 0.055 + vec2(TIME * wave_speed * 0.03, TIME * wave_speed * 0.02);
	vec2 uv_scroll_2 = world_pos.xz * 0.11 - vec2(TIME * wave_speed * 0.025, -TIME * wave_speed * 0.035);

	vec3 n1 = texture(wave_normal_tex, uv_scroll_1).rgb * 2.0 - 1.0;
	vec3 n2 = texture(wave_normal_tex, uv_scroll_2).rgb * 2.0 - 1.0;
	vec3 blended_normal = normalize(n1 + n2);
	NORMAL = normalize(mix(NORMAL, blended_normal, 0.40));

	// Absorción de profundidad (aguas someras claras vs abismo oceánico oscuro)
	float depth_ratio = clamp(water_depth / depth_distance, 0.0, 1.0);
	vec3 water_col = mix(albedo_shallow.rgb, albedo_deep.rgb, depth_ratio);

	// Espuma suave en la orilla / orillas de rocas
	float foam_wave = sin(world_pos.x * 0.4 + TIME * wave_speed * 2.0) * 0.15;
	float foam_edge = smoothstep(foam_distance + foam_wave, 0.02, water_depth);
	foam_edge = clamp(foam_edge, 0.0, 1.0);

	// Reflejo Fresnel óptico
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.5);
	vec3 final_surface = mix(water_col, foam_color.rgb, foam_edge * 0.85);

	ALBEDO = final_surface;
	ROUGHNESS = mix(roughness, 0.48, foam_edge);
	METALLIC = metallic;
	SPECULAR = 0.75 + fresnel * 0.25;
}
