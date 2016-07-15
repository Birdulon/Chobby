
if not (Spring.GetConfigInt("LuaSocketEnabled", 0) == 1) then
	Spring.Echo("LuaSocketEnabled is disabled")
	return false
end

function widget:GetInfo()
return {
	name    = "ZK replay downloader",
	desc    = "Downloads and launches ZK replays",
	author  = "Anarchid, abma (http demo)",
	date    = "July 2016",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
}
end

local socket = socket

local client
local set
local headersent

local host = "zero-k.info"
local port = 80
local file = "/replays/20160704_190323_Drab_100.sdf"
local replaydata = "";

local function dumpConfig()
	-- dump all luasocket related config settings to console
	for _, conf in ipairs({"TCPAllowConnect", "TCPAllowListen", "UDPAllowConnect", "UDPAllowListen"  }) do
		Spring.Echo(conf .. " = " .. Spring.GetConfigString(conf, ""))
	end

end

local function newset()
    local reverse = {}
    local set = {}
    return setmetatable(set, {__index = {
        insert = function(set, value)
            if not reverse[value] then
                table.insert(set, value)
                reverse[value] = table.getn(set)
            end
        end,
        remove = function(set, value)
            local index = reverse[value]
            if index then
                reverse[value] = nil
                local top = table.remove(set)
                if top ~= value then
                    reverse[top] = index
                    set[index] = top
                end
            end
        end
    }})
end


-- initiates a connection to host:port, returns true on success
local function SocketConnect(host, port)
	client=socket.tcp()
	client:settimeout(0)
	res, err = client:connect(host, port)
	if not res and not res=="timeout" then
		Spring.Echo("Error in connect: "..err)
		return false
	end
	set = newset()
	set:insert(client)
	return true
end

function widget:Initialize()
	CHOBBY_DIR = "LuaUI/widgets/chobby/"
	VFS.Include("LuaUI/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	lobby:AddListener("OnLaunchRemoteReplay", onLaunchReplay)
	--SocketConnect(host, port)
end

function onLaunchReplay(wtf, url, game, map, engine)
	Spring.Echo("LAUNCHING REPLAY")
	Spring.Echo("url: ".. url)
	Spring.Echo("game: ".. game)
	Spring.Echo('map: '.. map)
	Spring.Echo('engine: '.. engine)

	-- if needed stuff available: launch the game
	-- otherwise: start downloads (socket/VFS) and watch for their completion
end

-- called when data was received through a connection
local function SocketDataReceived(sock, str)
	replaydata = replaydata .. str;
end

local headersent
-- called when data can be written to a socket
local function SocketWriteAble(sock)
	if headersent==nil then
		-- socket is writeable
		headersent=1
		Spring.Echo("sending http request")
		sock:send("GET " .. file .. " HTTP/1.0\r\nHost: " .. host ..  " \r\n\r\n")
	end
end

-- called when a connection is closed
local function SocketClosed(sock)
	Spring.Echo("closed connection");
    
    local body_start = replaydata:find("\r\n\r\n", 1, true) + 4
    local f = assert(io.open('test.sdf', 'wb')) -- open in "binary" mode
    f:write(replaydata:sub(body_start));
    f:close()
	replaydata = "";
    Spring.Echo("saved replay file");
end

function widget:Update()
	if set==nil or #set<=0 then
		return
	end
	-- get sockets ready for read
	local readable, writeable, err = socket.select(set, set, 0)
	if err~=nil then
		-- some error happened in select
		if err=="timeout" then
			-- nothing to do, return
			return
		end
		Spring.Echo("Error in select: " .. error)
	end
	for _, input in ipairs(readable) do
		local s, status, partial = input:receive('*a') --try to read all data
		if status == "timeout" or status == nil then
			SocketDataReceived(input, s or partial)
		elseif status == "closed" then
			SocketClosed(input)
			input:close()
			set:remove(input)
		end
	end
	for __, output in ipairs(writeable) do
		SocketWriteAble(output)
	end
end