-- src/entities/Obstacle.lua
local class = require "src.utils.class"

local Obstacle = class()

function Obstacle:init(world, x, y, radius)
    self.radius = radius or 10

    -- 物理定义 (Static)
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    -- 障碍物通常很弹
    self.fixture:setRestitution(0.8) 
    self.fixture:setUserData({type = "Obstacle", object = self})
end

function Obstacle:draw()
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
end

return Obstacle