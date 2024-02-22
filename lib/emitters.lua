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
        local e = PS.Emitter:new(self.x,
            self.y + (bd.speed_y <= 0 and 1 or -1),
            self.w, self.h, nil, 2
        )
        local p = Particles.RunDust:new(self.x, self.y)
        p.anima:set_flip_x(obj.direction == 1)
        e:add_particle(p)
        e.lifetime = -1000
        self.gamestate:add_object(e)
        self.duration = 0.22
    end
end

Emitters.RunDust = function(self, obj)
    local e = PS.Emitter:new(obj.x, obj.y - 16, obj.w, 16, nil, math.huge, rundust_action)
    e:set_track_obj(obj)
    return e
end


return Emitters
