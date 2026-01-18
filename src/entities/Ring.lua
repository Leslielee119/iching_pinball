-- src/entities/Ring.lua
local class = require "src.utils.class"
local Config = require "src.conf.GameConfig"
local Resources = require "src.ResourceManager"

local Ring = class()

function Ring:init(world, cx, cy, radius, inner_radius)
    self.radius = radius
    self.inner_radius = inner_radius or (radius * 0.7)
    
    self.current_gua_index = 1
    self.current_gua = Config.gua.names[1]

    self.body = love.physics.newBody(world, cx, cy, "kinematic")
    
    -- 物理碰撞层：只需要外圈的链条即可，因为内部是空的
    local segments = 64
    local points = {}
    for i = 1, segments do
        local angle = (i-1) * (2 * math.pi / segments)
        table.insert(points, math.cos(angle) * radius)
        table.insert(points, math.sin(angle) * radius)
    end
    
    self.shape = love.physics.newChainShape(true, points)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setUserData({type = "Ring", object = self})
end

function Ring:update(dt)
    local speed = 2.0
    if love.keyboard.isDown("left") then
        self.body:setAngularVelocity(-speed)
    elseif love.keyboard.isDown("right") then
        self.body:setAngularVelocity(speed)
    else
        self.body:setAngularVelocity(0)
    end

    local angle = self.body:getAngle()
    local target_angle = math.pi / 2
    local relative_angle = (target_angle - angle) % (2 * math.pi)
    if relative_angle < 0 then relative_angle = relative_angle + 2 * math.pi end
    
    local index = math.floor(relative_angle / (math.pi / 4)) + 1
    if index > 8 then index = 1 end
    
    self.current_gua_index = index
    self.current_gua = Config.gua.names[index]
end

function Ring:getCurrentGua()
    return self.current_gua
end

function Ring:draw()
    love.graphics.push()
    love.graphics.translate(self.body:getX(), self.body:getY())
    love.graphics.rotate(self.body:getAngle())
    
    local r_out = self.radius
    local r_in = self.inner_radius
    local text_radius = (r_out + r_in) / 2
    
    -- 1. 扇形
    for i = 1, 8 do
        local color = Config.gua.colors[i]
        local angle1 = (i-1) * (math.pi/4)
        local angle2 = i * (math.pi/4)
        
        love.graphics.setColor(color[1], color[2], color[3], 0.3)
        love.graphics.arc("fill", "pie", 0, 0, r_out, angle1, angle2)
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.setLineWidth(2)
        love.graphics.arc("line", "pie", 0, 0, r_out, angle1, angle2)
    end
    
    -- 2. 遮罩圆 (挖空中间)
    local bg = Config.colors.background
    love.graphics.setColor(bg[1], bg[2], bg[3])
    love.graphics.circle("fill", 0, 0, r_in)
    
    -- 3. 内外边框
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("line", 0, 0, r_in)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r_out)

    -- 4. 文字
    for i = 1, 8 do
        local name = Config.gua.names[i]
        local angle1 = (i-1) * (math.pi/4)
        local angle2 = i * (math.pi/4)
        local mid_angle = (angle1 + angle2) / 2
        
        local tx = math.cos(mid_angle) * text_radius
        local ty = math.sin(mid_angle) * text_radius
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(Resources.fonts.gua)
        local tw = Resources.fonts.gua:getWidth(name)
        local th = Resources.fonts.gua:getHeight()
        love.graphics.print(name, tx, ty, -self.body:getAngle(), 1, 1, tw/2, th/2)
    end
    
    love.graphics.pop()
end

return Ring