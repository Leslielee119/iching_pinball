-- ============================================================
-- I-Ching Pinball (易经弹珠台 - 物理优化版)
-- ============================================================

local Config = require "src.conf.GameConfig"
local Resources = require "src.ResourceManager"
local Ball = require "src.entities.Ball"       
local Flipper = require "src.entities.Flipper"
local Plunger = require "src.entities.Plunger"
local DestructibleObstacle = require "src.entities.DestructibleObstacle"
local TriangleBumper = require "src.entities.TriangleBumper"
local Zone = require "src.entities.Zone" -- 【新增】
local Star = require "src.entities.Star" -- 【新增】

local world
local game = {
    current_gua = "乾",
    active_card = nil, -- 下卦卡牌
    score = 0,
    onPlunger = false
}

local entities = {
    walls = nil,      
    obstacles = {},   
    debris = {},      
    bumpers = {},
    zones = {}, -- 【新增】存放区域
    stars = {} -- 【新增】星星容器
}

local particleSystem
local destroyQueue = {}

function love.load()
    love.window.setTitle("I-Ching Pinball - Physics Optimized")
    love.window.setMode(Config.window.width, Config.window.height)

    Resources:load()

    love.physics.setMeter(Config.physics.meter)
    world = love.physics.newWorld(0, Config.physics.gravity * Config.physics.meter, true)
    world:setCallbacks(beginContact, endContact, nil, postSolve)

    particleSystem = love.graphics.newParticleSystem(Resources.images.particle, 200)
    particleSystem:setParticleLifetime(0.2, 0.5)
    particleSystem:setSpeed(200, 500)
    particleSystem:setColors(1, 1, 0.5, 1, 1, 0, 0, 0)
    particleSystem:setSizes(2, 0)

    createTableWalls()

    -- 实体
    entities.leftFlipper = Flipper(world, Config.layout.left_flipper_x, Config.layout.left_flipper_y, "left")
    entities.rightFlipper = Flipper(world, Config.layout.right_flipper_x, Config.layout.right_flipper_y, "right")
    entities.plunger = Plunger(world, Config.layout.plunger_x, Config.layout.plunger_y)
    entities.ball = Ball(world, Config.layout.ball_start_x, Config.layout.ball_start_y)
    
    -- 坤·洲
    local bumperL = TriangleBumper(world, Config.layout.left_bumper_x, Config.layout.left_bumper_y, "left")
    local bumperR = TriangleBumper(world, Config.layout.right_bumper_x, Config.layout.right_bumper_y, "right")
    table.insert(entities.bumpers, bumperL)
    table.insert(entities.bumpers, bumperR)

    -- 【新增】巽·风区
    local wz = Config.wind_zone
    local windZone = Zone(world, wz.x, wz.y, wz.width, wz.height, wz.force_x, wz.force_y)
    table.insert(entities.zones, windZone)

    generateObstacles()

    -- 【新增】生成北斗七星
    createBigDipper()
end

