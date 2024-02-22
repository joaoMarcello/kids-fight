local GC = _G.JM.BodyObject
local Phys = JM.Physics
local Utils = JM.Utils
local Projectile = require "lib.object.projectile"
local DisplayHP = require "lib.object.displayHP"
local Emitters = require "lib.emitters"

---@enum Kid.Gender
local Gender = {
    girl = 1,
    boy = 2,
}

---@enum Kid.States
local States = {
    normal = 1,
    preparing = 2,
    dead = 3,
    atk = 4,
    idle = 5,
    runAway = 6,
    goingTo = 7,
    victory = 8,
}

---@enum Kid.AnimaStates
local AnimaState = {
    idle = 1,
    run = 2,
    dead = 3,
    jump = 4,
    fall = 5,
    atk = 6,
    walk = 7,
    victory = 8,
    damage = 9,
    hitGround = 10,
}

local tile = _G.TILE or 16
local ACC = (16 * 12 * 60) --16 * 12  f = m * a   a = f / m
local MAX_SPEED = 16 * 4.5
local DACC = ACC * 2
local MAX_STONE = 10
local HP_MAX = 7
local INVICIBLE_DURATION = 1

local imgs
local animas

local random = love.math.random

---@param self Kid
local function throw_stone(self)
    if self.stones <= 0 then return false end
    local bd = self.body2

    local p = Projectile:new(
        (self.direction == 1 and bd:right() or (bd.x - 8)),
        bd.y,
        Projectile.Type.stone,
        self.body.y,
        self.direction
    )

    self.gamestate:add_object(p)
    self.stones = self.stones - 1

    self.cur_anima = self.animas[AnimaState.atk]
    self.cur_anima:reset()

    return true
end

---@class Kid : BodyObject
local Kid = setmetatable({}, GC)
Kid.__index = Kid
Kid.Gender = Gender
Kid.State = States
Kid.AnimaState = AnimaState
Kid.is_kid = true

function Kid:new(x, y, gender, direction, is_enemy, move_type)
    gender = gender or Gender.girl
    local x = x or (16 * 5)
    local y = y or (16 * 2)

    local obj = GC:new(x, y, 14, 3, nil, 10, "dynamic", nil)
    setmetatable(obj, self)
    return Kid.__constructor__(obj, gender, direction or 1, is_enemy, move_type)
end

local conf_stretch = { speed_x = 0.3, speed_y = 0.3, decay_speed_x = 0.5, decay_speed_y = 0.5 }

