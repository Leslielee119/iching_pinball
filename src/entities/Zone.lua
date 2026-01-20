-- src/entities/Zone.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Zone = class()

function Zone:init(world, x, y, w, h, fx, fy)
    self.x, self.y = x, y
    self.w, self.h = w, h
    self.fx = fx -- 风力 X
    self.fy = fy -- 风力 Y
    
    -- Static Sensor
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newRectangleShape(w, h)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    -- 【关键】设为传感器：球会穿过它，但会触发 beginContact
    self.fixture:setSensor(true) 
    self.fixture:setUserData({type = "Zone", object = self})
    
    self.active = true
    
    -- 简单的粒子效果装饰
    self.timer = 0
end

function Zone:update(dt)
    self.timer = self.timer + dt
end

function Zone:draw()
    -- 绘制半透明区域
    local c = Config.colors.wind_zone
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    
    -- 绘制风向箭头示意
    love.graphics.setColor(1, 1, 1, 0.3)
    local cx, cy = self.body:getWorldCenter()
    love.graphics.line(cx, cy, cx + self.fx * 0.05, cy + self.fy * 0.05)
    love.graphics.circle("fill", cx + self.fx * 0.05, cy + self.fy * 0.05, 3)
    
    -- 模拟云雾流动 (简单的正弦波)
    for i=1, 5 do
        local offset = math.sin(self.timer * 2 + i) * 20
        love.graphics.circle("fill", cx + offset, cy - 40 + i*15, 5 + math.cos(self.timer+i)*2)
    end
end

return Zone