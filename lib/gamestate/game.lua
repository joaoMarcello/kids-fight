local path = ...
local JM = _G.JM
local Kid = require "lib.object.kid"
local DisplayHP = require "lib.object.displayHP_game"
local Timer = require "lib.object.timer"
local Particles = require "lib.particles"


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
    preparingToTalk = 6,
    finishFight = 7,
    countDown = 8,
    endGame = 9,
}

State:set_color(JM_Utils:hex_to_rgba_float("3dbf26"))
local imgs
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

function data:all_kids_are_on_position()
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

    for i = #list, 1, -1 do
        ---@type Kid
        local k = list[i]

        if k ~= self.leader or send_leader then
            k:set_state(Kid.State.runAway)
            table.remove(list, i)
        end
    end
end

function data:start_countdown(init)
    self.countdown_time = init or 1
    Play_song("game", true)

    local audio = JM.Sound:get_current_song()
    if audio then audio:set_volume() end

    -- if State:is_current_active() then
    --     JM.Sound:fade_in()
    -- end
end

function data:start_game()
    if self.countdown_time and self.countdown_time <= 0
        and self:all_kids_are_on_position()
    then
        self:unlock_kids()
        self.countdown_time = nil
        self:set_state(States.game)
        return true
    end
    return false
end

function data:wave_is_over(check_on_ground)
    local list = self.kids
    if not list then return false end

    local c = 0
    local N = #list
    for i = 1, N do
        ---@type Kid
        local k = list[i]
        if k:is_dead()
            and ((check_on_ground and not k.is_jump) or not check_on_ground)
        then
            c = c + 1
        end
    end
    return c == N
end

---@param file_name string # the dialogue file directory
---@return JM.DialogueSystem.Dialogue dialogue # The Dialogue object
function data:load_dialogue(file_name)
    return JM.DialogueSystem:newDialogue(file_name, JM:get_font("pix8"),
        {
            align = "center",
            w = 16 * 8,
            n_lines = 2,
            text_align = 3,
            time_wait = 0.1,
            glyph_sfx = "glyph bip",
            finish_sfx = "box end"
        })
end

---@param new_state GameState.Game.States
function data:set_state(new_state)
    if new_state == self.gamestate then return false end
    self.gamestate = new_state
    self.time_gamestate = 0.0
    self.dialogue = nil

    if new_state == States.dialogue then
        self.dialogue = self:load_dialogue(
            string.format("/data/dialogue_%d.md", data.wave_number)
        )
        ---
    elseif new_state == States.endGame then
        local audio = JM.Sound:get_current_song()
        if audio then audio.source:stop() end
        ---
    elseif new_state == States.game then
        -- Play_song("game", true)
    elseif new_state == States.finishFight then
        local audio = JM.Sound:get_current_song()
        if audio then audio.source:stop() end
    end

    return true
end

---@param cam JM.Camera.Camera
function data:draw_dialogue(cam)
    local dialogue = data.dialogue
    if not dialogue or not dialogue.is_visible then return end

    local lgx = love.graphics
    local id = dialogue:get_id()
    local box = dialogue:get_cur_box()
    local speaker = id:match("bully") and data.leader or data.player

    -- local g, w, final = box:get_current_glyph()
    -- if w and w.text == "<void>" and not final then return end
    if not box.is_visible then return end

    box.x = speaker.x + speaker.w * 0.5 - dialogue.w * 0.5
    box.y = speaker.y - 52 - dialogue.h

    lgx.setColor(1, 1, 1)
    lgx.draw(imgs["balloon"], data.quad_balloon, box.x - 1, box.y)

    if speaker == data.leader then
        lgx.draw(imgs["balloon"], data.quad_balloon_tail, box.x + 40, box.y + box.h, 0, -1, 1, 16, 0)
    else
        lgx.draw(imgs["balloon"], data.quad_balloon_tail, box.x + 64, box.y + box.h, 0, 1, 1, 0, 0)
    end

    dialogue:draw(cam)

    if box:screen_is_finished() then
        local font = JM:get_font("pix8")
        font:printx("<color-hex=#334266><effect=float, speed=1, range=1, pixelmode=true>:arw_dw:", box.x + box.w + 1,
            box.y + dialogue.h - 12)
    end
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

