// Room colour grade — Ghost vs. Humans (written by Claude for the project, 2026-11-15).
// Purpose: warm vs. haunted rooms in the Whimsical Gothic Storybook art direction. Not an
// overlay: it regrades the rendered room so materials keep their differences.
//   warmth 1 (cozy): amber-gold highlights, warm brown shadows, gentle vignette.
//   warmth 0 (haunted): partly desaturated, shadows pulled to dusk blue and night charcoal,
//     highlights to a pale cold grey, less light, darker corners.
//   night: a little darker and cooler overall.
// Target: Godot 4.7, Forward+ (also Mobile/Compatibility), PC at 1280x720.
// Budget: one screen-texture sample per fragment; full-screen ColorRect in a CanvasLayer
// between the room and the HUD. No variants. Colours mirror Palette.SB_* (set from code).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

group_uniforms state;
/** 1 = cozy, 0 = haunted (RoomMood.warmth, eased). */
uniform float warmth : hint_range(0.0, 1.0) = 1.0;
/** 1 = night, 0 = day. */
uniform float night : hint_range(0.0, 1.0) = 0.0;
group_uniforms palette;
uniform vec3 warm_light : source_color = vec3(0.851, 0.722, 0.471);   // candlelight #D9B878
uniform vec3 cold_shadow : source_color = vec3(0.349, 0.404, 0.478);  // dusk blue #59677A
uniform vec3 deep_shadow : source_color = vec3(0.204, 0.216, 0.278);  // night charcoal #343747
uniform vec3 cold_light : source_color = vec3(0.780, 0.835, 0.840);   // pale cold grey-cyan
group_uniforms;

// Rec. 601 luma weights.
const vec3 LUMA = vec3(0.299, 0.587, 0.114);
// Cozy: how far highlights move toward candlelight, and the warm cast on everything.
const float COZY_HIGHLIGHT_LIFT = 0.5;
const vec3 COZY_CAST = vec3(1.09, 0.99, 0.82);
// Cozy: how much of the warm cast is applied (0..1).
const float COZY_CAST_AMOUNT = 0.75;
// Haunted: desaturation, overall light loss, how strongly shadows/highlights are tinted.
const float HAUNT_DESATURATE = 0.5;
const float HAUNT_EXPOSURE = 0.8;
const float HAUNT_SHADOW_TINT = 2.1;   // tint colours are dark; scale back to ~unit gain
const float HAUNT_HIGHLIGHT_TINT = 0.6;
// Ghost protection: how cyan (green-blue over red) and how bright a pixel must be to keep its
// own colour, and how much of it is kept. Ghost cyan #A8D5D9 scores 0.19 cyan, 0.79 luma.
const float GHOST_CYAN_MIN = 0.10;
const float GHOST_CYAN_FULL = 0.17;
const float GHOST_LUMA_MIN = 0.55;
const float GHOST_LUMA_FULL = 0.7;
const float GHOST_PROTECT = 0.85;
// Night: light loss and a slight blue cast.
const float NIGHT_EXPOSURE = 0.88;
const vec3 NIGHT_CAST = vec3(0.94, 0.97, 1.04);
// Vignette: centre (slightly above middle), vertical stretch, start/end radius, strength.
const vec2 VIGNETTE_CENTRE = vec2(0.5, 0.48);
const float VIGNETTE_ASPECT = 1.3;
const float VIGNETTE_INNER = 0.32;
const float VIGNETTE_OUTER = 0.9;
const float VIGNETTE_HAUNTED = 0.9;
const float VIGNETTE_COZY = 0.32;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, LUMA);
	// Cozy: lift highlights toward candlelight (scaled up so it brightens, not darkens).
	vec3 cozy = mix(c, c * (warm_light * 1.25), smoothstep(0.35, 0.95, l) * COZY_HIGHLIGHT_LIFT);
	cozy = mix(cozy, cozy * COZY_CAST, COZY_CAST_AMOUNT);
	// Haunted: desaturate, then split-tone: shadows toward charcoal → dusk blue, highlights
	// toward a cold grey; the masks blend smoothly by luma (no branching).
	vec3 haunt = mix(c, vec3(l), HAUNT_DESATURATE);
	vec3 shadow_tint = mix(deep_shadow, cold_shadow, smoothstep(0.05, 0.45, l));
	haunt = mix(haunt, haunt * shadow_tint * HAUNT_SHADOW_TINT, 1.0 - smoothstep(0.25, 0.7, l));
	haunt = mix(haunt, haunt * cold_light * 1.15, smoothstep(0.5, 1.0, l) * HAUNT_HIGHLIGHT_TINT);
	haunt *= HAUNT_EXPOSURE;
	vec3 col = mix(haunt, cozy, warmth);
	// Keep the ghost ghost-cyan in any light: bright pixels whose green-blue clearly exceeds
	// red (the ghost and its glow) are mostly spared the grade. Dusk-blue furniture is too
	// dark to match, so it is still graded.
	float cyan = smoothstep(GHOST_CYAN_MIN, GHOST_CYAN_FULL, (c.g + c.b) * 0.5 - c.r) * smoothstep(GHOST_LUMA_MIN, GHOST_LUMA_FULL, l);
	col = mix(col, c, cyan * GHOST_PROTECT);
	col *= mix(1.0, NIGHT_EXPOSURE, night);
	col = mix(col, col * NIGHT_CAST, night * 0.5);
	// Darker corners, stronger when haunted. deep_shadow * 1.6 keeps the corner tint dark
	// charcoal-blue rather than black.
	vec2 d = (SCREEN_UV - VIGNETTE_CENTRE) * vec2(1.0, VIGNETTE_ASPECT);
	float v = smoothstep(VIGNETTE_INNER, VIGNETTE_OUTER, length(d));
	col = mix(col, col * deep_shadow * 1.6, v * mix(VIGNETTE_HAUNTED, VIGNETTE_COZY, warmth));
	COLOR = vec4(col, 1.0);
}
