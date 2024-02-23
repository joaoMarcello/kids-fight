local path = ...
---@type GameState.Game|any
local Game
local Textbox = JM.GUI.TextBox
local lgx = love.graphics

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class GameState.HowToPlay : JM.Scene
local State = JM.Scene:new {
    x = nil,
    y = nil,
    w = nil,
    h = nil,
    canvas_w = _G.SCREEN_WIDTH or 320,
    canvas_h = _G.SCREEN_HEIGHT or 180,
    tile = _G.TILE,
    subpixel = _G.SUBPIXEL or 3,
    canvas_filter = _G.CANVAS_FILTER or 'linear',
    cam_scale = 1,
    show_border = false,
}

State:set_color(JM.Utils:hex_to_rgba_float("c5bde6")) --e5f285
-- State.camera:set_viewport(nil, nil, State.screen_w * 0.75, State.screen_h * 0.5)
-- State.camera:set_viewport(nil, nil, State.screen_w * 0.75, State.screen_h * 0.5)

--============================================================================
---@class GameState.HowToPlay.Data
local data = {
    x = 16 * 8, --32
    y = 14,
    w = 320 / 2,
    h = 180 / 2,
    time_state = 0.0,
}

--============================================================================

function State:__get_data__()
    return data
end

local function load()
    Game = require "lib.gamestate.game"
    Game:load()
    JM:get_font("pix5")
    JM:get_font("pix8")

    -- JM.Sound:add_sfx("/data/sfx/flipping-through-a-bookmp3-14415.ogg", "flip", 1)

    -- JM.Sound:add_song("/data/song/Bass-Invaders.ogg", "HowToPlay", 0.35)
end

local function finish()
    JM.Sound:remove_sfx("flip")
    JM.Sound:remove_song("HowToPlay")

    for k, v in next, data do
        if type(v) == "table" then
            data[k] = nil
        end
    end
end

local restart_game = function()
    Game:restaure_canvas()
    Game:init { wave_number = 3 }
    local data_ = Game:__get_data__()
    data_.player.ia_mode = true
    data_.player.move_type = 2
    data_.player.move_delay = 0.5
end

local function init(args)
    restart_game()

    data.text = string.format(
        "Throw stones on your enemies<next>Move:\tA/D or left/right\nJump:\tspace\nAttack:\tF/J/E<next>Done")

    local font = JM:get_font("pix8")
    font:push()
    -- font:set_font_size(font.__font_size * 2)
    font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("332424")))
    data.textbox = Textbox:new {
        text = data.text,
        font = JM:get_font("pix8"),
        x = 24 + 16,
        y = 16 * 7.25 + 1,
        w = 16 * 14,
        align = Textbox.AlignX.left,
        text_align = Textbox.AlignY.top,
        update_mode = Textbox.UpdateMode.by_screen,
        speed = 0.1,
        n_lines = 3,
        time_wait = 0.1,
        allow_cycle = false,
    }
    font:pop()

    data.layer_sawtooth = State:newLayer {
        infinity_scroll_y = true,
        height = TILE * 1.5,
        update = function(self, dt)
            self.py = self.py + 16 * dt
        end,
        draw = function(cam)
            data:sawtooth()
        end
    }

    ---@type JM.Template.Affectable
    data.aff = JM.Affectable:new()
    data.aff:apply_effect("pointing", { range = 1 })

    data.time_state = 0.0

    JM.Sound:play_song("HowToPlay", true)
end

local function textinput(t)

end

local function go_to_game()
    if not State.transition then
        -- do
        --     local title = package.loaded["lib.gamestate.title"]
        --     if title then title:finish() end
        --     package.loaded["lib.gamestate.title"] = nil
        --     package.loaded["lib.gamestate.ranking"] = nil
        -- end

        JM.Sound:stop_all()
        _G.Play_sfx("eat", true)

        return State:add_transition("sawtooth", "out",
            {
                duration = 0.7,
                type = "left-right",
                -- pause_scene = true,
                post_delay = 0.2,
                segments = 5,
            },
            nil,
            function(self)
                self:change_gamestate(Game,
                    {
                        unload = path,
                        keep_canvas = false,
                        transition = "sawtooth",
                        transition_conf = {
                            -- delay = 0.1,
                            duration = 0.5,
                            type = "left-right",
                            pause_scene = true,
                            segments = 5,
                        },
                    })
                Game:__get_data__().play_song()
                ---@diagnostic disable-next-line: cast-local-type
                data = nil
                Game = nil
                JM:flush()
            end)
    end
end