local function load()
    local font = JM:get_font("pix8")
    font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("242833")))

    local font = JM:get_font("pix5")
    font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("242833")))

    Kid:load()
    DisplayHP:load()
    Timer:load()

    local lgx = love.graphics
    imgs = imgs or {
        ["field"] = lgx.newImage("/data/img/background.png"),
        ["street_down"] = lgx.newImage("/data/img/back_down.png"),
        ["street_up"] = lgx.newImage("/data/img/back_up.png"),
        ["box"] = lgx.newImage("/data/img/box_gui.png"),
        ["balloon"] = lgx.newImage("/data/img/balloon.png"),
    }

    local Sound = JM.Sound
    Sound:add_sfx("/data/sfx/pause 01.ogg", "pause", 1)
    Sound:add_sfx("/data/sfx/219650__curly_hikari_94__scream_girl1.wav", "girl screaming", 0.1)
    Sound:add_sfx("/data/sfx/wrong-47985.ogg", "atk fail", 0.25)
    Sound:add_sfx("/data/sfx/throw_stone.ogg", "throw stone", 0.1)
    Sound:add_sfx("/data/sfx/triqystudio__dropitem.ogg", "slap")
    Sound:add_sfx("/data/sfx/heart up 01 square.ogg", "heart up", 0.25)
    Sound:add_sfx("/data/sfx/blippy-31899 (mp3cut.net) 3.ogg", "blip dying", 0.5)
    Sound:add_sfx("/data/sfx/pixel-death-66829.ogg", "game over", 1)
    Sound:add_sfx("/data/sfx/kid jump 01 square.wav", "jump", 0.2)
    Sound:add_sfx("/data/sfx/kid jump 02 sine.wav", "jump 2", 0.25)
    Sound:add_sfx("/data/sfx/success_bell-6776.ogg", "victory", 1)
    Sound:add_sfx("/data/sfx/UI/textbox 01 square.ogg", "glyph bip", 0.25)
    Sound:add_sfx("/data/sfx/UI/textbox end 02.wav", "box end", 0.15)
    Sound:add_sfx("/data/sfx/footstep06.ogg", "footstep 01", 0.25)
    Sound:add_sfx("/data/sfx/fist-punch-or-kick-7171.ogg", "foe hit", 0.75)
    Sound:add_sfx("/data/sfx/404747__owlstorm__retro-video-game-sfx-ouch.wav", "player damage", 0.75)
    Sound:add_sfx("/data/sfx/678385__deltacode__item-pickup-v2.wav", "pickup", 0.35)
    Sound:add_sfx("/data/sfx/344696__scrampunk__charm.ogg", "new record", 0.75)

    --==============================================================
    Sound:add_song("/data/song/More-Coin-Op-Chaos.ogg", "game", 0.35)
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

    JM.Sound:remove_song("game")
end

