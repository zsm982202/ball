local skynet = require "skynet"
local runconfig = require "runconfig"

skynet.start(function()
	--初始化
	skynet.error(runconfig.agentmgr.node)
	--退出自身
	skynet.exit()
end)