local function keypressed(key)
    if State.transition then return end

    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
        State.camera:toggle_debug()
    end

    -- if key == 's' then
    --     Game:init()
    -- end

    local P1 = JM.ControllerManager.P1
    local Button = P1.Button
    P1:switch_to_keyboard()

    if P1:pressed(Button.start, key) then
        return go_to_game()
    end

    if P1:pressed(Button.B, key) then
        if not State.transition then
            JM.Sound:fade_out()


            return State:add_transition("sawtooth", "out",
                { duration = 0.75, post_delay = 0.1, axis = "y", type = "" }, nil,
                function(self)
                    do
                        Game:finish()
                        local pause = package.loaded['lib.gamestate.pause']
                        if pause then
                            pause:finish()
                        end
                        package.loaded['lib.gamestate.pause'] = nil
                    end

                    self:change_gamestate(require "lib.gamestate.title", {
                        unload = path,
                        transition = "sawtooth",
                        transition_conf = {
                            axis = "y",
                            type = "",
                            duration = 0.5,
                            post_delay = 0.1
                        }
                    })
                    JM:flush()
                end)
        end
    end

    -- if P1:pressed(Button.X, key) then
    --     local st = require(JM_Package.SplashScreenPath)
    --     State:change_gamestate(st, { keep_canvas = true, skip_transition = true })
    --     return
    -- end

    local x = P1:pressed(Button.left_stick_x, key)
    if x > 0 or P1:pressed(Button.A, key) then
        local r = data.textbox:go_to_next_screen()
        if r then _G.Play_sfx("flip", true) end
    elseif x < 0 or P1:pressed(Button.stick_1_down, key) then
        local r = data.textbox:go_to_prev_screen()
        if r then _G.Play_sfx("flip", true) end
    end

    -- Game:keypressed(key)
end

local function keyreleased(key)
    -- Game:keyreleased(key)
end

local function gamepadpressed(joy, button)
    local P1 = JM.ControllerManager.P1
    local Button = P1.Button

    if P1:pressed(Button.A, joy, button) then
        return go_to_game()
    elseif P1:pressed(Button.R, joy, button)
        or P1:pressed(Button.dpad_right, joy, button)
        or P1:pressed(Button.dpad_down, joy, button)
    then
        return State:keypressed('right', 'right')
    elseif P1:pressed(Button.L, joy, button)
        or P1:pressed(Button.dpad_left, joy, button)
        or P1:pressed(Button.dpad_up, joy, button)
    then
        return State:keypressed('left', 'left')
    end

    if P1:pressed(Button.B, joy, button) then
        return State:keypressed('escape')
    end
end

local function gamepadaxis(joy, axis, value)
    local P1 = JM.ControllerManager.P1
    local Button = P1.Button

    local r = P1:pressed(Button.left_stick_x, joy, axis, value)
    if r == 1 then
        return State:keypressed('right', 'right')
    elseif r == -1 then
        return State:keypressed('left', 'left')
    end
end

local function mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        return State:keypressed('space', 'space')
    elseif button == 2 then
        return State:keypressed('return', 'return')
    end
end

local function mousereleased(x, y, button, istouch, presses)

end

local function mousemoved(x, y, dx, dy, istouch)

end

local function touchpressed(id, x, y, dx, dy, pressure)

end

local function touchreleased(id, x, y, dx, dy, pressure)

end

local resize = function(w, h)
    return _G.RESIZE(State, w, h)
end

local function update(dt)
    if dt > 1 / 30 then dt = 1 / 30 end

    data.time_state = data.time_state + dt

    JM.Sound:lock()
    Game:update(dt * 0.9)
    JM.Sound:unlock()

    local data_ = Game:__get_data__()
    if data_.player.hp <= 3
        or data_.time_game > 20
    then
        restart_game()
    end

    data.textbox:update(dt)

    data.layer_sawtooth:update(dt)
    data.aff:update(dt)
end

---@type love.Shader|nil
local overlay
if not _G.WEB then
    local code = love.filesystem.read("/jm-love2d-package/data/shader/overlay.glsl")
    overlay = love.graphics.newShader(code)
    local color = { JM_Utils:hex_to_rgba_float("e5f285") }
    color[4] = 0.3
    overlay:sendColor("c", color)
end

function data:sawtooth()
    lgx.setColor(JM_Utils:hex_to_rgba_float("a2a9d9"))
    local px = (TILE * 6)
    local h = TILE * 1.5
    local h2 = TILE * 0.5
    local w = TILE
    for i = 0, h - 1, h do
        lgx.polygon("fill",
            px, i,
            px + w, i + h2,
            px, i + h
        )
        lgx.rectangle("fill", 0 - 32, i, 96 + 32, h)
    end
end

local draw_arrow = function(self)
    local font = JM:get_font("pix8")
    font:push()
    font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("352e99")))
    font:print(" :arw_head_fr:", self.x, self.y)
    font:pop()
end

