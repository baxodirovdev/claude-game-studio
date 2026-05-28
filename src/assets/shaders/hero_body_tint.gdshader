shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Per-team tint applied only to skin regions (yellow-green hue band of the
// procedural Pudge palette). Non-skin surfaces — iron, leather, bone, blood,
// black — keep their per-vertex color untinted. When the textured PBR pass
// lands in the texture spec stage, this shader is replaced by one driven by
// a dedicated tint mask map (`body_tintmask.png`); the runtime API
// (`tint_color` uniform set from `HeroConfig.hero_color`) stays the same so
// no calling code needs to change.

uniform vec3 tint_color : source_color = vec3(0.5, 0.8, 0.2);
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;

// Hue range in normalized space (0..1) that selects the skin band. The
// procedural palette places `pudge_skin` and `pudge_skin_dark` at ~70-75°
// (yellow-green). Default range covers 55°-95° with soft edges.
uniform float skin_hue_min : hint_range(0.0, 1.0) = 0.15;
uniform float skin_hue_max : hint_range(0.0, 1.0) = 0.27;
uniform float skin_hue_feather : hint_range(0.0, 0.1) = 0.02;
uniform float skin_sat_min : hint_range(0.0, 1.0) = 0.10;
uniform float skin_lum_min : hint_range(0.0, 1.0) = 0.10;

varying vec4 v_color;

void vertex() {
	v_color = COLOR;
}

float rgb_to_hue(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn;
	if (d < 0.001) {
		return 0.0;
	}
	float h;
	if (mx == c.r) {
		h = (c.g - c.b) / d;
		if (c.g < c.b) {
			h += 6.0;
		}
	} else if (mx == c.g) {
		h = (c.b - c.r) / d + 2.0;
	} else {
		h = (c.r - c.g) / d + 4.0;
	}
	return h / 6.0;
}

void fragment() {
	vec3 base = v_color.rgb;
	float mx = max(base.r, max(base.g, base.b));
	float mn = min(base.r, min(base.g, base.b));
	float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
	float lum = (base.r + base.g + base.b) / 3.0;
	float hue = rgb_to_hue(base);

	float hue_mask = smoothstep(skin_hue_min - skin_hue_feather, skin_hue_min, hue)
		* (1.0 - smoothstep(skin_hue_max, skin_hue_max + skin_hue_feather, hue));
	float sat_mask = smoothstep(skin_sat_min * 0.5, skin_sat_min, sat);
	float lum_mask = smoothstep(skin_lum_min * 0.5, skin_lum_min, lum);
	float mask = hue_mask * sat_mask * lum_mask * tint_strength;

	// Replace chromatic content with the tint while preserving luminance.
	float base_value = max(base.r, max(base.g, base.b));
	float tint_max = max(tint_color.r, max(tint_color.g, tint_color.b));
	vec3 tinted = tint_color * (base_value / max(0.001, tint_max));
	ALBEDO = mix(base, tinted, mask);
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
}
