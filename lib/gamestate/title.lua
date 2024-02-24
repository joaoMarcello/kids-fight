local path = ...
local Container = JM.GUI.Container
local Component = JM.GUI.Component

do
    _G.SUBPIXEL = _G.SUBPIXEL or 3
    _G.CANVAS_FILTER = _G.CANVAS_FILTER or 'linear'
    _G.TILE = _G.TILE or 16
end

---@class GameState.Title : JM.Scene
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

---@enum GameState.Title.States
local States = {
    pressToPlay = 1,
    options = 2,                -- play / config / leaderboard / data / quit
    playModes = 3,              -- arcade / coop
    selectDifficultyArcade = 4, -- normal / hard
    selectDifficultyCoop = 5,
    data = 6,
    credits = 7,
}

-- State:set_color(JM_Utils:hex_to_rgba_float("b3f1ff"))
State:set_color(1, 0, 0, 1)
--============================================================================
---@class GameState.Title.Data
local data = {}

local imgs

--============================================================================

function State:__get_data__()
    return data
end

---@type JM.Font.Font|any
local font

---@type JM.Font.Font|any
local font_pix5

local function load()
    font = font or JM:get_font('pix8')
    font_pix5 = font_pix5 or JM:get_font("pix5")

    imgs = imgs or {
        ["chess"] = love.graphics.newImage("/data/img/chess_background.png")
    }

    imgs["chess"]:setFilter("nearest", "nearest")
    --========================================================================
    local Sound = JM.Sound
    Sound:add_sfx("/data/sfx/UI/move up down 01.ogg", "ui-move", 0.25)
    Sound:add_sfx("/data/sfx/UI/back 01.ogg", "ui-back", 0.15)
    Sound:add_sfx("/data/sfx/UI/select 01 sinewave.ogg", "ui-select", 0.25)
    Sound:add_sfx("/data/sfx/UI/select 02 sawtooth.ogg", "ui-select 02", 0.25)
    --========================================================================
    Sound:add_song("/data/song/Quirky-Coin-Op-Games.ogg", "title", 0.35)
end

local function finish()
    if imgs then
        imgs["chess"]:release()
    end
    imgs = nil
    font = nil
    font_pix5 = nil
    JM.Sound:remove_song("title")
end

local BT_WIDTH = TILE * 6
local BT_HEIGHT = TILE

---@param self JM.GUI.Component
local bt_draw = function(self)
    local lgx = love.graphics
    local x, y = self:rect()
    local right, bottom = self.right, self.bottom
    local on_focus = self.on_focus

    if on_focus then
        lgx.setColor(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("f4ffe8")))
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
local bt_gained_focus = function(self)
    -- return self:set_effect_transform("ox", -8)
    self:apply_effect("earthquake", { range_y = 0, duration_x = 0.3, range_x = 5 })
end

---@param self JM.GUI.Component
local bt_lose_focus = function(self)
    -- return self:set_effect_transform("ox", 0)
    self.__effect_manager:clear()
end

