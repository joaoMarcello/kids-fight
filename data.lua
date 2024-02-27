---@class SaveData
_G.SAVE_DATA = nil

do
    local file = "sav.dat"
    if love.filesystem.getInfo(file) then
        _G.SAVE_DATA = JM.Ldr.load(file)
    else
        _G.SAVE_DATA = {}
    end
end

do
    ---@class SaveData
    local data = SAVE_DATA
    data.skip_crt = data.skip_crt or false
    data.best_time = data.best_time or -1
end

---@class SaveData
local data = SAVE_DATA

local thread_save = not _G.WEB and love.thread.newThread([[
    local data = ...
    local Loader = require "jm-love2d-package.modules.jm_loader"
    if data then
    Loader.save(data, "sav.dat")
    end
    ]])
local call_save = false

function data:save_to_disc()
    local sav = {}
    for k, v in next, self do
        if type(v) ~= "function" then
            sav[k] = v
        end
    end

    -- saving using thread
    if thread_save then
        if not thread_save:isRunning() then
            return thread_save:start(sav)
        else
            call_save = true
            return
        end
    end

    -- saving without using thread
    -- love.filesystem.write("sav.txt", JM.Ldr.ser.pack(sav))
    return JM.Ldr.save(sav, "sav.dat")
end

function data:get_thread()
    return thread_save
end

function data:update(dt)
    if call_save and thread_save and not thread_save:isRunning() then
        self:save_to_disc()
        call_save = false
    end

    if thread_save then
        local err = thread_save:getError()
        assert(not err, err)
    end
end