local function load_wave(value)
    value = value or 1
    data.wave_number = value
    data:set_state(States.waveIsComing)

    if State:is_current_active() and not State:is_showing_black_bar() then
        State:show_black_bar(16)
    end

    data.kids = {}

    if data.leader then
        data.leader:ressurect()
    end

    ---@type Kid
    local k = data.leader or State:add_object(Kid:new(SCREEN_WIDTH, 16 * 7, Kid.Gender.boy, -1, true, 2, 2))

    if k.state ~= Kid.State.idle then
        k:set_position(SCREEN_WIDTH, 16 * 7)
        k:set_target_position(16 * 12)
        k:set_state(k.State.preparing)
    end
    k.time_move_y = 0.0
    k.anchor_y = 16 * 7
    k.goingTo_speed = 1.5
    k.time_jump = 0.0
    table.insert(data.kids, k)
    data.leader = k

    if value == 1 then
        local leader = k
        leader:set_hp(3)
            :set_delay(2)
        leader.time_throw = 0.0
        data.leader.goingTo_speed = 1.5
        data.leader.time_state = 0.45
        ---
    elseif value == 2 then
        ---@type Kid
        k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3, 3))
        k:set_position(SCREEN_WIDTH, 16 * 9)
        k:set_target_position(16 * 14, 16 * 9)
        k:set_state(k.State.preparing)
        k:set_hp(4)
        k.goingTo_speed = 1.5
        k.anchor_y = 16 * 9 - k.move_y_value
        k.time_move_y = math.pi * 0.5
        k.anchor_x = 16 * 14
        k.time_move_x = 0.0
        table.insert(data.kids, k)
        ---
    elseif value == 3 then
        local leader = data.leader
        leader:set_hp(4)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3, 4))
        k:set_position(SCREEN_WIDTH, 16 * 9)
        k:set_target_position(16 * 15.5, 16 * 9)
        k:set_state(Kid.State.preparing)
        k:set_hp(3)
        k:set_delay(0.75)
        k.goingTo_speed = 1.5
        k.anchor_y = 16 * 9 - k.move_y_value
        k.time_move_y = math.pi * 0.5
        k.anchor_x = 16 * 15.5
        k.time_move_x = 0.0
        table.insert(data.kids, k)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 4, 16 * 5, Kid.Gender.boy, -1, true, 2, 5))
        k:set_position(SCREEN_WIDTH, 16 * 5)
        k:set_target_position(16 * 15, 16 * 5)
        k:set_state(Kid.State.preparing)
        k:set_hp(3)
        k.goingTo_speed = 1.5
        k.anchor_y = 16 * 4 + k.move_y_value
        k.time_move_y = -math.pi * 0.5
        table.insert(data.kids, k)
        ---
    else
        local leader = data.leader
        leader:set_hp(5)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 12, 16 * 4, Kid.Gender.boy, -1, true, 2, 5))
        k:set_position(SCREEN_WIDTH, 16 * 7.5)
        k:set_target_position(16 * 18, 16 * 7.5)
        k:set_state(k.State.preparing)
        k:set_hp(3)
        k:set_delay(1)
        k.goingTo_speed = 1.5
        k.is_visible = false
        k.time_delay = 0.5
        table.insert(data.kids, k)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 15, 16 * 9, Kid.Gender.boy, -1, true, 3, 4))
        k:set_position(SCREEN_WIDTH, 16 * 9)
        k:set_target_position(16 * 14.5, 16 * 9)
        k:set_state(k.State.preparing)
        k:set_hp(4)
        k:set_delay(3)
        k.goingTo_speed = 1.5
        k.anchor_y = 16 * 9 - k.move_y_value
        k.time_move_y = math.pi * 0.5
        k.anchor_x = 16 * 14.5
        k.is_visible = false
        k.time_delay = 0.25
        k.time_move_x = 0.0
        table.insert(data.kids, k)

        ---@type Kid
        k = State:add_object(Kid:new(16 * 17, 16 * 5, Kid.Gender.boy, -1, true, 1, 3))
        k:set_position(SCREEN_WIDTH, 16 * 5)
        k:set_target_position(16 * 16.5, 16 * 5)
        k:set_state(k.State.preparing)
        k:set_hp(3)
        k.goingTo_speed = 1
        k.anchor_y = 16 * 5 + k.move_y_value
        k.time_move_y = -math.pi * 0.5
        table.insert(data.kids, k)
        ---
    end
end

function data:load_wave(value)
    return load_wave(value)
end

local function init(args)
    args = args or {}
    State:remove_black_bar(true)
    -- State.camera.x = 0
    -- State.camera.y = 0

    data.time_game = 0
    data.time_gamestate = 0.0
    data.time_gameover = 60 * 4
    data.time_gc = 0.0
    data.death_count = 0

    data.quad_clock = data.quad_clock
        or love.graphics.newQuad(32, 0, 16, 16, Particles.IMG:getDimensions())

    data.quad_balloon = data.quad_balloon
        or love.graphics.newQuad(0, 0, 16 * 9, 32, imgs["balloon"]:getDimensions())
    data.quad_balloon_tail = data.quad_balloon_tail
        or love.graphics.newQuad(16 * 9, 0, 32, 16, imgs["balloon"]:getDimensions())

    data.countdown_time = nil
    ---@type JM.DialogueSystem.Dialogue|any
    data.dialogue = nil

    data.world = JM.Physics:newWorld { tile = TILE }
    JM.GameObject:init_state(State, data.world)
    JM.ParticleSystem.time_to_flush = math.huge
    JM.ParticleSystem:init_module(data.world, State)

    State.game_objects = {}

    data.player = Kid:new(16 * 7, 16 * 7, 1)
    data.player:set_position(-50, 16 * 7)
    data.player:set_state(Kid.State.preparing)
    if State:is_current_active() then
        data.player.goingTo_speed = 3
        data.player.time_delay = 0.2
        data.player.is_visible = false
    end

    State:add_object(data.player)

    JM.Physics:newBody(data.world, 0, 0, SCREEN_WIDTH, 16 * 3, "static")
    JM.Physics:newBody(data.world, 0, SCREEN_HEIGHT - 16, SCREEN_WIDTH, 16, "static")

    data.leader = nil
    data.wave_number = args.wave_number or 1
    load_wave(data.wave_number)

    data.displayHP = DisplayHP:new(data.player)
    data.timer = Timer:new(0.0)

    data:set_state(States.waveIsComing)
