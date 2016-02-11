Network = class('Network')

-- initialize some basic values
function Network:initialize()
	--self.ip = '73.130.6.29'
	self.ip = 'localhost'
	self.port = '22122'

	-- used as the divider between tag and message in networked data communication
	self.magicChar = '|'

	self.lastEvent = nil
	self.peer = nil
end

-- create a host to the ip and port
function Network:connect()
	self.host = enet.host_create()
	self.host:connect(self.ip .. ':' .. self.port)

	-- activates data compression, may take more processing time
	--self.host:compress_with_range_coder()
end

function Network:checkForData()
	-- check some events, 100ms timeout
	local event = self.host:service(0)

	if event then
		--event.peer:ping_interval(1000)
		self.lastEvent = event
		self.peer = event.peer

		if event.type == 'connect' then
			self.state = 'run'
			self.timer = 0
			signal.emit('connect')

		elseif event.type == 'receive' then
			local str = event.data
			local location = string.find(str, self.magicChar)

			if not location then -- invalid data was sent

			else
				--[[
					The event.data (message sent through networking) is spliced into the tag and message
					For example, if the event.data is "chat|Hello ikroth", the tag will be "chat" and the message will be "Hello ikroth"
					A signal is emitted with the tag name ("chat"), and it is emitted with the message ("Hello ikroth")
				]]

				local dataType = string.sub(str, 1, location - 1)
				local message = string.sub(str, location + 1)

				-- insert code to de-serialize the message if it is a table

				signal.emit(dataType, peerIndex, message)
			end

		elseif event.type == 'disconnect' then
			signal.emit('disconnect')
		end
	end
end

function Network:sendMessage(dataType, message)
	local str = dataType .. self.magicChar .. message

	if self.peer then
		self.peer:send(str)
	end
end

-- send coordinates to the server
function Network:sendCoordinates(dataType, x, y)
	local str = dataType .. self.magicChar .. x .. ' ' .. y

	if self.peer then
		self.peer:send(str)
	end
end

-- accepts any number of arguments. it should all be numbers or strings
function Network:sendValues(dataType, ...)
	local str = '' -- start with an empty string
	-- add an element to the string
	for i, v in ipairs({...}) do
		if i > 1 then -- add a space before it if not the first variable
			str = str .. ' '
		end
		str = str .. v
	end

	self:sendDataToAll(dataType, str)
end

function Network:sendDataToAll(dataType, inputStr) -- inputStr should NOT already include the tag
	local str = self:assembleString(dataType, inputStr)

	self.host:broadcast(str)
end

function Network:assembleString(dataType, str)
	return dataType .. self.magicChar .. str
end

-- works with any number of values
function Network:convertDataString(dataStr)
	-- looks for the space character
	local location = string.find(dataStr, ' ')

	if not location then -- only one element left
		return dataStr
	else
		-- just make this into a function
		local first = string.sub(dataStr, 1, location - 1)
		local second = string.sub(dataStr, location + 1)

		return first, self:convertDataString(second)
	end
end

function Network:drawInformation()
	local x, y = 0, 0
	local h = 40
	local i = 0

	love.graphics.print('Total sent data: ' .. self.host:total_sent_data() .. ' bytes', x, y + i*h)
	i = i + 1

	love.graphics.print('Total received data: ' .. self.host:total_received_data() .. ' bytes', x, y + i*h)
	i = i + 1

	love.graphics.print('Service time: ' .. self.host:service_time(), x, y + i*h)
	i = i + 1

	love.graphics.print('Max peers: ' .. self.host:peer_count(), x, y + i*h)
	i = i + 1

	love.graphics.print('Socket address ' .. self.host:get_socket_address(), x, y + i*h)
	i = i + 1

	if self.peer then
		love.graphics.print('Peer index: ' .. self.peer:index(), x, y + i*h)
		i = i + 1
	end
end
