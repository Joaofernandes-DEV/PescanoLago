// Água estilizada do lago: ondas suaves no vértice, cor que escurece no meio do
// lago e anéis de ondulação onde há cardume (GDD: "cardumes aparecem como
// ondulações e bolhas na água; peixes grandes e raros deixam um brilho mais forte").
// Funciona nos renderizadores Forward+ e Mobile (sem textura de profundidade).
shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.25, 0.72, 0.69, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.44, 0.55, 1.0);
uniform float wave_height = 0.08;
uniform float wave_speed = 0.6;
uniform float lake_radius = 110.0;
// Até 4 cardumes: x, z, raio, intensidade (0 = invisível).
uniform vec4 schools[4];

varying vec3 world_pos;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;
	float h = sin(w.x * 0.35 + t * 2.0) * 0.5 + sin(w.z * 0.27 - t * 1.6) * 0.5;
	VERTEX.y += h * wave_height;
	world_pos = w;
}

void fragment() {
	float d = clamp(length(world_pos.xz) / lake_radius, 0.0, 1.0);
	vec3 base = mix(deep_color.rgb, shallow_color.rgb, smoothstep(0.55, 1.0, d));
	float ripple = 0.0;
	for (int i = 0; i < 4; i++) {
		vec4 s = schools[i];
		if (s.w <= 0.0) {
			continue;
		}
		float r = length(world_pos.xz - s.xy);
		float ring = sin(r * 3.0 - TIME * 4.0);
		float fall = 1.0 - smoothstep(s.z * 0.2, s.z, r);
		ripple += smoothstep(0.7, 1.0, ring) * fall * s.w;
	}
	ALBEDO = base + vec3(ripple * 0.4);
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
}
