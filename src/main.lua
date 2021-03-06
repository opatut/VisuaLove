require("util/resources")
id3 = require("id3")
require("fftdata")
require("audio")
require("util/getopt_alt")

resources = Resources("data/")
soundData = nil
soundSource = nil

-- CURRENT STATE INFORMATION ABOUT THE SONG
info = {}
info.filename = "data/test.mp3"
info.title = ""
info.album = ""
info.artist = ""
info.comment = ""
info.genre = ""
info.track = 0
info.year = 0
info.position = 0 -- in seconds
info.duration = 0 -- in seconds
info.sample = 0 -- sample number
info.length = 0 -- sample length
info.sampleRate = 0 -- samples per second
info.channels = 2
info.fft = nil
info.amplitude = 0

BUFFER = 2048
WIDTH = 600
HEIGHT = 400

currentVisualizer = nil
currentVisualizerInfo = {}

isFullscreen = false
infoFade = 0
debug = true

function getVisualizers()
    l = love.filesystem.getDirectoryItems("visualizers/")
    vis = {}
    for n, f in pairs(l) do
        if love.filesystem.isDirectory("visualizers/" .. f) and
            love.filesystem.isFile("visualizers/" .. f .. "/main.lua") then
                table.insert(vis, f)
        end
    end
    return vis
end

function setVisualizer(v)
    local cls = require("visualizers/" .. v .. "/main")
    currentVisualizer = cls()
    currentVisualizer:load()
    currentVisualizerInfo = currentVisualizer:conf()
    infoFade = 5
end

function nextVisualizer()
    vis = getVisualizers()
    current = 0
    for n, f in pairs(vis) do
        if f == currentVisualizerInfo.identity then
            current = n
        end
    end

    if current == #vis then current = 1
    else current = current + 1 end
    setVisualizer(vis[current])
end

function previousVisualizer()
    vis = getVisualizers()
    current = #vis
    for n, f in pairs(vis) do
        if f == currentVisualizerInfo.identity then
            current = n
        end
    end

    if current == 1 then current = #vis
    else current = current - 1 end
    setVisualizer(vis[current])
end

