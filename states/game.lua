--[[
	The current tags used are as follows:
		chat   - used for chat messages. accepts any string
		state  - used to send an update to the clients about a new game state. accepts any string
		pNum - tell the client which player they are (1 or 2)
		bullet  - sent out the coordinates for a new bullet, in the format: "x y"

	The current states used are as follows:
		wait - pauses gameplay until both players join
		battle - main gameplay mode. fire ze cannons!
]]


game = {}

function game:add(obj)
	table.insert(self.objects, obj)
	return obj
end

function game:remove(obj)
	for i, object in pairs(self.objects) do
		if object == obj then
			table.remove(self.objects, i)
			break
		end
	end
end

function game:enter()
	-- Objects is a table of physics objects associated with classes
	self.objects = {}

	-- EVERYTHING BELOW IS FOR SERVER USAGE
	self.timer = 0

	self.packetTick = .05 -- 30 ms
	self.tick = 0

	self.chatBox = {}

	self.movementQueue = {up = 0, down = 0, left = 0, right = 0}

	--self.currentState = 'wait' -- waiting for a number of players to join. initial state
	self.currentState = 'battle'
	self.playerNumber = 0 -- 0 means player number not yet assigned. Otherwise the player number will be 0 < playerNumber <= maximum number of players

	-- connect to the server
	self.network = Network:new()
	self.network:connect()

	-- whenever a message with the "chat" tag is sent, call the following function
	self.chatObserver = signal.register('chat', function(peerIndex, message) self:receiveChatMessage(peerIndex, message) end)
	self.stateObserver = signal.register('state', function(peerIndex, newState) self:receiveNewState(peerIndex, newState) end)
	self.playerNumberObserver = signal.register('pNum', function(peerIndex, playerNumber) self:receivePlayerNumber(peerIndex, playerNumber) end)
	self.bulletObserver = signal.register('bullet', function(peerIndex, coordString) self:receiveNewBullet(peerIndex, coordString) end)
	self.newPlayerObserver = signal.register('newPlayer', function(peerIndex, valueString) self:receiveNewPlayer(peerIndex, valueString) end)
	self.objectstepObserver = signal.register('step', function(peerIndex, valueString) self:receivePlayerStep(peerIndex, valueString) end)
end

function game:update(dt)
	self.timer = self.timer + dt
	self.tick = self.tick + dt

	self.network:checkForData()

	if love.keyboard.isDown('w') then
		self.movementQueue['up'] = self.movementQueue['up'] + 1
		self:movePlayer(self.playerNumber, 'up', 1)
	elseif love.keyboard.isDown('s') then
		self.movementQueue['down'] = self.movementQueue['down'] + 1
		self:movePlayer(self.playerNumber, 'down', 1)
	end
	if love.keyboard.isDown('d') then
		self.movementQueue['right'] = self.movementQueue['right'] + 1
		self:movePlayer(self.playerNumber, 'right', 1)
	elseif love.keyboard.isDown('a') then
		self.movementQueue['left'] = self.movementQueue['left'] + 1
		self:movePlayer(self.playerNumber, 'left', 1)
	end

	if self.tick >= self.packetTick then
			self.tick = 0

			for k, count in pairs(self.movementQueue) do
				if count > 0 then
					self.network:sendValues('move', k, count)
					--self:movePlayer(self.playerNumber, k, count)
				end
				self.movementQueue = {up = 0, down = 0, left = 0, right = 0}
			end
	end

	self:updateObjects(dt)
end

function game:updateObjects(dt)
	for i, obj in pairs(self.objects) do
		if tonumber(obj.playerNumber) ~= tonumber(self.playerNumber) then
			obj:update(dt)
		end
	end
end

function game:keypressed(key, code)
	if key == 'i' then
		self.network:sendMessage('chat', 'Hello ikroth')
	elseif key == 'n' then
		self.network:sendMessage('chat', 'Hello nuthen')
	end
end

