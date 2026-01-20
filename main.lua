-- ============================================================
-- I-Ching Pinball (2.5D 视觉版)
-- ============================================================

local Config = require "src.conf.GameConfig"
local Resources = require "src.ResourceManager"
local Ball = require "src.entities.Ball"       
local Flipper = require "src.entities.Flipper"
local Plunger = require "src.entities.Plunger"
local DestructibleObstacle = require "src.entities.DestructibleObstacle"
local TriangleBumper = require "src.entities.TriangleBumper"
local Zone = require "src.entities.Zone" 
local Star = require "src.entities.Star" 

local world
local game = {
    current_gua = "乾",
    active_card = nil, 
    score = 0,
    onPlunger = false
}

local entities = {
    walls = nil,      
    obstacles = {},   
    debris = {},      
    bumpers = {},
    zones = {}, 
    stars = {} 
}

local particleSystem
local destroyQueue = {}

-- 【核心函数】2.5D 坐标转换
function toScreen(x, y, z)
    local tilt = Config.view.tilt or 0.7
    return x, (y * tilt) - (z or 0)
end

function love.load()
    love.window.setTitle("I-Ching Pinball - 2.5D")
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

    entities.leftFlipper = Flipper(world, Config.layout.left_flipper_x, Config.layout.left_flipper_y, "left")
    entities.rightFlipper = Flipper(world, Config.layout.right_flipper_x, Config.layout.right_flipper_y, "right")
    entities.plunger = Plunger(world, Config.layout.plunger_x, Config.layout.plunger_y)
    entities.ball = Ball(world, Config.layout.ball_start_x, Config.layout.ball_start_y)
    
    local bumperL = TriangleBumper(world, Config.layout.left_bumper_x, Config.layout.left_bumper_y, "left")
    local bumperR = TriangleBumper(world, Config.layout.right_bumper_x, Config.layout.right_bumper_y, "right")
    table.insert(entities.bumpers, bumperL)
    table.insert(entities.bumpers, bumperR)

    local wz = Config.wind_zone
    local windZone = Zone(world, wz.x, wz.y, wz.width, wz.height, wz.force_x, wz.force_y)
    table.insert(entities.zones, windZone)

    generateObstacles()
    createBigDipper()
end

