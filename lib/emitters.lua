local PS = JM.ParticleSystem
local Particles = require "lib.particles"

local Emitters = {}

---@param self JM.Emitter
local function rundust_action(self, dt, args)
    ---@type Kid|any
    local obj = self.__obj__
    local bd = obj.body

    if self.duration == 0 and not obj.is_jump
    -- and math.abs(bd.speed_x) > 64
    then
        local e = PS.Emitter:new(
            self.x,
            self.y + (bd.speed_y <= 0 and 1 or -1),
            self.w, self.h, nil, 2
        )
        e.update_order = 1000
        local ex = 0
        if math.abs(bd.speed_x) ~= 0 then
            ex = bd.speed_x > 0 and -8 or 8
        else
            local diff_x = obj.lpx - obj.x
            if diff_x ~= 0 then
                ex = diff_x > 0 and 8 or -8
            end
        end

        local p = Particles.RunDust:new(
            self.x + ex,
            self.y
        )
        p.anima:set_flip_x(obj.direction == 1)
        e:add_particle(p)
        e.lifetime = -1000
        self.gamestate:add_object(e)
        self.duration = 0.22
    end
end

Emitters.RunDust = function(self, obj)
    local e = PS.Emitter:new(obj.x, obj.y - 16, obj.w, 16, nil, math.huge, rundust_action)
    e.update_order = 1000
    e:set_track_obj(obj)
    return e
end

Emitters.FallDust = function(self, obj)
    local e = PS.Emitter:new(obj.x, obj.y + 0.5, obj.w, 16, nil, 2)
    local p = Particles.FallDust:new(obj.x + 16, obj.y)
    e:add_particle(p)

    p = Particles.FallDust:new(obj.x - 16, obj.y)
    p.anima:set_flip_x(true)
    e:add_particle(p)
    e.lifetime = -100
    return e
end

Emitters.Paft = function(self, x, y)
    local e = PS.Emitter:new(x, 1000, 16, 16, nil, 2)
    local p = Particles.Paft:new(x, y)
    e:add_particle(p)
    e.update_order = 1000
    e.lifetime = -1000
    return e
end

Emitters.Zup = function(self, obj)
    local e = PS.Emitter:new(obj.x, obj.y + 0.5, 16, 16, nil, 2)
    local p = Particles.Zup:new(obj.x, obj.y)
    e:add_particle(p)
    e.lifetime = -1000
    return e
end

return Emitters