local __init__ = {
    [States.options] = function()
        data.container = Container:new {
            x = TILE * 1.5, y = TILE * 2.5, w = 128, h = 180,
            space_vertical = 12,
            on_focus = true,
        }
        data.container:set_type("vertical_list")

        local draw = bt_draw
        local on_focus = bt_gained_focus
        local lose_focus = bt_lose_focus

        data.bt_play = data.bt_play
            or JM.GUI.Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                on_focus = false,
                text = 'Play',
                draw = draw,
            }

        data.bt_leader = data.bt_leader
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                on_focus = false,
                text = 'Leaderboard',
                draw = draw,
            }

        data.bt_config = data.bt_config
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                on_focus = false,
                text = 'Settings',
                draw = draw,
            }

        data.bt_credits = data.bt_credits
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                on_focus = false,
                text = 'About',
                draw = draw,
            }

        data.bt_data = data.bt_data
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                on_focus = false,
                text = 'Data',
                draw = draw,
            }

        data.bt_quit = data.bt_quit
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                on_focus = false,
                text = 'Quit',
                draw = draw,
            }

        data.container:add(data.bt_play)
        -- data.container:add(data.bt_leader)
        -- data.container:add(data.bt_config)
        -- data.container:add(data.bt_data)
        data.container:add(data.bt_credits)
        data.container:add(data.bt_quit)

        for i = 1, data.container.N do
            local obj = data.container:get_obj_at(i)
            obj:set_focus(false)
            obj:on_event("gained_focus", on_focus)
            obj:on_event("lose_focus", lose_focus)
        end
        data.container:get_obj_at(1):set_focus(true)

        -- data.container:switch(1)
    end,
    ---
    [States.playModes] = function()
        data.container = Container:new {
            x = TILE, y = TILE * 2.5, w = 128, h = 180,
            on_focus = true,
            space_vertical = 12,
        }
        data.container:set_type("vertical_list")

        local draw = bt_draw
        local on_focus = bt_gained_focus
        local lose_focus = bt_lose_focus

        data.bt_arcade = data.bt_arcade
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                draw = draw,
                text = "Solo",
            }

        data.bt_coop = data.bt_coop
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                draw = draw,
                text = 'Multiplayer',
            }

        local cont = data.container
        cont:add(data.bt_arcade)
        cont:add(data.bt_coop)
        for i = 1, cont.N do
            local obj = cont:get_obj_at(i)
            obj:set_focus(false)
            obj:on_event("gained_focus", on_focus)
            obj:on_event("lose_focus", lose_focus)
        end
        cont:get_obj_at(1):set_focus(true)
    end,
    ---
    [States.selectDifficultyArcade] = function()
        data.container = Container:new {
            x = TILE, y = TILE * 2.5, w = 128, h = 180,
            on_focus = true,
            space_vertical = 12,
        }
        data.container:set_type("vertical_list")

        local draw = bt_draw
        local gained_focus = bt_gained_focus
        local lose_focus = bt_lose_focus

        data.bt_normal_1 = data.bt_normal_1
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                draw = draw,
                text = 'Normal',
            }
        data.bt_hard_1 = data.bt_hard_1
            or Component:new {
                w = BT_WIDTH, h = BT_HEIGHT,
                draw = draw,
                text = 'Hard',
            }

        local cont = data.container
        cont:add(data.bt_normal_1)
        cont:add(data.bt_hard_1)

        for i = 1, cont.N do
            local obj = cont:get_obj_at(i)
            obj:set_focus(false)
            obj:on_event("gained_focus", gained_focus)
            obj:on_event("lose_focus", lose_focus)
        end
        cont:get_obj_at(1):set_focus(true)
    end,
    ---
    [States.data] = function()
        data.container = nil
    end,
    ---
    [States.credits] = function()
        local font = JM:get_font("pix8")
        font:push()
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("332424")))
        data.credits = data.credits or JM.DialogueSystem:newDialogue("data/credits.md", JM:get_font("pix8"),
            { x = 0, y = 32, w = State.screen_w, update_mode = "by_screen", align = "center" })
        font:pop()

        data.credits_py = SCREEN_HEIGHT --16 * 12
    end
}

---@param new_state GameState.Title.States
function data:switch_state(new_state)
    data.state = new_state
    return __init__[new_state]()
end

local function init(args)
    data.state = args and args.state or States.pressToPlay

    local px, py = 0, 0

    data.layers = {
        [1] = State:newLayer {
            infinity_scroll_x = true,
            infinity_scroll_y = true,
            width = imgs["chess"]:getWidth(),   -- 64
            height = imgs["chess"]:getHeight(), --64
            -- factor_x = 0.5,
            -- factor_y = 0.5,
            ---
            update = function(self, dt)
                px = px - 16 * dt
                py = py + 16 * dt
                self.px = JM_Utils:round(px) -- * self.factor_x
                self.py = JM_Utils:round(py) -- * self.factor_y
            end,
            draw = function(cam)
                local lgx = love.graphics
                -- lgx.setColor(JM_Utils:hex_to_rgba_float("d1dbf2"))
                -- lgx.rectangle("fill", 0, 0, 32, 32)
                -- lgx.rectangle("fill", 32, 32, 32, 32)
                -- lgx.setColor(JM_Utils:hex_to_rgba_float("e9e8ff"))
                -- lgx.rectangle("fill", 32, 0, 32, 32)
                -- lgx.rectangle("fill", 0, 32, 32, 32)

                lgx.setColor(1, 1, 1)
                lgx.draw(imgs["chess"])
            end
        },
        ---
        ---
    }

    _G.Play_song("title")
    -- JM.Sound:fade_in()
end

local function textinput(t)

end