function love.update(dt)
    world:update(dt)
    particleSystem:update(dt)

    -- 1. 更新基础实体
    if entities.leftFlipper then entities.leftFlipper:update(dt) end
    if entities.rightFlipper then entities.rightFlipper:update(dt) end
    if entities.plunger then entities.plunger:update(dt) end
    if entities.ball then entities.ball:update(dt) end

    -- 更新列表类型的实体
    for _, bumper in ipairs(entities.bumpers) do bumper:update(dt) end
    for _, z in ipairs(entities.zones) do z:update(dt) end 
    for _, star in ipairs(entities.stars) do star:update(dt) end

    -- 2. 风区物理逻辑
    for _, zone in ipairs(entities.zones) do
        -- 利用 Box2D 的 testPoint 检测球是否在风区内
        if zone.fixture:testPoint(entities.ball.body:getX(), entities.ball.body:getY()) then
            entities.ball.body:applyForce(zone.fx, zone.fy)
            -- 随机粒子特效
            if love.math.random() < 0.1 then
                particleSystem:setPosition(entities.ball.body:getX(), entities.ball.body:getY())
                particleSystem:emit(1)
            end
        end
    end

    -- 3. 【核心修复】碎片更新与清理
    -- 必须使用倒序循环 (#list, 1, -1)，否则 table.remove 会导致索引错乱或遗漏
    for i = #entities.debris, 1, -1 do
        local d = entities.debris[i]
        d:update(dt)
        if d:isDead() then 
            d:destroy() -- 销毁物理刚体
            table.remove(entities.debris, i) -- 从列表中安全移除
        end
    end

    -- 4. 处理销毁队列 (物理破坏)
    for _, info in ipairs(destroyQueue) do
        local obs = info.obstacle
        if obs and not obs.is_destroyed then
            -- 加分
            game.score = game.score + Config.gameplay.score_per_brick
            
            -- 生成碎片
            local new_debris = obs:breakApart(0, 0, info.force)
            for _, d in ipairs(new_debris) do 
                table.insert(entities.debris, d) 
            end
            
            -- 从障碍物列表中移除
            for k, v in ipairs(entities.obstacles) do
                if v == obs then 
                    table.remove(entities.obstacles, k) 
                    break 
                end
            end
        end
    end
    destroyQueue = {} -- 清空队列

    -- 5. 球出界重置
    if entities.ball.body:getY() > Config.window.height + 100 then
        entities.ball:reset()
        entities.ball.body:setPosition(Config.layout.ball_start_x, Config.layout.ball_start_y)
    end

    -- 6. 检查任务状态
    checkBigDipperMission()
end

function love.draw()
    local bg = Config.colors.background
    love.graphics.setBackgroundColor(bg[1], bg[2], bg[3])
    
    -- 向下平移以居中显示
    love.graphics.push()
    love.graphics.translate(0, 50) 

    -- 1. 地面层 (Zone, Star, 连线, 墙壁底座)
    for _, z in ipairs(entities.zones) do z:draw() end
    drawBigDipperLines() 
    for _, star in ipairs(entities.stars) do star:draw() end

    -- 2. 墙壁立体化
    if entities.walls then
        local wallH = Config.view.wall_height or 40
        for _, fix in ipairs(entities.walls:getFixtures()) do
            local shape = fix:getShape()
            local points = {entities.walls:getWorldPoints(shape:getPoints())}
            for i = 1, #points, 2 do
                local x1, y1 = points[i], points[i+1]
                local x2, y2
                if i + 2 > #points then x2, y2 = points[1], points[2] else x2, y2 = points[i+2], points[i+3] end
                
                local bx1, by1 = toScreen(x1, y1, 0)
                local tx1, ty1 = toScreen(x1, y1, wallH)
                local bx2, by2 = toScreen(x2, y2, 0)
                local tx2, ty2 = toScreen(x2, y2, wallH)
                
                love.graphics.setColor(Config.colors.wall)
                love.graphics.polygon("fill", bx1, by1, bx2, by2, tx2, ty2, tx1, ty1)
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.line(tx1, ty1, tx2, ty2)
            end
        end
    end

    -- 3. 立体实体 (障碍物, 挡板, 弹射器, 弹珠, 碎片)
    if entities.leftFlipper then entities.leftFlipper:draw() end
    if entities.rightFlipper then entities.rightFlipper:draw() end
    if entities.plunger then entities.plunger:draw() end
    
    for _, obs in ipairs(entities.obstacles) do obs:draw() end
    for _, bumper in ipairs(entities.bumpers) do bumper:draw() end
    for _, d in ipairs(entities.debris) do d:draw() end
    
    if entities.ball then 
        if game.active_card then
            love.graphics.setColor(game.active_card.color)
        else
            love.graphics.setColor(1, 1, 1)
        end
        entities.ball:draw() 
    end
    
    -- 粒子系统 (不转换，直接画)
    love.graphics.draw(particleSystem)
    
    love.graphics.pop()

    drawUI()
end

function drawUI()
    -- ... (保持之前的 drawUI 不变) ...
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
    local outerChain = love.physics.newChainShape(false, 0, h, 0, 100, 200, 0, w-100, 0, w, 100, w, h)
    love.physics.newFixture(wallBody, outerChain)
    local laneX = Config.layout.plunger_x - 30 
    local laneChain = love.physics.newChainShape(false, laneX, 200, laneX, h)
    love.physics.newFixture(wallBody, laneChain)
    local guideLeft = love.physics.newChainShape(false, 0, 600, Config.layout.left_flipper_x - 10, Config.layout.left_flipper_y - 20)
    love.physics.newFixture(wallBody, guideLeft)
    local guideRight = love.physics.newChainShape(false, laneX, 600, Config.layout.right_flipper_x + 10, Config.layout.right_flipper_y - 20)
    love.physics.newFixture(wallBody, guideRight)
    entities.walls = wallBody
end

function createBigDipper()
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
    for i = 1, #entities.stars - 1 do
        local s1, s2 = entities.stars[i], entities.stars[i+1]
        local sx1, sy1 = toScreen(s1.x, s1.y, 0)
        local sx2, sy2 = toScreen(s2.x, s2.y, 0)
        love.graphics.line(sx1, sy1, sx2, sy2)
    end
end

function checkBigDipperMission()
    local allLit = true
    for _, star in ipairs(entities.stars) do if not star.isLit then allLit = false; break end end
    if allLit and #entities.stars > 0 then
        game.score = game.score + Config.gameplay.score_big_dipper
        local cardKeys = {"Li", "Kan", "Zhen"}
        local randomKey = cardKeys[love.math.random(1, #cardKeys)]
        game.active_card = Config.cards[randomKey]
        for _, star in ipairs(entities.stars) do star:reset() end
        particleSystem:emit(200)
    end
end

function generateObstacles()
    local max_obstacles = 45 
    local count = 0
    local attempts = 0
    while count < max_obstacles and attempts < 1000 do
        attempts = attempts + 1
        local x = love.math.random(200, 1000) 
        local y = love.math.random(150, 500)   
        local dcx, dcy = x - Config.layout.cx, y - Config.layout.cy
        local dist_center = math.sqrt(dcx*dcx + dcy*dcy)
        if dist_center > 80 and x < 1100 then
            local overlap = false
            for _, obs in ipairs(entities.obstacles) do
                local dx, dy = x - obs.x, y - obs.y
                if math.sqrt(dx*dx + dy*dy) < 85 then overlap = true; break end
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
-- 物理碰撞回调
-- ============================================================

function beginContact(a, b, coll)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end

    -- 辅助函数：快速获取球和其他对象
    local function getObject(type)
        if da.type == type then return da.object end
        if db.type == type then return db.object end
        return nil
    end

    local ball = getObject("Ball")
    if not ball then return end -- 如果没有球参与碰撞，直接返回

    -- === 1. 北斗七星检测 (Sensor) ===
    local star = getObject("Star")
    if star then
        -- 调试日志
        -- print("HIT STAR! ID:", star.id) 
        if star:activate() then
            game.score = game.score + Config.gameplay.score_per_star
            particleSystem:setPosition(star.x, star.y)
            particleSystem:emit(10)
        end
        return -- Sensor 不产生物理碰撞，逻辑处理完即可返回
    end

    -- === 2. 挡板物理增强 (Flipper Physics 2.0) ===
    -- 这是你要求的核心改动：基于角速度的暴击逻辑
    local flipper = getObject("Flipper")
    if flipper then
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
            local force = Config.flipper.boost_force or 3000
            
            -- Box2D 碰撞法线方向是从 A 指向 B
            -- 我们需要给球一个远离挡板的力
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
            -- 如果挡板静止（比如按住不放球落下来），不加额外力，自然反弹
        end
    end

    -- === 3. 三角形弹射 (EarthBumper) ===
    local earthBumper = getObject("EarthBumper")
    if earthBumper then
        earthBumper:hit()
        local nx, ny = coll:getNormal()
        local force = Config.earth_bumper.kick_force
        
        -- 确保力是推开球的
        if da.type == "Ball" then 
            ball.body:applyLinearImpulse(nx * force, ny * force)
        else 
            ball.body:applyLinearImpulse(-nx * force, -ny * force) 
        end
        
        particleSystem:setPosition(ball.body:getX(), ball.body:getY())
        particleSystem:emit(20)
    end

    -- === 4. 弹射器接触检测 (Plunger) ===
    local plunger = getObject("Plunger")
    if plunger then
        game.onPlunger = true
    end
end

function endContact(a, b, coll)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end
    if (da.type == "Ball" and db.type == "Plunger") or (da.type == "Plunger" and db.type == "Ball") then game.onPlunger = false end
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
    local da, db = a:getUserData(), b:getUserData()
    if not da or not db then return end
    local ball, obstacle
    if da.type == "Ball" and db.type == "Destructible" then ball = da.object; obstacle = db.object end
    if db.type == "Ball" and da.type == "Destructible" then ball = db.object; obstacle = da.object end
    if ball and obstacle then
        local force = normalimpulse
        local threshold = Config.destruction.break_threshold
        if game.active_card and game.active_card.name == "离·火" then threshold = threshold * 0.5 end
        if force > threshold then
            table.insert(destroyQueue, {obstacle = obstacle, force = force})
            particleSystem:setPosition(ball.body:getX(), ball.body:getY())
            particleSystem:emit(10)
        end
    end
end