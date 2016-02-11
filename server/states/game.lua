--[[
	The current tags used are as follows:
		chat   - used for chat messages. accepts any string
		state  - used to send an update to the clients about a new game state. accepts any string
		pNum - tell the client which player they are (1 or 2)
		bullet  - sent out the coordinates for a new bullet, in the format: "x y"

	The current states used are as follows:
		wait - pauses gameplay until both players join
		battle - initiate wave mode
]]


game = {}

function game:add(obj, index)
	if not self:exists(Player, index) then
		self.objects[index] = obj
	end

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
	self.prevObjects = {}

	self.chatBox = {}

	self.timer = 0

	self.packetTick = .03 -- 30 ms
	self.tick = 0

	self.playerMax = 2
	self.currentState = 'wait' -- waiting for a number of players to join

	self.network = Network:new(self.playerMax)
	self.network:connect()

	self.playerList = {} -- just used to check for all players being connected
							   --in the future this should perhaps not be boolean values

	-- assign false to each element of playerList initially
	for i = 1, self.playerMax do
		self.playerList[i] = false
	end

	self.connectObserver = signal.register('connect', function(peerIndex) self:playerConnect(peerIndex) end)
	self.disconnectObserver = signal.register('disconnect', function(peerIndex) self:playerDisconnect(peerIndex) end)

	-- whenever a message with the "chat" tag is sent, call the following function
	self.chatObserver = signal.register('chat', function(peerIndex, message) self:receiveChatMessage(peerIndex, message) end)
	self.bulletObserver = signal.register('bullet', function(peerIndex, coordString) self:receiveNewBullet(peerIndex, coordString) end)

	self.moveObserver = signal.register('move', function(peerIndex, dir) self:receiveNewMove(peerIndex, dir) end)
end

function game:update(dt)
	self.timer = self.timer + dt
	self.tick = self.tick + dt

	self.network:checkForData()

	self:updateObjects(dt)

	if self.currentState == 'wait' then
		if self:checkFull() then
			self.currentState = 'battle'

			-- tell the clients that they can battle now
			self:sendState(self.currentState)
		end
	end

	-- when the network timestep is reached, send out entity data
	if self.tick >= self.packetTick then
			self.tick = 0

			self:sendObjectData()
	end
end

function game:updateObjects(dt)
	for i, obj in pairs(self.objects) do
		obj:update(dt)
	end
end

function game:sendObjectData()
	for i, obj in pairs(self.objects) do
		-- check if it is a networking object

		local playerNumber, x, y = obj:getValues()

		-- don't be wasteful, only send if any values have changed
		-- later step: only send the values which change
		--if obj:isChanged() then
		--end
		-- compare it to the previous obj table

		self.network:sendValues('step', playerNumber, x, y)
	end
end

function game:keypressed(key, code)
	if key == 'i' then
		self:sendMessage('chat', 'Hello ikroth')
	elseif key == 'n' then
		self:sendMessage('chat', 'Hello nuthen')
	end
end

function game:mousepressed(x, y, mbutton)

end

function game:draw()
	self.network:drawInformation()

	self:drawObjects()

	-- print the name of the current state
	love.graphics.print('State: ' .. self.currentState, love.graphics.getWidth() - 200, 0)
end

function game:drawChatBox()
	local x = 0
	local y = 0
	local h = 40
	for i = 1, #self.chatBox do
		love.graphics.print(self.chatBox[i], x, y+i*h)
	end
end

function game:drawObjects()
	for i, obj in pairs(self.objects) do
		obj:draw()
	end
end

function game:sendState(newState)
	self.network:sendMessage('state', newState)
end


function game:addPlayer(playerNum)
	local player = Player:new(playerNum)
	self:add(player, playerNum)
end

function game:sendAllInitialPlayerData()
	for i, obj in pairs(self.objects) do
		-- check if it is a networking object

		local playerNumber, x, y, width, height = obj:getValues()
		self.network:sendValues('newPlayer', playerNumber, x, y, width, height)
	end
end


-- SIGNAL FUNCTIONS --

-- called when a chat message is received
-- add message to chat box
-- send message to clients
function game:receiveChatMessage(peerIndex, message)
	table.insert(self.chatBox, message)

	-- as soon as a chat message is received, send it right back out
	self.network:sendMessage('chat', message)
end


--   1 <= index <= self.playerMax, should always work for the array
-- index is not guarenteed to be the first open spot in the array
--     (though it usually is, unless a player connects -> disconnects -> connects again)
function game:playerConnect(index)
	-- set the playerList array location to true
	if not self.playerList[index] then
		self.playerList[index] = true -- player connected!
	end

	-- tell each player which player they are (1 or 2) based on their index on the server
	-- only send it to the specific player
	self.network:sendPeerMessage(index, 'pNum', index)

	-- broadcast the new player to all. send the x and y positions
	self:addPlayer(index)

	-- send every initial player data to every player, regardless of them already having it
	self:sendAllInitialPlayerData()

	-- issue: new players do not get to add players connected before them
end

function game:playerDisconnect(index)
	if self.playerList[index] then
		self.playerList[index] = false -- player disconnected!
	end
end

-- determines if the maximum number of players are connected
-- [for example, if the max connections are 2, and 2 players are connected, it will return true]
-- useful if you are waiting for some number of players to join before starting a match
function game:checkFull()
	local isHere = true -- assumes all are here

	for i = 1, #self.playerList do
		if not self.playerList[i] then
			isHere = false -- woah! we have found that someone is not here yet
		end
	end

	return isHere
end

-- accepts a string in the format "x y"
function game:receiveNewBullet(peerIndex, coordString)
	local x, y = self.network:convertDataString(coordString) -- tell the network class to fix the data for you

	-- the server now knows the coordinates of the bullet
	-- now send it to the peer that didn't send it out
	self.network:sendCoordinatesNotPeer('bullet', x, y, peerIndex)
end

function game:receiveNewMove(peerIndex, dirString)
	local dir, count = self.network:convertDataString(dirString) -- tell the network class to fix the data for you

	-- movement packets include a count for how many times it was pressed in a given time frame
	-- required to limit packet jamming
	self:movePlayer(peerIndex, dir, tonumber(count)) -- peer index = dir
end

-- assumption: playerNumber = index in the players table
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