local function go_to_how_to_play()
    if not State.transition then
        -- JM.Sound:fade_out()
        -- JM.Sound:stop_all()

        return State:add_transition("fade", "out", { duration = 1, post_delay = 0.1 }, nil, function(self)
            self:change_gamestate(require "lib.gamestate.howToPlay",
                {
                    unload = path,
                })

            ---@diagnostic disable-next-line: cast-local-type
            data = nil
            JM:flush()
        end)
    end
end

local __keypressed__ = {
    [States.pressToPlay] = function(self, key)
        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        P1:switch_to_keyboard()

        if P1:pressed(Button.start, key)
            or P1:pressed(Button.A, key)
            or P1:pressed(Button.B, key)
        then
            -- -- return go_to_how_to_play()
            -- data.state = States.options
            -- return __init__[data.state]()
            _G.Play_sfx("ui-select", true)
            return data:switch_state(States.options)
        end
    end,
    ---
    [States.options] = function(self, key)
        if State.transition then return end

        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        P1:switch_to_keyboard()

        if P1:pressed(Button.dpad_up, key) then
            _G.Play_sfx("ui-move", true)
            return data.container:switch_up()
        elseif P1:pressed(Button.dpad_down, key) then
            _G.Play_sfx("ui-move", true)
            return data.container:switch_down()
        end

        if P1:pressed(Button.dpad_right, key) then
            return self[States.options](self, 'space')
        end

        if P1:pressed(Button.B, key) then
            local obj = data.container:get_cur_obj()
            if obj ~= data.bt_quit then
                _G.Play_sfx("ui-move", true)
                return data.container:switch(data.container.N)
            else
                return State:keypressed('space', 'space')
            end
        end

        if P1:pressed(Button.A, key)
            or P1:pressed(Button.start, key)
        then
            local obj = data.container:get_obj_at(data.container.num)

            if obj ~= data.bt_leader then
                _G.Play_sfx("ui-select", true)
            end

            if obj == data.bt_leader then
                if not State.transition then
                    _G.Play_sfx('ui-select 02')

                    return State:add_transition("sawtooth", "out",
                        { duration = 0.75, type = "right-left", post_delay = 0.2 }, nil,
                        function(self)
                            return self:change_gamestate(require "lib.gamestate.mlrs", {
                                skip_finish = true,
                                transition = "sawtooth",
                                transition_conf = {
                                    duration = 0.5,
                                    type = "right-left",
                                }
                            })
                        end)
                end
                ---
            elseif obj == data.bt_play then
                JM.Sound:stop_all()
                _G.Play_sfx("ui-select 02", true)
                return go_to_how_to_play()
                ---
            elseif obj == data.bt_quit then
                return JM:exit_game()
            elseif obj == data.bt_data then
                return data:switch_state(States.data)
            elseif obj == data.bt_credits then
                return data:switch_state(States.credits)
            end
            ---
        end
    end,
    ---
    [States.playModes] = function(self, key)
        if State.transition then return end

        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        P1:switch_to_keyboard()

        if P1:pressed(Button.dpad_up, key) then
            _G.Play_sfx("ui-move", true)
            return data.container:switch_up()
            ---
        elseif P1:pressed(Button.dpad_down, key) then
            _G.Play_sfx("ui-move", true)
            return data.container:switch_down()
            ---
        end

        if P1:pressed(Button.dpad_left, key)
            or P1:pressed(Button.B, key)
        then
            _G.Play_sfx("ui-back", true)
            return data:switch_state(States.options)
            ---
        elseif P1:pressed(Button.dpad_right, key) then
            return self[States.playModes](self, 'space')
            ---
        end

        if P1:pressed(Button.A, key)
            or P1:pressed(Button.start, key)
        then
            _G.Play_sfx("ui-select", true)
            local obj = data.container:get_cur_obj()

            if obj == data.bt_arcade then
                return data:switch_state(States.selectDifficultyArcade)
                ---
            elseif obj == data.bt_coop then
                ---
            end
        end
    end,
    ---
    [States.selectDifficultyArcade] = function(self, key)
        if State.transition then return end

        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        P1:switch_to_keyboard()

        if P1:pressed(Button.dpad_up, key) then
            _G.Play_sfx("ui-move", true)
            return data.container:switch_up()
        elseif P1:pressed(Button.dpad_down, key) then
            _G.Play_sfx("ui-move", true)
            return data.container:switch_down()
        end

        if P1:pressed(Button.dpad_left, key)
            or P1:pressed(Button.B, key)
        then
            _G.Play_sfx("ui-back", true)
            return data:switch_state(States.playModes)
            ---
        elseif P1:pressed(Button.dpad_right, key) then
            return self[States.selectDifficultyArcade](self, 'space')
            ---
        end

        if P1:pressed(Button.A, key)
            or P1:pressed(Button.start, key)
        then
            JM.Sound:stop_all()
            _G.Play_sfx("ui-select 02", true)

            local obj = data.container:get_cur_obj()
            if obj == data.bt_hard_1 then
                return go_to_how_to_play()
                ---
            elseif obj == data.bt_normal_1 then
                return go_to_how_to_play()
                ---
            end
        end
    end,
    ---
    [States.data] = function(self, key)
        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        P1:switch_to_keyboard()

        if P1:pressed(Button.B, key)
            or P1:pressed(Button.dpad_left, key)
        then
            _G.Play_sfx("ui-back", true)
            data:switch_state(States.options)
            return data.container:switch_to_obj(data.bt_data)
        end
    end,
    ---
    [States.credits] = function(self, key)
        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        P1:switch_to_keyboard()

        if P1:pressed(Button.B, key)
            or P1:pressed(Button.dpad_left, key)
        then
            _G.Play_sfx("ui-back", true)
            data:switch_state(States.options)
            return data.container:switch_to_obj(data.bt_credits)
        end
    end,
}

