local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Zone = class()

function Zone:init(world, x, y, w, h, fx, fy)
    self.x, self.y = x, y
    self.w, self.h = w, h
    self.fx, self.fy = fx, fy
    
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newRectangleShape(w, h)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setSensor(true)
    self.fixture:setUserData({type = "Zone", object = self})
    
    self.timer = 0
end

function Zone:update(dt)
    self.timer = self.timer + dt
end

function Zone:draw()
    local c = Config.colors.wind_zone
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    
    -- 【修改】直接转换物理多边形顶点，Z=0
    local points = {self.body:getWorldPoints(self.shape:getPoints())}
    local screenPoints = {}
    for i = 1, #points, 2 do
        local sx, sy = toScreen(points[i], points[i+1], 0)
        table.insert(screenPoints, sx)
        table.insert(screenPoints, sy)
    end
    
    love.graphics.polygon("fill", screenPoints)
    
    -- 风向装饰
    local cx, cy = self.body:getWorldCenter()
    love.graphics.setColor(1, 1, 1, 0.3)
    local sx, sy = toScreen(cx, cy, 0)
    love.graphics.circle("fill", sx, sy, 3)
end

return Zone