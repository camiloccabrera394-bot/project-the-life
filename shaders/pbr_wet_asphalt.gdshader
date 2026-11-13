shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.055, 0.060, 0.072, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.88;
uniform float rain_ripples : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv_macro = world_pos.xz * 0.032;
	vec2 uv_mid = world_pos.xz * 0.11;
	vec2 uv_micro = world_pos.xz * 0.55;

	float n_macro = texture(noise_tex, uv_macro).r;
	float n_mid = texture(noise_tex, uv_mid).r;
	float n_grain = texture(noise_tex, uv_micro).r;

	float puddle_raw = n_macro * 0.72 + n_mid * 0.28;
	float puddle = smoothstep(0.56 - wetness * 0.20, 0.70 - wetness * 0.16, puddle_raw) * wetness;

	vec3 base = asphalt_color.rgb * (0.86 + n_grain * 0.28);
	vec3 wet_col = base * mix(1.0, 0.48, wetness * 0.55);
	vec3 final_col = mix(wet_col, base * 0.34, puddle);

	vec3 grain_n = texture(normal_tex, uv_micro).rgb;
	vec3 flat_n = vec3(0.5, 0.5, 1.0);
	vec3 surf_n = mix(grain_n, flat_n, puddle * 0.90);

	if (rain_ripples > 0.05 && puddle > 0.15) {
		vec2 rp_uv = world_pos.xz * 2.4;
		vec2 cell = floor(rp_uv);
		vec2 f = fract(rp_uv) - 0.5;
		float h = hash21(cell);
		vec2 drop_center = vec2(fract(h * 17.3) - 0.5, fract(h * 31.7) - 0.5) * 0.42;
		float t = fract(TIME * 1.15 + h);
		float d = length(f - drop_center);
		float ring = sin((d - t * 0.45) * 42.0) * exp(-abs(d - t * 0.45) * 18.0) * (1.0 - t);
		vec2 dir = normalize((f - drop_center) + vec2(0.0001));
		vec2 ripple_xy = dir * ring * puddle * rain_ripples * 0.22;
		surf_n.xy = clamp(surf_n.xy + ripple_xy, vec2(0.05), vec2(0.95));
	}

	ALBEDO = final_col;
	ROUGHNESS = mix(mix(0.78, 0.30, wetness * 0.75), 0.04, puddle);
	SPECULAR = mix(0.45, 0.88, wetness * (0.4 + 0.6 * puddle));
	METALLIC = 0.02;
	NORMAL_MAP = surf_n;
	NORMAL_MAP_DEPTH = mix(0.85, 0.18, puddle);
}
