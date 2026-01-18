-- src/entities/DestructibleObstacle.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"
local Debris = require "src.entities.Debris"

local DestructibleObstacle = class()

function DestructibleObstacle:init(world, x, y)
    self.world = world
    self.x, self.y = x, y
    self.is_destroyed = false
    
    -- 单个分块的大小
    self.part_size = 20 
    
    -- 创建主刚体 (Static，因为没碎之前是不动的)
    self.body = love.physics.newBody(world, x, y, "static")
    
    -- 【核心逻辑】拼图法：给同一个 Body 赋予 4 个 Fixture
    -- 形状排列：
    -- [1][2]
    -- [3][4]
    local s = self.part_size
    local offset = s / 2
    
    -- 我们记录这4个部分的相对偏移，方便破碎时生成碎片
    self.parts = {
        {x = -offset, y = -offset}, -- 左上
        {x = offset,  y = -offset}, -- 右上
        {x = -offset, y = offset},  -- 左下
        {x = offset,  y = offset}   -- 右下
    }
    
    for _, part in ipairs(self.parts) do
        -- newRectangleShape(x, y, w, h, angle) 这里的x,y是相对于body中心的偏移
        local shape = love.physics.newRectangleShape(part.x, part.y, s, s, 0)
        local fixture = love.physics.newFixture(self.body, shape)
        fixture:setRestitution(0.5)
        -- 所有部分的 UserData 都指向同一个对象
        fixture:setUserData({type = "Destructible", object = self})
    end
end

-- 破碎函数：返回一组碎片对象
function DestructibleObstacle:breakApart(impactX, impactY, impactForce)
    if self.is_destroyed then return {} end
    self.is_destroyed = true
    
    -- 1. 销毁自身
    self.body:destroy()
    self.body = nil
    
    -- 2. 生成碎片
    local debris_list = {}
    local speed_mod = impactForce * 0.5 -- 碎片飞散的速度取决于撞击力度
    
    for _, part in ipairs(self.parts) do
        -- 计算碎片的世界坐标
        local worldX = self.x + part.x
        local worldY = self.y + part.y
        
        -- 计算飞散向量 (从中心向外爆)
        -- 归一化方向向量
        local len = math.sqrt(part.x^2 + part.y^2)
        local dirX, dirY = part.x / len, part.y / len
        
        local vx = dirX * speed_mod
        local vy = dirY * speed_mod
        
        -- 创建碎片对象
        local d = Debris(self.world, worldX, worldY, self.part_size, vx, vy)
        table.insert(debris_list, d)
    end
    
    return debris_list
end

function DestructibleObstacle:draw()
    if self.is_destroyed then return end
    
    local c = Config.colors.obstacle_intact
    love.graphics.setColor(c[1], c[2], c[3])
    
    -- 因为我们是一个Body带多个Fixture，需要遍历绘制
    -- 或者因为我们知道它是怎么拼的，直接画4个方块
    for _, part in ipairs(self.parts) do
        -- 简单画法：利用 love.graphics.translate
        love.graphics.push()
        love.graphics.translate(self.x + part.x, self.y + part.y)
        -- 画中心矩形
        love.graphics.rectangle("fill", -self.part_size/2, -self.part_size/2, self.part_size, self.part_size)
        -- 画黑边
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", -self.part_size/2, -self.part_size/2, self.part_size, self.part_size)
        love.graphics.pop()
        
        -- 恢复颜色
        love.graphics.setColor(c[1], c[2], c[3])
    end
end

return DestructibleObstacle