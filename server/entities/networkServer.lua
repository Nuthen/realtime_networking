Network = class('Network')

-- initialize some basic values
function Network:initialize(maxConnections)
	self.ip = '*'
	self.port = '22122'

	self.maxConnections = maxConnections or 2

	-- used as the divider between tag and message in networked data communication
	self.magicChar = '|'

	self.peers = {}
end

-- create a host to the ip and port
function Network:connect()
	-- create the host at the given ip and port, with a maximum number of connections
	self.host = enet.host_create(self.ip..':'..self.port, self.maxConnections)

	if self.host == nil then
		error("Couldn't initialize host, there is probably another server running on that port")
	end

	-- activates data compression, may take more processing time. must be enabled for both client and server
	--self.host:compress_with_range_coder()
end

-- looks for a packet and handles it
function Network:checkForData()
	-- check some events, 100ms timeout
	local event = self.host:service(0)

	if event then
		local peerIndex = event.peer:index()
		self.peers[peerIndex] = event.peer -- peer index will always be within the number of maxConnections

		-- the event type will always be either "connect", "receive" or "disconnect"
		-- see lua-enet documentation for further details
		if event.type == 'connect' then
			signal.emit('connect', peerIndex)

		elseif event.type == 'receive' then
			local str = event.data
			local location = string.find(str, self.magicChar)

			if location then
				--[[
					The event.data (message sent through networking) is spliced into the tag and message
					For example, if the event.data is "chat|Hello ikroth", the tag will be "chat" and the message will be "Hello ikroth"
					A signal is emitted with the tag name ("chat"), and it is emitted with the message ("Hello ikroth")
				]]

				local dataType = string.sub(str, 1, location - 1)
				local message = string.sub(str, location + 1)

				-- insert code to de-serialize the message if it is a table

				signal.emit(dataType, peerIndex, message)
			else
				-- invalid data sent
			end

		elseif event.type == 'disconnect' then
			signal.emit('disconnect', peerIndex)
		end
	end
end

-- sends a global message to all connected players
function Network:sendMessage(dataType, message)
	local str = dataType .. self.magicChar .. message

	self.host:broadcast(str)
end

-- sends a message to the peer at the specified peer index
function Network:sendPeerMessage(peerIndex, dataType, message)
	local str = self:assembleString(dataType, message)

	local peer = self.peers[peerIndex]
	peer:send(str)
end

-- send coordinates to a specific peer
function Network:sendCoordinates(dataType, x, y)
	local str = dataType .. self.magicChar .. x .. ' ' .. y

	self.host:broadcast(str)
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

-- sends the coordinates to all peers except the one given
function Network:sendCoordinatesNotPeer(dataType, x, y, peerIndex)
	local str = dataType .. self.magicChar .. x .. ' ' .. y

	for i = 1, #self.peers do
		if i ~= peerIndex then
			local peer = self.peers[i]
			peer:send(str)
		end
	end
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

	for peerIndex = 1, #self.peers do
		if self.peers[peerIndex] then
			local peer = self.peers[peerIndex]

			love.graphics.print('Info for peer: ' .. peerIndex, x, y + i*h)
			i = i + 1

			love.graphics.print('Peer connect ID: ' .. peer:connect_id(), x, y + i*h)
			i = i + 1

			love.graphics.print('Peer index: ' .. peer:index(), x, y + i*h)
			i = i + 1

			love.graphics.print('Peer ping: ' .. peer:round_trip_time(), x, y + i*h)
			i = i + 1
		end
	end
end
