-- src/entities/Debris.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Debris = class()

function Debris:init(world, x, y, size, vx, vy)
    self.lifetime = Config.destruction.debris_lifetime
    self.radius = size -- 使用半径
    
    self.body = love.physics.newBody(world, x, y, "dynamic")
    -- 【修改】碎片也是圆形的
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)
    
    self.fixture:setRestitution(0.5)
    self.fixture:setUserData({type = "Debris", object = self})
    
    self.body:setLinearVelocity(vx, vy)
    -- 阻尼大一点，让它飞一会就慢下来
    self.body:setLinearDamping(0.5) 
end

function Debris:update(dt)
    self.lifetime = self.lifetime - dt
end

function Debris:isDead()
    return self.lifetime <= 0
end

function Debris:draw()
    local alpha = self.lifetime / Config.destruction.debris_lifetime
    local c = Config.colors.obstacle_debris
    
    love.graphics.setColor(c[1], c[2], c[3], alpha)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
end

function Debris:destroy()
    if self.body then
        self.body:destroy()
        self.body = nil
    end
end

return Debris