local GC = JM_Package.GameObject
local TILE = _G.TILE

---@class DisplayAtk : GameObject
local Display = setmetatable({}, GC)
Display.__index = Display

---@param player Kid
---@return DisplayAtk
function Display:new(player)
    local obj = GC:new(20, 100, 32, 5, 5, 20)
    setmetatable(obj, self)
    Display.__constructor__(obj, player)
    return obj
end

---@param player Kid
function Display:__constructor__(player)
    self.max_width = self.w
    self.w = 0
    self.kid = player
    self.time_show = 0.0
    self.is_visible = false
end

function Display:load()

end

function Display:finish()

end

function Display:show(value)
    self.time_show = value or 3
    self.is_visible = true
end

function Display:update(dt)
    GC.update(self, dt)

    if self.time_show ~= 0 then
        self.time_show = self.time_show - dt
        if self.time_show <= 0 then
            self.time_show = 0
            self.is_visible = false
        end
    end

    local kid = self.kid
    local bd = kid.body2

    local percent = (kid.hp_init - kid.hp)
        / kid.hp_init

    local v = percent --math.floor(percent / 0.1) * 0.1

    self.w = self.max_width * (1.0 - v)

    self.x = bd.x + bd.w * 0.5 - self.max_width * 0.5
    self.y = bd.y - TILE * 1.5
end

function Display:my_draw()
    if self.w <= 0
        or not self.kid.is_enemy
        or self.kid:is_dead()
    then
        return
    end
    local lgx = love.graphics
    local Utils = JM_Utils

    lgx.setColor(Utils:hex_to_rgba_float("242833"))
    lgx.rectangle("fill", self.x, self.y, self.max_width, self.h)

    local hp = self.kid.hp
    local max = self.kid.hp_init

    if max == 3 then
        if hp <= 1 then
            lgx.setColor(Utils:hex_to_rgba_float("bf3526"))
        elseif hp <= 2 then
            lgx.setColor(Utils:hex_to_rgba_float("e6c45c"))
        else
            lgx.setColor(Utils:hex_to_rgba_float("9ed921"))
        end
        ---
    elseif max == 4 then
        if hp == 1 then
            lgx.setColor(Utils:hex_to_rgba_float("bf3526"))
        elseif hp == 2 then
            lgx.setColor(Utils:hex_to_rgba_float("e6c45c"))
        else
            lgx.setColor(Utils:hex_to_rgba_float("9ed921"))
        end
    else
        if hp <= max * 0.33 then
            lgx.setColor(Utils:hex_to_rgba_float("bf3526"))
        elseif hp <= max * 0.66 then
            lgx.setColor(Utils:hex_to_rgba_float("e6c45c"))
        else
            lgx.setColor(Utils:hex_to_rgba_float("9ed921"))
        end
    end
    lgx.rectangle("fill", self.x, self.y, self.w, self.h)

    lgx.setColor(Utils:hex_to_rgba_float("332424"))
    lgx.rectangle("line", self.x, self.y, self.max_width, self.h)
end

function Display:draw()
    if self.kid:is_dead() then return end
    GC.draw(self, self.my_draw)

    -- local font = _G.JM_Font
    -- font:print(self.percent, self.x, self.y - 20)
end

return Display