end

local function textinput(t)

end

local function keypressed(key)
    if State.transition then return end

    -- if key == 'c' and love.keyboard.isDown('lctrl') then
    --     return JM:toggle_capture_mode {
    --         id = tostring(os.time()),
    --         frameskip = 1,
    --         duration = 20.0,
    --     }
    -- end

    -- if key == 'o' then
    --     State.camera:toggle_grid()
    --     State.camera:toggle_world_bounds()
    -- end

    local P1 = data.player.controller
    local Button = P1.Button
    P1:switch_to_keyboard()
    local state = data.gamestate

    -- condition to skip cutscene
    if state ~= States.game
        and state ~= States.finishFight
        and state ~= States.endGame
        and P1:pressed(Button.start, key)
        and not data.countdown_time
    then
        JM.Sound:fade_out()

        State:add_transition("door", "out",
            {
                axis = "y",
                duration = 1,
                post_delay = 0.3
            },

            nil,

            ---@param State JM.Scene
            function(State)
                data:skip_intro()
                JM.Sound:fade_in(0.01)
                State:add_transition("door", "in",
                    { axis = "y", duration = 0.5, pause_scene = false }
                )
            end
        )

        return
    end



    do
        local dialogue = data.dialogue

        if dialogue
            and (P1:pressed(Button.A, key)
                or P1:pressed(Button.dpad_right, key)
                or P1:pressed(Button.X))
        then
            if dialogue:finished() and dialogue.is_visible then
                if data.gamestate ~= States.endGame then
                    dialogue.flush()
                    data.dialogue = nil
                    data:start_countdown(4)
                    State:remove_black_bar()
                    ---
                else
                    data.time_gamestate = 0.0
                    data.dialogue.is_visible = false
                end

                JM:flush()
                return
            else
                ---
                if data.gamestate ~= States.endGame then
                    dialogue:next()
                else
                    if data.player:is_on_target_position() then
                        dialogue:next()
                    end
                end

                return
                ---
            end
        end
    end -- end Dialogue handler code block


    -- condition to skip countdown
    if (P1:pressed(Button.start, key))
        and data.countdown_time
        and data.countdown_time > 1
        and not State:is_showing_black_bar()
    then
        data.countdown_time = 1
        return
    end


    -- condition to pause the game
    if (P1:pressed(Button.start, key)
            or P1:pressed(Button.B, key))
        and not data.countdown_time
        and state ~= States.endGame
        and state ~= States.preparingToTalk
        and state ~= States.finishFight
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
    if button == 1 then
        return State:keypressed('f')
        ---
    elseif button == 2 then
        return State:keypressed('space')
        ---
    elseif button == 3 then
        return State:keypressed('escape')
        --
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
    local P1 = data.player.controller
    local Button = P1.Button

    if P1:pressed(Button.A, joystick, button) then
        State:keypressed('space')
        --
    elseif P1:pressed(Button.B, joystick, button) then
        State:keypressed('escape')
        --
    elseif P1:pressed(Button.start, joystick, button) then
        State:keypressed('enter')
        --
    elseif P1:pressed(Button.dpad_left, joystick, button) then
        State:keypressed('left')
        --
    elseif P1:pressed(Button.dpad_right, joystick, button) then
        State:keypressed('right')
        --
    elseif P1:pressed(Button.dpad_up, joystick, button) then
        State:keypressed('up')
        --
    elseif P1:pressed(Button.dpad_down, joystick, button) then
        State:keypressed('down')
        --
    elseif P1:pressed(Button.X, joystick, button)
        or P1:pressed(Button.L, joystick, button)
        or P1:pressed(Button.R, joystick, button)
    then
        --
        State:keypressed('f')
        --
    end

    P1:switch_to_joystick()
end

local function gamepadreleased(joystick, button)

end