function love.update(dt)
    world:update(dt)
    particleSystem:update(dt)

    -- 更新实体
    if entities.leftFlipper then entities.leftFlipper:update(dt) end
    if entities.rightFlipper then entities.rightFlipper:update(dt) end
    if entities.plunger then entities.plunger:update(dt) end
    if entities.ball then entities.ball:update(dt) end

    for _, bumper in ipairs(entities.bumpers) do bumper:update(dt) end
    for _, d in ipairs(entities.debris) do 
        d:update(dt)
        if d:isDead() then d:destroy(); table.remove(entities.debris, _); end
    end
    for _, z in ipairs(entities.zones) do z:update(dt) end -- 更新风区动画

    -- 【新增】更新星星动画
    for _, star in ipairs(entities.stars) do star:update(dt) end
    -- 【新增】风区逻辑：检测球是否在风区内
    -- 我们可以用 Box2D 的 GetContactList，或者简单的 AABB 检测，或者利用 begin/endContact 维护标记
    -- 这里最简单直接用 physics body 的包含检测
    for _, zone in ipairs(entities.zones) do
        -- 利用 Box2D 的 testPoint (检测点是否在形状内)
        -- 注意：fixture:testPoint 需要世界坐标
        if zone.fixture:testPoint(entities.ball.body:getX(), entities.ball.body:getY()) then
            -- 施加持续的风力
            entities.ball.body:applyForce(zone.fx, zone.fy)
            
            -- 可选：在风区内生成一点点拖尾粒子
            if love.math.random() < 0.1 then
                particleSystem:setPosition(entities.ball.body:getX(), entities.ball.body:getY())
                particleSystem:emit(1)
            end
        end
    end

    -- 销毁队列
    for _, info in ipairs(destroyQueue) do
        local obs = info.obstacle
        if obs and not obs.is_destroyed then
            -- 加分
            game.score = game.score + Config.gameplay.score_per_brick
            
            local new_debris = obs:breakApart(0, 0, info.force)
            for _, d in ipairs(new_debris) do table.insert(entities.debris, d) end
            for k, v in ipairs(entities.obstacles) do
                if v == obs then table.remove(entities.obstacles, k) break end
            end
        end
    end
    destroyQueue = {}

    -- 重置球
    if entities.ball.body:getY() > Config.window.height + 100 then
        entities.ball:reset()
        entities.ball.body:setPosition(Config.layout.ball_start_x, Config.layout.ball_start_y)
    end

    -- 【新增】检查七星任务状态
    checkBigDipperMission()
end

function love.draw()
    local bg = Config.colors.background
    love.graphics.setBackgroundColor(bg[1], bg[2], bg[3])
    
    if entities.walls then
        love.graphics.setColor(Config.colors.wall)
        love.graphics.setLineWidth(3)
        for _, fix in ipairs(entities.walls:getFixtures()) do
            local shape = fix:getShape()
            love.graphics.line(entities.walls:getWorldPoints(shape:getPoints()))
        end
    end

    -- 绘制风区 (画在底层)
    for _, z in ipairs(entities.zones) do z:draw() end
    drawBigDipperLines() -- 【新增】画连线

    if entities.leftFlipper then entities.leftFlipper:draw() end
    if entities.rightFlipper then entities.rightFlipper:draw() end
    if entities.plunger then entities.plunger:draw() end
    
    for _, obs in ipairs(entities.obstacles) do obs:draw() end
    for _, bumper in ipairs(entities.bumpers) do bumper:draw() end
    -- 【新增】画星星
    for _, star in ipairs(entities.stars) do star:draw() end
    
    if entities.ball then entities.ball:draw() end
    for _, d in ipairs(entities.debris) do d:draw() end
    
    love.graphics.draw(particleSystem)
    drawUI()
end

-- UI和辅助函数省略，保持之前一致...
function drawUI()
    local gw, gh = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Resources.fonts.ui)
    
    love.graphics.print("分数: " .. game.score, 20, 20)
    
    if game.active_card then
        love.graphics.setColor(game.active_card.color)
        love.graphics.print("当前卡牌: " .. game.active_card.name, 20, 50)
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.print(game.active_card.desc, 20, 80)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("点亮北斗七星以获取卦象", 20, 50)
    end
    
    -- 蓄力条
    local p = entities.plunger
    if p then
        local currentY = p.body:getY()
        local displacement = math.max(0, currentY - p.minY)
        local ratio = displacement / Config.plunger.max_depth
        if ratio > 1 then ratio = 1 end
        
        local barX, barY = gw - 40, gh - 200
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", barX, barY, 20, 150)
        love.graphics.setColor(1, 1 - ratio, 0.2)
        love.graphics.rectangle("fill", barX, barY + 150*(1-ratio), 20, 150*ratio)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", barX, barY, 20, 150)
    end
end

