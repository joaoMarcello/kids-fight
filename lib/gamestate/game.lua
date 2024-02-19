local path = ...
local JM = _G.JM
local Kid = require "lib.object.kid"
local DisplayHP = require "lib.object.displayHP_game"

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

function data.play_song()

end

--============================================================================

function State:__get_data__()
    return data
end

local imgs
local function load()
    local font = JM:get_font("pix8")
    font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("242833")))

    local font = JM:get_font("pix5")
    font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("242833")))

    Kid:load()
    DisplayHP:load()

    local lgx = love.graphics
    imgs = imgs or {
        ["field"] = lgx.newImage("/data/img/background.png"),
        ["street_down"] = lgx.newImage("/data/img/back_down.png"),
        ["street_up"] = lgx.newImage("/data/img/back_up.png"),
        ["box"] = lgx.newImage("/data/img/box_gui.png"),
    }
end

local function finish()
    Kid:finish()
    DisplayHP:finish()

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

    ---@type Kid
    local k = State:add_object(Kid:new(16 * 13, 16 * 7, Kid.Gender.boy, -1, true, 1))
    -- k:set_position(16 * 14, 16 * 9)

    k = State:add_object(Kid:new(16 * 12, 16 * 4, Kid.Gender.boy, -1, true, 2))
    k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3))

    data.displayHP = DisplayHP:new(data.player)
end

local function textinput(t)

end

local function keypressed(key)
    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end

    local P1 = data.player.controller
    local Button = P1.Button
    P1:switch_to_keyboard()

    if (P1:pressed(Button.start, key) or P1:pressed(Button.B, key))
    then
        JM.Sound:pause()
        _G.Play_sfx("pause", true)

        local audio = JM.Sound:get_current_song()
        if audio then
            -- audio.source:pause()
            audio:set_volume(audio.init_volume * 0.15)
        end

        return State:change_gamestate(require "lib.gamestate.pause", {
            skip_finish = true,
            skip_transition = true,
            keep_canvas = true,
            save_prev = true,
        })
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
    local P1 = data.player.controller
    local Button = P1.Button

    if P1:pressed(Button.A, joystick, button) then
        State:keypressed('space')
    elseif P1:pressed(Button.B, joystick, button) then
        State:keypressed('escape')
    elseif P1:pressed(Button.start, joystick, button) then
        State:keypressed('enter')
    elseif P1:pressed(Button.dpad_left, joystick, button) then
        State:keypressed('left')
    elseif P1:pressed(Button.dpad_right, joystick, button) then
        State:keypressed('right')
    elseif P1:pressed(Button.dpad_up, joystick, button) then
        State:keypressed('up')
    elseif P1:pressed(Button.dpad_down, joystick, button) then
        State:keypressed('down')
    elseif P1:pressed(Button.X, joystick, button)
        or P1:pressed(Button.L, joystick, button)
        or P1:pressed(Button.R, joystick, button)
    then
        State:keypressed('f')
    end

    P1:switch_to_joystick()
end

local function gamepadreleased(joystick, button)

end

local function gamepadaxis(joystick, axis, value)
    local P1 = data.player.controller
    local Button = P1.Button

    local x_axis = P1:pressed(Button.left_stick_x, joystick, axis, value)
    if x_axis == 1 then
        State:keypressed('right')
    elseif x_axis == -1 then
        State:keypressed('left')
    end

    local y_axis = P1:pressed(Button.left_stick_y, joystick, axis, value)
    if y_axis == 1 then
        State:keypressed('down')
    elseif y_axis == -1 then
        State:keypressed('up')
    end

    P1:switch_to_joystick()
end

local function resize(w, h)
    return _G.RESIZE(State, w, h)
end

local function update(dt)
    data.world:update(dt)
    State:update_game_objects(dt)

    data.displayHP:update(dt)
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

    lgx.setColor(JM_Utils:hex_to_rgba_float("799299"))
    lgx.draw(imgs["street_down"])

    local font = JM:get_font("pix5")
    local px = data.displayHP.x
    local py = data.displayHP.y + 8

    lgx.setColor(1, 1, 1, 0.75)
    lgx.draw(imgs["box"], px - 12, data.displayHP.y - 4)

    if data.player.stones == data.player.max_stones then
        font:printx(string.format("ammo x %d <effect=flickering, speed=0.5><color-hex=ff0000>max", data.player.stones),
            px, py)
    elseif data.player.stones <= 0 then
        font:printx(string.format("<effect=flickering, speed=0.5><color-hex=ff0000>no ammo"), px, py)
    else
        font:printf(string.format("ammo x %d", data.player.stones), px, py)
    end

    data.displayHP:draw()
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
