-- src/entities/Debris.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Debris = class()

function Debris:init(world, x, y, size, vx, vy)
    self.lifetime = Config.destruction.debris_lifetime
    
    -- 碎片是动态的，会被弹飞
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.shape = love.physics.newRectangleShape(size, size)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5) -- 密度小一点
    
    self.fixture:setRestitution(0.3)
    -- 设置碰撞过滤器：碎片之间不碰撞(可选)，或者不跟球碰撞(groupIndex负数)
    -- 这里我们让它跟谁都碰，制造混乱感
    
    self.fixture:setUserData({type = "Debris", object = self})
    
    -- 继承一点初速度，并加上随机旋转
    self.body:setLinearVelocity(vx, vy)
    self.body:setAngularVelocity(love.math.random(-10, 10))
end

function Debris:update(dt)
    self.lifetime = self.lifetime - dt
end

function Debris:isDead()
    return self.lifetime <= 0
end

function Debris:draw()
    -- 根据寿命透明度渐变
    local alpha = self.lifetime / Config.destruction.debris_lifetime
    local c = Config.colors.obstacle_debris
    
    love.graphics.setColor(c[1], c[2], c[3], alpha)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
end

function Debris:destroy()
    if self.body then
        self.body:destroy()
        self.body = nil
    end
end

return Debris