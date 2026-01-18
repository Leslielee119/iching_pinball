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
    self.fixture = love.physics.newFixture(self.body, self.shape, 1) -- 密度1
    
    self.fixture:setRestitution(0.3) -- 球不需要太弹，主要靠板子撞
    self.fixture:setUserData({type = "Ball", object = self})
    
    -- 必须开启子弹模式
    self.body:setBullet(true) 
end

function Ball:update(dt)
    -- 限制最大速度，防止飞出宇宙
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
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
end

return Ball