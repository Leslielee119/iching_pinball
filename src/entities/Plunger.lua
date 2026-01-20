local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Plunger = class()

function Plunger:init(world, x, y)
    self.world = world
    
    -- 【修复点 1】不再使用 chord_y 计算位置
    -- 直接使用传入的 x, y (来自 Config.layout.plunger_x/y)
    self.startY = y
    self.minY = y
    self.maxY = y + Config.plunger.max_depth

    -- 【修复点 2】不再通过圆半径计算宽度
    -- 给定一个固定的尺寸，适配右侧通道
    local width = 60 
    local height = 20

    -- 创建物理刚体
    self.body = love.physics.newBody(world, x, self.startY, "kinematic")
    self.shape = love.physics.newRectangleShape(width, height)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    self.fixture:setFriction(0.8)
    self.fixture:setRestitution(0.0) 
    self.fixture:setUserData({type = "Plunger", object = self})
    
    self.state = "idle" 
end

function Plunger:update(dt)
    local y = self.body:getY()
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
        -- === 释放阶段 ===
        if displacement > 2 then 
            self.state = "releasing"
            
            -- 胡克定律力度计算
            local k = Config.plunger.spring_k or 50
            local v_up = k * displacement * 2 
            v_up = math.min(v_up, 5000) -- 速度上限
            
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
    -- 2.5D 绘制逻辑
    local offset = self.body:getY() - self.minY
    local ratio = offset / Config.plunger.max_depth
    local height = 20 -- 视觉高度
    
    -- 蓄力越深颜色越亮/红
    love.graphics.setColor(1, 1 - ratio, 1 - ratio)
    
    -- 获取矩形顶点
    local points = {self.body:getWorldPoints(self.shape:getPoints())}
    local topPoints = {}
    
    -- 转换为 2.5D 屏幕坐标
    -- 注意：这里假设 main.lua 中定义了全局函数 toScreen
    -- 如果报错 toScreen nil，请确保 main.lua 正确加载
    for i = 1, #points, 2 do
        local sx, sy = toScreen(points[i], points[i+1], height)
        table.insert(topPoints, sx)
        table.insert(topPoints, sy)
    end
    
    love.graphics.polygon("fill", topPoints)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", topPoints)
end

return Plunger