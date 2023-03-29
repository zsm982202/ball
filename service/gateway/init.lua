local skynet = require "skynet"
local s = require "service"
local socket = require "skynet.socket"
local runconfig = require "runconfig"

conns = {} --[fd] = conn
players = {} --[playerid] = gateplayer

function conn()
	local m = {
		fd = nil,
		playerid = nil,
	}
	return m
end

function gateplayer()
	local m = {
		playerid = nil,
		agent = nil,
		conn = nil,
	}
	return m
end

local process_buff = function(fd, readbuff)
	while true do
		local msgstr, rest = string.match(readbuff, "(.-)\r\n(.*)")
		if msgstr then
			readbuff = rest
			process_msg(fd, msgstr)
		else
			break
		end
	end
	return readbuff
end

local recv_loop = function(fd)
	socket.start(fd)
	skynet.error("socket connected "..fd)
	local readbuff = ""
	while true do
		local recvstr = socket.read(fd)
		if recvstr then
			readbuff = readbuff..recvstr
			readbuff = process_buff(fd, readbuff)
		else
			skynet.error("socket close" ..fd)
			disconnect(fd)
			socket.close(fd)
			break
		end
	end
end

local connect = function(fd, addr)
	print("connect from "..addr.." "..fd)
	local c = conn()
	conns[fd] = c
	c.fd = fd
	skynet.fork(recv_loop, fd)
end

function s.init()
	local node = skynet.getenv("node")
	local nodecfg = runconfig[node]
	local port = nodecfg.gateway[s.id].port

	local listenfd = socket.listen("0.0.0.0", port)
	skynet.error("Listen socket: ", "0.0.0.0", port)
	socket.start(listenfd, connect)
end

s.start(...)

local str_unpack = function(msgstr)
	local msg = {}
	while true do
		local arg, rest = string.match(msgstr, "(.-),(.*)")
		if arg then
			msgstr = rest
			table.insert(msg, arg)
		else
			table.insert(msg, msgstr)
			break
		end
	end
	return msg[1], msg
end

local str_pack = function(cmd, msg)
	return table.concat(msg, ",").."\r\n"
end

local process_msg = function(fd, msgstr)
	local cmd, msg = str_unpack(msgstr)
	skynet.error("recv "..fd.." ["..cmd.."] {"..table.concat(msg, ",").."}")
	local conn = conns[fd]
	local playerid = conn.playerid

	if not playerid then
		local node = skynet.getenv("node")
		local nodecfg = runconfig(node)
		local loginid = math.random(1, #nodecfg.login)
		local login = "login"..loginid
		skynet.send(login, "lua", "client", fd, cmd, msg)
	else
		local gplayer = players[playerid]
		local agent = gplayer.agent
		skynet.send(agent, "lua", "client", cmd, msg)
	end
end

