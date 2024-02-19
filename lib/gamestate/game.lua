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

---@enum GameState.Game.States
local States = {
    game = 1,
    sendKidsAway = 2,
    waveIsComing = 3,
    playerIsDead = 4,
    dialogue = 5,
}
--============================================================================
---@class GameState.Game.Data
local data = {}

function data.play_song()

end

function data:unlock_kids()
    for i = 1, #self.kids do
        ---@type Kid
        local k = self.kids[i]
        if k
            and k.state == Kid.State.idle
            and k:is_on_target_position()
        then
            k:set_state(Kid.State.normal)
        end
    end

    if self.player.state == Kid.State.idle
        and self.player:is_on_target_position()
    then
        self.player:set_state(Kid.State.normal)
    end
end

function data:all_kids_on_position()
    local list = self.kids
    local player = self.player

    if not list or not player:is_on_target_position() then return false end
    for i = 1, #list do
        ---@type Kid
        local k = list[i]
        if not k:is_on_target_position() then
            return false
        end
    end
    return true
end

function data:put_kids_to_run(send_leader)
    local list = self.kids
    if not list then return end

    for i = 1, #list do
        ---@type Kid
        local k = list[i]

        if k ~= self.leader or send_leader then
            k:set_state(Kid.State.runAway)
        end
    end
end

function data:start_countdown(init)
    self.countdown_time = init or 1
end

function data:start_game()
    if self.countdown_time and self.countdown_time <= 0
        and self:all_kids_on_position()
    then
        self:unlock_kids()
        self.countdown_time = nil
        self:set_state(States.game)
        return true
    end
    return false
end

function data:wave_is_over()
    local list = self.kids
    if not list then return false end

    local c = 0
    local N = #list
    for i = 1, N do
        ---@type Kid
        local k = list[i]
        if k:is_dead() then
            c = c + 1
        end
    end
    return c == N
end

---@param new_state GameState.Game.States
function data:set_state(new_state)
    if new_state == self.gamestate then return false end
    self.gamestate = new_state

    return true
end

function data:leader_is_dead()
    if not self.leader then return false end
    return self.leader:is_dead()
end

function data:remove_all_projectiles()
    local list = State.game_objects
    for i = 1, #list do
        ---@type Projectile|any
        local obj = list[i]
        if obj.is_projectile and not obj:on_ground() then
            obj:remove()
        end
    end
end

function data:enemy_victory()
    local list = data.kids
    for i = 1, #list do
        ---@type Kid
        local k = list[i]
        if not k:is_dead() then
            k:set_state(Kid.State.victory)
        end
    end
end

function data:player_victory()
    data.player:set_state(Kid.State.victory)
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

    data.kids = nil
    data.world = nil
    data.player = nil
end

