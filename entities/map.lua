Map = class('Map')

function Map:initialize(width, height)
	self.position = vector(100, love.graphics.getHeight()/4)
	self.height = height
	self.width = width
	self.tileSize = 64
	self.grid = {}

	for x=1, self.width do
		self.grid[x] = {}
		for y=1, self.height do
			self.grid[x][y] = 0
		end
	end
end

function Map:set(x, y, v)
	self.grid[x][y] = v
end

function Map:get(x, y)
	return self.grid[x][y]
end

function Map:getScreenX(tileX)
	return self.position.x + (tileX-1) * self.tileSize 
end

function Map:getScreenY(tileY)
	return self.position.y + (tileY-1) * self.tileSize 
end

function Map:getTileX(screenX)
	return math.ceil((screenX - self.position.x)/self.tileSize)
end

function Map:getTileY(screenY)
	return math.ceil((screenY - self.position.y)/self.tileSize)
end

function Map:draw()
	love.graphics.setColor(66, 66, 66, 255)
	love.graphics.rectangle('line', self.position.x, self.position.y, self.width*self.tileSize, self.height*self.tileSize)

	for x=1, self.width do
		for y=1, self.height do
			local position = self.position + vector(x-1, y-1)*self.tileSize

			if self.grid[x][y] ~= 0 then
				love.graphics.setColor(0, 0, 0, 127)
				love.graphics.rectangle('fill', position.x, position.y, self.tileSize, self.tileSize)
			end
		end
	end

	for x=1, self.width do
		love.graphics.setColor(66, 66, 66, 255)

		-- column lines
		love.graphics.line(self.position.x + x*self.tileSize,
							self.position.y,
							self.position.x + x*self.tileSize,
							self.position.y + self.height*self.tileSize)
		for y=1, self.height do
			-- row lines
			love.graphics.line(self.position.x,
							   self.position.y + y*self.tileSize,
							   self.position.x + self.width*self.tileSize,
							   self.position.y + y*self.tileSize)
		end
	end
end