function createTableWalls()
    local w, h = Config.window.width, Config.window.height
    local wallBody = love.physics.newBody(world, 0, 0, "static")
    
    -- A. 外框 (适配 1200 宽)
    local outerChain = love.physics.newChainShape(false,
        0, h,          -- 左下
        0, 100,        -- 左上直边
        200, 0,        -- 顶部左圆角
        w-100, 0,      -- 顶部右圆角
        w, 100,        -- 右上直边
        w, h           -- 右下
    )
    love.physics.newFixture(wallBody, outerChain)

    -- B. 弹射通道隔板 (在最右侧)
    local laneX = Config.layout.plunger_x - 30 
    local laneChain = love.physics.newChainShape(false,
        laneX, 200,    -- 通道顶部开口
        laneX, h       -- 通道底部
    )
    love.physics.newFixture(wallBody, laneChain)

    -- C. 底部导向板 (关键：要把球导向挡板)
    -- 左侧导向：从墙壁导向左挡板锚点
    local guideLeft = love.physics.newChainShape(false,
        0, 600, 
        Config.layout.left_flipper_x - 10, Config.layout.left_flipper_y - 20
    )
    love.physics.newFixture(wallBody, guideLeft)
    
    -- 右侧导向：从通道隔板导向右挡板锚点
    local guideRight = love.physics.newChainShape(false,
        laneX, 600,
        Config.layout.right_flipper_x + 10, Config.layout.right_flipper_y - 20
    )
    love.physics.newFixture(wallBody, guideRight)
    
    entities.walls = wallBody
end

function createBigDipper()
    -- 将北斗七星放在屏幕左上区域
    local startX = 600 
    local startY = 350
    for i, pos in ipairs(Config.big_dipper) do
        local star = Star(world, startX + pos.x, startY + pos.y, i)
        table.insert(entities.stars, star)
    end
end

function drawBigDipperLines()
    if #entities.stars < 2 then return end
    love.graphics.setColor(Config.colors.star_line)
    love.graphics.setLineWidth(2)
    -- 按顺序连接
    for i = 1, #entities.stars - 1 do
        local s1 = entities.stars[i]
        local s2 = entities.stars[i+1]
        love.graphics.line(s1.x, s1.y, s2.x, s2.y)
    end
end