function love.load()
    opts = getopt(arg, "frvwh")
    info.filename = opts.f or "data/test.mp3"
    setVisualizer(opts.v or "default")

    defaultWidth, defaultHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local modes = love.window.getFullscreenModes()
    table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end)   -- sort from smallest to largest
    fullscreenWidth, fullscreenHeight = modes[#modes].width, modes[#modes].height
    toggleFullscreen()

    math.randomseed(os.time())

    -- load images
    -- resources:addImage("logo", "logo.png")

    -- load fonts
    resources:addFont("lcd", "liquidcrystal.otf", 40)
    resources:addFont("small", "bankgthd.ttf", 24)
    resources:addFont("normal", "bankgthd.ttf", 32)

    resources:load()
    loadTrack()

    if opts.r ~= nil then
        local i = {}
        i.width = opts.w or 1920
        i.height = opts.h or 1080
        render(i)
        love.event.quit()
    end
end



function love.update(dt)
    if infoFade > 0 then
        infoFade = infoFade - dt
        if infoFade < 0 then infoFade = 0 end
    end

    if soundData and soundSource then
        info.position = soundSource:tell("seconds")
        info.sample = soundSource:tell("samples")
        processAudio()
        currentVisualizer:update(dt)
    end
end

function drawMetainfo()
    if currentVisualizerInfo.displayMetainfo then
        -- TITLE
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(resources.fonts.normal)
        love.graphics.print(info.title, 20, HEIGHT - 100)

        -- ARTIST
        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.setFont(resources.fonts.small)
        love.graphics.print(info.artist, 20, HEIGHT - 65)

        -- TIME
        s = clock(info.position)  .. " - " .. clock(info.duration)
        love.graphics.print(s, 20, HEIGHT - 40)
    end

    if debug then
        love.graphics.setColor(255, 255, 255, 100)
        love.graphics.setFont(resources.fonts.lcd)
        love.graphics.print(string.format("%03.f", love.timer.getFPS()), 5, 5)
    end
end

function love.draw()
    if not soundData then
        s = "loading"
        love.graphics.print(s,
            WIDTH / 2 - love.graphics.getFont():getWidth(s) / 2,
            HEIGHT / 2 - love.graphics.getFont():getHeight() / 2)
        loadFile = true
    end

    if soundSource then
        currentVisualizer:draw()

        if infoFade > 0 then
            local a = infoFade
            local nameWidth = resources.fonts.normal:getWidth(currentVisualizerInfo.name)
            local authorWidth = resources.fonts.small:getWidth(currentVisualizerInfo.author)

            local w = math.max(nameWidth, authorWidth) + 40
            local h = 100
            if a > 1 then a = 1 end
            love.graphics.setColor(0, 0, 0, 100 * a)
            love.graphics.rectangle("fill", WIDTH / 2 - w / 2, 0, w, h)
            love.graphics.setColor(255, 255, 255, a * 255)
            love.graphics.setFont(resources.fonts.normal)
            love.graphics.print(currentVisualizerInfo.name, WIDTH / 2 - nameWidth / 2, 20)

            love.graphics.setColor(255, 255, 255, a * 128)
            love.graphics.setFont(resources.fonts.small)

            love.graphics.print(currentVisualizerInfo.author, WIDTH / 2 - authorWidth / 2, 50)
        end

        drawMetainfo()
    end
end

function toggleFullscreen()
    if isFullscreen then
        WIDTH = defaultWidth
        HEIGHT = defaultHeight

    else
        WIDTH = fullscreenWidth
        HEIGHT = fullscreenHeight
    end
    isFullscreen = not isFullscreen
    love.window.setMode(WIDTH, HEIGHT, {fullscreen=isFullscreen})
end

function love.keypressed(k, u)
    if k == "escape" then
        love.event.quit()
    elseif k == "F11" or k == "f" then
        toggleFullscreen()
    elseif k == "i" then
        infoFade = 5
    elseif k == "p" then
        local s = love.graphics.newScreenshot()
        s:encode("screenshot.png")
    elseif k == "right" then
        nextVisualizer()
    elseif k == "left" then
        previousVisualizer()
    end
end

function love.quit()
end

function render(renderinfo, sampleStart, sampleEnd)
    renderinfo = renderinfo or {}
    renderinfo.width = renderinfo.width or 1920
    renderinfo.height = renderinfo.height or 1080
    renderinfo.framerate = renderinfo.framerate or 25
    renderinfo.extension = renderinfo.extension or "jpg"

    love.window.setMode(600, 400, {fullscreen=false})
    WIDTH, HEIGHT = renderinfo.width, renderinfo.height
    canvas = love.graphics.newCanvas(WIDTH, HEIGHT)

    sampleStart = sampleStart or 1
    sampleEnd = sampleEnd or info.length

    soundSource:pause()
    debug = false
    local samplesPerFrame = info.sampleRate / renderinfo.framerate
    local frames = (sampleEnd - sampleStart) / samplesPerFrame
    local startFrame = sampleStart / samplesPerFrame
    print("")
    print(string.format("Starting Render at %sx%s as %s", renderinfo.width, renderinfo.height, renderinfo.extension))

    local startTime = love.timer.getTime()

    for frame = startFrame, startFrame + frames do
        local t = love.timer.getTime() - startTime
        local fps = frame / t

        -- fake audio position
        love.event.pump()
        for e,a,b,c,d in love.event.poll() do
            if e == "quit" then
                print("")
                print("Aborted.")
                return
            end
            love.handlers[e](a,b,c,d)
        end
        info.sample = math.floor(sampleStart + frame * samplesPerFrame)
        info.position = info.sample / info.sampleRate
        processAudio()
        currentVisualizer:update(1 / renderinfo.framerate)
        -- love.graphics.clear()
        canvas:clear()
        love.graphics.setCanvas(canvas)
        currentVisualizer:draw()
        drawMetainfo()

        io.write(string.format("\rFrame %04.f of %04.f (%.01f%%) - % 4.1f FPS - ETA %s", frame + 1, frames, (frame + 1) / frames * 100, fps, clock((frames - (frame + 1)) / fps)))
        io.flush()

        -- local s = love.graphics.newScreenshot()
        local s = canvas:getImageData()
        s:encode(string.format("%04.f.%s", frame, renderinfo.extension))

        love.graphics.setCanvas()
        love.graphics.setBackgroundColor(0, 0, 0)
        love.graphics.clear()
        local img = love.graphics.newImage(canvas:getImageData())
        love.graphics.draw(img, 0, 0, 0, 600 / WIDTH, 600 / WIDTH)
        local perc = string.format("%.01f%%", (frame + 1) / frames * 100)
        perc = "Rendering " .. perc .. " done - " .. clock((frames - (frame + 1)) / fps) .. " left"
        love.graphics.setFont(resources.fonts.small)
        love.graphics.setColor(255, 255, 255)
        love.graphics.print(perc, 300 - love.graphics.getFont():getWidth(perc) / 2, 355)
        love.graphics.present()
    end
    print()
    print(string.format("Rendering done in %s.", clock(love.timer.getTime() - startTime)))
    print()
    print("Now go to the output directory and execute:")
    print("$ ffmpeg -i %04d." .. renderinfo.extension .. " -i path/to/music.mp3 -framerate 25 -c:a copy movie.mp4")
end
