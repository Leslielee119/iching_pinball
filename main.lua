-- main.lua
local Config = require "src.conf.GameConfig"
local Resources = require "src.ResourceManager"
local Ball = require "src.entities.Ball"       
local Ring = require "src.entities.Ring"       
local Plunger = require "src.entities.Plunger"
local DestructibleObstacle = require "src.entities.DestructibleObstacle"

local world
local game = { current_gua = "乾" }
local entities = { obstacles = {}, debris = {} }
local particleSystem
local destroyQueue = {}

function love.load()
    love.window.setTitle("I-Ching Pinball - Random Layout")
    love.window.setMode(Config.window.width, Config.window.height)

    Resources:load()

    love.physics.setMeter(Config.physics.meter)
    world = love.physics.newWorld(0, Config.physics.gravity * Config.physics.meter, true)
    world:setCallbacks(beginContact, endContact, nil, postSolve)

    particleSystem = love.graphics.newParticleSystem(Resources.images.particle, 100)
    particleSystem:setParticleLifetime(0.3, 0.6)
    particleSystem:setSpeed(100, 300)
    particleSystem:setColors(1, 1, 0.5, 1, 1, 0, 0, 0)
    particleSystem:setSizes(2, 0)

    -- 1. 创建大圆环
    entities.ring = Ring(world, Config.layout.cx, Config.layout.cy, Config.layout.radius, Config.layout.inner_radius)
    -- 2. 创建弹射板
    entities.plunger = Plunger(world, Config.layout.cx, Config.layout.cy)
    -- 3. 创建球
    entities.ball = Ball(world, Config.layout.cx, Config.layout.cy)
    
    -- ==========================================================
    -- 【核心修改】障碍物随机散布算法
    -- ==========================================================
    local count = 0
    local max_obstacles = 25      -- 目标生成数量
    local attempts = 0
    local max_attempts = 200      -- 防止死循环
    
    local safe_radius = 20        -- 障碍物半径 (用于防重叠)
    local spawn_radius_min = 50   -- 距离圆心最近
    local spawn_radius_max = Config.layout.inner_radius - 40 -- 距离圆心最远 (要在内圆内)

    while count < max_obstacles and attempts < max_attempts do
        attempts = attempts + 1
        
        -- 1. 极坐标随机生成: 随机角度，随机半径
        local angle = love.math.random() * math.pi * 2
        -- 半径开根号分布，防止圆心聚集过多 (Area sampling)
        local r_min2 = spawn_radius_min * spawn_radius_min
        local r_max2 = spawn_radius_max * spawn_radius_max
        local r = math.sqrt(love.math.random() * (r_max2 - r_min2) + r_min2)
        
        local x = Config.layout.cx + math.cos(angle) * r
        local y = Config.layout.cy + math.sin(angle) * r

        -- 2. 额外过滤：不要生成在弹射板正上方的通道，防止挡路
        -- 弹射通道大概在 x=cx 左右，宽度 60
        if math.abs(x - Config.layout.cx) < 40 and y > Config.layout.cy then
             -- 跳过这次生成，保护弹射路径
             goto continue
        end

        -- 3. 防重叠检测
        local overlap = false
        for _, obs in ipairs(entities.obstacles) do
            local dx = x - obs.x -- DestructibleObstacle 需要存 x,y
            local dy = y - obs.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < (safe_radius * 2 + 10) then -- 留10px间隙
                overlap = true
                break
            end
        end

        if not overlap then
            local obs = DestructibleObstacle(world, x, y)
            table.insert(entities.obstacles, obs)
            count = count + 1
        end
        
        ::continue::
    end
end

function love.update(dt)
    world:update(dt)
    particleSystem:update(dt)

    entities.ring:update(dt)
    entities.plunger:update(dt)
    entities.ball:update(dt)

    -- 更新碎片
    for i = #entities.debris, 1, -1 do
        local d = entities.debris[i]
        d:update(dt)
        if d:isDead() then
            d:destroy()
            table.remove(entities.debris, i)
        end
    end

    -- 处理销毁
    for _, info in ipairs(destroyQueue) do
        local obs = info.obstacle
        local force = info.force
        if not obs.is_destroyed then
            local new_debris = obs:breakApart(0, 0, force)
            for _, d in ipairs(new_debris) do table.insert(entities.debris, d) end
            for k, v in ipairs(entities.obstacles) do
                if v == obs then table.remove(entities.obstacles, k) break end
            end
        end
    end
    destroyQueue = {}

    game.current_gua = entities.ring:getCurrentGua()
    
    if entities.ball.body:getY() > Config.window.height + 100 then
        entities.ball:reset()
    end
end

function love.draw()
    local bg = Config.colors.background
    love.graphics.setBackgroundColor(bg[1], bg[2], bg[3])
    
    entities.ring:draw()
    entities.plunger:draw()
    
    -- 画障碍物
    for _, obs in ipairs(entities.obstacles) do
        obs:draw()
    end
    
    entities.ball:draw()
    
    -- 画碎片
    for _, debris in ipairs(entities.debris) do
        debris:draw()
    end

    love.graphics.draw(particleSystem)
    drawUI()
end

function drawUI()
    local gw, gh = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Resources.fonts.ui)
    
    love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 20)
    love.graphics.print("当前卦象: " .. game.current_gua, 20, 50)
    
    -- 蓄力条 (根据压缩量绘制)
    local p = entities.plunger
    if p then
        local currentY = p.body:getY()
        local displacement = math.max(0, currentY - p.minY)
        local ratio = displacement / Config.plunger.max_depth
        if ratio > 1 then ratio = 1 end
        
        local barWidth = 300
        local barHeight = 15
        local barX = gw/2 - barWidth/2
        local barY = gh - 60
        
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
        
        -- 颜色随力度变化
        love.graphics.setColor(1, 1 - ratio, 0.2)
        love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("按住 [空格] 蓄力，力度由压缩量决定 (F=kx)", 0, gh - 40, gw, "center")
end

-- 物理回调
function beginContact(a, b, coll) end
function endContact(a, b, coll) end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end

    local ball, obstacle
    if da.type == "Ball" and db.type == "Destructible" then
        ball = da.object; obstacle = db.object
    elseif db.type == "Ball" and da.type == "Destructible" then
        ball = db.object; obstacle = da.object
    end

    if ball and obstacle then
        local force = normalimpulse
        if force > Config.destruction.break_threshold then
            table.insert(destroyQueue, {obstacle = obstacle, force = force})
            particleSystem:setPosition(ball.body:getX(), ball.body:getY())
            particleSystem:emit(10)
        end
    end
end