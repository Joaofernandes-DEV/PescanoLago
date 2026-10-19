// Água estilizada do Lago Aurora (Fase 5).
//
// - Ondas: soma de ondas senoidais de águas profundas (omega = sqrt(g * k)),
//   com a altura e a inclinação calculadas aqui e, com a mesma fórmula, em
//   LakeWater.height_at() — o barco flutua exatamente na superfície que se vê.
// - Normais analíticas das ondas + detalhe de ruído procedural (sem textura).
// - Fresnel: em ângulo rasante a água reflete a cor do horizonte do céu.
// - Espuma na margem, esteira atrás do barco (pontos que se abrem com o tempo)
//   e anéis de ondulação nos cardumes (GDD: "cardumes aparecem como ondulações
//   e bolhas na água"; "água com brilho suave e espuma na proa do barco").
// - Casco seco: a superfície não é desenhada dentro da canoa (contorno interno
//   do casco, o mesmo de BoatController.is_inside_hull), e há espuma junto à
//   proa quando o barco anda.
// Funciona nos renderizadores Forward+, Mobile e Compatibility (sem textura de
// profundidade nem leitura da tela).
shader_type spatial;
render_mode specular_schlick_ggx, cull_back;

uniform vec4 shallow_color : source_color = vec4(0.25, 0.72, 0.69, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.44, 0.55, 1.0);
uniform vec4 foam_color : source_color = vec4(0.96, 0.98, 1.0, 1.0);
uniform vec4 sky_color : source_color = vec4(0.80, 0.92, 0.96, 1.0);
uniform float water_time = 0.0;
uniform float lake_radius = 110.0;
uniform float shore_foam_m = 3.0;
uniform float fresnel_strength = 0.55;
uniform float detail_strength = 0.18;
// Ondas: xy = direção, z = número de onda k (rad/m), w = amplitude (m).
uniform vec4 wave_dir_k_amp[4];
// Ondas: x = frequência angular omega (rad/s), y = fase (rad).
uniform vec4 wave_omega_phase[4];
// Até 4 cardumes: x, z, raio, intensidade (0 = invisível).
uniform vec4 schools[4];
// Esteira do barco: pontos deixados pela popa (x, z, idade em s, intensidade;
// 0 = vazio), do mais novo para o mais velho, e a popa agora (wake_head).
uniform vec4 wake[12];
uniform vec4 wake_head = vec4(0.0);
uniform float wake_life_s = 3.0;
uniform float wake_spread_m_s = 1.2;
// Casco do barco: do mundo para o casco; x = meia boca, y = meio comprimento,
// z = espessura do costado, w = 1 se há barco; expoentes do perfil da seção;
// velocidade de 0 a 1 (espuma na proa).
uniform mat4 hull_inverse = mat4(1.0);
uniform vec4 hull_shape = vec4(0.0);
uniform vec2 hull_profile = vec2(2.2, 0.55);
uniform float hull_speed = 0.0;

varying vec3 world_pos;