local function keypressed(key)
    if State.transition then return end
    if key == 'o' then
        State.camera:toggle_grid()
        State.camera:toggle_world_bounds()
    end

    return __keypressed__[data.state](__keypressed__, key)
end

local function keyreleased(key)

end

local function mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        return State:keypressed('return', 'return')
    elseif button == 2 then
        return State:keypressed('escape', 'escape')
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

    if P1:pressed(Button.dpad_left, joystick, button) then
        return State:keypressed('left', 'left')
    elseif P1:pressed(Button.dpad_right, joystick, button) then
        return State:keypressed('right', 'right')
    end

    if P1:pressed(Button.start, joystick, button)
        or P1:pressed(Button.A, joystick, button)
    then
        return State:keypressed('space', 'space')
    end

    if P1:pressed(Button.B, joystick, button) then
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

    local x_axis = P1:pressed(Button.left_stick_x, joystick, axis, value)

    if x_axis == 1 then
        return State:keypressed('right', 'right')
    elseif x_axis == -1 then
        return State:keypressed('left', 'left')
    end
end

local resize = function(w, h)
    return _G.RESIZE(State, w, h)
end

local function update(dt)
    data.layers[1]:update(dt)

    if data.container then
        data.container:update(dt)
    end

    if data.credits and data.state == States.credits then
        for i = 1, data.credits.n_boxes do
            ---@type JM.GUI.TextBox
            local box = data.credits.boxes[i]
            box:update(dt)
        end

        local P1 = JM.ControllerManager.P1
        local Button = P1.Button
        local speed = 16
        P1:switch_to_keyboard()
        if P1:pressing(Button.A)
            or (P1:switch_to_joystick()
                and (P1:pressing(Button.A)
                    or P1:pressing(Button.dpad_down)
                    or P1:pressing(Button.left_stick_y) ~= 0))
        then
            speed = 48
        end
        data.credits_py = data.credits_py - speed * dt
    end
end

