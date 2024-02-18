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
    use_canvas_layer = true,
}
--============================================================================
---@class GameState.Game.Data
local data = {}

--============================================================================

function State:__get_data__()
    return data
end

local imgs
local function load()
    Kid:load()

    local lgx = love.graphics
    imgs = imgs or {
        ["field"] = lgx.newImage("/data/img/background.png"),
        ["street_down"] = lgx.newImage("/data/img/back_down.png"),
        ["street_up"] = lgx.newImage("/data/img/back_up.png"),
    }
end

local function finish()
    Kid:finish()

    if imgs then
        imgs["field"]:release()
        imgs["street_down"]:release()
        imgs["street_up"]:release()
    end
    imgs = nil
end

local function init(args)
    data.world = JM.Physics:newWorld { tile = TILE }
    JM.GameObject:init_state(State, data.world)
    State.game_objects = {}

    data.player = Kid:new(nil, SCREEN_HEIGHT * 0.5, 1)
    State:add_object(data.player)

    JM.Physics:newBody(data.world, 0, 0, SCREEN_WIDTH, 16 * 3, "static")
    JM.Physics:newBody(data.world, 0, SCREEN_HEIGHT - 16, SCREEN_WIDTH, 16, "static")

    State:add_object(Kid:new(16 * 12, SCREEN_HEIGHT * 0.5, Kid.Gender.boy, -1))

    -- data.layer_shadow = State:newLayer {

    -- }
end

local function textinput(t)

end

local function keypressed(key)
    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end

    data.player:keypressed(key)

    if key == 'u' then
        data.player:damage(1, nil)
    end
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

local sort_draw = function(a, b)
    local y1 = a.get_shadow and not a.__remove and a:get_shadow().y or a.y
    local y2 = b.get_shadow and not b.__remove and b:get_shadow().y or b.y
    return y1 < y2
end

---@param cam JM.Camera.Camera
local function draw(cam)
    local lgx = love.graphics
    lgx.setColor(1, 1, 1)
    lgx.draw(imgs["field"])

    -- data.world:draw(true, nil, cam)

    local _canvas = lgx.getCanvas()
    lgx.setCanvas(State.canvas_layer)
    lgx.clear()
    local list = State.game_objects
    for i = 1, #list do
        ---@type GameObject|BodyObject|Kid|Projectile|any
        local obj = list[i]
        if not obj.__remove and obj.get_shadow and obj.is_visible then
            local s = obj:get_shadow()
            local x, y, w, h = s:rect()
            lgx.setColor(0, 0, 0, 1)
            lgx.ellipse("fill", x + w * 0.5, y, w, 4)
        end
    end
    lgx.setCanvas(_canvas)
    lgx.setColor(1, 1, 1, 0.5)
    lgx.draw(State.canvas_layer, 0, 0, 0, 1 / State.subpixel)

    lgx.setColor(1, 1, 1)
    lgx.draw(imgs["street_up"])

    State:draw_game_object(cam, nil, sort_draw)

    lgx.setColor(1, 1, 1)
    lgx.draw(imgs["street_down"])
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