local function gamepadaxis(joystick, axis, value)
    local P1 = data.player.controller
    local Button = P1.Button

    local x_axis = P1:pressed(Button.left_stick_x, joystick, axis, value)

    if x_axis < 0 then
        State:keypressed('right')
        --
    elseif x_axis > 0 then
        State:keypressed('left')
        --
    end

    local y_axis = P1:pressed(Button.left_stick_y, joystick, axis, value)

    if y_axis > 0 then
        State:keypressed('down')
        --
    elseif y_axis < 0 then
        State:keypressed('up')
        --
    end

    P1:switch_to_joystick()
end

local function resize(w, h)
    return _G.RESIZE(State, w, h)
end

local function game_logic(dt)
    local state = data.gamestate
    if State.transition then return end

    if state == States.game then
        ---
        if data.player:is_dead() then
            data:enemy_victory()
            data.death_count = data.death_count + 1
            data:set_state(States.finishFight)
            ---
        elseif data:wave_is_over(true) then
            if data.wave_number < 4 then
                local player = data.player
                player:set_state(Kid.State.victory)

                data.wave_number = data.wave_number + 1
                data:set_state(States.finishFight)
                ---
            else
                local player = data.player
                player:set_target_position(16 * 7, 16 * 7)
                player:set_state(Kid.State.preparing)
                player.goingTo_speed = 1.5

                data:set_state(States.endGame)
                State:show_black_bar(16)
            end
            data.timer:flick()
        end
        ---
    elseif state == States.endGame then
        ---
        local player = data.player
        local dialogue = data.dialogue

        if player:is_on_target_position() then
            if not dialogue then
                data.dialogue = data:load_dialogue("/data/dialogue_final.md")
            end
            ---
        else
            Play_sfx("footstep 01")
        end

        if dialogue and not dialogue.is_visible
            and data.time_gamestate > 1
            and not State.transition
        then
            return State:add_transition("fade", "out",
                {
                    -- axis = "y",
                    -- type = "bottom-top",
                    post_delay = 0.2
                }, nil,
                ---@param State JM.Scene
                function(State)
                    return State:change_gamestate(require "lib.gamestate.victory", {
                        skip_finish = true,
                        transition = "fade",
                        -- transition_conf = { axis = "y", type = "bottom-top" }
                    })
                end)
        end
        ---
    elseif state == States.finishFight then
        JM.GameObject.update(data.timer, dt)

        if data.time_gamestate >= 3 then
            if not data.player:is_dead() then
                data:put_kids_to_run(false)

                local player = data.player
                player:set_target_position(16 * 7, 16 * 7)
                player:set_state(Kid.State.preparing)
                player.goingTo_speed = 1.5

                local leader = data.leader
                leader:ressurect()
                leader:set_target_position(16 * 12, 16 * 7)
                leader:set_state(Kid.State.preparing)
                leader.goingTo_speed = 2

                if not State:is_showing_black_bar() then
                    State:show_black_bar(16)
                end

                data:set_state(States.preparingToTalk)
                ---
            else
                if not State.transition then
                    JM.Sound:fade_out()
                    State:add_transition("door", "out",
                        { axis = "y", post_delay = 0.2 }, nil,
                        ---@param State JM.Scene
                        function(State)
                            JM.Sound:fade_in(0.01)
                            data.player:ressurect()
                            data.player:set_state(Kid.State.preparing)
                            data.player.stones = 5
                            data.player:update(0)
                            data.displayHP = DisplayHP:new(data.player)

                            data:set_state(States.waveIsComing)

                            data:skip_intro()
                            State:add_transition("door", "in", { axis = "y", pause_scene = false })
                            JM:flush()
                        end)
                end
            end
        end
        ---
    elseif state == States.preparingToTalk then
        ---
        if data:all_kids_are_on_position() then
            data:set_state(States.waveIsComing)
            load_wave(data.wave_number)
        else
            Play_sfx("footstep 01")
        end
        ---
    elseif state == States.waveIsComing then
        if not data.countdown_time then
            if data:all_kids_are_on_position() then
                if State:is_current_active() then
                    -- data:start_countdown(3.6)
                    -- State:remove_black_bar()
                    data:set_state(States.dialogue)
                else
                    data:start_countdown(-0.5)
                end
            else
                Play_sfx("footstep 01")
            end
        end
        ---
    elseif state == States.dialogue then

    end
end

