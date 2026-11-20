// Ordnad 4x4-dithering och färgreducering över 3D-bilden, som en gammal
// konsol med 15-bitars färg. UI:t ligger ovanpå och ditheras inte.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float levels = 20.0;
uniform float strength = 1.0;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	float t = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0 - 0.5;
	vec3 q = floor(c * levels + t * strength + 0.5) / levels;
	COLOR = vec4(q, 1.0);
}