vec3 wave_height_and_slope(vec2 p) {
	float h = 0.0;
	vec2 slope = vec2(0.0);
	for (int i = 0; i < 4; i++) {
		vec4 a = wave_dir_k_amp[i];
		vec4 b = wave_omega_phase[i];
		if (a.w <= 0.0) {
			continue;
		}
		float theta = a.z * dot(a.xy, p) - b.x * water_time + b.y;
		h += a.w * sin(theta);
		slope += a.w * a.z * a.xy * cos(theta);
	}
	return vec3(h, slope);
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Inclinação de um ruído suave com a derivada analítica (4 hashes por chamada),
// para o detalhe da superfície.
vec2 noise_slope(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec2 du = 6.0 * f * (1.0 - f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	float k = a - b - c + d;
	return du * vec2(b - a + k * u.y, c - a + k * u.x);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 hs = wave_height_and_slope(w.xz);
	VERTEX.y += hs.x;
	NORMAL = normalize(vec3(-hs.y, 1.0, -hs.z));
	world_pos = vec3(w.x, w.y + hs.x, w.z);
}

void fragment() {
	// Casco seco: dentro do contorno interno da canoa, não há água.
	vec3 hull_local = (hull_inverse * vec4(world_pos, 1.0)).xyz;
	float hull_t = abs(hull_local.z) / max(hull_shape.y, 0.001);
	float hull_half = 0.0;
	if (hull_shape.w > 0.0 && hull_t < 1.0) {
		hull_half = hull_shape.x * pow(max(0.02, 1.0 - pow(hull_t, hull_profile.x)), hull_profile.y);
		if (abs(hull_local.x) < hull_half - hull_shape.z) {
			discard;
		}
	}

	vec2 p = world_pos.xz;
	float r = length(p);
	float d = clamp(r / lake_radius, 0.0, 1.0);
	vec3 base = mix(deep_color.rgb, shallow_color.rgb, smoothstep(0.45, 1.0, d));

	// Detalhe: duas camadas de ruído que andam em direções diferentes.
	vec2 detail = noise_slope(p * 0.9 + vec2(water_time * 0.35, water_time * 0.12));
	detail += noise_slope(p * 1.7 - vec2(water_time * 0.18, -water_time * 0.27)) * 0.5;
	vec3 world_normal = normalize(
		(INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz + vec3(-detail.x, 0.0, -detail.y) * detail_strength
	);
	NORMAL = normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz);

	// Espuma da margem: faixa perto da beira, recortada pelo ruído e pulsando com as ondas.
	float to_shore = lake_radius - r;
	float foam = 0.0;
	if (to_shore < shore_foam_m) {
		float shore = 1.0 - smoothstep(0.0, shore_foam_m, to_shore);
		float shore_noise = value_noise(p * 1.3 + vec2(water_time * 0.4));
		foam = shore * smoothstep(0.35, 0.65, shore_noise + shore * 0.35);
	}

	// Esteira em "V": segmentos entre a popa e os pontos deixados por ela. A
	// largura cresce com a idade (as bordas se abrem) e a espuma fica nas bordas,
	// com turbulência no meio logo atrás da popa. Primeiro as máscaras; o ruído
	// que quebra a espuma só é calculado onde há esteira.
	float wake_edge = 0.0;
	float wake_wash = 0.0;
	vec4 seg_a = wake_head;
	for (int i = 0; i < 12; i++) {
		vec4 seg_b = wake[i];
		if (seg_a.w <= 0.0 || seg_b.w <= 0.0) {
			seg_a = seg_b;
			continue;
		}
		vec2 ab = seg_b.xy - seg_a.xy;
		float t = clamp(dot(p - seg_a.xy, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
		float age = mix(seg_a.z, seg_b.z, t);
		float strength = mix(seg_a.w, seg_b.w, t);
		float life = clamp(1.0 - age / wake_life_s, 0.0, 1.0);
		float dist = length(p - (seg_a.xy + ab * t));
		float half_width = 0.4 + age * wake_spread_m_s;
		float edge = 1.0 - smoothstep(0.0, 0.18 + age * 0.12, abs(dist - half_width));
		float wash = (1.0 - smoothstep(0.0, half_width * 0.7, dist)) * (1.0 - smoothstep(0.0, 0.9, age));
		wake_edge = max(wake_edge, edge * life * strength);
		wake_wash = max(wake_wash, wash * life * strength);
		seg_a = seg_b;
	}
	// Espuma na proa: faixa junto ao costado na metade da frente (a proa é +z do
	// casco) e à frente dela, mais larga e forte com a velocidade.
	float bow_foam = 0.0;
	if (hull_shape.w > 0.0 && hull_speed > 0.02) {
		float front = clamp(hull_local.z / max(hull_shape.y, 0.001), 0.0, 1.2);
		float gap = hull_t < 1.0
			? max(abs(hull_local.x) - hull_half, 0.0)
			: length(vec2(hull_local.x, hull_local.z - sign(hull_local.z) * hull_shape.y));
		float band = 0.1 + 0.35 * hull_speed;
		bow_foam = (1.0 - smoothstep(0.0, band, gap)) * smoothstep(0.15, 0.85, front) * hull_speed;
	}
	if (wake_edge + wake_wash + bow_foam > 0.001) {
		float broken = smoothstep(0.25, 0.7, value_noise(p * 4.0 + vec2(water_time * 0.8)));
		foam = max(foam, max(wake_edge * broken, wake_wash * (0.5 + 0.5 * broken)));
		foam = max(foam, bow_foam * (0.4 + 0.6 * broken));
	}

	// Cardumes: anéis de ondulação e bolhas cintilando.
	float ripple = 0.0;
	for (int i = 0; i < 4; i++) {
		vec4 s = schools[i];
		if (s.w <= 0.0) {
			continue;
		}
		float rs = length(p - s.xy);
		if (rs >= s.z) {
			continue;
		}
		float ring = sin(rs * 3.0 - water_time * 4.0);
		float fall = 1.0 - smoothstep(s.z * 0.2, s.z, rs);
		// Bolhas: pontinhos redondos sorteados dentro de células de 33 cm, que piscam.
		vec2 cell = floor(p * 3.0);
		vec2 spot = vec2(hash(cell + 7.1), hash(cell + 3.3)) - 0.5;
		float pop = step(0.9, hash(cell + floor(water_time * 3.0)));
		float bubbles = pop * (1.0 - smoothstep(0.12, 0.2, length(fract(p * 3.0) - 0.5 - spot * 0.5)));
		ripple += (smoothstep(0.7, 1.0, ring) + bubbles * 0.8) * fall * s.w;
	}

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * fresnel_strength;
	vec3 color = mix(base, sky_color.rgb, fresnel);
	color += vec3(ripple * 0.35);
	color = mix(color, foam_color.rgb, clamp(foam, 0.0, 1.0));
	ALBEDO = color;
	ROUGHNESS = mix(0.08, 0.6, clamp(foam, 0.0, 1.0));
	SPECULAR = 0.55;
}
