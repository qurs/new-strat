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

	shaders.add('outline', [[
		uniform vec2 coordStep;
		uniform int size;
		uniform vec4 targetColor;

		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
			vec4 origin = Texel(texture, texture_coords);
			if (origin == vec4(0)) {
				return origin * color;
			}

			bool found = false;
			for (int i = 1; i <= size; i++) {
				if (
					Texel(texture, texture_coords + vec2(coordStep.x * i, 0)) == vec4(0) ||
					Texel(texture, texture_coords + vec2(0, coordStep.y * i)) == vec4(0) ||
					Texel(texture, texture_coords - vec2(coordStep.x * i, 0)) == vec4(0) ||
					Texel(texture, texture_coords - vec2(0, coordStep.y * i)) == vec4(0)
				) {
					found = true;
					break;
				}
			}

			if (found) {
				return targetColor;
			}
			else {
				return origin * color;
			}
		}
	]])

	shaders.add('outline_mul', [[
		uniform vec2 coordStep;
		uniform int size;
		uniform float mul;

		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
			vec4 origin = Texel(texture, texture_coords);
			if (origin == vec4(0)) {
				return origin * color;
			}

			bool found = false;
			for (int i = 1; i <= size; i++) {
				if (
					Texel(texture, texture_coords + vec2(coordStep.x * i, 0)) == vec4(0) ||
					Texel(texture, texture_coords + vec2(0, coordStep.y * i)) == vec4(0) ||
					Texel(texture, texture_coords - vec2(coordStep.x * i, 0)) == vec4(0) ||
					Texel(texture, texture_coords - vec2(0, coordStep.y * i)) == vec4(0)
				) {
					found = true;
					break;
				}
			}

			if (found) {
				return vec4(origin[0] * color[0] * mul, origin[1] * color[1] * mul, origin[2] * color[2] * mul, 1);
			}
			else {
				return origin * color;
			}
		}
	]])
end)