local GC = _G.JM.BodyObject
local Phys = JM.Physics
local Utils = JM.Utils
local Projectile = require "lib.object.projectile"
local DisplayHP = require "lib.object.displayHP"

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
}

local tile = _G.TILE or 16
local ACC = (16 * 12 * 60) --16 * 12  f = m * a   a = f / m
local MAX_SPEED = 16 * 4.5
local DACC = ACC * 2
local MAX_STONE = 15
local HP_MAX = 10
local INVICIBLE_DURATION = 1

local imgs
local animas

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
    return true
end

---@class Kid : BodyObject
local Kid = setmetatable({}, GC)
Kid.__index = Kid
Kid.Gender = Gender
Kid.is_kid = true

function Kid:new(x, y, gender, direction, is_enemy)
    gender = gender or Gender.girl
    local x = x or (16 * 5)
    local y = y or (16 * 2)

    local obj = GC:new(x, y, 14, 3, nil, 10, "dynamic", nil)
    setmetatable(obj, self)
    return Kid.__constructor__(obj, gender, direction or 1, is_enemy)
end

function Kid:__constructor__(gender, direction, is_enemy)
    self.ox = self.w * 0.5
    self.oy = self.h

    self.gender = gender
    self.is_enemy = is_enemy or false
    self.direction = direction

    self.stones = not self.is_enemy and math.floor(MAX_STONE * 0.5) or 1000
    self.max_stones = not self.is_enemy and MAX_STONE or math.huge

    self.hp = self.is_enemy and 5 or HP_MAX
    self.hp_init = self.hp
    -- self.hp = 2
    self.time_invincible = 0.0

    self:set_state(States.normal)

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

    ---@type JM.Anima
    self.anima_idle = animas["idle"]:copy()
    ---@type JM.Anima
    self.cur_anima = self.anima_idle
    self.cur_anima:set_flip_x(self.direction == -1)
    --
    self.update = Kid.update
    self.draw = Kid.draw

    -- self:update(1 / 60)
    self:keep_on_bounds()
    return self
end

function Kid:load()
    Projectile:load()
    DisplayHP:load()

    local lgx = love.graphics
    local Anima = JM.Anima

    imgs = imgs or {
        ["idle"] = lgx.newImage("/data/img/kid_01.png"),
    }

    animas = animas or {
        ["idle"] = Anima:new { img = imgs["idle"], frames = 1 },
    }
end

function Kid:finish()
    Projectile:finish()
    DisplayHP:finish()
end

function Kid:remove()
    GC.remove(self)
    self.body2.__remove = true
    self.body2 = nil
end

function Kid:set_state(new_state)
    if self.state == new_state then return end
    self.state = new_state
    self.time_state = 0.0

    return true
end

function Kid:keypressed(key)
    local P1 = self.controller
    local Button = P1.Button
    P1:switch_to_keyboard()

    if P1:pressed(Button.A, key) then
        return self:jump()
    elseif P1:pressed(Button.X, key) then
        return self:attack()
    end
end

function Kid:damage(value, obj)
    value = value or 1
    if self:is_dead() or self.time_invincible ~= 0.0 then return false end

    self.hp = Utils:clamp(self.hp - value, 0, HP_MAX)
    self.time_invincible = INVICIBLE_DURATION

    if self.hp == 0 then
        self:set_state(States.dead)
    else
        self.displayHP:show()
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
    return self:atk_action()
end

function Kid:jump()
    local bd2 = self.body2
    if bd2.speed_y == 0 then
        self.is_jump = true
        return bd2:jump(16 * 2, -1)
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

    if self.direction < 0 then
        px = 16 * 12
        pr = SCREEN_WIDTH
    end

    bd:refresh(math.min(math.max(px, bd.x), pr), math.min(py, bd.y))
    if bd.x == 0 and bd.speed_x < 0
        or (bd.x == pr and bd.speed_x > 0)
    then
        bd.speed_x = 0
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
local function movement(self, dt)
    local P1 = self.controller
    local Button = P1.Button

    if not self.is_enemy then
        local x = P1:pressing(Button.dpad_right) and 1 or 0
        x = (x == 0 and P1:pressing(Button.dpad_left) and -1) or x
        x = (x == 0 and tonumber(P1:pressing(Button.left_stick_x))) or x

        local y = P1:pressing(Button.dpad_up) and -1 or 0
        y = (y == 0 and P1:pressing(Button.dpad_down) and 1) or y
        y = (y == 0 and tonumber(P1:pressing(Button.left_stick_y))) or y
        return x, y
    else
        return -1, 0
    end
end

local args_flick = { speed = 0.06 }

function Kid:update(dt)
    GC.update(self, dt)
    self.displayHP:update(dt)

    local P1 = self.controller
    local Button = P1.Button
    local bd = self.body   --shadow
    local bd2 = self.body2 -- player body

    local x_axis, y_axis = movement(self, dt)
    self.time_state = self.time_state + dt

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
            self.is_jump = false
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

    if self.is_enemy then
        self.temp = self.temp or 3
        self.temp = self.temp - dt
        if self.temp <= 0 then
            self.temp = 3
            self:attack()
        end
    end

    self.cur_anima:update(dt)
    self.cur_anima:set_flip_x(self.direction == -1)

    self.x, self.y = bd.x, bd.y
end

---@param self Kid
local my_draw = function(self)
    local lgx = love.graphics
    lgx.setColor(1, 0, 0)
    -- lgx.rectangle("fill", self:rect())

    lgx.setColor(0, 0, 1)
    -- lgx.rectangle("line", self.body2:rect())

    self.cur_anima:draw_rec(self.body2:rect())
end

function Kid:draw()
    GC.draw(self, my_draw)

    -- love.graphics.setColor(0, 0, 0)
    -- love.graphics.print(tostring(self.hp), self.x, self.y - 32)

    self.displayHP:draw()
    -- love.graphics.print(string.format("%.2f %.2f", self.body.amount_x, self.body.amount_y), self.x, self.y - 48)
end

return Kid
