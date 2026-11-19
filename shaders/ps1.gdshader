// PS1-shader: vertexsnappning, affin texturmappning, vertexljus,
// vertexdimma och 15-bitars färg med ordnad dithering.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_texture = true;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0);
uniform float emission = 0.0;      // 1 = lyser själv, ignorerar ljus
uniform float snap_res = 120.0;    // lägre = mer darrig geometri
uniform float fog_start = 5.0;
uniform float fog_end = 38.0;

const vec3 MOON_DIR = vec3(-0.30, 0.40, -0.87);
const vec3 MOON_COL = vec3(0.95, 0.30, 0.22);
const vec3 RIM_DIR = vec3(0.3, 0.5, 0.8);
const vec3 RIM_COL = vec3(0.10, 0.10, 0.22);
const vec3 AMBIENT = vec3(0.30, 0.20, 0.32);
const vec3 FOG_COL = vec3(0.16, 0.05, 0.07);

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                                3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

varying vec3 v_light;
varying float v_fog;
varying vec3 v_aff;

void vertex() {
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_light = AMBIENT
		+ MOON_COL * max(dot(wn, normalize(MOON_DIR)), 0.0)
		+ RIM_COL * max(dot(wn, normalize(RIM_DIR)), 0.0);
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	v_fog = clamp((length(view.xyz) - fog_start) / (fog_end - fog_start), 0.0, 1.0);
	vec4 clip = PROJECTION_MATRIX * view;
	if (clip.w > 0.05) {
		vec2 grid = vec2(snap_res * 4.0 / 3.0, snap_res);
		clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	}
	POSITION = clip;
	v_aff = vec3(UV * uv_scale * clip.w, clip.w);
}

vec3 ps1_color(vec3 c, vec2 frag) {
	ivec2 p = ivec2(mod(frag, 4.0));
	float b = BAYER[p.y * 4 + p.x] / 16.0 - 0.5;
	vec3 s = pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
	s = floor(s * 31.0 + 0.5 + b) / 31.0;
	return pow(clamp(s, 0.0, 1.0), vec3(2.2));
}

void fragment() {
	vec2 uv = v_aff.xy / v_aff.z;
	vec3 c = tint.rgb;
	if (use_texture) {
		c *= texture(albedo_tex, uv).rgb;
	}
	vec3 lit = mix(c * v_light, c, emission);
	lit = mix(lit, FOG_COL, v_fog);
	ALBEDO = ps1_color(lit, FRAGCOORD.xy);
}
