Cannon = class('Cannon', Block)

function Cannon:initialize(x, y, width, height)
	Block.initialize(self, x, y, width, height)
	self.color = {0, 0, 0}

	self.barrelPosition = vector(self.position.x + self.width/2, self.position.y)
end

function Cannon:update(dt)
	local mouse = vector(love.mouse.getX(), love.mouse.getY())
	local diff = mouse - self.barrelPosition

	self.angle = diff:angleTo()
	self.power = diff:len()

	--[[
	-- angle locking
	if self.angle > 0 then
		self.angle = 0
	elseif self.angle < -math.pi/2 + 0.01 then
		self.angle = -math.pi/2 + 0.01
	end
	]]
end

function Cannon:fire(x, y)
	local b = game:add(Projectile:new(self.position.x + self.width/2, self.position.y))
	--local b = game:add(Projectile:new(self.position.x, self.position.y))

	local angle = self.angle
	--local angle = math.atan(x - b.x, y - b.y)
	local targetX = math.cos(angle) * self.power
	local targetY = math.sin(angle) * self.power

	b.body:setLinearVelocity(targetX, targetY)
	b.fixture:setUserData(b)
	b.fixture:setGroupIndex(GROUP_ALLY)
end

function Cannon:enemyFire(x, y)
	local b = game:add(Projectile:new(self.position.x + self.width/2, self.position.y))
	--local b = game:add(Projectile:new(self.position.x, self.position.y))

	local diff = vector(x - b.x, y - b.y)

	local angle = diff:angleTo()
	local power = diff:len()
	
	
	--local angle = math.atan2(y - b.y, x - b.x)
	local targetX = math.cos(angle) * power
	local targetY = math.sin(angle) * power

	b.body:setLinearVelocity(targetX, targetY)
	b.fixture:setUserData(b)
	b.fixture:setGroupIndex(GROUP_ENEMY)
end

function Cannon:draw()
	Block.draw(self)

	local targetX = math.cos(self.angle) * 50
	local targetY = math.sin(self.angle) * 50

	love.graphics.setLineWidth(10)
	love.graphics.line(self.barrelPosition.x, self.barrelPosition.y, self.barrelPosition.x + targetX, self.barrelPosition.y + targetY)

	love.graphics.circle('fill', self.barrelPosition.x, self.barrelPosition.y, 20)

	love.graphics.setLineWidth(1)
	love.graphics.line(self.barrelPosition.x, self.barrelPosition.y, love.mouse.getX(), love.mouse.getY())

	love.graphics.setColor(255, 255, 255)
	love.graphics.print(self.angle, self.position.x, self.position.y)
end