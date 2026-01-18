-- src/entities/Plunger.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Plunger = class()

function Plunger:init(world, cx, cy)
    self.world = world
    
    local r = Config.layout.radius
    local chord_y = Config.layout.chord_y
    
    self.startY = cy + chord_y + 15
    self.minY = self.startY
    self.maxY = self.startY + Config.plunger.max_depth -- x_max

    -- 计算宽度
    local half_w = math.sqrt(r*r - chord_y*chord_y)
    local width = half_w * 2 + 20 -- 稍微宽一点嵌入墙体
    local height = 40 

    -- Kinematic Body (动力活塞)
    self.body = love.physics.newBody(world, cx, self.startY, "kinematic")
    self.shape = love.physics.newRectangleShape(width, height)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    self.fixture:setFriction(0.8)
    self.fixture:setRestitution(0.0) 
    self.fixture:setUserData({type = "Plunger", object = self})
    
    self.state = "idle" 
end

function Plunger:update(dt)
    local y = self.body:getY()
    
    -- 计算当前的压缩位移 x
    local displacement = math.max(0, y - self.minY)
    
    if love.keyboard.isDown("space") then
        -- === 蓄力阶段 ===
        self.state = "charging"
        if y < self.maxY then
            self.body:setLinearVelocity(0, Config.plunger.move_down_speed)
        else
            self.body:setLinearVelocity(0, 0)
            self.body:setY(self.maxY)
        end
    else
        -- === 释放阶段 (应用胡克定律逻辑) ===
        if displacement > 2 then -- 如果有位移
            self.state = "releasing"
            
            -- 【物理公式核心】
            -- 势能 Ep = 1/2 * k * x^2
            -- 动能 Ek = 1/2 * m * v^2
            -- 假设能量完全转化 => v 正比于 x * sqrt(k/m)
            -- 简化为: v = k_factor * x
            
            local k = Config.plunger.spring_k
            local v_up = k * displacement * 2 -- *2 是为了调整手感倍率
            
            -- 限制一个最大速度，防止穿模太严重
            v_up = math.min(v_up, 5000) 
            
            -- 设置向上速度
            self.body:setLinearVelocity(0, -v_up)
        else
            -- === 归位 ===
            self.state = "idle"
            self.body:setLinearVelocity(0, 0)
            self.body:setY(self.minY)
        end
    end
end

function Plunger:draw()
    -- 颜色可视化：压缩越厉害，能量越强(红色)
    local offset = self.body:getY() - self.minY
    local ratio = offset / Config.plunger.max_depth
    
    love.graphics.setColor(1, 1 - ratio, 1 - ratio)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
end

return Plunger