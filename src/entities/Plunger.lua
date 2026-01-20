-- src/entities/Plunger.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"

local Plunger = class()

function Plunger:init(world)
    self.world = world
    
    -- 位置在右下角通道
    local x = Config.layout.plunger_x
    local y = Config.layout.plunger_y
    self.minY = y
    self.maxY = y + Config.plunger.max_depth
    
    -- 尺寸适应通道宽度
    local width = 40 
    local height = 20

    self.body = love.physics.newBody(world, x, self.minY, "kinematic")
    self.shape = love.physics.newRectangleShape(width, height)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setFriction(0.5)
    self.fixture:setUserData({type = "Plunger", object = self})
    
    self.state = "idle"
end

function Plunger:update(dt)
    local y = self.body:getY()
    local displacement = math.max(0, y - self.minY)
    
    if love.keyboard.isDown("space") then
        -- 蓄力下压
        self.state = "charging"
        if y < self.maxY then
            self.body:setLinearVelocity(0, Config.plunger.move_down_speed)
        else
            self.body:setLinearVelocity(0, 0)
            self.body:setY(self.maxY)
        end
    else
        -- 弹射
        if displacement > 5 then
            self.state = "releasing"
            -- 胡克定律 V = k * x
            local v_up = Config.plunger.spring_k * displacement
            self.body:setLinearVelocity(0, -v_up)
        else
            self.state = "idle"
            self.body:setLinearVelocity(0, 0)
            self.body:setY(self.minY)
        end
    end
end

function Plunger:draw()
    local offset = self.body:getY() - self.minY
    local ratio = offset / Config.plunger.max_depth
    love.graphics.setColor(1, 1 - ratio, 0.2)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
end

return Plunger