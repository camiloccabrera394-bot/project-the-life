shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wall_color : source_color = vec4(0.14, 0.15, 0.18, 1.0);
uniform float building_seed = 1.0;
uniform float night_factor : hint_range(0.0, 1.0) = 1.0;
uniform float wetness : hint_range(0.0, 1.0) = 0.75;
uniform sampler2D concrete_noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 world_pos;
varying vec3 world_nrm;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 43.17);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	bool is_wall = abs(world_nrm.y) < 0.5;

	if (!is_wall) {
		// Superficie de azotea con textura granulada y humedad
		vec2 r_uv = world_pos.xz * 0.16;
		float rn = texture(concrete_noise_tex, r_uv).r;
		ALBEDO = wall_color.rgb * (0.68 + rn * 0.25) * mix(1.0, 0.72, wetness * 0.5);
		ROUGHNESS = mix(0.86, 0.28, wetness * 0.65);
		SPECULAR = 0.45;
		METALLIC = 0.0;
		NORMAL_MAP = texture(concrete_normal_tex, r_uv).rgb;
		NORMAL_MAP_DEPTH = 0.7;
		EMISSION = vec3(0.0);
	} else {
		float u = (abs(world_nrm.x) > 0.5) ? world_pos.z : world_pos.x;
		float v = world_pos.y;
		vec2 w_uv = vec2(u, v) * 0.15;
		float wn = texture(concrete_noise_tex, w_uv).r;

		// Oscurecimiento por humedad cerca de la acera
		float lower_wet = (1.0 - smoothstep(0.0, 3.2, v)) * wetness;

		// Cuadrícula de ventanas en pisos superiores
		bool in_window_zone = (v >= 3.8);
		vec2 cell_uv = vec2(u / 2.6, v / 3.6);
		vec2 cell_id = floor(cell_uv);
		vec2 f = fract(cell_uv);

		bool pane_bounds = (f.x > 0.18 && f.x < 0.82 && f.y > 0.22 && f.y < 0.86);
		bool mullion = abs(f.x - 0.50) < 0.025;
		bool is_glass = in_window_zone && pane_bounds && !mullion;

		if (is_glass) {
			float h1 = hash21(cell_id + vec2(building_seed, building_seed * 0.37));
			float h2 = hash21(cell_id + vec2(building_seed * 1.73, 19.3));
			float lit_thresh = mix(0.84, 0.50, night_factor);
			float lit = step(lit_thresh, h1);

			vec3 warm_room = vec3(1.0, 0.82, 0.52);
			vec3 cool_room = vec3(0.48, 0.82, 1.0);
			vec3 room_col = mix(warm_room, cool_room, step(0.74, h2));
			float ceiling_grad = mix(0.58, 1.12, f.y);

			ALBEDO = mix(vec3(0.025, 0.038, 0.055), room_col * 0.35, lit);
			ROUGHNESS = mix(0.07, 0.14, wetness * 0.4);
			METALLIC = 0.18;
			SPECULAR = 0.90;
			NORMAL_MAP = vec3(0.5, 0.5, 1.0);
			NORMAL_MAP_DEPTH = 0.0;
			EMISSION = room_col * lit * ceiling_grad * mix(0.28, 1.45, night_factor);
		} else {
			// Muros de hormigón / ladrillo y marcos metálicos
			float frame_band = (in_window_zone && (f.x > 0.13 && f.x < 0.87 && f.y > 0.17 && f.y < 0.90)) ? 1.0 : 0.0;
			float joint = step(0.97, fract(v / 3.6));
			vec3 wall_base = wall_color.rgb * (0.82 + wn * 0.32);
			wall_base = mix(wall_base, wall_base * 0.52, joint * 0.55);
			wall_base = mix(wall_base, vec3(0.06, 0.07, 0.09), frame_band * 0.78);
			wall_base *= (1.0 - lower_wet * 0.36);

			ALBEDO = wall_base;
			ROUGHNESS = mix(mix(0.84, 0.50, lower_wet), 0.38, frame_band);
			METALLIC = mix(0.04, 0.45, frame_band);
			SPECULAR = mix(0.35, 0.65, lower_wet);
			NORMAL_MAP = texture(concrete_normal_tex, w_uv).rgb;
			NORMAL_MAP_DEPTH = mix(0.68, 0.25, frame_band);
			EMISSION = vec3(0.0);
		}
	}
}
