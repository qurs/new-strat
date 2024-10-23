mapGen = mapGen or {}

local function dist(w, h, x, y)
	local nx = 2 * x / w - 1
	local ny = 2 * y / h - 1
	return 1 - (1 - nx^2) * (1 - ny^2)
end

local function pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	local noise = love.math.noise(baseX + freq * x, baseY + freq * y)
	local sum = 1

	for i = 1, octave do
		noise = noise + 1 / (2^i) * love.math.noise(baseX + freq * (2^i) * x, baseY + freq * (2^i) * y)
		sum = sum + 1 / (2^i)
	end

	noise = noise / sum

	local d = dist(w, h, x, y)
	local e = noise

	if d > 0.5 then
		e = Lerp(0.5, noise, 1 - d)
	end

	if e < 0.5 then
		return 0, 0, 0, 1
	else
		return 1, 1, 1, 1
	end
end

function mapGen.generateLand(path, w, h, freq, octave)
	local baseX = 1337 * love.math.random()
	local baseY = 1337 * love.math.random()

	freq = freq or 0.0015
	octave = octave or 5

	local imgdata = love.image.newImageData(w, h)

	imgdata:mapPixel(function(x, y, r, g, b, a)
		return pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	end)

	local data = imgdata:encode('png')
	love.filesystem.write(path, data)
end

function mapGen.generateProvs(img, count)
	
end