local __draw__ = {
    [States.pressToPlay] = function(self, cam)
        font:push()
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("334266")))
        font:printx("<effect=ghost, min=0.1, max=1.15>Press [enter] to play", 0, 16 * 7, SCREEN_WIDTH,
            "center")

        font:printf("©2024, JM", 0, 16 * 9, SCREEN_WIDTH, "center")

        love.graphics.setColor(JM_Utils:hex_to_rgba_float("998e79"))
        love.graphics.ellipse("fill", SCREEN_WIDTH * 0.5 + 1, 16 * 2 + 16 + 4 + 2, 64, 32)
        love.graphics.setColor(1, 1, 1)
        love.graphics.ellipse("fill", SCREEN_WIDTH * 0.5, 16 * 2 + 16 + 4, 64, 32)

        font:set_font_size(18)
        font:printf("KIDS\nFIGHT", 0, 16 * 2, SCREEN_WIDTH, "center")

        font:pop()
    end,
    ---
    [States.options] = function(self, cam)
        data.container:draw(cam)
    end,
    ---
    [States.playModes] = function(self, cam)
        font:push()
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("242833")))
        font:print("Select Mode:", TILE, TILE)
        font:pop()
        data.container:draw(cam)
    end,
    ---
    [States.selectDifficultyArcade] = function(self, cam)
        font:push()
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("242833")))
        font:print("Select difficulty:", TILE, TILE)
        font:pop()

        data.container:draw(cam)
    end,
    ---
    -- [States.data] = function(self, cam)
    --     local tile = _G.TILE
    --     local h, m, s = unpack(SAVE_DATA.total_time)
    --     local color = JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("332424"))
    --     local left = tile * 2

    --     font:push()
    --     font:set_color(color)
    --     local px, py = font:print(string.format("Playtime:\t%02d:%02d:%02d", h, m, s), left, tile)

    --     px, py = font:print(string.format("Hi-score:\t%d", SAVE_DATA.hi_score), left, py + tile)

    --     px, py = font:print(string.format("Total matches:\t%d", SAVE_DATA.total_match), left, py + tile)

    --     px, py = font:print(string.format("Total finished matches:\t%d", SAVE_DATA.total_finished_match), left, py + tile)

    --     px, py = font:print(string.format("Fish eated:\t%d", SAVE_DATA.player_data[1].fish_eated), left, py + tile)

    --     px, py = font:print(string.format("Fish hitted:\t%d", SAVE_DATA.player_data[1].hit_count), left, py + tile)

    --     px, py = font:print(string.format("Poison Fish hitted:\t%d", SAVE_DATA.player_data[1].poison_hit_count), left,
    --         py + tile)

    --     px, py = font:print(string.format("Total heart:\t%d", SAVE_DATA.player_data[1].heart_count), left, py + tile)

    --     font:pop()
    -- end,
    ---
    ---@param cam JM.Camera.Camera
    [States.credits] = function(self, cam)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", SCREEN_WIDTH * 0.5 - 16 * 3, 0, 16 * 6, 16 * 4)

        local sx, sy, sw, sh = love.graphics.getScissor()

        love.graphics.setScissor(
            cam:scissor_transform(0, 16 * 4.25, SCREEN_WIDTH, SCREEN_HEIGHT - (16 * 4.25), State.subpixel)
        )

        local list = data.credits.boxes
        local py = math.floor(data.credits_py + 0.5)
        -- local py = data.credits_py

        for i = 1, data.credits.n_boxes do
            ---@type JM.GUI.TextBox
            local box = list[i]

            -- box.y = math.floor(py + 0.5)
            box.y = py
            box:draw(cam)
            py = py + box.h + 16
        end

        do
            font:push()
            font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("332424")))
            font:printf("Copyright, ©2024. `#334266`Kids Fight`#-`, by `#000000`JM`#-`.<br>All rights reserved.", 0,
                math.max(py + 16, 16 * 6), SCREEN_WIDTH, "center")

            if py < 16 * 4.25 then
                font:print("[esc] Back", 16, TILE * 9.5)
            end
            font:pop()
        end

        love.graphics.setScissor(sx, sy, sw, sh)
    end
}

---@param cam JM.Camera.Camera
local function draw(cam)
    data.layers[1].angle = -math.pi * 0.015
    data.layers[1]:draw(cam)

    local color = JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("334266"))
    local state = data.state

    if state ~= States.pressToPlay
        and state ~= States.data
        and state ~= States.credits
    then
        font:push()
        font:set_color(color)
        font:printf("[up/down] move\t [space] select\t [esc] back", 8, TILE * 10, SCREEN_WIDTH, "center")
        font:pop()

        local font = FONT_THALEAH
        font:push()
        font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("334266")))
        font:printf('Select an option:', 24, 16, SCREEN_WIDTH, "left")
        font:pop()
        ---
    elseif state ~= States.data
        and state ~= States.credits
    then
        font_pix5:push()
        font_pix5:set_color(color)
        font_pix5:printf(string.format("%s %s", "version ", "1.0.0"), 0, 16 * 10, SCREEN_WIDTH - 16, "right")
        font_pix5:pop()
    end

    -- local font = _G.FONT_THALEAH
    -- font:print("teste", 16, 16)
    return __draw__[data.state](__draw__, cam)
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
