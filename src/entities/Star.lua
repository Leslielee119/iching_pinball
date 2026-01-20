-- src/entities/Star.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Star = class()

function Star:init(world, x, y, id)
    self.x, self.y = x, y
    self.id = id
    self.isLit = false
    self.radius = 15 -- 星星大小
    
    -- Static Sensor
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setSensor(true) -- 关键：不发生物理碰撞
    self.fixture:setUserData({type = "Star", object = self})
    
    self.animTimer = 0
end

function Star:update(dt)
    if self.isLit then
        self.animTimer = self.animTimer + dt
    end
end

function Star:activate()
    if not self.isLit then
        self.isLit = true
        return true -- 返回 true 表示新点亮
    end
    return false
end

function Star:reset()
    self.isLit = false
    self.animTimer = 0
end

function Star:draw()
    if self.isLit then
        love.graphics.setColor(Config.colors.star_on)
        -- 呼吸效果
        local scale = 1 + math.sin(self.animTimer * 5) * 0.2
        love.graphics.circle("fill", self.x, self.y, self.radius * scale)
        -- 光晕
        love.graphics.setColor(1, 1, 0.8, 0.3)
        love.graphics.circle("fill", self.x, self.y, self.radius * 1.6)
    else
        love.graphics.setColor(Config.colors.star_off)
        love.graphics.circle("line", self.x, self.y, self.radius)
        love.graphics.circle("fill", self.x, self.y, self.radius * 0.4)
    end
end

return Star