local function draw(cam)
    -- lgx.setColor(JM.Utils:hex_to_rgba_float("f4ffe8"))
    -- lgx.rectangle("fill", cam.x, cam.y, cam.viewport_w, cam.viewport_h)

    local sx = data.w / State.screen_w
    local sy = data.h / State.screen_h

    local Utils = JM_Utils

    -- lgx.setColor(Utils:hex_to_rgba_float("e6c45c"))
    -- lgx.rectangle("fill", 0, 0, 96, SCREEN_HEIGHT)
    data.layer_sawtooth.angle = -math.pi * 0.015
    data.layer_sawtooth:draw(cam)
    -- data:sawtooth()

    lgx.setColor(Utils:hex_to_rgba_float("d96c21"))
    lgx.ellipse("fill", 48, 24, 40, 16, 10)
    local font = _G.FONT_THALEAH --JM:get_font("pix8")
    font:push()
    font:set_line_space(3)
    font:set_color(Utils:get_rgba3("f4ffe8"))
    font:printf("HOW TO\nPLAY", 0, TILE, 96, "center")
    font:pop()

    local font = JM:get_font("pix8")

    lgx.setColor(Utils:hex_to_rgba_float("352e99"))
    -- blue shadow for game screen
    lgx.rectangle("fill", data.x + 2, data.y + 2, Game.screen_w * sx, Game.screen_h * sy)

    do
        -- drawing Game mini screen
        local shaders = Game.shader
        Game:set_shader_params(shaders[1], false)
        Game:draw_capture(State, cam, data.x, data.y, 0, sx, sy, nil, nil, nil, nil, overlay)
        Game:set_shader_params(shaders[1], true)
        -- SAVE_DATA.use_blur = use_blur
        -- outline for game screen
        lgx.setColor(Utils:hex_to_rgba_float("334266")) --242833
        lgx.rectangle("line", data.x, data.y, data.w, data.h)
    end

    local box = data.textbox
    lgx.setColor(Utils:hex_to_rgba_float("f4ffe8")) --e8fff0
    local x, y, w, h = box:rect()
    lgx.rectangle("fill", x - 8, y - 4, w + 16 + 16, h + 8, 2, 2)
    box:draw(cam)

    -- box outline
    lgx.setColor(Utils:hex_to_rgba_float("334266"))
    lgx.rectangle("line", x - 8, y - 4, w + 16 + 16, h + 8, 2, 2)

    -- orange box shadow
    lgx.setColor(Utils:hex_to_rgba_float("334266"))
    lgx.polygon("fill",
        x - 16 + 4 + 1, y - 12 + 1,
        x - 12 + 16 * 4 + 1, y - 12 + 1,
        x - 12 + 16 * 4 - 4 + 1, y + 1,
        x - 16 + 1, y + 1
    )
    -- orange box
    lgx.setColor(Utils:hex_to_rgba_float("213ad9")) --d96c21
    lgx.polygon("fill",
        x - 16 + 4, y - 12,
        x - 12 + 16 * 4, y - 12,
        x - 12 + 16 * 4 - 4, y,
        x - 16, y
    )

    local font = JM:get_font("pix5")
    font:push()
    font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("665c57")))
    font:printf(string.format("%d/%d", box.cur_screen, box.amount_screens), x + w, y + h - 8, 16, "right")

    font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("352e99")))
    font:printx("<effect=flickering, speed=1>press [enter] to play", 0, SCREEN_HEIGHT - 14, SCREEN_WIDTH - 8,
        "right")

    local text = "goal"
    text = box.cur_screen == 2 and "controls" or text
    text = box.cur_screen >= 3 and "tips" or text
    font:set_color(JM.Utils:get_rgba(1, 1, 1))
    font:printf(text, x - 16, y - 12, 16 * 4, "center")
    font:pop()

    local aff = data.aff
    aff.x = 16 * 18
    aff.y = 16 * 8.5
    aff:set_effect_transform("sx", 1)
    if box.cur_screen ~= box.amount_screens then
        aff:draw(draw_arrow)
    end

    aff.x = 16 * 2
    if box.cur_screen ~= 1 then
        aff:set_effect_transform("ox", -aff.__effect_transform.ox)
        aff:set_effect_transform("sx", -1)
        aff:draw(draw_arrow)
    end
end
--============================================================================
State:implements {
    load = load,
    finish = finish,
    init = init,
    textinput = textinput,
    keypressed = keypressed,
    keyreleased = keyreleased,
    gamepadpressed = gamepadpressed,
    gamepadaxis = gamepadaxis,
    mousepressed = mousepressed,
    mousereleased = mousereleased,
    mousemoved = mousemoved,
    touchpressed = touchpressed,
    touchreleased = touchreleased,
    resize = resize,
    update = update,
    draw = draw,
    -- layers = layers,
}

return State
