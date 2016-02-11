Projectile = class('Projectile', Object)

function Projectile:initialize(x, y)
	Object.initialize(self)
	self.x = x
	self.y = y
	self.radius = 10
	self.body = love.physics.newBody(game.world, self.x, self.y, "dynamic")
	self.shape = love.physics.newCircleShape(self.radius)
	self.fixture = love.physics.newFixture(self.body, self.shape)
end

function Projectile:update(dt)
	self.x = self.body:getX()
	self.y = self.body:getY()

	Object.update(self, dt)
end

function Projectile:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.circle('fill', self.body:getX(), self.body:getY(), self.radius)
end