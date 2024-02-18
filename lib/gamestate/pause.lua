local path = ...

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class GameState.Pause : JM.Scene
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

State:set_color(JM.Utils:hex_to_rgba_float("242833"))

--============================================================================
---@class GameState.Pause.Data
local data = {}

function data:unpause()
    local audio = JM.Sound:get_current_song()
    if audio then
        audio:set_volume()
    end
    return State:change_gamestate(State.prev_state, {
        skip_finish = true,
        skip_transition = true,
        skip_init = true,
        skip_load = true
    })
end

function data:restart()
    if not State.transition then
        JM.Sound:stop_all()

        ---@type GameState.Game.Data
        local data_ = State.prev_state:__get_data__()

        State:add_transition("door", "out", { duration = 0.8, axis = "y", pause_scene = true, post_delay = 0.1 }, nil,
            function()
                State:change_gamestate(State.prev_state, {
                    -- skip_finish = true,
                    skip_load = true,

                    trans_end_action = function()
                        data_.play_song()
                    end,

                    transition = "door",
                    transition_conf = {
                        -- delay = 0.2,
                        duration = 0.75,
                        axis = "x",
                        pause_scene = true,
                    }
                })
                JM.Sound:stop_all()
                JM:flush()
            end)
    end
end

local function func(State)
    State:change_gamestate(require "lib.gamestate.title", {
        unload = path,
        transition = "sawtooth",
        transition_conf = { axis = "y", type = "bottom-top", duration = 0.5, segments = 10, len = 24 }
    })

    ---@diagnostic disable-next-line: cast-local-type
    data = nil

    JM:flush()
end

function data:go_to_title()
    if not State.transition then
        JM.Sound:stop_all()

        return State:add_transition("sawtooth", "out",
            { axis = "y", type = "bottom-top", duration = 0.75, post_delay = 0.2, segments = 10, len = 24 },
            nil, func)
    end
end

--============================================================================

function State:__get_data__()
    return data
end

local function load()

end

local function finish()
    if data.extra_canvas then
        data.extra_canvas:release()
        data.extra_canvas = nil
    end
    for k, v in next, data do
        if type(v) == "table" then
            data[k] = nil
        end
    end
end

local BT_WIDTH = TILE * 5
local BT_HEIGHT = TILE

---@param self JM.GUI.Component
local bt_draw = function(self)
    local lgx = love.graphics
    local x, y = self:rect()
    local right, bottom = self.right, self.bottom
    local on_focus = self.on_focus
    local font = JM:get_font("pix8")

    if on_focus then
        lgx.setColor(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("664433")))
    else
        lgx.setColor(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("664433")))
    end
    lgx.polygon("fill",
        x + 4 + 2, y + 2,
        right + 1, y + 2,
        right - 4 + 1, bottom + 2,
        x + 2, bottom + 2
    )

    if on_focus then
        lgx.setColor(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("d96c21")))
    else
        lgx.setColor(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("99752e")))
    end
    lgx.polygon("fill",
        x + 4, y,
        right, y,
        right - 4, bottom,
        x, bottom
    )

    font:push()
    if on_focus then
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("f4ffe8")))
    else
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("bfbf91")))
    end
    font:printf(self.text, self.x - 32, self.y + (self.h - font.__font_size - font.__line_space) * 0.5,
        self.w + 64, "center")
    font:pop()
end

---@param self JM.GUI.Component
local gained_focus = function(self)
    self:apply_effect("earthquake", { range_y = 0, duration_x = 0.3, range_x = 5 })
end

---@param self JM.GUI.Component
local lose_focus = function(self)
    return self.__effect_manager:clear()
end

local function init(args)
    data.capture = false

    data.extra_canvas = data.extra_canvas or State.create_canvas(State)

    do
        data.container = JM.GUI.Container:new {
            x = TILE * 5, y = TILE * 3.5, w = TILE * 10, h = TILE * 5.5,
            on_focus = true,
            show_bounds = false,
            skip_scissor = true,
        }
        data.container:set_type("vertical_list")

        data.bt_resume = data.bt_resume
            or JM.GUI.Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                text = "Resume",
                draw = bt_draw,
            }

        data.bt_restart = data.bt_restart
            or JM.GUI.Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                text = "Restart",
                draw = bt_draw,
            }

        data.bt_quit = data.bt_quit
            or JM.GUI.Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                text = "Quit",
                draw = bt_draw,
            }

        local cont = data.container
        cont:add(data.bt_resume)
        cont:add(data.bt_restart)
        cont:add(data.bt_quit)
        for i = 1, cont.N do
            local obj = cont:get_obj_at(i)
            obj:set_focus(false)
            obj:on_event("gained_focus", gained_focus)
            obj:on_event("lose_focus", lose_focus)
        end
        cont:get_cur_obj():set_focus(true)
    end


    local SceneLayer = require "jm-love2d-package.modules.jm_scene_layer"
    data.layers = {
        SceneLayer:new(State, {
            factor_x = 0,
            factor_y = 0,

            draw = function(cam)
                if data.capture then
                    local game = State.prev_state
                    love.graphics.setColor(0.6, 0.6, 0.7, 1)
                    love.graphics.draw(game.canvas, 0, 0, 0, 1 / State.subpixel)
                end
            end
        })
    }
