local path = ...
local JM = _G.JM
local Kid = require "lib.object.kid"

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class GameState.Game : JM.Scene
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
}
--============================================================================
---@class GameState.Game.Data
local data = {}

--============================================================================

function State:__get_data__()
    return data
end

local function load()
    Kid:load()
end

local function finish()
    Kid:finish()
end

local function init(args)
    data.world = JM.Physics:newWorld { tile = TILE }
    JM.GameObject:init_state(State, data.world)
    State.game_objects = {}

    

    data.player = Kid:new(nil, nil, 1)
    State:add_object(data.player)

    JM.Physics:newBody(data.world, 0, 0, SCREEN_WIDTH, 16 * 2, "static")
    JM.Physics:newBody(data.world, 0, SCREEN_HEIGHT - 16, SCREEN_WIDTH, 16, "static")
end

local function textinput(t)

end

local function keypressed(key)
    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end

    data.player:keypressed(key)
end

local function keyreleased(key)

end

local function mousepressed(x, y, button, istouch, presses)

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

end

local function gamepadreleased(joystick, button)

end

local function gamepadaxis(joystick, axis, value)
end

local function update(dt)
    data.world:update(dt)
    State:update_game_objects(dt)
end

local function draw(cam)
    data.world:draw(true, nil, cam)
    State:draw_game_object(cam)
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
    update = update,
    draw = draw,
}

return State
