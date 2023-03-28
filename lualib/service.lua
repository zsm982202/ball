local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
	--type id
	name = "",
	id = 0,
	--callback
	exit = nil,
	init = nil,
	resp = {},
}

return M
