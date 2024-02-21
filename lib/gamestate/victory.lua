local path = ...
local JM = _G.JM

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class GameState.Victory : JM.Scene
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
    bound_top = 0,
    bound_left = 0,
    bound_right = 1366,
    bound_bottom = 1366,
    cam_scale = 1,
}

State:set_color(JM_Utils:hex_to_rgba_float("2c2433"))
--============================================================================
---@class GameState.Victory.Data
local data = {}

--============================================================================

function State:__get_data__()
    return data
end

local function load()
    JM:get_font("pix8")
    JM:get_font("pix5")
end

local function finish()

end

local function init(args)
    local game = require "lib.gamestate.game"
    local _data_ = game:__get_data__()

    data.total_time = _data_.time_game
    data.death_count = _data_.death_count or 0
    data.time_gamestate = 0.0
end

local function textinput(t)

end

local function keypressed(key)
    if State.transition or data.time_gamestate < 3 then return end

    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end

    local P1 = JM.ControllerManager.P1
    local Button = P1.Button

    if P1:pressed(Button.start, key)
        or P1:pressed(Button.A, key)
    then
        if not State.transition then
            return State:add_transition("fade", "out", { post_delay = 0.2 }, nil,
                ---@param State JM.Scene
                function(State)
                    return State:change_gamestate(
                        require "lib.gamestate.title",
                        {
                            transition = "fade",
                        }
                    )
                end)
        end
    end
end

local function keyreleased(key)

end

local function mousepressed(x, y, button, istouch, presses)
    if button == 1 or button == 2 then
        return State:keypressed('space')
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

local function gamepadpressed(joystick, button)
    local P1 = JM.ControllerManager.P1
    local Button = P1.Button

    if P1:pressed(Button.start, joystick, button)
        or P1:pressed(Button.A, joystick, button)
    then
        return State:keypressed('return')
    end
end

local function gamepadreleased(joystick, button)

end

local function gamepadaxis(joystick, axis, value)
end

local function resize(w, h)
    return _G.RESIZE(State, w, h)
end

local function update(dt)
    data.time_gamestate = data.time_gamestate + dt
end

local function draw(cam)
    local font = JM:get_font("pix8")
    local Utils = JM_Utils
    font:push()
    font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("e5f285")))

    font:printf(string.format("N. deaths: <color-hex=d96c21>%d", data.death_count), 0, 16 * 4, SCREEN_WIDTH, "center")

    font:printf(string.format("Your time was\n<color-hex=f4ffe8>%.1f</color> seconds", tostring(data.total_time or 0)), 0,
        16 * 6,
        SCREEN_WIDTH, "center")

    -- font:set_font_size(font.__font_size * 2)
    if data.time_gamestate > 3.0 then
        font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("bf91b4")))
        font:printx("<effect=flickering, speed=1>Press [space] to continue", 0, 16 * 9.5, SCREEN_WIDTH,
            "center")
    end

    font:pop()

    font = JM:get_font("pix5")
    font:push()
    font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("e5f285")))
    font:set_font_size(font.__font_size * 2)
    font:printf("you defeat the bullies!", 0, 16 * 1.5, SCREEN_WIDTH, "center")
    font:pop()
end

--============================================================================
State:implements {
    load = load,
    init = init,
    finish = finish,
    textinput = textinput,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousepressed = mousepressed,
    mousereleased = mousereleased,
    mousemoved = mousemoved,
    touchpressed = touchpressed,
    touchreleased = touchreleased,
    gamepadpressed = gamepadpressed,
    gamepadreleased = gamepadreleased,
    gamepadaxis = gamepadaxis,
    resize = resize,
    update = update,
    draw = draw,
}

return State
