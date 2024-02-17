local JM = require "jm-love2d-package.init"
local lgx = love.graphics

function love.load()
    math.randomseed(os.time())
    lgx.setBackgroundColor(0.1, 0.1, 0.1, 1)
    lgx.setDefaultFilter("nearest", "nearest")
    lgx.setLineStyle("rough")
    love.mouse.setVisible(false)

    _G.SCREEN_WIDTH = JM.Utils:round(320) --398
    _G.SCREEN_HEIGHT = JM.Utils:round(180)

    _G.WEB = false
    _G.SUBPIXEL = 4
    _G.TILE = 16
    _G.CANVAS_FILTER = "linear"
    _G.TARGET = love.system.getOS()

    if WEB then
        JM.Sound:set_song_mode("static")
    end

    ---@param State JM.Scene
    _G.RESIZE = function(State, w, h)
        local percent = 0.02
        if not State.shader then
            percent = 0
        end
        State.x = math.floor(w * percent)
        State.w = w - State.x
        State.y = math.floor(w * percent)
        State.h = h - State.y
    end

    JM:get_font():set_font_size(8)
    JM.esc_to_quit = false

    local P1 = JM.ControllerManager.P1
    local Button = P1.Button
    P1.button_to_key[P1.Button.A] = { 'space' }
    P1.button_to_key[P1.Button.X] = { 'f', 'e', 'j' }
    P1.button_to_key[P1.Button.B] = { 'escape', 'backspace' }
    P1.button_to_key[P1.Button.R] = { 'f', 'rshift' }
    P1.button_to_key[P1.Button.L] = { 'f', 'lshift' }

    local P2 = JM.ControllerManager.P2
    P2.button_to_key[Button.A] = { 'i' }
    P2.button_to_key[Button.X] = { 'u' }

    -- love.keyboard.isDown('ls')

    do
        local Word = require "jm-love2d-package.modules.font.Word"
        ---@diagnostic disable-next-line: inject-field
        Word.eff_wave_range = 0.75
        ---@diagnostic disable-next-line: inject-field
        Word.eff_scream_range_y = 1
        ---@diagnostic disable-next-line: inject-field
        Word.eff_spooky_range_y = 0.4
    end

    JM.Scene.set_default_scene_config(function(self)
        if self.is_splash_screen
            or _G.WEB
            or true
        then
            return
        end

        -- local scanline = JM.Shader:get_shader("scanline", self, { screen_h = 256, width = 0.85 })
        -- scanline:send("opacity", 0.25)
        -- self:set_shader(scanline)

        do
            local shader = JM.Shader:get_shader("crt_scanline", self, {
                screen_h = 288,
                width = 1,
            })
            shader:send("opacity", 0.25)
            self:set_shader(shader)
        end
    end)
    return JM:load_initial_state("lib.gamestate.game", false)
    -- return JM:load_initial_state("jm-love2d-package.modules.editor.editor", false)
end

function love.textinput(t)
    return JM:textinput(t)
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'p' and love.keyboard.isDown('lctrl') then
        return love.graphics.captureScreenshot("img_" .. os.time() .. ".png")
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

end

local km = 0
function love.update(dt)
    km = collectgarbage("count") / 1024.0
    return JM:update(dt)
end

function love.draw()
    JM:draw()

    do
        -- local font = JM.Font.current
        -- font:push()
        -- font:set_font_size(32)
        -- font:set_color(JM_Utils:get_rgba(1, 0, 0))
        -- font:print(succes and admob and "Loaded" or "Error", 10, 30)
        -- font:pop()

        lgx.setColor(0, 0, 0, 0.7)
        lgx.rectangle("fill", 0, 0, 80, 120)
        lgx.setColor(1, 1, 0, 1)
        lgx.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
        lgx.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
        local maj, min, rev, code = love.getVersion()
        lgx.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)

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
