// Himmel: blodröd horisont, nästan svart topp, några stjärnor.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled;

const vec3 FOG_COL = vec3(0.16, 0.05, 0.07);
const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                                3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

varying vec3 v_dir;

void vertex() {
	v_dir = VERTEX;
}

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void fragment() {
	vec3 d = normalize(v_dir);
	float h = d.y;
	vec3 horizon = vec3(0.50, 0.08, 0.06);
	vec3 mid = vec3(0.17, 0.04, 0.10);
	vec3 top = vec3(0.025, 0.015, 0.05);
	vec3 c;
	if (h < 0.0) {
		c = FOG_COL;
	} else if (h < 0.22) {
		c = mix(mix(FOG_COL, horizon, smoothstep(0.0, 0.03, h)), mid, h / 0.22);
	} else {
		c = mix(mid, top, clamp((h - 0.22) / 0.5, 0.0, 1.0));
	}
	if (h > 0.18 && hash(floor(d * 140.0)) > 0.996) {
		c += vec3(0.55, 0.45, 0.45);
	}
	ivec2 p = ivec2(mod(FRAGCOORD.xy, 4.0));
	float b = BAYER[p.y * 4 + p.x] / 16.0 - 0.5;
	vec3 s = pow(c, vec3(1.0 / 2.2));
	s = floor(s * 31.0 + 0.5 + b) / 31.0;
	ALBEDO = pow(clamp(s, 0.0, 1.0), vec3(2.2));
}
