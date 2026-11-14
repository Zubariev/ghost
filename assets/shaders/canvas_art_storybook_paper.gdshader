// Storybook paper surface — Ghost vs. Humans (written by Claude for the project, 2026-11-15).
// Purpose: Whimsical Gothic Storybook art direction. Everything drawn in a storybook room
// gets fine paper grain, soft pigment pooling and faint vertical brush streaks. Subtle by
// design: it varies tone by a few percent and never changes hue, so shapes stay readable.
// Target: Godot 4.7, Forward+ (also fine on Mobile/Compatibility), PC at 1280x720.
// Budget: procedural, no texture samples; 4 hash/value-noise evaluations per fragment.
// Applied as the material of the room view (RoomStage) only. No variants.
shader_type canvas_item;

group_uniforms texture_strength;
/** Per-pixel paper grain: tone change, fraction (0.045 = ±2.25%). */
uniform float grain_strength : hint_range(0.0, 0.2) = 0.045;
/** Large soft pigment pools: tone change, fraction. */
uniform float pigment_strength : hint_range(0.0, 0.3) = 0.07;
/** Faint vertical brush streaks: tone change, fraction. */
uniform float brush_strength : hint_range(0.0, 0.2) = 0.035;
group_uniforms texture_scale;
/** Size of the pigment pools, px. */
uniform float pigment_size_px : hint_range(10.0, 300.0) = 70.0;
/** Brush streak width and length, px. */
uniform vec2 brush_size_px = vec2(2.5, 46.0);
group_uniforms;

// Second, smaller pigment layer: relative size and weight, and an offset so the two
// layers do not line up.
const float POOL_DETAIL_SCALE = 0.37;
const float POOL_DETAIL_WEIGHT = 0.35;
const vec2 POOL_DETAIL_OFFSET = vec2(17.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec4 c = COLOR;
	vec2 p = FRAGCOORD.xy;
	// Each term is centred on 0 (noise - 0.5) so the average tone is unchanged.
	float paper = hash(floor(p)) - 0.5;
	float pool = value_noise(p / pigment_size_px) * (1.0 - POOL_DETAIL_WEIGHT)
		+ value_noise(p / (pigment_size_px * POOL_DETAIL_SCALE) + POOL_DETAIL_OFFSET) * POOL_DETAIL_WEIGHT - 0.5;
	float brush = value_noise(p / brush_size_px) - 0.5;
	c.rgb *= 1.0 + paper * grain_strength + pool * pigment_strength + brush * brush_strength;
	COLOR = c;
}
