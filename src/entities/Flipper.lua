-- src/entities/Flipper.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Flipper = class()

function Flipper:init(world, x, y, side)
    self.world = world
    self.x, self.y = x, y
    self.side = side 
    
    -- 【修改】从配置读取尺寸，适应宽屏
    local length = Config.flipper.length or 130
    local thickness = Config.flipper.thickness or 25
    
    self.body = love.physics.newBody(world, x, y, "kinematic")
    
    local points = {
        0, -thickness/2,       
        length, -thickness/4,  
        length, thickness/4,   
        0, thickness/2         
    }
    
    self.shape = love.physics.newPolygonShape(points)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setUserData({type = "Flipper", object = self})
    
    -- 角度保持不变 (30度下垂是比较舒服的接球角度)
    if side == "left" then
        self.baseAngle = math.rad(30)    
        self.targetAngle = math.rad(-30) 
        self.key = "left"
    else
        self.baseAngle = math.rad(150)   
        self.targetAngle = math.rad(210) 
        self.key = "right"
    end
    
    self.body:setAngle(self.baseAngle)
    self.isActive = false 
end

function Flipper:update(dt)
    -- ... (保持原有逻辑不变) ...
    local currentAngle = self.body:getAngle()
    local speed = Config.flipper.speed
    
    if love.keyboard.isDown(self.key) then
        self.isActive = true
        if self.side == "left" then
            if currentAngle > self.targetAngle then self.body:setAngularVelocity(-speed)
            else self.body:setAngle(self.targetAngle); self.body:setAngularVelocity(0) end
        else
            if currentAngle < self.targetAngle then self.body:setAngularVelocity(speed)
            else self.body:setAngle(self.targetAngle); self.body:setAngularVelocity(0) end
        end
    else
        self.isActive = false
        if self.side == "left" then
            if currentAngle < self.baseAngle then self.body:setAngularVelocity(speed)
            else self.body:setAngle(self.baseAngle); self.body:setAngularVelocity(0) end
        else
            if currentAngle > self.baseAngle then self.body:setAngularVelocity(-speed)
            else self.body:setAngle(self.baseAngle); self.body:setAngularVelocity(0) end
        end
    end
end

function Flipper:draw()
    if self.isActive then
        love.graphics.setColor(1, 0.6, 0.6)
    else
        love.graphics.setColor(Config.colors.flipper)
    end
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
    love.graphics.circle("fill", self.x, self.y, 5)
end

return Flipper