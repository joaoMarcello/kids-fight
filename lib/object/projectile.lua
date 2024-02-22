local GC = _G.JM.BodyObject
local Phys = JM.Physics

---@enum Projectile.Types
local Types = {
    stone = 1,
    rabbit = 2,
    seed = 3, -- watemelon
    ray = 4,
    stoneMove = 5,
}

local ACC = (16 * 12 * 60)
local MAX_SPEED = 16 * 7
local DACC = ACC * 0.5

---@type love.Image|any
local IMG

local QUADS

---@class Projectile : BodyObject
local Projectile = setmetatable({}, GC)
Projectile.Type = Types
Projectile.__index = Projectile
Projectile.is_projectile = true

---@param x number
---@param y number
---@param id Projectile.Types
---@param bottom number
---@param direction -1|1
---@return Projectile
function Projectile:new(x, y, id, bottom, direction, mult)
    id = id or Types.stone
    x = x or 0
    y = y or 0
    local obj = GC:new(x, y, 8, 8, 50, nil, "ghost")
    setmetatable(obj, self)
    return Projectile.__constructor__(obj, id, bottom, direction or 1, mult or 1)
end

function Projectile:__constructor__(id, bottom, direction, mult)
    self.type = id
    self.time_force = 0.95 --0.5
    self.direction = direction

    local bd = self.body
    bd.lock_friction_x = true
    bd.lock_resistance_x = true
    bd.lock_resistance_y = true
    bd.allowed_gravity = false
    bd.allowed_air_dacc = true
    -- bd.max_speed_x = MAX_SPEED
    bd.mass = bd.mass * 0.25
    bd.speed_x = (MAX_SPEED * mult) * self.direction

    self.ox = bd.w * 0.5
    self.oy = bd.h * 0.5

    bd = Phys:newBody(self.world, bd.x, bottom, bd.w, 2, "dynamic")
    bd.lock_friction_x = true
    bd.lock_resistance_x = true
    bd.lock_resistance_y = true
    bd.allowed_gravity = false
    bd.allowed_air_dacc = false
    bd:set_holder(self)
    self.body2 = bd

    self.lifetime = 5.0

    --
    self.update = Projectile.update
    self.draw = Projectile.draw
    return self
end

function Projectile:load()
    local lgx = love.graphics
    IMG = IMG or love.graphics.newImage("/data/img/projectiles.png")
    local w, h = IMG:getDimensions()
    QUADS = QUADS or {
        [Types.stone] = lgx.newQuad(0, 0, 16, 16, w, h),
        [Types.stoneMove] = lgx.newQuad(16, 0, 32, 16, w, h),
    }
end

function Projectile:finish()
    if IMG then
        IMG:release()
    end
    IMG = nil
    QUADS = nil
end

function Projectile:remove()
    GC.remove(self)
    self.body2.__remove = true
    self.body2 = nil
end

function Projectile:on_ground()
    local bd = self.body   -- projectile collider
    local bd2 = self.body2 -- the projectile shadow
    return bd:bottom() == bd2.y
end

function Projectile:get_shadow()
    return self.body2
end

local flick_args = { speed = 0.07 }
function Projectile:update(dt)
    GC.update(self, dt)

    local bd = self.body   -- projectile collider
    local bd2 = self.body2 -- the projectile shadow

    if self.time_force ~= 0 then
        self.time_force = self.time_force - dt
        if self.time_force <= 0 then
            self.time_force = 0
            bd.dacc_x = DACC
            bd.allowed_gravity = true
            bd.allowed_air_dacc = true
        end
    end

    local cam = self.gamestate.camera
    if not cam:rect_is_on_view(bd:rect()) and bd.y > cam.y then
        return self:remove()
    end

    if bd:bottom() > bd2.y then
        bd:refresh(nil, bd2.y - bd.h)
        bd.speed_y = 0.0
    end

    if bd.speed_y == 0 and bd.allowed_gravity
        and bd.y == bd2.y - bd.h
    then
        bd:apply_force(DACC * -bd:direction_x())
    end
    bd2:refresh(bd.x)

    if self:on_ground() then
        self.lifetime = self.lifetime - dt
        if self.lifetime <= 0 then
            return self:remove()
        elseif self.lifetime <= 1.6 then
            self:apply_effect("flickering", flick_args)
        end
    end
    --==============================================================

    local items = self.world:get_items_in_cell_obj(bd.x, bd.y, bd.w, bd.h, bd.empty_table())
    if items then
        for item, _ in next, items do
            ---@type JM.Physics.Collide
            local item = item
            ---@type Kid|nil
            local kid = item.holder

            if kid and kid.is_kid then
                local kbd = kid.body2
                if bd:check_collision(kbd.x, kbd:bottom() - 16, kbd.w, 16)
                    and kid:distance() <= 8
                then
                    if self:on_ground() then
                        local success = kid:add_stone()
                        if success then
                            return self:remove()
                        end
                        ---
                    else
                        -- if self.direction ~= kid.direction then
                        --     local cond = math.abs(kid:get_shadow():bottom() - bd2.y) <= 32
                        --     local success = cond and kid:damage(1, self)
                        --     if success then
                        --         return self:remove()
                        --     end
                        -- end
                    end
                end

                if not self:on_ground()
                    and bd:check_collision(kbd:rect())
                then
                    if self.direction ~= kid.direction then
                        local cond = math.abs(kid:get_shadow():bottom() - bd2.y) <= 14
                        local success = cond and kid:damage(1, self)
                        if success then
                            return self:remove()
                        end
                    end
                end
            end
        end
    end


    self.x, self.y = bd.x, bd.y
end

---@param self Projectile
local function my_draw(self)
    local lgx = love.graphics
    -- lgx.setColor(1, 1, 0)
    -- lgx.rectangle("line", self:rect())

    -- lgx.setColor(1, 0, 0)
    -- lgx.rectangle("fill", self.body2:rect())

    lgx.setColor(1, 1, 1)
    ---@type love.Quad
    local quad = QUADS[self.type]
    if not self:on_ground() and not self.body.allowed_gravity then
        quad = QUADS[Types.stoneMove]
    end
    local vx, vy, vw, vh = quad:getViewport()
    lgx.draw(IMG, quad, self.x + self.w * 0.5, self.y + self.h * 0.5, 0, self.direction, 1, vw * 0.5, vh * 0.5)
end

function Projectile:draw()
    GC.draw(self, my_draw)

    love.graphics.setColor(0, 0, 0)
    -- love.graphics.print(string.format("%.2f", self.body.speed_x), self.body.x, self.body.y - 16)
end

return Projectile