function Kid:__constructor__(gender, direction, is_enemy, move_type)
    self.ox = self.w * 0.5
    self.oy = self.h

    self.gender = gender
    self.__id = 1

    self.is_enemy = is_enemy or false
    self.direction = direction

    self.stones = not self.is_enemy and math.floor(MAX_STONE * 0.5) or 1000
    self.max_stones = not self.is_enemy and MAX_STONE or math.huge

    self.hp = self.is_enemy and 2 or HP_MAX
    self.hp_init = self.hp
    -- self.hp = 2
    self.time_invincible = 0.0


    self.controller = JM.ControllerManager.P1

    local bd = self.body -- this is the shadow
    bd.max_speed_x = MAX_SPEED
    bd.max_speed_y = MAX_SPEED
    bd.dacc_x = DACC
    bd.dacc_y = DACC
    bd.allowed_gravity = false
    bd.lock_friction_x = true
    bd.lock_resistance_x = true
    bd.lock_resistance_y = true
    bd.use_ledge_hop = false
    bd.allowed_air_dacc = true
    bd.coef_resis_x = 0

    local bd2 = Phys:newBody(self.world, bd.x, bd.y - 24, bd.w, 24, "dynamic")
    bd2.allowed_gravity = true
    bd2.lock_friction_x = true
    bd2.lock_resistance_x = true
    bd2.lock_resistance_y = true
    bd2.use_ledge_hop = false
    bd2.allowed_air_dacc = true
    bd2.coef_resis_x = 0
    bd2.type = bd2.Types.ghost
    bd2.mass = bd2.mass * 0.75
    bd2:set_holder(self)
    self.body2 = bd2 -- body2 is the actual player collider

    self.atk_action = throw_stone

    self.displayHP = DisplayHP:new(self)


    self.animas = {
        [AnimaState.idle] = animas[self.__id]["idle"]:copy(),
        [AnimaState.run] = animas[self.__id]["run"]:copy(),
        [AnimaState.dead] = animas[self.__id]["death"]:copy(),
        [AnimaState.jump] = animas[self.__id]["jump"]:copy(),
        [AnimaState.fall] = animas[self.__id]["fall"]:copy(),
        [AnimaState.victory] = animas[self.__id]["victory"]:copy(),
        [AnimaState.atk] = animas[self.__id]["attack"]:copy(),
        [AnimaState.damage] = animas[self.__id]["damage"]:copy(),
        [AnimaState.hitGround] = animas[self.__id]["hitGround"]:copy(),
    }

    ---@type JM.Anima
    self.cur_anima = self.animas[AnimaState.idle]
    self.cur_anima:set_flip_x(self.direction == -1)
    self.cur_anima.current_frame = random(1, #self.cur_anima.frames_list)

    --
    self.update = Kid.update
    self.draw = Kid.draw


    -- if self.is_enemy then
    do
        self.time_throw = 1 + 3 * random()
        self.time_jump = random()
        self.time_delay = 0.0
        self.time_jump_interval = 1 + random()
        self.time_move_y = (math.pi * 0.5) * random(4)
        self.time_move_x = (math.pi * 0.5) * random(4)
        self.anchor_x = self.x
        self.anchor_y = 16 * 6 --self.y
        self.target_pos_x = self.x
        self.target_pos_y = self.y
        self.move_type = move_type or 1
        self.goingTo_speed = 1.5
        self.move_x_value = 28
        self.move_y_value = 40
        self.move_delay = 0.5
        -- self:update(0)
    end

    self.ia_mode = false

    -- self:set_position(self.x, self.y)
    self:keep_on_bounds()

    self.emitter_rundust = Emitters:RunDust(self)
    self.gamestate:add_object(self.emitter_rundust)

    self:set_state(States.normal)

    self.lpx = self.x
    self.lpy = self.y
    return self
end

function Kid:load()
    Projectile:load()
    DisplayHP:load()

    local lgx = love.graphics
    local Anima = JM.Anima

    imgs = imgs or {
        ["idle"] = lgx.newImage("/data/img/kid_idle-Sheet.png"),
        ["run"] = lgx.newImage("/data/img/kid_run-Sheet.png"),
        ["death"] = lgx.newImage("/data/img/kid_death-Sheet.png"),
        ["jump"] = lgx.newImage("/data/img/kid_jump-Sheet.png"),
        ["fall"] = lgx.newImage("/data/img/kid_fall-Sheet.png"),
        ["victory"] = lgx.newImage("/data/img/kid_victory-Sheet.png"),
        ["attack"] = lgx.newImage("/data/img/kid_atk-Sheet.png"),
        ["damage"] = lgx.newImage("/data/img/kid_damage-Sheet.png"),
        ["hitGround"] = lgx.newImage("/data/img/kid_hit_ground-Sheet.png"),
    }

    animas = animas or {}

    animas[1] = animas[1] or {
        ["idle"] = Anima:new { img = imgs["idle"], frames = 4, duration = 0.3 },
        ["run"] = Anima:new { img = imgs["run"], frames = 8, duration = 0.5 },
        ["death"] = Anima:new { img = imgs["death"], frames = 1 },
        ["jump"] = Anima:new { img = imgs["jump"], frames = 3, duration = 0.25, stop_at_the_end = true },
        ["fall"] = Anima:new { img = imgs["fall"], frames = 1 },
        ["victory"] = Anima:new { img = imgs["victory"], frames = 1 },
        ["attack"] = Anima:new { img = imgs["attack"], frames = 2, duration = 0.2, stop_at_the_end = true },
        ["damage"] = Anima:new { img = imgs["damage"], frames = 1 },
        ["hitGround"] = Anima:new { img = imgs["hitGround"], frames = 1 },
    }
end

function Kid:finish()
    Projectile:finish()
    DisplayHP:finish()
end

function Kid:remove()
    GC.remove(self)
    self.emitter_rundust:destroy()
    self.body2.__remove = true
    self.body2 = nil
end

function Kid:ressurect()
    self.hp = self.hp_init
    self:set_state(States.idle)
end

function Kid:set_target_position(x, y)
    self.target_pos_x = x or self.target_pos_x
    self.target_pos_y = y or self.target_pos_y

    self.target_pos_x = math.floor(self.target_pos_x)
    self.target_pos_y = math.floor(self.target_pos_y)
end

function Kid:is_on_target_position()
    -- if self.state ~= States.goingTo then return false end
    local bd = self.body
    return bd.x == self.target_pos_x and bd.y == self.target_pos_y
end

function Kid:set_delay(value)
    value = value or 0
    self.time_delay = value
    if value ~= 0 then
        self.is_visible = false
        self.emitter_rundust.pause = true
    end
end

---@param new_state Kid.States
function Kid:set_state(new_state)
    if self.state == new_state then return end
    self.state = new_state
    self.time_state = 0.0

    self.emitter_rundust.pause = false

    if new_state == States.goingTo
        or new_state == States.preparing
    then
        self.time_going = 0.0
        local bd = self.body
        self.diff_x = bd.x - self.target_pos_x
        self.diff_y = bd.y - self.target_pos_y
        self.init_x = bd.x
        self.init_y = bd.y
    elseif new_state == States.idle then
        self.goingTo_speed = 1.5
        self.emitter_rundust.pause = true
        self.body.speed_x = 0.0
        --
    elseif new_state == States.victory then
        self.time_jump_interval = random() * 0.5
        ---
    elseif new_state == States.runAway then
        self.hp = self.hp_init
        self.emitter_rundust.pause = false
        ---
    elseif new_state == States.dead then
        self.emitter_rundust.pause = true
    elseif new_state == States.normal then
        self.emitter_rundust.pause = true
    end

    self:adjust_cur_anima()

    return true
end

function Kid:keypressed(key)
    do
        local state = self.state
        if state == States.victory
            or state == States.dead
        then
            return false
        end
    end

    local P1 = self.controller
    local Button = P1.Button
    P1:switch_to_keyboard()

    if P1:pressed(Button.A, key) then
        return self:jump()
    elseif P1:pressed(Button.X, key)
        or P1:pressed(Button.L, key)
        or P1:pressed(Button.R, key)
    then
        return self:attack()
    end
end

---@param self Kid
local function pause_action(dt, self)
    self:set_visible(true)
    self.gamestate.camera:update(dt)
end

function Kid:is_the_last()
    ---@type GameState.Game.Data
    local data = self.gamestate:__get_data__()
    local list = data.kids
    local N = #list
    local count = 0

    for i = 1, N do
        ---@type Kid
        local kid = list[i]
        if kid:is_dead() then
            count = count + 1
        end
    end

    return count == N
end

function Kid:damage(value, obj)
    value = value or 1
    if self:is_dead() or self.time_invincible ~= 0.0 then return false end
    do
        local state = self.state
        if state == States.preparing
            or state == States.idle
            or state == States.victory
        then
            return false
        end
    end

    self.hp = Utils:clamp(self.hp - value, 0, HP_MAX)

    if self.is_enemy then
        self.time_invincible = INVICIBLE_DURATION * 1 --0.5
    else
        self.time_invincible = INVICIBLE_DURATION
    end


    if self.hp == 0 then
        self:set_state(States.dead)

        if not self.is_enemy then
            self.gamestate.camera:shake_x(3, 0.08, 0.5)
            self.gamestate.camera:shake_y(2, 0.08, 0.4)
        end
    else
        if not self.is_enemy then
            self.gamestate.camera:shake_x(3, 0.08, 0.5)
            self.gamestate.camera:shake_y(3, 0.08, 0.3)
        end

        self.displayHP:show()
    end

    self.cur_anima = self.animas[AnimaState.damage]
    self.cur_anima:reset()

    if not self.is_enemy then
        self.gamestate:pause(self:is_dead() and 1.3 or 0.2, pause_action, self)
    else
        local is_the_last = self:is_dead() and self:is_the_last()
        if is_the_last then
            self.gamestate.camera:shake_x(3, 0.08, 0.5)
            self.gamestate.camera:shake_y(3, 0.08, 0.3)
        end
        self.gamestate:pause(
            is_the_last and 1 or 0.2,
            pause_action, self)
    end

    return true
end

function Kid:get_shadow()
    return self.body
end

function Kid:is_dead()
    return self.hp <= 0
end

function Kid:add_stone()
    if self.stones < self.max_stones then
        self.stones = self.stones + 1
        return true
    end
    return false
end

function Kid:attack()
    if self:is_dead() then return false end

    do
        local state = self.state
        if state == States.idle
            or state == States.preparing
            or state == States.runAway
            or state == States.victory
        then
            return false
        end
    end

    return self:atk_action()
end

function Kid:jump(height)
    if self:is_dead() then return false end
    do
        local state = self.state
        if state == States.preparing
            or state == States.idle
            or state == States.runAway
        -- or (state == States.victory and not self.is_enemy)
        then
            return false
        end
    end

    local bd2 = self.body2
    if bd2.speed_y == 0 then
        self.is_jump = true
        bd2.allowed_gravity = true
        self:remove_effect("stretchSquash")
        self.emitter_rundust.pause = true
        self.gamestate:add_object(
            Emitters:Zup(self)
        )
        return bd2:jump(height or (16 * 2), -1)
    end
end

---@param x -1|1|0
---@param y -1|1|0
function Kid:move(x, y)
    x = x or 0
    y = y or 0
    local bd = self.body
    return bd:apply_force(ACC * x, ACC * y)
end

function Kid:keep_on_bounds()
    local bd = self.body
    local bd2 = self.body2

    local px, py = 0, (SCREEN_HEIGHT - bd.h)
    local pr = 16 * 7

    local state = self.state
    if self.direction < 0 then
        px = 16 * 12
        pr = SCREEN_WIDTH - bd2.w - 2
        if state == States.preparing
            or state == States.runAway
        then
            pr = SCREEN_WIDTH + 100
        end
        --
    else
        if state == States.preparing
            or state == States.runAway
        then
            px = -100
        end
    end

    bd:refresh(math.min(math.max(px, bd.x), pr), math.min(py, bd.y))
    if bd.x == 0 and bd.speed_x < 0
        or (bd.x == pr and bd.speed_x > 0)
    then
        -- bd.speed_x = 0
    end
    if bd.y == py and bd.speed_y > 0 then
        bd.speed_y = 0
    end
    bd2:refresh(bd.x)
end

function Kid:distance()
    local bd = self.body   -- shadow
    local bd2 = self.body2 --player collider

    return (bd.y - bd2:bottom())
end

---@param self Kid
local function auto_jump(self, dt)
    if not self.is_jump then
        self.time_jump = self.time_jump + dt
        if self.time_jump >= self.time_jump_interval then
            self.time_jump = 0.0
            self.time_jump_interval = random(2)
            -- self.time_jump_interval = 0.3
            self.body2.speed_y = 0.0
            self:keypressed('space')
        end
    end
end

---@param self Kid
local function goingTo(self, dt)
    local bd = self.body
    local diff_x = self.diff_x
    local diff_y = self.diff_y

    local v = math.sin(self.time_going)

    self:set_position(self.init_x - diff_x * v, self.init_y - diff_y * v)

    local domain = math.pi * 0.5
    self.time_going = Utils:clamp(
        self.time_going + (domain / self.goingTo_speed) * dt,
        0, domain
    )

    if self:is_on_target_position() then
        if self:is_dead() then
            self:set_state(States.dead)
        elseif self.state == States.preparing then
            self:set_state(States.idle)
        else
            self:set_state(States.normal)
        end
    end

    return 0, 0
end

---@param self Kid
local function movement(self, dt)
    local P1 = self.controller
    local Button = P1.Button

    local state = self.state

    if state == States.dead
        or state == States.idle
    then
        self.emitter_rundust.pause = true
        return 0, 0
    elseif state == States.victory then
        if not self.is_jump then
            self.time_jump = self.time_jump + dt
            if self.time_jump >= self.time_jump_interval then
                self.time_jump = 0.0
                self.time_jump_interval = 0.15 --0.1 + 0.4 * random()
                self.body2.speed_y = 0.0
                self:jump(16)
            end
        end
        return 0, 0
    elseif (state == States.goingTo
            and not self.is_enemy)
        or state == States.preparing
    then
        return goingTo(self, dt)
    elseif state == States.runAway then
        return 1, 0
    end

    if not self.is_enemy and not self.ia_mode then
        local x = P1:pressing(Button.dpad_right) and 1 or 0
        x = (x == 0 and P1:pressing(Button.dpad_left) and -1) or x
        x = (x == 0 and tonumber(P1:pressing(Button.left_stick_x))) or x

        local y = P1:pressing(Button.dpad_up) and -1 or 0
        y = (y == 0 and P1:pressing(Button.dpad_down) and 1) or y
        y = (y == 0 and tonumber(P1:pressing(Button.left_stick_y))) or y

        if x == 0 and y == 0 or self.is_jump then
            self.emitter_rundust.pause = true
        else
            self.emitter_rundust.pause = false
        end

        return x, y
    else
        local x = 0
        local y = 0

        auto_jump(self, dt)

        if self.move_type == 1 then
            if not self.is_jump then
                self.time_move_y = self.time_move_y + dt
            end
            local vy = self.move_y_value * math.sin(self.time_move_y)

            self:set_position(nil, self.anchor_y + vy)

            if not self:is_dead() then
                self.emitter_rundust.pause = false
            end
            --
        elseif self.move_type == 2 then
            if self.state == States.normal then
                if self.time_state >= self.move_delay then
                    if self.direction == -1 then
                        self:set_target_position(
                            16 * random(13, 17),
                            16 * random(4, 9)
                        )
                    else
                        if self.stones <= 0 then
                            local list = self.gamestate.game_objects
                            local found = false
                            for i = 1, #list do
                                ---@type Projectile|any
                                local obj = list[i]

                                if obj.is_projectile
                                    and not obj.__remove
                                    and obj:on_ground()
                                then
                                    self:set_target_position(
                                        Utils:clamp(obj.x, 0, 16 * 7),
                                        obj.y + obj.h * 0.5
                                    )
                                    found = true
                                    break
                                end
                            end

                            if not found then
                                self:set_target_position(
                                    16 * random(2, 7),
                                    16 * random(4, 9)
                                )
                            end
                        else
                            self:set_target_position(
                                16 * random(2, 7),
                                16 * random(4, 9)
                            )
                        end
                    end
                    self:set_state(States.goingTo)
                end
            else
                return goingTo(self, dt)
            end
            ---
        else
            if not self.is_jump then
                self.time_move_y = self.time_move_y + dt
                self.time_move_x = self.time_move_x + ((math.pi) / 5.0) * dt
            end

            local vy = self.move_y_value * math.sin(self.time_move_y)
            local vx = self.move_x_value * math.sin(self.time_move_x)

            self:set_position(self.anchor_x + vx, self.anchor_y + vy)

            if not self:is_dead() then
                self.emitter_rundust.pause = false
            end
        end


        return x, y
    end
end

function Kid:set_position(x, y)
    local bd = self.body
    local bd2 = self.body2

    x = x or bd.x
    y = y or bd.y

    local diff_y = bd.y - bd2:bottom()

    bd:refresh(x, y)
    bd2:refresh(bd.x, bd.y - bd2.h - diff_y)
    self.x, self.y = bd.x, bd.y
end

local args_flick = { speed = 0.06 }

function Kid:update(dt)
    if self.time_delay ~= 0 then
        self.time_delay = self.time_delay - dt
        if self.time_delay <= 0 then
            self.time_delay = 0
            self.is_visible = true
            self.emitter_rundust.pause = false
        else
            self.is_visible = false
            return
        end
    end

    GC.update(self, dt)
    self.displayHP:update(dt)


    -- local P1 = self.controller
    -- local Button = P1.Button
    local bd = self.body   --shadow
    local bd2 = self.body2 -- player body

    self.lpx, self.lpy = bd.x, bd.y

    local x_axis, y_axis = movement(self, dt)
    self.time_state = self.time_state + dt

    if self.state == States.runAway then
        if not self.gamestate.camera:rect_is_on_view(self:rect()) then
            return self:remove()
        end
    end

    -- flick when invincible
    if self.time_invincible ~= 0 and not self:is_dead()
        and not self.gamestate:is_paused()
    then
        self:apply_effect('flickering', args_flick)
    else
        local eff = self.eff_actives and self.eff_actives['flickering']
        if eff then
            eff.__remove = true
            self.eff_actives['flickering'] = nil
            self:set_visible(true)
        end
    end

    if self.time_invincible ~= 0 then
        self.time_invincible = Utils:clamp(self.time_invincible - dt, 0, INVICIBLE_DURATION)
    end

    if type(x_axis) == "number" and type(y_axis) == "number" then
        if bd.speed_x > 0 and x_axis == -1
            or bd.speed_x < 0 and x_axis == 1
        then
            bd.dacc_x = DACC * 1.5
        else
            self:move(x_axis, 0)
            bd.dacc_x = DACC
        end

        if bd.speed_y > 0 and y_axis == -1
            or bd.speed_y < 0 and y_axis == 1
        then
            bd.dacc_y = DACC * 1.5
        else
            self:move(0, y_axis)
            bd.dacc_y = DACC
        end
    end

    if self.is_jump then
        bd.max_speed_x = MAX_SPEED * 0.75
        bd.max_speed_y = MAX_SPEED * 0.75

        bd2:refresh(nil, bd2.y + bd.amount_y)

        if bd2.speed_y >= 0.0 and bd2:bottom() >= bd.y then
            bd2:refresh(nil, bd.y - bd2.h)
            bd2.speed_y = 0.0
            bd2.allowed_gravity = false
            self.is_jump = false
            self:apply_effect("stretchSquash", conf_stretch, true)
            self.cur_anima = self.animas[AnimaState.hitGround]
            self.cur_anima:reset()

            local e = Emitters:FallDust(self)
            self.gamestate:add_object(e)
        end
    else
        if not self.is_jump then
            bd2:refresh(nil, bd.y - bd2.h)
            bd2.speed_y = 0.0
            bd.max_speed_x = MAX_SPEED
            bd.max_speed_y = MAX_SPEED
        end
    end

    self:keep_on_bounds()

    if self.is_enemy or self.ia_mode then
        if self.state == States.normal
            or self.state == States.goingTo
        then
            self.time_throw = self.time_throw - dt
            if self.time_throw <= 0 then
                ---@type GameState.Game.Data
                local data = self.gamestate:__get_data__()

                if not data:leader_is_dead() then
                    self.time_throw = 1 + 3 * random()
                else
                    self.time_throw = 0.5 + 2 * random()
                end
                self:attack()
            end
        end
    end


    local last = self.cur_anima
    self.cur_anima = self:get_cur_anima()
    if last ~= self.cur_anima then
        self.cur_anima:reset()
    end

    self.x, self.y = bd.x, bd.y
    self.cur_anima:update(dt)
    self:adjust_cur_anima()
end

function Kid:get_cur_anima(state)
    state = state or self.state

    local bd = self.body
    local bd2 = self.body2
    local diff_x = self.lpx - bd.x
    local diff_y = self.lpy - bd.y

    if state == States.victory then
        return self.animas[AnimaState.victory]
        ---
    elseif self.cur_anima == self.animas[AnimaState.damage] then
        local anima = self.cur_anima
        if anima:time_updating() >= 0.1 then
            self.cur_anima = nil
            return self:get_cur_anima()
        else
            return anima
        end
        ---
    elseif self:is_dead() then
        return self.animas[AnimaState.dead]
        ---
    elseif self.cur_anima == self.animas[AnimaState.atk] then
        local anima = self.cur_anima
        if anima:time_updating() >= 0.2 then
            self.cur_anima = nil
            return self:get_cur_anima()
        else
            return anima
        end
        ---
    elseif self.cur_anima == self.animas[AnimaState.hitGround] then
        local anima = self.cur_anima
        if anima:time_updating() >= 0.1 then
            self.cur_anima = nil
            return self:get_cur_anima()
        else
            return anima
        end
    elseif self.is_jump then
        if bd2.speed_y < 0 then
            return self.animas[AnimaState.jump]
        else
            return self.animas[AnimaState.fall]
        end
        ---
    elseif diff_x ~= 0 or bd.speed_x ~= 0.0
        or (not self.is_jump and (diff_y ~= 0.0 or bd.speed_y ~= 0))
    then
        return self.animas[AnimaState.run]
    else
        return self.animas[AnimaState.idle]
    end
end

function Kid:adjust_cur_anima()
    local anima = self.cur_anima
    if not anima then return end

    anima:set_flip_x(self.direction == -1)
    if self.state == States.runAway then
        anima:set_flip_x(false)
        -- anima:set_rotation(0)
        ---
    elseif self.state == States.dead then
        -- anima:set_rotation(math.pi * 0.5 * -self.direction)
    else
        -- anima:set_rotation(0)
    end
end

---@param self Kid
local my_draw = function(self)
    -- local lgx = love.graphics
    -- lgx.setColor(1, 0, 0)
    -- lgx.rectangle("fill", self:rect())

    -- lgx.setColor(0, 0, 1)
    -- lgx.rectangle("line", self.body2:rect())

    return self.cur_anima:draw_rec(self.body2:rect())
end

function Kid:draw()
    GC.draw(self, my_draw)
    return self.displayHP:draw()
end

return Kid
