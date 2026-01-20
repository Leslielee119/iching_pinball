-- src/entities/Ball.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Ball = class()

function Ball:init(world, cx, cy)
    self.world = world
    self.radius = 16 
    self.startX = cx
    self.startY = cy 

    self.body = love.physics.newBody(world, self.startX, self.startY, "dynamic")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1) 
    
    self.fixture:setRestitution(0.3)
    self.fixture:setUserData({type = "Ball", object = self})
    
    self.body:setBullet(true) 
end

function Ball:update(dt)
    local vx, vy = self.body:getLinearVelocity()
    local max_speed = 3000
    if vx*vx + vy*vy > max_speed*max_speed then
        local angle = math.atan2(vy, vx)
        self.body:setLinearVelocity(math.cos(angle)*max_speed, math.sin(angle)*max_speed)
    end
end

function Ball:reset()
    self.body:setLinearVelocity(0, 0)
    self.body:setPosition(self.startX, self.startY)
end

function Ball:draw()
    local x, y = self.body:getPosition()
    local r = self.radius
    local tilt = Config.view.tilt or 0.7
    
    -- 1. 绘制影子 (Z=0)
    love.graphics.setColor(0, 0, 0, 0.4)
    local sx_shadow, sy_shadow = toScreen(x, y, 0)
    -- 影子压扁
    love.graphics.ellipse("fill", sx_shadow, sy_shadow, r, r * tilt)
    
    -- 2. 绘制球体 (Z=Config.view.ball_height)
    local h = Config.view.ball_height or 12
    local sx, sy = toScreen(x, y, h)
    
    -- 恢复球的颜色 (由 main.lua 外部设置，或这里重置)
    -- 注意：main.lua 里 set color 会影响这里，这里最好不强制 set white
    -- love.graphics.setColor(1, 1, 1) 
    
    -- 球体视觉上是圆的，不压扁
    love.graphics.circle("fill", sx, sy, r)
    
    -- 高光
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", sx - r*0.3, sy - r*0.3, r*0.3)
end

return Ball