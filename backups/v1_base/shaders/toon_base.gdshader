shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 base_color : source_color = vec4(0.15, 0.16, 0.20, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.25;
uniform vec4 rim_color : source_color = vec4(1.0, 0.68, 0.42, 1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.5);
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.55;
	SPECULAR = 0.25;
	EMISSION = emission_color.rgb * emission_energy + rim_color.rgb * (fresnel * rim_amount);
}