function data:skip_intro()
    local list = self.kids
    if not list then return end

    local player = self.player
    player:set_state(Kid.State.idle)
    player:set_position(player.target_pos_x, player.target_pos_y)
    player.time_delay = 0.0
    player.is_visible = true

    for i = #list, 1, -1 do
        ---@type Kid
        local k = list[i]
        k:remove()
        table.remove(list, i)
    end

    do
        local objs = State.game_objects

        for i = #objs, 1, -1 do
            ---@type Kid|JM.Emitter|any
            local k = objs[i]

            if k.is_kid and not k.__remove and k ~= player then
                k:remove()
                ---
            elseif k.__is_emitter
                and k.lifetime ~= math.huge
                and not k.__remove
            then
                k:destroy()
                k:remove()
            end
        end -- end FOR
    end
    data.leader = nil

    load_wave(data.wave_number)
    list = data.kids

    for i = 1, #list do
        ---@type Kid
        local k = list[i]
        k:set_state(Kid.State.idle)
        k:set_position(k.target_pos_x, k.target_pos_y)
        k.is_visible = true
        k.time_delay = 0.0
    end
    data:start_countdown(3.9)
    -- self:set_state(States.waveIsComing)
    -- game_logic(0)

    State:remove_black_bar(true)
    -- data.countdown_time = 1
end

local lim = 1 / 30
local function update(dt)
    dt = dt > lim and lim or dt

    if data.gamestate == States.game
        and not data:wave_is_over()
    then
        data.time_game = data.time_game + dt
        data.timer:update(dt)
    end

    data.time_gamestate = data.time_gamestate + dt

    if data.countdown_time
        and (not State:is_showing_black_bar())
        and not State.transition
    then
        data.countdown_time = data.countdown_time - dt
        if data.countdown_time <= 0 then
            data:start_game()
        end
    end

    data.world:update(dt)
    State:update_game_objects(dt)

    if data.gamestate == States.game
        or (data.countdown_time and data.countdown_time > 0
            and not State:is_showing_black_bar() and not State.transition)
        or not State:is_current_active()
    then
        data.displayHP:update(dt)
    end

    do
        local D = data.dialogue
        if D then D:update(dt) end
    end

    game_logic(dt)

    data.time_gc = data.time_gc + dt
    if data.time_gc > 20 then
        data.time_gc = 0.0
        for _ = 1, 10 do
            collectgarbage('step')
        end
    end
end

local sort_draw = function(a, b)
    local y1 = (a.get_shadow and not a.__remove and a:get_shadow().y) or a.y
    local y2 = (b.get_shadow and not b.__remove and b:get_shadow().y) or b.y
    return y1 < y2
end

