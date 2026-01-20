local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Debris = class()

function Debris:init(world, x, y, size, vx, vy)
    self.lifetime = Config.destruction.debris_lifetime
    self.radius = size 
    
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)
    
    self.fixture:setRestitution(0.5)
    self.fixture:setUserData({type = "Debris", object = self})
    
    self.body:setLinearVelocity(vx, vy)
    self.body:setLinearDamping(0.5) 
end

function Debris:update(dt)
    self.lifetime = self.lifetime - dt
end

function Debris:isDead()
    return self.lifetime <= 0
end

function Debris:draw()
    -- 【核心修复】安全检查
    -- 如果物理刚体已经被销毁（nil），直接返回，不要尝试画它
    if not self.body then return end

    local alpha = self.lifetime / Config.destruction.debris_lifetime
    local c = Config.colors.obstacle_debris
    local tilt = Config.view.tilt or 0.7
    
    local x, y = self.body:getPosition()
    local r = self.radius
    
    -- 1. 绘制影子
    love.graphics.setColor(0, 0, 0, 0.3 * alpha) 
    local sx_shadow, sy_shadow = toScreen(x, y, 0)
    love.graphics.ellipse("fill", sx_shadow, sy_shadow, r, r * tilt)
    
    -- 2. 绘制本体
    local sx, sy = toScreen(x, y, r)
    love.graphics.setColor(c[1], c[2], c[3], alpha)
    love.graphics.circle("fill", sx, sy, r)
    
    -- 3. 高光
    love.graphics.setColor(1, 1, 1, 0.4 * alpha)
    love.graphics.circle("fill", sx - r*0.3, sy - r*0.3, r*0.3)
end

function Debris:destroy()
    if self.body then
        self.body:destroy()
        self.body = nil
    end
end

return Debris