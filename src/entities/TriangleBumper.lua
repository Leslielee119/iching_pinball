-- src/entities/TriangleBumper.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local TriangleBumper = class()

function TriangleBumper:init(world, x, y, side)
    self.x, self.y = x, y
    self.side = side 
    
    local w = Config.earth_bumper.width
    local h = Config.earth_bumper.height
    
    self.body = love.physics.newBody(world, x, y, "static")
    
    -- 【修改】形状优化：倾斜的弹射台
    -- 坐标原点 (0,0) 是三角形的“顶点”
    local points = {}
    if side == "left" then
        -- 左侧：放在左挡板上方
        -- 形状：直角边在左侧和上侧，斜边朝向右下 (导向挡板)
        -- 或者：更标准的 Slingshot 是斜边朝向右上 (把球弹回场内)
        -- 我们做一个向内倾斜的形状
        points = {
            0, 0,           -- 顶点 (Top)
            -20, h,         -- 左下 (Bottom-Left, 稍微向外扩)
            w, h            -- 右下 (Bottom-Right, 斜面底端)
        }
        -- 这样 (0,0) 到 (w,h) 就是那个弹射斜面
    else
        -- 右侧：镜像
        points = {
            0, 0,           -- 顶点
            -w, h,          -- 左下 (斜面底端)
            20, h           -- 右下 (向外扩)
        }
    end
    
    self.shape = love.physics.newPolygonShape(points)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    self.fixture:setRestitution(0.5) 
    self.fixture:setUserData({type = "EarthBumper", object = self})
    
    self.flashTimer = 0
end

function TriangleBumper:update(dt)
    if self.flashTimer > 0 then self.flashTimer = self.flashTimer - dt end
end

function TriangleBumper:hit()
    self.flashTimer = Config.earth_bumper.flash_duration
end

function TriangleBumper:draw()
    if self.flashTimer > 0 then
        love.graphics.setColor(Config.colors.earth_bumper_active)
    else
        love.graphics.setColor(Config.colors.earth_bumper)
    end
    
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
    
    -- 绘制“坤”字装饰
    love.graphics.setColor(0, 0, 0, 0.5)
    local cx, cy = self.body:getWorldCenter()
    -- 简单的三横线画法
    love.graphics.rectangle("fill", cx-8, cy-8, 16, 3)
    love.graphics.rectangle("fill", cx-8, cy, 16, 3)
    love.graphics.rectangle("fill", cx-8, cy+8, 16, 3)
end

return TriangleBumper