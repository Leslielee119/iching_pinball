local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local TriangleBumper = class()

function TriangleBumper:init(world, x, y, side)
    self.x, self.y = x, y
    self.side = side 
    
    local w, h = Config.earth_bumper.width, Config.earth_bumper.height
    
    self.body = love.physics.newBody(world, x, y, "static")
    
    local points = {}
    
    -- 【修改核心】：调整顶点坐标，使靠墙的一侧垂直
    if side == "left" then
        -- 左侧：最左边垂直 (X坐标相同，这里设为 -20)
        points = {
            -20, -20,       -- 左上 (Top-Left) -> 垂直基准线
            -20, h + 10,    -- 左下 (Bottom-Left) -> 垂直基准线
            w, h + 10,      -- 右下 (斜面底部)
            10, 10          -- 斜面折点
        }
    else
        -- 右侧：最右边垂直 (X坐标相同，这里设为 20)
        points = {
            20, -20,        -- 右上 (Top-Right) -> 垂直基准线
            -10, 10,        -- 斜面折点
            -w, h + 10,     -- 左下 (斜面底部)
            20, h + 10      -- 右下 (Bottom-Right) -> 垂直基准线
        }
    end
    
    self.shape = love.physics.newPolygonShape(points)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    self.fixture:setRestitution(0.5) 
    self.fixture:setUserData({type = "EarthBumper", object = self})
    
    self.flashTimer = 0
end

-- 下面的 update, hit, draw 函数保持不变，不需要修改
function TriangleBumper:update(dt)
    if self.flashTimer > 0 then self.flashTimer = self.flashTimer - dt end
end

function TriangleBumper:hit()
    self.flashTimer = Config.earth_bumper.flash_duration
end

function TriangleBumper:draw()
    if self.flashTimer > 0 then love.graphics.setColor(Config.colors.earth_bumper_active)
    else love.graphics.setColor(Config.colors.earth_bumper) end
    
    local height = 25 
    local points = {self.body:getWorldPoints(self.shape:getPoints())}
    
    -- 画顶面
    local topPoints = {}
    for i = 1, #points, 2 do
        local sx, sy = toScreen(points[i], points[i+1], height)
        table.insert(topPoints, sx)
        table.insert(topPoints, sy)
    end
    love.graphics.polygon("fill", topPoints)
    
    -- 画边框
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", topPoints)
    
    -- 画侧面连接线
    love.graphics.setColor(0, 0, 0, 0.2)
    for i = 1, #points, 2 do
        local bx, by = toScreen(points[i], points[i+1], 0)
        local tx, ty = toScreen(points[i], points[i+1], height)
        love.graphics.line(bx, by, tx, ty)
    end
end

return TriangleBumper