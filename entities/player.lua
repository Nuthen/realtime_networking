Player = class('Player')

function Player:initialize(playerNum, x, y, width, height)
  self.playerNumber = playerNum or 0

  self.x = x or math.random(love.graphics.getWidth())
  self.y = y or math.random(love.graphics.getHeight()())
  self.width = width or math.random(30, 70)
  self.height = height or math.random(30, 70)

  self.vx = 0
  self.vy = 0

  self.targetX = self.x
  self.targetY = self.y

  self.speed = .1
  self.damping = 1
end

function Player:update(dt)
  --self.x = self.x + self.vx * dt
  --self.y = self.y + self.vy * dt

  --self.vx = self.vx * self.damping
  --self.vy = self.vy * self.damping

  -- assume this only runs for other players, not own client player
  --if game.network.peer:round_trip_time() < 100 then
    self.x = self.x + (self.targetX - self.x)*game.network.peer:round_trip_time()/1000
    self.y = self.y + (self.targetY - self.y)*game.network.peer:round_trip_time()/1000
  --end
end

function Player:updateValues(x, y, width, height)
  self.x = x or self.x
  self.y = y or self.y
end

function Player:move(dx, dy)
  dx = dx or 0
  dy = dy or 0

  --dx = dx * self.speed
  --dy = dy * self.speed

  --self.vx = self.vx + dx
  --self.vy = self.vy + dy

  self.x = self.x + dx
  self.y = self.y + dy
end

function Player:updateValues(x, y, width, height)
  self.targetX = x or self.x
  self.targetY = y or self.y
end

function Player:draw()
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
