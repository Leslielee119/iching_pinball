local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local PachinkoSlot = class()

function PachinkoSlot:init(world, x, y, w, h, guaName)
    self.guaName = guaName
    self.isActive = false
    
    -- 传感器主体
    self.body = love.physics.newBody(world, x, y, "static")
    self.shape = love.physics.newRectangleShape(w, h)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setSensor(true)
    self.fixture:setUserData({type = "Slot", object = self})
    
    -- 视觉尺寸
    self.w, self.h = w, h
end

function PachinkoSlot:activate()
    self.isActive = true
    -- 可以在这里加闪烁动画逻辑
end

function PachinkoSlot:deactivate()
    self.isActive = false
end

function PachinkoSlot:draw()
    if self.isActive then
        love.graphics.setColor(Config.colors.slot_active)
    else
        love.graphics.setColor(Config.colors.slot_inactive)
    end
    -- 画一个空心框
    love.graphics.rectangle("line", self.body:getX() - self.w/2, self.body:getY() - self.h/2, self.w, self.h)
    
    -- 画文字
    love.graphics.print(self.guaName, self.body:getX() - 10, self.body:getY() - 10)
end

return PachinkoSlot