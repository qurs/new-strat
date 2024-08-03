hook.Add('Initialize', 'shaders', function()
	shaders.add('draw_province', [[
		uniform vec3 targetColor;

		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
			if (Texel(texture, texture_coords).rgb != targetColor) {
				discard;
			}
			return vec4(1.0);
		}
	]])
end)