Object = class('Object')

function Object:initialize()
	self.destroyed = false
end

function Object:update(dt)
	if self.destroyed then
		self:destroy()
	end
end

function Object:draw()

end

function Object:destroy()
	game:remove(self)

	if self.body ~= nil then
		self.body:destroy()
	end
end