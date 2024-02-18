local GC = JM.GameObject

local WIDTH = 8
local HEIGHT = 8
local OFFSET = 3
local TIME_INCREASE = 0.15

local States = {
    init = 0,
    normal = 1,
    dead = 2,
}

local img
---@type love.Quad|any
local quad1
---@type love.Quad|any
local quad2

---@type love.Shader|nil
local outline
if not _G.WEB then
    outline = JM.Shader:get_exclusive_shader("outline")
end

local color_outline = { 6, 1, 0.5 }
--=========================================================================
---@param self DisplayHP2
local function init_action(self, dt)
    self.time_init = self.time_init + dt

    if self.time_init >= TIME_INCREASE then
        self.time_init = self.time_init - TIME_INCREASE
        if self.time_init >= TIME_INCREASE then
            self.time_init = 0.0
        end

        -- self.actives[self.cur_hp] = true
        self:activate_heart(self.cur_hp)

        self.cur_hp = self.cur_hp + 1
        _G.Play_sfx("heart up", true)

        if self.cur_hp > self.player.hp_init then
            self.cur_hp = self.player.hp_init
            self:set_state(States.normal)
        end
    end
end

---@param self DisplayHP2
local function normal_action(self, dt)
    local player_hp = self.player.hp

    if self.cur_hp ~= player_hp then
        if self.cur_hp > player_hp then
            self:deactivate_heart(self.cur_hp)
            self.cur_hp = self.cur_hp - 1

            if player_hp == 1
                and not self.player_is_dying
            then
                self.time_outline = 0.0
                self.player_is_dying = true
            elseif self.player:is_dead() then
                self.player_is_dying = false
                self.draw_outline = false
            end
        else
            self.cur_hp = self.cur_hp + 1
            self:activate_heart(self.cur_hp)

            self.player_is_dying = false
            self.draw_outline = false
        end
    end

    self.cur_hp = _G.JM_Utils:clamp(self.cur_hp, 1, self.player.hp_init)
end
--=========================================================================

---@class DisplayHP2 : GameObject
local Display = setmetatable({}, GC)
Display.__index = Display

---@param player Kid | nil
---@return DisplayHP2
function Display:new(player)
    local obj = GC:new(32, 4, 16, 16, 1000)
    setmetatable(obj, Display)
    Display.__constructor__(obj, player)
    return obj
end

function Display:__constructor__(player)
    ---@type GameState.Game.Data
    self.data = self.gamestate:__get_data__()

    ---@type Kid
    self.player = player or self.data.player
    self.cur_hp = 1

    local hp_max = self.player.hp_init

    self.actives = {}

    for i = 1, hp_max do
        self.actives[i] = false
    end

    self.time_init = 0.0
    self.time_outline = 0.0
    self.draw_outline = false

    self.player_is_dying = false

    ---@type JM.Template.Affectable
    self.aff = JM.Affectable:new()
    self.aff:apply_effect("pulse", { range = 0.15, speed = 1 })
    self.aff.ox = 8
    self.aff.oy = 8

    self.state = nil
    self:set_state(States.init)

    self.update = Display.update
    self.draw = Display.draw
end

function Display:load()
    img = img or love.graphics.newImage("/data/img/mini_heart.png")
    quad1 = love.graphics.newQuad(0, 0, 16, 16, img:getDimensions())
    quad2 = love.graphics.newQuad(16, 0, 16, 16, img:getDimensions())

    local r, g, b = JM_Utils:hslToRgb(unpack(color_outline))

    if outline then
        outline:send("stepSize", { 1.0 / img:getWidth(), 1.0 / img:getWidth() })
        outline:send("color", { r, g, b })
    end
end

function Display:finish()
    if img then img:release() end
    img = nil
    quad1 = nil
    quad2 = nil
end

function Display:restart()
    self.state = nil
    self.cur_hp = 1
    self:set_state(States.init)
end

function Display:set_state(new_state)
    if self.state == new_state then return false end
    self.state = new_state

    if new_state == States.init then
        self.time_init = -0.5
        self.cur_action = init_action
        --
    elseif new_state == States.normal then
        self.cur_action = normal_action
    end

    return true
end

function Display:activate_heart(pos)
    self.actives[pos] = true
end

function Display:deactivate_heart(pos)
    self.actives[pos] = false
end

function Display:update(dt)
    GC.update(self, dt)
    self.aff:update(dt)
    self:cur_action(dt)

    if self.player_is_dying then
        self.time_outline = self.time_outline + (math.pi / 0.1) * dt
        local s = math.sin(self.time_outline)
        local v = JM_Utils:clamp(math.floor(s) + math.ceil(s), -1, 1)

        if v == -1 and not self.player:is_dead() then
            self.draw_outline = true
        else
            self.draw_outline = false
        end

        _G.Play_sfx("blip dying")
    end
end

local function pulse_heart(self)
    local lgx = love.graphics
    lgx.setColor(1, 1, 1)
    lgx.draw(img, self.quad, self.x, self.y, 0, 1, 1, 0, 0)
end

---@param self DisplayHP2
local function draw_mini_hearts(self)
    local lgx = love.graphics

    for i = 1, self.player.hp_init do
        local quad
        if self.actives[i] then
            -- love.graphics.setColor(0.8, 0.3, 0.3)
            quad = quad1
        else
            -- love.graphics.setColor(0.1, 0.1, 0.1)
            quad = quad2
        end

        local px = self.x + (i - 1) * (WIDTH + OFFSET)
        -- love.graphics.rectangle("fill", px, self.y, WIDTH, HEIGHT)

        if i == self.player.hp and self.state ~= States.init
            and not self.player:is_dead()
        then
            ---@class JM.Template.Affectable
            local aff = self.aff
            aff.x = px - 4
            aff.y = self.y - 4
            aff.quad = quad
            aff:draw(pulse_heart)
        else
            lgx.setColor(1, 1, 1)
            lgx.draw(img, quad, px + 4, self.y + 4, 0, 1, 1, 8, 8)
        end
    end
end

function Display:my_draw()
    local lgx = love.graphics

    if self.draw_outline and outline then
        local last_shader = lgx.getShader()
        lgx.setShader(outline)
        draw_mini_hearts(self)
        lgx.setShader(last_shader)
    end

    draw_mini_hearts(self)
end

function Display:draw()
    GC.draw(self, Display.my_draw)
end

return Display
