local JM = require "jm-love2d-package.init"
local lgx = love.graphics

function love.load()
    math.randomseed(os.time())
    lgx.setBackgroundColor(0.1, 0.1, 0.1, 1)
    lgx.setDefaultFilter("nearest", "nearest")
    lgx.setLineStyle("rough")
    love.mouse.setVisible(true)

    _G.SCREEN_WIDTH = 320 --398
    _G.SCREEN_HEIGHT = 180

    _G.WEB = false
    _G.SUBPIXEL = 4
    _G.TILE = 16
    _G.CANVAS_FILTER = "linear"
    _G.TARGET = love.system.getOS()
    _G.USE_VPAD = true

    if WEB then
        JM.Sound:set_song_mode("static")
    end

    require "data"

    -- _G.FONT_THALEAH = JM.FontGenerator:new_by_ttf {
    --     name = "thaleah",
    --     dir = "data/font/ThaleahFat.ttf",
    --     dpi = 16,
    --     character_space = 1,
    --     word_space = 3,
    --     line_space = 8,
    --     min_filter = 'linear',
    --     max_filter = 'nearest',
    --     max_texturesize = 2048,
    --     save = true,
    -- }
    _G.FONT_THALEAH = JM.FontGenerator:new {
        name = 'thaleah',
        dir = "data/font/thaleah.png",
        glyphs = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſ",
        min_filter = "linear",
        max_filter = "nearest",
        character_space = 1,
        word_space = 3,
        line_space = 8,
    }
    FONT_THALEAH:set_font_size(7)
    FONT_THALEAH:set_color(JM_Utils:get_rgba3("242833"))

    JM.Vpad:set_font(FONT_THALEAH)

    ---@param State JM.Scene
    _G.RESIZE = function(State, w, h)
        local percent = 0.005
        if not State.shader then
            percent = 0
        end
        State.x = math.floor(w * percent)
        State.w = w - State.x
        State.y = math.floor(w * percent) -- + h * 0.15
        State.h = h - State.y
    end

    -- JM:get_font():set_font_size(8)
    JM.esc_to_quit = false

    local P1 = JM.ControllerManager.P1
    local Button = P1.Button
    P1.button_to_key[P1.Button.A] = { 'space' }
    P1.button_to_key[P1.Button.X] = { 'f', 'e', 'j' }
    P1.button_to_key[P1.Button.B] = { 'escape', 'backspace' }
    P1.button_to_key[P1.Button.R] = { 'f', 'rshift' }
    P1.button_to_key[P1.Button.L] = { 'f', 'lshift' }
    P1:set_vpad(JM.Vpad)

    local P2 = JM.ControllerManager.P2
    P2.button_to_key[Button.A] = { 'i' }
    P2.button_to_key[Button.X] = { 'u' }

    do
        local Word = require "jm-love2d-package.modules.font.Word"
        ---@diagnostic disable-next-line: inject-field
        Word.eff_wave_range = 0.75
        ---@diagnostic disable-next-line: inject-field
        Word.eff_scream_range_y = 1
        ---@diagnostic disable-next-line: inject-field
        Word.eff_spooky_range_y = 0.4
    end

    ---@param self JM.Scene|any
    JM.Scene.set_default_scene_config(function(self)
        if self.is_splash_screen
            or _G.WEB
            or true
        then
            return
        end

        if SAVE_DATA.skip_crt then
            self:set_shader()
            return
        end

        -- do
        --     local code = love.filesystem.read("/data/crt.frag")
        --     local shader = love.graphics.newShader(code)
        --     _G.Time = 0.0
        --     self:set_shader({ shader }, function(self, shader, n)
        --         if n == 1 then
        --             Time = Time + love.timer.getDelta() * 20.0
        --             shader:send("uTime", Time)
        --             shader:send("uSeed", love.math.random())
        --         end
        --     end)
        --     return
        -- end

        do
            local shader = JM.Shader:get_shader("crt_scanline", self, {
                screen_h = 256,
                width = 0.85,
            })
            shader:send("opacity", 0.15)
            shader:send("uNoise", { 0.125, 1.0 })

            local ab = JM.Shader:get_shader("aberration", self, { aberration_x = 0.1, aberration_y = 0.15 })
            -- local filmgrain = JM.Shader:get_shader("filmgrain", self, { opacity = 0.3 })
            -- local noise = {}

            _G.Time = 0.0
            self:set_shader({ ab, shader },
                function(self, shader, n)
                    if n == 2 then
                        Time = Time - love.timer.getDelta() * 20.0
                        shader:send("phase", Time)
                        shader:send("uSeed", love.math.random())
                    end

                    -- if n == 2 then
                    --     noise[1] = love.math.random()
                    --     noise[2] = love.math.random()
                    --     shader:send("noise", noise)
                    -- end
                end)
        end
    end)
    return JM:load_initial_state("lib.gamestate.title", true, true)
