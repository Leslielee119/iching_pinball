-- src/entities/DestructibleObstacle.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"
local Debris = require "src.entities.Debris"

local DestructibleObstacle = class()

function DestructibleObstacle:init(world, x, y)
    self.world = world
    self.x, self.y = x, y
    self.is_destroyed = false
    
    -- 【修改】改为圆形半径
    self.radius = 25 
    
    -- 创建刚体 (Static)
    self.body = love.physics.newBody(world, x, y, "static")
    
    -- 【修改】使用圆形形状
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    -- 弹性设高一点，增加反弹乐趣
    self.fixture:setRestitution(0.8)
    self.fixture:setUserData({type = "Destructible", object = self})
end

-- 破碎函数
function DestructibleObstacle:breakApart(impactX, impactY, impactForce)
    if self.is_destroyed then return {} end
    self.is_destroyed = true
    
    -- 1. 销毁自身
    self.body:destroy()
    self.body = nil
    
    -- 2. 生成碎片 (4个小球向四周炸开)
    local debris_list = {}
    -- 碎片飞散速度系数 (基于撞击力度)
    local speed_mod = math.max(impactForce * 0.8, 200) 
    
    -- 在 0, 90, 180, 270 度方向生成碎片
    for i = 1, 4 do
        local angle = (i-1) * (math.pi / 2) + (math.pi/4) -- 45度角发射
        
        -- 碎片产生位置 (从圆心向外偏移一点)
        local offset = self.radius * 0.5
        local dx = math.cos(angle) * offset
        local dy = math.sin(angle) * offset
        
        local worldX = self.x + dx
        local worldY = self.y + dy
        
        -- 碎片速度向量
        local vx = math.cos(angle) * speed_mod
        local vy = math.sin(angle) * speed_mod
        
        -- 创建碎片 (碎片半径是本体的一半的一半)
        local size = self.radius * 0.4
        local d = Debris(self.world, worldX, worldY, size, vx, vy)
        table.insert(debris_list, d)
    end
    
    return debris_list
end

function DestructibleObstacle:draw()
    if self.is_destroyed then return end
    
    local c = Config.colors.obstacle_intact
    love.graphics.setColor(c[1], c[2], c[3])
    
    -- 【修改】绘制圆形
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- 画个漂亮的边框
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius)
    
    -- 画个圆心点缀
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.3)
end

return DestructibleObstacle