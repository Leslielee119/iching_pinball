local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Star = class()

function Star:init(world, x, y, id)
    self.x, self.y = x, y
    self.id = id
    self.isLit = false
    self.radius = 15 
    
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setSensor(true)
    self.fixture:setUserData({type = "Star", object = self})
    
    self.animTimer = 0
end

function Star:update(dt)
    if self.isLit then self.animTimer = self.animTimer + dt end
end

function Star:activate()
    if not self.isLit then self.isLit = true; return true end
    return false
end

function Star:reset() self.isLit = false; self.animTimer = 0 end

function Star:draw()
    local tilt = Config.view.tilt or 0.7
    -- 【修改】Z=0，地面效果
    local sx, sy = toScreen(self.x, self.y, 0)
    
    if self.isLit then
        love.graphics.setColor(Config.colors.star_on)
        local scale = 1 + math.sin(self.animTimer * 5) * 0.2
        -- 压扁圆形
        love.graphics.ellipse("fill", sx, sy, self.radius * scale, self.radius * scale * tilt)
        love.graphics.setColor(1, 1, 0.8, 0.3)
        love.graphics.ellipse("fill", sx, sy, self.radius * 1.6, self.radius * 1.6 * tilt)
    else
        love.graphics.setColor(Config.colors.star_off)
        love.graphics.ellipse("line", sx, sy, self.radius, self.radius * tilt)
        love.graphics.ellipse("fill", sx, sy, self.radius * 0.4, self.radius * 0.4 * tilt)
    end
end

return Star