function game:canFire()
	if self.currentState == 'battle' then
		-- also check if it is the player's turn
		return true
	end
end

function game:canBuild()
	-- check if it is the building phase
	return true
end

function game:mousepressed(x, y, mbutton)

end

function game:draw()
	-- this will hopefully ensure that the ground and other objects have been created, but no guarentee
	if self.currentState == 'battle' then
		--self:drawEnvironment()
		--self.grid:draw()
		self:drawObjects()
	end

	self:drawChatBox()

	self.network:drawInformation()

	-- print the name of the current state
	love.graphics.print('State: ' .. self.currentState, love.graphics.getWidth() - 200, 0)
end

function game:drawObjects()
	for i, obj in pairs(self.objects) do
		obj:draw()
	end
end


function game:drawChatBox()
	local x = 0
	local y = 0
	local h = 40
	for i = 1, #self.chatBox do
		love.graphics.print(self.chatBox[i], x, y+i*h)
	end
end


function game:movePlayer(playerNumber, dir, count)
	-- check that the movement is reasonable (cheat/lag handling)

	local player = self.objects[playerNumber]

	local dx, dy = 0, 0
	local speed = count
	-- instead, change the velocity
	if dir == 'up' then
		dy = -speed
	elseif dir == 'down' then
		dy = speed
	elseif dir == 'left' then
		dx = -speed
	elseif dir == 'right' then
		dx = speed
	end

	-- change this to accept the dir instead
	player:move(dx, dy)
end


-- SIGNAL FUNCTIONS --

-- called when a chat message is received
-- add message to chat box
-- send message to clients
function game:receiveChatMessage(peerIndex, message)
	table.insert(self.chatBox, message)
end

-- called when the server sends out a new game state
function game:receiveNewState(peerIndex, newState)
	self.currentState = newState
end

-- called when the server tells the client what their player number is. should only be called once
-- sets the player number and creates all of the physics objects
function game:receivePlayerNumber(peerIndex, playerNumber)
	playerNumber = tonumber(playerNumber)
	self.playerNumber = playerNumber
end

-- accepts a string in the format "x y"
function game:receiveNewBullet(peerIndex, coordString)
	local x, y = self.network:convertDataString(coordString) -- tell the network class to fix the data for you

	-- now create the bullet
	-- assume the enemy cannon exists
	self.enemyCannon:enemyFire(x, y)
	--self.cannon:fire(x, y)
end

function game:receiveNewPlayer(peerIndex, valueString)
	-- translate the string into all of the expected values
	local playerNum, x, y, width, height = self.network:convertDataString(valueString)

	-- protect against invalid values
	if playerNum and x and y and width and height then
			if not self:exists(Player, playerNum) then
				self:add(Player:new(playerNum, x, y, width, height))
			end
	else -- the server sent you bad values

	end
end

function game:receivePlayerStep(peerIndex, valueString)
	-- translate the string into all of the expected values
	local playerNum, x, y = self.network:convertDataString(valueString)

	-- protect against invalid values
	if playerNum and x and y then
			if not self:exists(Player, playerNum) then
				-- this should never have to be used, but it is a failsafe
				self:add(Player:new(playerNum, x, y))
			elseif tonumber(playerNum) ~= self.playerNumber then -- don't change the position for yourself, it looks bad
				-- only acts on other players
				self:updatePlayer(playerNum, x, y)
			end
	else -- the server sent you bad values

	end
end

function game:updatePlayer(playerNum, ...)
	for i, player in ipairs(self.objects) do
		if tonumber(player.playerNumber) == tonumber(playerNum) then -- we have found the correct player
			player:updateValues(...)
			break
		end
	end
end


-- if any instace of same class type and same player number is found, return true
-- else, return false
function game:exists(class, playerNum)
	for i, obj in pairs(self.objects) do
		if obj.class == class then
			if obj.playerNumber == playerNum then
				return true
			end
		end
	end

	return false
end