---@param cam JM.Camera.Camera
local function draw(cam)
    local lgx = love.graphics
    local Utils = JM_Utils
    -- State.canvas:setFilter("nearest", "nearest")

    lgx.setColor(1, 1, 1)
    lgx.draw(imgs["field"])

    -- data.world:draw(true, nil, cam)

    -- Drawing the Object's shadow
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
    -- End drawing shadows


    lgx.setColor(1, 1, 1)
    lgx.draw(imgs["street_up"], -16, -16)

    State:draw_game_object(cam, nil, sort_draw)

    lgx.setColor(Utils:hex_to_rgba_float("799299"))
    lgx.draw(imgs["street_down"], -16)

    local font = JM:get_font("pix5")

    --================================================================
    -- Drawing the UI
    cam:detach()
    local state = data.gamestate
    if state == States.game
        -- or state == States.waveIsComing
        or (data.countdown_time and data.countdown_time > 0)
        or not State:is_current_active()
    then
        local px = data.displayHP.x
        local py = data.displayHP.y + 8

        if not State:is_showing_black_bar() then
            lgx.setColor(1, 1, 1, 0.75)
            lgx.draw(imgs["box"], px - 12, data.displayHP.y - 4)
            data.displayHP:draw()

            if data.player.stones == data.player.max_stones then
                font:printx(
                    string.format("ammo x %d <effect=flickering, speed=0.5><color-hex=ff0000>max", data.player.stones),
                    px, py)
            elseif data.player.stones <= 0 then
                font:printx(string.format("<effect=flickering, speed=0.5><color-hex=ff0000>no ammo"), px, py)
            else
                font:printf(string.format("ammo x %d", data.player.stones), px, py)
            end
        end
    end
    if State:is_current_active() and not State:is_showing_black_bar()
        and (state == States.finishFight
            or state == States.game
            or state == States.preparingToTalk
            or data.player.state == Kid.State.victory
            or state == States.endGame
            or (data.countdown_time))
    then
        data.timer:draw()
        lgx.setColor(1, 1, 1)
        lgx.draw(Particles.IMG, data.quad_clock, 16 * 13 - 3, 8, 0, 1, 1)

        if SAVE_DATA.best_time >= 0 then
            font = JM:get_font("pix5")
            font:push()
            font:set_line_space(0)
            font:set_color(Utils:get_rgba3("dcffb3"))
            local min, sec, dec = Timer.get_time2(Timer, SAVE_DATA.best_time)
            font:print(string.format("best time:\n  <color-hex=e5f285>%02d\"%02d'%02d", min, sec, dec),
                16 * 16, 16 * 10 - 4)
            font:pop()
        end
    end
    cam:attach(nil, State.subpixel)
    -- End drawing the UI
    --================================================================

    -- do
    --     local leader = data.leader
    --     if leader and not leader.__remove and not leader:is_dead()
    --         -- and state ~= States.dialogue and state ~= States.endGame
    --         -- and state ~= States.preparingToTalk
    --         -- and state ~= States.waveIsComing
    --         and state == States.game
    --         and not data.countdown_time
    --         and State:is_current_active()
    --     then
    --         font = JM:get_font("pix8")
    --         font:print("<color>LEADER", data.leader.x, data.leader.y - 48)
    --     end
    -- end

    do -- block to draw the countdown
        ---
        local countdown_time = data.countdown_time
        if countdown_time and countdown_time > 0
            and not State:is_showing_black_bar()
        then
            font = _G.FONT_THALEAH --JM:get_font("pix8")
            font:push()
            font:set_color(JM_Utils:get_rgba(JM_Utils:hex_to_rgba_float("665c57")))
            lgx.setColor(Utils:hex_to_rgba_float("f4ffe8bf"))
            local x, y, w, h = (16 * 7), (16 * 2), (16 * 6), (16 * 2.5)
            lgx.rectangle("fill", x, y, w, h)

            if countdown_time > 1 then
                if data.wave_number < 4 then
                    if countdown_time > 3.1 then
                        font:printx(
                            string.format(
                                "<effect=flickering,speed=0.2>STARTING IN</effect no-space> \n<color-hex=bf3526>%d",
                                math.min(3, data.countdown_time)),
                            x, y + 8, w, "center")
                    else
                        font:printx(
                            string.format(
                                "<sep>STARTING IN \n<color-hex=bf3526>%d",
                                math.min(3, data.countdown_time)),
                            x, y + 8, w, "center")
                    end
                else
                    if countdown_time > 3 then
                        font:printx(
                            string.format(
                                "<effect=flickering, speed=0.2>FINAL FIGHT IN</effect no-space> \n<color-hex=bf3526>%d",
                                math.min(3, data.countdown_time)),
                            x, y + 8, w, "center")
                    else
                        font:printx(string.format("FINAL FIGHT IN \n<color-hex=bf3526>%d",
                                math.min(3, data.countdown_time)),
                            x, y + 8, w, "center")
                    end
                end
            else
                font:printx("<effect=scream>FIGHT!!!", x, y + 14, w, "center")
            end

            font:pop()
        end
    end -- end block to draw the countdown

    data:draw_dialogue(cam)

    if State:is_showing_black_bar() and not data.countdown_time
        and state ~= States.endGame
    then
        lgx.setColor(0, 0, 0, 0.5)
        local x, y, w, h = 16 * 15.25, (16 * 9 + 4), 16 * 4, 12
        lgx.rectangle("fill", x, y, w, h)

        font = JM:get_font("pix5")
        font:push()
        font:set_color(Utils:get_rgba(Utils:hex_to_rgba_float("f4ffe8")))

        local P1 = JM.ControllerManager.P1
        if P1:is_on_keyboard_mode() then
            font:printf("[enter] skip", x, y, w, "center")
            ---
        elseif P1:is_on_joystick_mode() then
            font:printf("[start] skip", x, y, w, "center")
        end
        font:pop()
    end

    -- State.canvas:setFilter("linear", "linear")

    -- font:print(string.format("%.1f", data.time_game), 16, 16 * 6)
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
