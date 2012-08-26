require("visualizer")

local V = class("V", Visualizer)

function V:__init()
    Visualizer.__init(self)
    self.lifetime = 0
    self.accu = 0
end

function V:update(dt)
    self.lifetime = self.lifetime + dt

    local f = dt * 1
    local a = info.amplitude * 10

    -- a = info.fft:rangeValue(100, 120) / BUFFER * 10
    -- a = math.log10(a / BUFFER + 1) * 100

    self.accu = self.accu * (1 - f) + a * f
end

function V:draw()
    local r,g,b = hsv2rgb((self.lifetime * 0.05) % 1, 1, 0.5)
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)

    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill",
        0,
        HEIGHT / 2 - 100 * self.accu,
        WIDTH,
        -10)
    love.graphics.rectangle("fill",
        0,
        HEIGHT / 2 + 100 * self.accu,
        WIDTH,
        10)
end

function V:load() end

function V:conf()
    conf = {}
    conf.displayMetainfo = true
    conf.name = "Default Visualizer"
    conf.identity = "default"
    conf.author = "opatut"
    conf.generateFFT = true
    conf.generateAmplitude = true
    conf.timeOffset = 0.01
    return conf
end

return V
