Block = class('Block', Object)

function Block:initialize(x, y, width, height)
	Object.initialize(self)
	self.position = vector(x, y)
	self.width = width
	self.height = height
	self.color = {127, 127, 127}

	self.body = love.physics.newBody(game.world, self.position.x + self.width/2, self.position.y + self.height/2, "static")
	self.shape = love.physics.newRectangleShape(self.width, self.height)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	self.fixture:setUserData(self)
	self.fixture:setGroupIndex(GROUP_ENEMY)

	-- game properties
	self.health = 100
end

function Block:update(dt)
	Object.update(self, dt)

	if self.health <= 0 then
		self:destroy()
	end
end

function Block:destroy()
	if game.grid then
		game.grid:set(game.grid:getTileX(self.position.x+1), game.grid:getTileY(self.position.y+1), 0)
	end

	Object.destroy(self)
end

function Block:draw()
	self.color[4] = math.min(255, self.health/100*255)

	love.graphics.setColor(self.color)
	love.graphics.rectangle('fill', self.position.x, self.position.y, self.width, self.height)
end

function Block:setGroupIndex(group)
	self.fixture:setGroupIndex(group)
	return self
end