local function load_wave(value)
    value = value or 1
    data.wave_number = value
    data:set_state(States.waveIsComing)

    if data.kids then
        local list = data.kids
        for i = 1, #list do
            ---@type Kid
            local k = list[i]

            if k ~= data.leader then
                k:set_state(Kid.State.runAway)
            end
        end
    end

    data.kids = {}

    if value == 1 then
        ---@type Kid
        local k = State:add_object(Kid:new(SCREEN_WIDTH, 16 * 7, Kid.Gender.boy, -1, true, 2))
        k:set_position(SCREEN_WIDTH, 16 * 7)
        k:set_target_position(16 * 12)
        k:set_state(k.State.preparing)
        k.time_move_y = 0.0
        k.anchor_y = 16 * 7
        k.goingTo_speed = 1.5
        table.insert(data.kids, k)
        data.leader = k

        ---@type Kid
        k = State:add_object(Kid:new(16 * 12, 16 * 9, Kid.Gender.boy, -1, true, 1))
        k:set_position(SCREEN_WIDTH, 16 * 9)
        k:set_target_position(16 * 14, 16 * 9)
        k:set_state(k.State.preparing)
        k.goingTo_speed = 0.75
        k.anchor_y = 16 * 9 - k.move_y_value
        k.time_move_y = math.pi * 0.5
        table.insert(data.kids, k)

        -- ---@type Kid
        -- k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3))
        -- k:set_position(SCREEN_WIDTH, 16 * 9)
        -- k:set_target_position(16 * 14, 16 * 9)
        -- k:set_state(k.State.preparing)
        -- k.goingTo_speed = 2
        -- k.anchor_y = 16 * 9 - k.move_y_value
        -- k.time_move_y = math.pi * 0.5
        -- k.anchor_x = 16 * 14
        -- k.time_move_x = 0.0
        -- table.insert(data.kids, k)

        -- ---@type Kid
        -- k = State:add_object(Kid:new(16 * 18, 16 * 5, Kid.Gender.boy, -1, true, 1))
        -- k:set_position(SCREEN_WIDTH, 16 * 5)
        -- k:set_target_position(16 * 18, 16 * 5)
        -- k:set_state(k.State.preparing)
        -- k.goingTo_speed = 2
        -- k.anchor_y = 16 * 5 + k.move_y_value
        -- k.time_move_y = -math.pi * 0.5
        -- table.insert(data.kids, k)
        ---
    elseif value == 2 then
        if data.leader then
            data.leader:ressurect()
        end

        ---@type Kid
        local k = data.leader or State:add_object(Kid:new(SCREEN_WIDTH, 16 * 7, Kid.Gender.boy, -1, true, 1))
        -- k:set_position(SCREEN_WIDTH, 16 * 7)
        k:set_target_position(16 * 12, 16 * 7)
        k:set_state(k.State.preparing)
        k.time_move_y = 0.0
        k.anchor_y = 16 * 7
        k.goingTo_speed = 1.5
        table.insert(data.kids, k)
        data.leader = k

        ---@type Kid
        k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3))
        k:set_position(SCREEN_WIDTH, 16 * 9)
        k:set_target_position(16 * 14, 16 * 9)
        k:set_state(k.State.preparing)
        k.goingTo_speed = 2
        k.anchor_y = 16 * 9 - k.move_y_value
        k.time_move_y = math.pi * 0.5
        k.anchor_x = 16 * 14
        k.time_move_x = 0.0
        table.insert(data.kids, k)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 17, 16 * 5, Kid.Gender.boy, -1, true, 1))
        k:set_position(SCREEN_WIDTH, 16 * 5)
        k:set_target_position(16 * 17, 16 * 5)
        k:set_state(k.State.preparing)
        k.goingTo_speed = 2
        k.anchor_y = 16 * 5 + k.move_y_value
        k.time_move_y = -math.pi * 0.5
        table.insert(data.kids, k)
        ---
    else
        if data.leader then
            data.leader:ressurect()
        end

        ---@type Kid
        local k = data.leader or State:add_object(Kid:new(SCREEN_WIDTH, 16 * 7, Kid.Gender.boy, -1, true, 1))
        -- k:set_position(SCREEN_WIDTH, 16 * 7)
        k:set_target_position(16 * 12, 16 * 7)
        k:set_state(k.State.preparing)
        k.time_move_y = 0.0
        k.anchor_y = 16 * 7
        k.goingTo_speed = 1.5
        table.insert(data.kids, k)
        data.leader = k

        k = State:add_object(Kid:new(16 * 12, 16 * 4, Kid.Gender.boy, -1, true, 2))
        k:set_position(SCREEN_WIDTH, 16 * 4)
        k:set_target_position(16 * 14, 16 * 4)
        k:set_state(k.State.preparing)
        k.goingTo_speed = 0.75
        table.insert(data.kids, k)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3))
        k:set_position(SCREEN_WIDTH, 16 * 9)
        k:set_target_position(16 * 14, 16 * 9)
        k:set_state(k.State.preparing)
        k.goingTo_speed = 2
        k.anchor_y = 16 * 9 - k.move_y_value
        k.time_move_y = math.pi * 0.5
        k.anchor_x = 16 * 14
        k.time_move_x = 0.0
        table.insert(data.kids, k)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 17, 16 * 5, Kid.Gender.boy, -1, true, 1))
        k:set_position(SCREEN_WIDTH, 16 * 5)
        k:set_target_position(16 * 17, 16 * 5)
        k:set_state(k.State.preparing)
        k.goingTo_speed = 2
        k.anchor_y = 16 * 5 + k.move_y_value
        k.time_move_y = -math.pi * 0.5
        table.insert(data.kids, k)
        ---
    end
end


local function init(args)
    args = args or {}

    data.time_game = 0
    data.countdown_time = nil

    data.world = JM.Physics:newWorld { tile = TILE }
    JM.GameObject:init_state(State, data.world)
    State.game_objects = {}

    data.player = Kid:new(16 * 7, 16 * 7, 1)
    data.player:set_position(-50, 16 * 7)
    data.player:set_state(Kid.State.preparing)
    data.player.goingTo_speed = 2

    State:add_object(data.player)

    JM.Physics:newBody(data.world, 0, 0, SCREEN_WIDTH, 16 * 3, "static")
    JM.Physics:newBody(data.world, 0, SCREEN_HEIGHT - 16, SCREEN_WIDTH, 16, "static")

    data.leader = nil
    data.wave_number = args.wave_number or 1
    load_wave(data.wave_number)

    data.displayHP = DisplayHP:new(data.player)

    data:start_countdown(0.3)
    data:set_state(States.waveIsComing)
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

local function game_logic(dt)
    local state = data.gamestate
    if state == States.game then
        if data:wave_is_over() then
            load_wave(data.wave_number + 1)
            data:set_state(States.waveIsComing)

            local player = data.player
            player:set_target_position(16 * 7, 16 * 7)
            player:set_state(Kid.State.preparing)
            player.goingTo_speed = 1.5
        end
        ---
    elseif state == States.waveIsComing then
        if not data.countdown_time
            and data:all_kids_on_position()
        then
            data:start_countdown(3.6)
        end
    end
end

local function update(dt)
    data.time_game = data.time_game + dt
    if data.countdown_time then
        data.countdown_time = data.countdown_time - dt
        if data.countdown_time <= 0 then
            data:start_game()
        end
    end

    data.world:update(dt)
    State:update_game_objects(dt)

    data.displayHP:update(dt)

    game_logic(dt)
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

    font = JM:get_font("pix8")
    font:print(tostring(#State.game_objects), 16, 16 * 4)

    if data:wave_is_over() then
        font:printf("WAVE IS OVER", 0, 16 * 4, SCREEN_WIDTH, "center")
    end
    data.displayHP:draw()

    font:print("<color>LEADER", data.leader.x, data.leader.y - 48)

    do
        local countdown_time = data.countdown_time
        if countdown_time and countdown_time > 0 then
            if countdown_time > 1 then
                font:printf(string.format("WAVE START IN\n%d", data.countdown_time), 0, 16 * 4, SCREEN_WIDTH, "center")
            else
                font:printx("<effect=scream>FIGHT", 0, 16 * 4, SCREEN_WIDTH, "center")
            end
        end
    end
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