end

local function textinput(t)

end

local function keypressed(key)
    if State.transition then return end

    local P1 = JM.ControllerManager.P1
    local Button = P1.Button
    P1:switch_to_keyboard()

    if P1:pressed(Button.dpad_up, key) then
        return data.container:switch_up()
    elseif P1:pressed(Button.dpad_down, key) then
        return data.container:switch_down()
    end

    if P1:pressed(Button.B, key) then
        data.container:switch(1)
        return State:keypressed('space', 'space')
    end

    if P1:pressed(Button.start, key)
        or P1:pressed(Button.A, key)
    then
        local cur_bt = data.container:get_cur_obj()

        if cur_bt == data.bt_resume then
            return data:unpause()
        elseif cur_bt == data.bt_restart then
            return data:restart()
        elseif cur_bt == data.bt_quit then
            return data:go_to_title()
        end
    end

    if key == 'o' then
        if love.keyboard.isDown("lctrl") then
            State.show_info = not State.show_info
        else
            State.camera:toggle_grid()
            State.camera:toggle_world_bounds()
        end
    end
end

local function keyreleased(key)

end

local function mousepressed(x, y, button, istouch, presses)
    if button == 2 then
        return State:keypressed('escape', 'escape')
    elseif button == 1 then
        return State:keypressed('space', 'space')
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

    if P1:pressed(Button.dpad_up, joystick, button) then
        return State:keypressed('up', 'up')
    elseif P1:pressed(Button.dpad_down, joystick, button) then
        return State:keypressed('down', 'down')
    end

    if P1:pressed(Button.A, joystick, button) then
        return State:keypressed('space', 'space')
    end

    if P1:pressed(Button.B, joystick, button)
        or P1:pressed(Button.start, joystick, button)
    then
        return State:keypressed('escape', 'escape')
    end
end

local function gamepadreleased(joystick, button)

end

local function gamepadaxis(joystick, axis, value)
    local P1 = JM.ControllerManager.P1
    local Button = P1.Button

    local y_axis = P1:pressed(Button.left_stick_y, joystick, axis, value)
    if y_axis == -1 then
        return State:keypressed('up', 'up')
    elseif y_axis == 1 then
        return State:keypressed('down', 'down')
    end
end

local resize = function(w, h)
    return _G.RESIZE(State, w, h)
end

local function update(dt)
    data.container:update(dt)
end

---@type love.Shader|nil
local blur
if not _G.WEB then
    blur = JM.Shader:get_exclusive_shader("boxblur", State)
    blur:send("radius", 1.0)
end

local shaders = { blur, blur }
local dir = { 1, 0 }
local shader_action = function(shader, n)
    if shader == blur then
        if n == 1 then
            dir[1] = 1 / (State.screen_w)
            dir[2] = 0
        else
            dir[1] = 0
            dir[2] = 1 / (State.screen_h)
        end
        shader:send("direction", dir)
    end
end

---@param cam JM.Camera.Camera
local function draw(cam)
    ---@type JM.Scene
    local game = State.prev_state
    if game then
        if not data.capture then
            game:draw_capture(State, cam, 0, 0, 0, 1, 1)
            data.capture = true
        else
            local layer = data.layers[1]
            if blur then
                layer:set_shader(shaders, shader_action)
            end
            layer:draw(cam, State.canvas_layer, data.extra_canvas, State.canvas)
        end
    end

    local TILE = TILE
    local Utils = JM_Utils
    local lgx = love.graphics
    local x, y, w, h = TILE * 5, TILE * 1.5, TILE * 10, TILE * 9
    lgx.setColor(JM_Utils:hex_to_rgba_float("665c57"))
    lgx.rectangle("fill", x, y + 4, w, h, 2, 2)
    lgx.setColor(JM_Utils:hex_to_rgba_float("eef2d1"))
    lgx.rectangle("fill", x, y, w, h, 2, 2)

    local line_width = lgx.getLineWidth()
    lgx.setLineWidth(2)
    lgx.setColor(JM_Utils:hex_to_rgba_float("e6c45c"))
    lgx.rectangle("line", x, y, w, h, 2, 2)
    lgx.setLineWidth(line_width)

    cam:detach()
    local font = JM:get_font()
    font:push()
    font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("d96c21")))
    font:printx("<effect=wave>PAUSE", 0, 32, State.screen_w, "center")
    font:pop()
    -- love.graphics.setColor(1, 1, 0)
    -- love.graphics.printf("PAUSE", 0, State.screen_h * 0.15, State.screen_w, "center")
    cam:attach(nil, State.subpixel)

    return data.container:draw(cam)
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
    draw = draw
}

return State
