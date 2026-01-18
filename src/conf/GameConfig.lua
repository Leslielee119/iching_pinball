-- src/conf/GameConfig.lua
return {
    window = { width = 1200, height = 800 },
    
    colors = {
        background = {0.15, 0.15, 0.2},
        obstacle_intact = {0.4, 0.8, 0.8},
        obstacle_debris = {0.3, 0.6, 0.6}
    },

    physics = { 
        meter = 64, 
        gravity = 60 
    },
    
    layout = {
        cx = 600,       
        cy = 400,       
        -- 【修改】加大圆环，变薄边缘
        radius = 380,       -- 外圆极大，接近屏幕边缘
        inner_radius = 340, -- 内圆也很大，留出中间巨大的空间
        chord_y = 300       -- 弹射板位置下移
    },

    plunger = {
        -- 下压速度
        move_down_speed = 250, 
        -- 最大下沉距离 (x_max)
        max_depth = 150,
        
        -- 【新增】弹簧劲度系数 k (用于计算弹射力度)
        -- 公式: v = spring_k * displacement
        spring_k = 30 
    },
    
    destruction = {
        break_threshold = 600, -- 稍微降低阈值，因为空间大了球容易减速
        debris_lifetime = 2.0, 
        debris_count = 4       
    },
    
    gua = {
        names = {"乾", "兑", "离", "震", "巽", "坎", "艮", "坤"},
        colors = {
            {0.9, 0.9, 0.9}, {0.8, 0.8, 1.0}, {1.0, 0.4, 0.4}, {0.4, 1.0, 0.4},
            {0.6, 1.0, 0.6}, {0.4, 0.4, 1.0}, {0.6, 0.4, 0.2}, {0.2, 0.2, 0.2}
        }
    }
}