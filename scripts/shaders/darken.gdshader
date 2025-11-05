shader_type canvas_item;

// Uniform to control the darkness. 0.0 is black, 1.0 is normal color.
uniform float darkness_factor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Get the original color from the texture
	vec4 original_color = texture(TEXTURE, UV);
	
	// Multiply the RGB components by the darkness factor
	original_color.rgb *= darkness_factor;
	
	// Set the final color
	COLOR = original_color;
}
