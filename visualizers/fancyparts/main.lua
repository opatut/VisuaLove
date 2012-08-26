require("visualizer")

local Parts = class("Parts")

function Parts:__init(image, buffer)
    self.p = love.graphics.newParticleSystem(image, buffer)
    self.minX = 0
    self.maxX = 0
    self.minY = 0
    self.maxY = 0

    self.eR = 0
end

function Parts:setEmissionRate(rate)
    self.eR = rate
    self.p:setEmissionRate(rate)
end

function Parts:doUpdate(dt)
    self.p:setPosition(
        self.minX + math.random() * (self.maxX - self.minX),
        self.minY + math.random() * (self.maxY - self.minY))
    self.p:update(dt)
end

function Parts:update(dt)
    local accu = dt

    if self.eR == 0 then
        self.p:update(accu)
    else
        local et = 1 / self.eR
        local x, y = self.p:getPosition()

        while accu > et do
            accu = accu - et
            self:doUpdate(et)
        end
        self:doUpdate(accu)
        self.p:setPosition(x, y)
    end
end


-- == -- == -- == -- == -- == -- == -- == -- == -- == -- == -- == --
   -- == -- == -- == -- == -- == -- == -- == -- == -- == -- == --
-- == -- == -- == -- == -- == -- == -- == -- == -- == -- == -- == --

local V = class("V", Visualizer)

function V:__init()
    Visualizer.__init(self)

    self.h = 0
    self.prevSample = 0
end

function V:update(dt)
    self.h = self.h + dt * 20
    local r,g,b = hsv2rgb(self.h / 360, 0.5, 0.5)
    local r2,g2,b2 = hsv2rgb(self.h / 360, 1, 0.8)
    love.graphics.setBackgroundColor(r, g, b)

    self.parts.p:setColors(
        r2, g2, b2, 255,
        r, g, b, 255,
        r, g, b, 255,
        r, g, b, 255,
        r, g, b, 0)
    self.parts:update(dt)
    --self.parts:setEmissionRate(math.min(self.h * 10, 300))
    self.parts:setEmissionRate(math.min(300, info.amplitude * 1000))
    if self.prevSample == info.sample then
        self.parts:setEmissionRate(0)
    end
    self.prevSample = info.sample
end

function V:draw()
    local b = 0
    local bars = 140
    local w = WIDTH - b * 2
    local ww = math.floor(w / bars)
    w = bars * ww
    b = (WIDTH - w) / 2
    local h = HEIGHT / 2 - 100
    local y = HEIGHT / 2

    self.parts.minX = b
    self.parts.maxX = b + w
    self.parts.minY = y
    self.parts.maxY = y

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(
        self.resources.images.gradient,
        0,
        0,
        0,
        WIDTH / 1000,
        HEIGHT / 1000)

    love.graphics.setBlendMode("additive")

    local df = info.sampleRate / BUFFER
    local fPerBar = (BUFFER / 2) / bars

    -- for f, a in pairs(info.fft.frequencies) do
    -- m = 0
    values = {}
    for i = 1, bars do
        local fMin = i * df
        local fMax = (i + 1) * df
        local v = info.fft:rangeValue(fMin, fMax) / BUFFER
        v = math.log10(v + 1) * 3000
        -- m = math.max(v, m)
        values[i] = v
    end


    for i = 1, bars do
        local x = (i - 1) * ww
        -- local v = 1 - math.pow(math.exp(1), -values[i]) / m
        -- v = v / BUFFER * 1000
        v = values[i] / 100 -- / m

        local R,G,B = hsv2rgb(self.h / 360, 0.5, 0.5)
        love.graphics.setColor(R, G, B)
        --[[love.graphics.rectangle("fill",
            x + b,
            0,
            ww - 1,
            HEIGHT) ]]

        --love.graphics.setColor(255, 255, 255)
        --[[ love.graphics.rectangle("fill",
            x + b + 2,
            y,
            ww - 1 - 2 * 2,
            v * h) ]]

        local bW = math.max(ww - 5, 3)
        local bH = v * h + 1

        local sx = bW / 20
        local sy = bH / 200

        love.graphics.draw(self.resources.images.bar,
            x + b + 2 - 10 * sx,
            y - 10 * sy,
            0,
            sx,
            sy)
    end

    love.graphics.draw(self.parts.p, 0, 0)

    --[[local fac = 0.01
    local p = math.sqrt(1.2)
    local I = 4;
    local barCount = 100

    for i = 1, barCount do
        --local from = math.pow(i, p);
        --local to = math.pow(i + 1, p);
        local from = math.exp(p, i + I);
        local to = math.pow(p, i + 1 + I);

        local v = info.fft:rangeValue(from, to) * fac;
        v = 1 - math.pow(math.exp(1), -v);

        love.graphics.rectangle("fill",
            i * 3 + 50,
            200,
            2,
            v * 200 + 2)
    end]]


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

    love.graphics.setBlendMode("alpha")
end

function V:load()
    -- load resources
    self.resources:addImage("gradient", "gradient.png")
    self.resources:addImage("bar", "bar.png")
    self.resources:addImage("particle", "particle.png")
    self.resources:load()

    self.parts = Parts(self.resources.images.particle, 1000)
    self.parts.p:setLifetime(-1)
    self.parts.p:setParticleLife(2)
    self.parts:setEmissionRate(0)
    self.parts.p:setDirection(math.pi / 2)
    self.parts.p:setSpeed(100)
    self.parts.p:setGravity(90)
    self.parts.p:setSizes(
        3 / 32,
        1 / 32
    )
end

function V:conf()
    conf = {}
    conf.displayMetainfo = false
    conf.name = "FancyParts"
    conf.identity = "fancyparts"
    conf.author = "opatut"
    conf.generateFFT = true
    conf.generateAmplitude = true
    conf.timeOffset = 0
    return conf
end

return V