function checkBigDipperMission()
    local allLit = true
    for _, star in ipairs(entities.stars) do
        if not star.isLit then allLit = false; break end
    end
    
    -- 如果全亮
    if allLit and #entities.stars > 0 then
        -- 奖励分数
        game.score = game.score + Config.gameplay.score_big_dipper
        
        -- 随机抽取卡牌
        local cardKeys = {"Li", "Kan", "Zhen"}
        local randomKey = cardKeys[love.math.random(1, #cardKeys)]
        game.active_card = Config.cards[randomKey]
        
        -- 重置星星
        for _, star in ipairs(entities.stars) do star:reset() end
        
        -- 特效
        particleSystem:emit(200)
    end
end

function generateObstacles()
    -- 【修改】增加数量，扩大范围
    local max_obstacles = 45 -- 增加数量
    local count = 0
    local attempts = 0
    
    -- 范围：以 cx, cy 为中心，半径覆盖大部分屏幕
    -- 但要避开底部的挡板区域
    
    while count < max_obstacles and attempts < 1000 do
        attempts = attempts + 1
        
        -- 随机生成点 (方形分布或圆形分布)
        -- 宽屏用方形分布可能更均匀
        local x = love.math.random(200, 1000) -- 横向铺开
        local y = love.math.random(150, 500)   -- 纵向集中在中上部
        
        -- 避开风区中心 (可选)
        -- 避开中间八卦文字 (圆心附近)
        local dcx, dcy = x - Config.layout.cx, y - Config.layout.cy
        local dist_center = math.sqrt(dcx*dcx + dcy*dcy)
        
        -- 1. 避开中间太极/文字区 (半径80)
        -- 2. 避开右侧弹射通道 (x > 1100)
        if dist_center > 80 and x < 1100 then
            
            -- 防重叠
            local overlap = false
            for _, obs in ipairs(entities.obstacles) do
                local dx, dy = x - obs.x, y - obs.y
                if math.sqrt(dx*dx + dy*dy) < 85 then 
                    overlap = true; break 
                end
            end
            
            if not overlap then
                local obs = DestructibleObstacle(world, x, y)
                table.insert(entities.obstacles, obs)
                count = count + 1
            end
        end
    end
end

-- ============================================================
-- 物理碰撞回调 (核心物理修正)
-- ============================================================

function beginContact(a, b, coll)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end

    -- 1. Flipper 物理增强 (Flipper Physics 2.0)
    local ball, flipper
    if da.type == "Ball" and db.type == "Flipper" then ball = da.object; flipper = db.object end
    if db.type == "Ball" and da.type == "Flipper" then ball = db.object; flipper = da.object end

    if ball and flipper then
        -- 获取挡板当前的角速度 (正负代表方向)
        local angVel = flipper.body:getAngularVelocity()
        
        -- 判断挡板是否正在“向上弹起”
        -- 左挡板(side='left'): 向上弹是逆时针 (角速度 < 0)
        -- 右挡板(side='right'): 向上弹是顺时针 (角速度 > 0)
        local isMovingUp = false
        local threshold = Config.flipper.min_angular_velocity or 5.0
        
        if flipper.side == "left" and angVel < -threshold then isMovingUp = true end
        if flipper.side == "right" and angVel > threshold then isMovingUp = true end
        
        if isMovingUp then
            -- 【核心优化】使用法线方向施力，而不是无脑向上
            -- coll:getNormal() 返回从 fixtureA 指向 fixtureB 的法线
            local nx, ny = coll:getNormal()
            
            -- 确保法线方向是推开球的方向
            -- 我们不知道A是球还是板，所以做个简单的点积判断或者位置判断
            -- 简单方案：如果A是球，力沿着法线反向？ Box2D法线通常从A指向B
            -- 最稳妥：计算球相对于挡板的方向
            
            -- 直接使用 Impulse 力度
            local force = Config.flipper.boost_force
            
            -- 如果A是球，我们需要力朝向B(挡板)的反方向吗？
            -- Box2D Collision normal points from shape A to shape B
            if da.type == "Ball" then
                -- A是球，B是板。Normal指向板。我们要球远离板，所以用 -Normal
                ball.body:applyLinearImpulse(-nx * force, -ny * force)
            else
                -- A是板，B是球。Normal指向球。直接用 Normal
                ball.body:applyLinearImpulse(nx * force, ny * force)
            end
            
            -- 特效
            particleSystem:setPosition(ball.body:getX(), ball.body:getY())
            particleSystem:emit(30)
        else
            -- 如果挡板没动或者正在回落，球自然反弹，不加作弊力
            -- 这样球停在举起的挡板上时，就不会一直乱跳了
        end
    end

    -- 2. Earth Bumper (坤·洲)
    local earthBumper
    if da.type == "Ball" and db.type == "EarthBumper" then ball = da.object; earthBumper = db.object end
    if db.type == "Ball" and da.type == "EarthBumper" then ball = db.object; earthBumper = da.object end
    
    if ball and earthBumper then
        earthBumper:hit()
        local nx, ny = coll:getNormal()
        local force = Config.earth_bumper.kick_force
        if da.type == "Ball" then ball.body:applyLinearImpulse(nx * force, ny * force)
        else ball.body:applyLinearImpulse(-nx * force, -ny * force) end
        particleSystem:setPosition(ball.body:getX(), ball.body:getY())
        particleSystem:emit(20)
    end

    -- 3. 弹射器检测
    if (da.type == "Ball" and db.type == "Plunger") or (da.type == "Plunger" and db.type == "Ball") then
        game.onPlunger = true
    end
end

function endContact(a, b, coll)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end
    if (da.type == "Ball" and db.type == "Plunger") or (da.type == "Plunger" and db.type == "Ball") then
        game.onPlunger = false
    end
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end
    
    local ball, obstacle
    if da.type == "Ball" and db.type == "Destructible" then ball = da.object; obstacle = db.object end
    if db.type == "Ball" and da.type == "Destructible" then ball = db.object; obstacle = da.object end

    if ball and obstacle then
        local force = normalimpulse
        if force > Config.destruction.break_threshold then
            table.insert(destroyQueue, {obstacle = obstacle, force = force})
            particleSystem:setPosition(ball.body:getX(), ball.body:getY())
            particleSystem:emit(10)
        end
    end
end