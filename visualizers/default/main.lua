require("visualizer")

local V = class("Default", Visualizer)

function V:__init()
    Visualizer.__init(self)

    self.h = 0
end

function V:update(dt)
    self.h = self.h + dt * 20
    r,g,b = hsl2rgb(self.h, 100, 100)
    love.graphics.setBackgroundColor(r, g, b)
end

function average(list)
    a = 0
    n = 0
    for k,v in pairs(list) do
        a = a + v
        n = n + 1
    end
    if n == 0 then return 0 end
    return a / n
end

function rangeValue(from, to)
    local values = {}
    for f, a in pairs(info.fftFreq) do
        if f >= from and f <= to then
            values[f] = a
        end
    end
    return average(values)
end

function logF(f, w)
    local maxFreq = info.sampleRate / 2
    local minFreq = info.sampleRate / BUFFER
    return math.log10(f - minFreq + 1) / math.log10(maxFreq - minFreq + 1) * w
end

function V:draw()
    local b = 100
    local w = love.graphics.getWidth() - b * 2
    local h = love.graphics.getHeight() / 2 - 100
    local y = love.graphics.getHeight() / 2

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(
        self.resources.images.gradient,
        0,
        0,
        0,
        love.graphics.getWidth() / 1000,
        love.graphics.getHeight() / 1000)


    -- TITLE
    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(resources.fonts.normal)
    love.graphics.print(info.title, b, y - 60)

    -- ARTIST
    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.setFont(resources.fonts.small)
    love.graphics.print(info.artist, b, y - 30)

    -- TIME
    s = clock(info.position)  .. " - " .. clock(info.duration)
    love.graphics.print(s, w + b - love.graphics.getFont():getWidth(s), y - 30)


    love.graphics.setColor(255, 255, 255)

    local df = info.sampleRate / BUFFER
    local bars = 100
    local fPerBar = (BUFFER / 2) / bars

    -- for f, a in pairs(info.fftFreq) do
    m = 0
    values = {}
    for i = 1, bars do
        local fMin = i * df
        local fMax = (i + fPerBar - 1) * df
        local v = rangeValue(fMin, fMax)
        m = math.max(v, m)
        values[i] = v
    end

    for i = 1, bars do
        local x = (i - 1) / bars * w
        -- local v = 1 - math.pow(math.exp(1), -values[i]) / m
        -- v = v / BUFFER * 1000
        v = values[i] / m


        love.graphics.rectangle("fill",
            x + b,
            y,
            5,
            v * h)
    end
    print(m)

    --[[local fac = 0.01
    local p = math.sqrt(1.2)
    local I = 4;
    local barCount = 100

    for i = 1, barCount do
        --local from = math.pow(i, p);
        --local to = math.pow(i + 1, p);
        local from = math.exp(p, i + I);
        local to = math.pow(p, i + 1 + I);

        local v = rangeValue(from, to) * fac;
        v = 1 - math.pow(math.exp(1), -v);

        love.graphics.rectangle("fill",
            i * 3 + 50,
            200,
            2,
            v * 200 + 2)
    end]]

end

function V:load()
    -- load resources
    self.resources:addImage("gradient", "gradient.png")
    self.resources:load()
end

function V:conf()
    conf = {}
    conf.displayMetainfo = false
    conf.name = "Default Visualizer"
    conf.identity = "default"
    conf.author = "opatut"
    conf.generateFFT = true
    conf.generateAmplitude = true
    return conf
end

return V
