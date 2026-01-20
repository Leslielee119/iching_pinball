-- src/conf/GameConfig.lua
return {
    -- 1. 窗口设置 (1200 x 800)
    window = { width = 1200, height = 800 },
    
    -- 2. 颜色配置 (包含所有阶段的颜色)
    colors = {
        -- 基础环境
        background = {0.1, 0.1, 0.15}, 
        wall = {0.3, 0.3, 0.4},
        
        -- 实体
        flipper = {0.9, 0.4, 0.4},
        obstacle_intact = {0.4, 0.8, 0.8},
        obstacle_debris = {0.3, 0.6, 0.6},
        
        -- 坤·洲 (弹射三角)
        earth_bumper = {0.8, 0.7, 0.3}, 
        earth_bumper_active = {1.0, 1.0, 0.8},
        
        -- 巽·风区
        wind_zone = {0.6, 0.9, 1.0, 0.1},
        
        -- 北斗七星
        star_off = {0.3, 0.3, 0.3},
        star_on = {1.0, 0.9, 0.2},
        star_line = {1.0, 1.0, 0.8, 0.5}
    },


    -- 【新增】2.5D 视觉参数
    view = {
        tilt = 0.7,       -- 倾斜系数 (0.6~0.8 效果最好)
        wall_height = 40, -- 墙壁高度
        ball_height = 12, -- 球的视觉半径/高度
        obs_height = 20   -- 障碍物高度
    },


    -- 3. 物理参数
    physics = { 
        meter = 64, 
        gravity = 60 
    },
    
    -- 4. 布局坐标 (1200宽屏适配)
    layout = {
        cx = 600,
        cy = 400,
        radius = 350,
        inner_radius = 280,
        
        -- 弹射通道
        plunger_x = 1150,
        plunger_y = 700,
        ball_start_x = 1150,
        ball_start_y = 650,
        
        -- 挡板
        left_flipper_x = 420, 
        left_flipper_y = 750,
        right_flipper_x = 780, 
        right_flipper_y = 750,
        
        -- 三角弹射器
        left_bumper_x = 320, 
        left_bumper_y = 470,
        right_bumper_x = 880,
        right_bumper_y = 470
    },

    -- 5. 组件参数
    plunger = {
        move_down_speed = 250, 
        max_depth = 150,
        spring_k = 40 
    },

    flipper = {
        speed = 25, 
        boost_force = 3000,
        length = 130,     -- 挡板长度
        thickness = 25    -- 挡板厚度
    },
    
    earth_bumper = {
        width = 60,
        height = 100,
        kick_force = 1500, 
        flash_duration = 0.1
    },

    wind_zone = {
        x = 600, y = 200,
        width = 300, -- 风区变宽
        height = 150,
        force_x = -1500, 
        force_y = -800  
    },
    
    -- 6. 游戏性与破坏
    destruction = {
        break_threshold = 500,
        debris_lifetime = 1.0, 
        debris_count = 4       
    },

    gameplay = {
        score_per_brick = 10,
        score_per_star = 50,
        score_big_dipper = 5000
    },

    -- 7. 北斗七星坐标 (相对中心偏移)
    -- 我把坐标乘了 1.5 倍左右，让勺子更大
    big_dipper = {
        {x = -180, y = -120}, -- 摇光 (勺柄尾)
        {x = -130, y = -80},  -- 开阳
        {x = -70, y = -50},   -- 玉衡
        {x = 0, y = 0},       -- 天权 (勺身连接处)
        {x = 60, y = 30},     -- 天玑
        {x = 80, y = 90},     -- 天璇
        {x = 20, y = 90}      -- 天枢
    },

    -- 8. 卡牌 (下卦)
    cards = {
        ["Li"] = { name = "离·火", color = {1, 0.3, 0.3}, desc = "破坏力大幅增强" },
        ["Kan"] = { name = "坎·水", color = {0.3, 0.3, 1}, desc = "获得积分翻倍" },
        ["Zhen"] = { name = "震·雷", color = {0.8, 0.8, 0.2}, desc = "弹射速度加快" }
    },
    
    -- 9. 上卦定义
    gua = {
        names = {"乾", "兑", "离", "震", "巽", "坎", "艮", "坤"},
        colors = {
            {0.9, 0.9, 0.9}, {0.8, 0.8, 1.0}, {1.0, 0.4, 0.4}, {0.4, 1.0, 0.4},
            {0.6, 1.0, 0.6}, {0.4, 0.4, 1.0}, {0.6, 0.4, 0.2}, {0.2, 0.2, 0.2}
        }
    }
}