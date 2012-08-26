require("visualizer")

local V = class("V", Visualizer)

-- http://nova-fusion.com/2011/07/16/glow-effect-for-lined-shapes-in-love2d/
function glowShape(r, g, b, a, type, ...)
    love.graphics.setColor(r, g, b, 15 * a / 255)
    for i = 7, 2, -1 do
        if i == 2 then
            i = 1
            love.graphics.setColor(r, g, b, a)
        end

        love.graphics.setLineWidth(i)

        if type == "line" then
            love.graphics[type](...)
        else
            love.graphics[type]("line", ...)
        end
    end
end

-- "Sorted by key" table iterator
-- Extracted from http://www.lua.org/pil/19.3.html

function pairsKeySorted(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)

    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end

    return iter
end

DUR = 4

function V:__init()
    Visualizer.__init(self)
    self.lifetime = 0
    self.accu = 0
    self.values = {}
end

function V:update(dt)
    self.lifetime = self.lifetime + dt

    local f = math.min(dt * 10, 1)
    local a = info.amplitude * 5
    self.accu = self.accu * (1 - f) + a * f

    self.values[self.lifetime] = self.accu

    for t, v in pairs(self.values) do
        if t < self.lifetime - DUR then
            self.values[t] = nil
        end
    end
end

function V:draw()
    love.graphics.setBackgroundColor(0, 0, 0)

    local barWidth = 200
    for i = 0, math.max(WIDTH, HEIGHT) / barWidth do
        local r,g,b = hsv2rgb((self.lifetime * 0.2) % 1, 1, 1)
        love.graphics.setColor(r, g, b, 20)

        local o = (self.lifetime / barWidth * 100 % 1) * 2 * barWidth
        local d1 = o + i * barWidth * 2
        local d2 = d1 - barWidth

        love.graphics.polygon("fill",
            0, d1,
            0, d2,
            d2, 0,
            d1, 0)
    end


    local prevX, prevY = -1, 0

    for t, v in pairsKeySorted(self.values) do
        local r,g,b = hsv2rgb((t * 0.2) % 1, 1, 1)
        --local r,g,b = hsv2rgb(1 - v * 0.5, 1, 1)

        local x = (1 - (self.lifetime - t) / DUR) * WIDTH
        local y = v * HEIGHT / 10

        if prevX ~= -1 then
            glowShape(r, g, b, 255, "line", prevX + 1, HEIGHT / 2 + prevY, x, HEIGHT / 2 + y)
            glowShape(r, g, b, 255, "line", prevX + 1, HEIGHT / 2 - prevY, x, HEIGHT / 2 - y)
            -- glowShape(255, 255, 255, "circle", x, y, 10, 10)
        end

        prevX = x
        prevY = y
    end

    glowShape(0, 255, 0, 255, "line", WIDTH / 2, 0, WIDTH / 2, HEIGHT)
end

function V:load() end

function V:conf()
    conf = {}
    conf.displayMetainfo = true
    conf.name = "Lines"
    conf.identity = "lines"
    conf.author = "opatut"
    conf.generateFFT = true
    conf.generateAmplitude = true
    conf.timeOffset = DUR / 2
    return conf
end

return V
