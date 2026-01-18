-- src/ResourceManager.lua
local ResourceManager = {
    fonts = {},
    images = {},
    particles = {}
}

function ResourceManager:load()
    -- 1. 加载字体
    local fontPath = "assets/fonts/font.ttf"
    
    if love.filesystem.getInfo(fontPath) then
        self.fonts.ui = love.graphics.newFont(fontPath, 20)
        self.fonts.gua = love.graphics.newFont(fontPath, 32)
    else
        self.fonts.ui = love.graphics.newFont(16)
        self.fonts.gua = love.graphics.newFont(24)
        print("Warning: Font file not found!")
    end

    -- 2. 创建通用粒子材质
    local particleData = love.image.newImageData(4, 4)
    particleData:mapPixel(function(x, y) return 1, 1, 1, 1 end)
    self.images.particle = love.graphics.newImage(particleData)
end

return ResourceManager