end

function love.textinput(t)
    return JM:textinput(t)
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'p' and love.keyboard.isDown('lctrl') then
        return love.graphics.captureScreenshot("img_" .. os.time() .. ".png")
    end

    if _G.WEB and scancode == 'f11' then
        return
    end

    if scancode == 'f10'
        and not _G.WEB
    then
        SAVE_DATA.skip_crt = not SAVE_DATA.skip_crt
        local scene = JM.SceneManager.scene
        if scene then
            JM.Scene.default_config(scene)
            scene:resize(love.graphics:getDimensions())
            SAVE_DATA:save_to_disc()
        end
        return
    end

    return JM:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    return JM:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
    return JM:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    return JM:mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    return JM:mousemoved(x, y, dx, dy, istouch)
end

function love.focus(f)
    return JM:focus(f)
end

function love.visible(v)
    return JM:visible(v)
end

function love.wheelmoved(x, y)
    return JM:wheelmoved(x, y)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if not _G.USE_VPAD then
        _G.USE_VPAD = true
        JM.Vpad:resize(love.graphics.getDimensions())
    end
    return JM:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    return JM:touchreleased(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    return JM:touchmoved(id, x, y, dx, dy, pressure)
end

function love.joystickpressed(joystick, button)
    return JM:joystickpressed(joystick, button)
end

function love.joystickreleased(joystick, button)
    return JM:joystickreleased(joystick, button)
end

function love.joystickaxis(joystick, axis, value)
    return JM:joystickaxis(joystick, axis, value)
end

function love.joystickadded(joystick)
    return JM:joystickadded(joystick)
end

function love.joystickremoved(joystick)
    return JM:joystickremoved(joystick)
end

function love.gamepadpressed(joy, button)
    return JM:gamepadpressed(joy, button)
end

function love.gamepadreleased(joy, button)
    return JM:gamepadreleased(joy, button)
end

function love.gamepadaxis(joy, axis, value)
    return JM:gamepadaxis(joy, axis, value)
end

function love.resize(w, h)
    return JM:resize(w, h)
end

function love.quit()
    local tr = SAVE_DATA:get_thread()
    local r = tr and tr:wait()
end

local km = 0
local lim = 1 / 30
function love.update(dt)
    km = collectgarbage("count") / 1024.0
    dt = dt > lim and lim or dt
    SAVE_DATA:update(dt)
    return JM:update(dt)
end

function love.draw()
    JM:draw()

    -- love.graphics.setColor(1, 1, 0)
    -- love.graphics.print(tostring(JM:has_default_font()), 32, 32)

    do
        -- local font = JM.Font.current
        -- font:push()
        -- font:set_font_size(32)
        -- font:set_color(JM_Utils:get_rgba(1, 0, 0))
        -- font:print(succes and admob and "Loaded" or "Error", 10, 30)
        -- font:pop()

        -- lgx.setColor(0, 0, 0, 0.7)
        -- lgx.rectangle("fill", 0, 0, 80, 120)
        -- lgx.setColor(1, 1, 0, 1)
        -- lgx.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
        -- lgx.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
        -- local maj, min, rev, code = love.getVersion()
        -- lgx.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)

        -- local stats = love.graphics.getStats()
        -- local fmt = string.format
        -- lgx.setColor(0.9, 0.9, 0.9)
        -- lgx.printf(
        --     fmt("draw: %d\ncanvas_sw: %d\nshader_sw: %d\ntextMemo: %.2f\ncanvases: %d\ndrawBatched: %d",
        --         stats.drawcalls,
        --         stats.canvasswitches,
        --         stats.shaderswitches,
        --         stats.texturememory / (1024 ^ 2),
        --         stats.canvases,
        --         stats.drawcallsbatched),
        --     lgx.getWidth() - 212, 12, 200,
        --     "right")
    end
end
