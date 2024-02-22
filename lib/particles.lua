local PS = JM.ParticleSystem
local Particles = {}
local Anima = JM.Anima
local lgx = love.graphics

local IMG = lgx.newImage("/data/img/particles.png")

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

local anima_fall_dust = Anima:new { img = lgx.newImage("/data/img/fall_dust-Sheet.png"), frames = 7, duration = 0.3 }
local FallDust = {
    new = function(self, x, bottom)
        local p = PS.Particle:new(nil, x, bottom - 16, 16, 16)
        p.lifetime = 0.3
        p.draw = self.draw
        p.anima = anima_fall_dust:copy()
        return p
    end,
    ---
    ---@param self JM.Particle
    draw = function(self)
        return self.anima:draw_rec(self.x, self.y, 16, 16)
    end
}

local Paft = {
    new = function(self, x, y)
        local p = PS.Particle:new(IMG, x, y, 16, 16, 0, 0, 16, 16)
        p.lifetime = 0.1
        p.draw = self.draw
        return p
    end,
    ---
    ---@param self JM.Particle
    draw = function(self)
        lgx.setColor(1, 1, 1)
        return lgx.draw(IMG, self.quad, self.x - 4, self.y - 4, 0, 1, 1, 8, 8)
    end
}

local Zup = {
    new = function(self, x, bottom)
        local p = PS.Particle:new(IMG, x, bottom - 16, 16, 16, 16, 0, 16, 16)
        p.lifetime = 0.075
        p.delay = 0.07
        p.draw = self.draw
        return p
    end,
    ---
    draw = function(self)
        lgx.setColor(1, 1, 1)
        return lgx.draw(IMG, self.quad, self.x, self.y)
    end
}

Particles.RunDust = RunDust
Particles.FallDust = FallDust
Particles.Paft = Paft
Particles.Zup = Zup

return Particles
