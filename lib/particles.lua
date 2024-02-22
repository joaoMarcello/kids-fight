local PS = JM.ParticleSystem
local Particles = {}
local Anima = JM.Anima
local lgx = love.graphics

local anima_run_dust = Anima:new { img = lgx.newImage("/data/img/dust_run-Sheet.png"), frames = 4, duration = 0.7 }

local RunDust = {
    new = function(self, x, bottom)
        local p = PS.Particle:new(nil, x, bottom - 16, 16, 16)
        p.lifetime = 0.7
        p.anima = anima_run_dust:copy()
        p.draw = self.draw
        return p
    end,
    ---
    ---@param self JM.Particle
    draw = function(self)
        return self.anima:draw_rec(self.x, self.y, 16, 16)
    end
}

Particles.RunDust = RunDust

return Particles
