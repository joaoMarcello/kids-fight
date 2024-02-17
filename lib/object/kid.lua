local GC = _G.JM.BodyObject
local Phys = JM.Physics
local Projectile = require "lib.object.projectile"

local TILE = _G.TILE or 16
local ACC = (16 * 12 * 60) --16 * 12  f = m * a   a = f / m
local MAX_SPEED = 16 * 7
local DACC = ACC * 2
local MAX_STONE = 15

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

function Kid:new(x, y, id, direction)
    id = id or 1
    local x = x or (16 * 5)
    local y = y or (16 * 2)

    local obj = GC:new(x, y, 14, 3, nil, 10, "dynamic", nil)
    setmetatable(obj, self)
    return Kid.__constructor__(obj, id, direction or 1)
end

function Kid:__constructor__(id, direction)
    self.ox = self.w * 0.5
    self.oy = self.h

    self.id = id
    self.direction = direction

    self.stones = MAX_STONE

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

    local bd2 = Phys:newBody(self.world, bd.x, bd.y, bd.w, 24, "dynamic")
    bd2.allowed_gravity = true
    bd2.lock_friction_x = true
    bd2.lock_resistance_x = true
    bd2.lock_resistance_y = true
    bd2.use_ledge_hop = false
    bd2.allowed_air_dacc = true
    bd2.coef_resis_x = 0
    bd2.type = bd2.Types.ghost
    self.body2 = bd2 -- body2 is the actual player collider

    self.atk_action = throw_stone

    --
    self.update = Kid.update
    self.draw = Kid.draw

    return self
end

function Kid:load()
    Projectile:load()
end

function Kid:finish()
    Projectile:finish()
end

function Kid:remove()
    GC.remove(self)
    self.body2.__remove = true
    self.body2 = nil
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

function Kid:add_stone()
    if self.stones < MAX_STONE then
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

function Kid:update(dt)
    local P1 = self.controller
    local Button = P1.Button
    local bd = self.body   --shadow
    local bd2 = self.body2 -- player body

    local x_axis = P1:pressing(Button.left_stick_x)
    local y_axis = P1:pressing(Button.left_stick_y)

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
        end
    end

    self:keep_on_bounds()
    self.x, self.y = bd.x, bd.y
end

---@param self Kid
local my_draw = function(self)
    local lgx = love.graphics
    lgx.setColor(1, 0, 0)
    lgx.rectangle("fill", self:rect())

    lgx.setColor(0, 0, 1)
    lgx.rectangle("line", self.body2:rect())
end

function Kid:draw()
    GC.draw(self, my_draw)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring(self.body2.speed_y), self.x, self.y - 32)
    love.graphics.print(string.format("%.2f %.2f", self.body.amount_x, self.body.amount_y), self.x, self.y - 48)
end

return Kid
