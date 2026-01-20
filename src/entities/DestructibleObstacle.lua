-- src/entities/DestructibleObstacle.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"
local Debris = require "src.entities.Debris"

local DestructibleObstacle = class()

function DestructibleObstacle:init(world, x, y)
    self.world = world
    self.x, self.y = x, y
    self.is_destroyed = false
    self.radius = 25 
    
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    self.fixture:setRestitution(0.8)
    self.fixture:setUserData({type = "Destructible", object = self})
end

function DestructibleObstacle:breakApart(impactX, impactY, impactForce)
    if self.is_destroyed then return {} end
    self.is_destroyed = true
    self.body:destroy()
    self.body = nil
    
    local debris_list = {}
    local speed_mod = math.max(impactForce * 0.8, 200) 
    
    for i = 1, 4 do
        local angle = (i-1) * (math.pi / 2) + (math.pi/4)
        local offset = self.radius * 0.5
        local dx = math.cos(angle) * offset
        local dy = math.sin(angle) * offset
        local worldX = self.x + dx
        local worldY = self.y + dy
        local vx = math.cos(angle) * speed_mod
        local vy = math.sin(angle) * speed_mod
        local size = self.radius * 0.4
        local d = Debris(self.world, worldX, worldY, size, vx, vy)
        table.insert(debris_list, d)
    end
    
    return debris_list
end

function DestructibleObstacle:draw()
    if self.is_destroyed then return end
    
    local r = self.radius
    local h = Config.view.obs_height or 20
    local tilt = Config.view.tilt or 0.7
    local c = Config.colors.obstacle_intact
    
    local bx, by = toScreen(self.x, self.y, 0) -- 底部
    local tx, ty = toScreen(self.x, self.y, h) -- 顶部
    
    -- 1. 侧面 (颜色暗一点)
    love.graphics.setColor(c[1]*0.7, c[2]*0.7, c[3]*0.7)
    -- 画矩形连接上下
    love.graphics.rectangle("fill", bx - r, ty, r*2, by - ty)
    -- 补底部半圆
    love.graphics.arc("fill", "pie", bx, by, r, 0, math.pi) 
    
    -- 2. 顶面 (亮色)
    love.graphics.setColor(c)
    love.graphics.ellipse("fill", tx, ty, r, r * tilt)
    
    -- 3. 边框
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.ellipse("line", tx, ty, r, r * tilt)
    
    -- 圆心点缀
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.ellipse("fill", tx, ty, r * 0.3, r * 0.3 * tilt)
end

return DestructibleObstacle