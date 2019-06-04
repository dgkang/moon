local moon = require("moon")
local socket = require("moon.socket")

local function run_slave()
    local count = 0
    do
        socket.on("accept",function(fd, msg)
            --print("accept ", fd, msg:bytes())
        end)

        socket.on("message",function(fd, msg)
            --tcpserver.send(sessionid, msg:bytes())
            socket.write(fd, msg:bytes())
            count = count + 1
        end)

        socket.on("close",function(fd, msg)
            --print("close ", fd, msg:bytes())
        end)

        socket.on("error",function(fd, msg)
            --print("error ", fd, msg:bytes())
        end)
    end

    -- moon.repeated(1000,-1,function()
    --     if count> 0 then
    --         print(count, "per sec")
    --         count = 0
    --     end
    -- end)
end


local function run_master(conf)
    local listenfd  = socket.listen(conf.host,conf.port,moon.PTYPE_SOCKET)

    print(string.format([[

        network benchmark run at %s %d with %d slaves.
    ]], conf.host, conf.port, conf.count))

    local slave = {}

    moon.async(function()
        for _=1,conf.count do
            local sid = moon.co_new_service("lua",{name="slave",file="network_benchmark.lua"})
            table.insert(slave,sid)
        end

        local balance = 1
        while true do
            if balance>#slave then
                balance = 1
            end
            socket.accept(listenfd,slave[balance])
            balance = balance + 1
        end
    end)

    moon.destroy(function()
        socket.close(listenfd)
    end)
end

moon.init(function(conf)
    if conf.master then
        run_master(conf)
    else
        run_slave()
    end
    return true
end)