require("util/resources")
id3 = require("id3")
require("fftdata")

resources = Resources("data/")
soundData = nil
soundSource = nil

frame = 0

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

currentVisualizer = nil
currentVisualizerInfo = {}

isFullscreen = false
infoFade = 0
debug = true

function getVisualizers()
    l = love.filesystem.enumerate("visualizers/")
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
    defaultWidth, defaultHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local modes = love.graphics.getModes()
    table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end)   -- sort from smallest to largest
    fullscreenWidth, fullscreenHeight = modes[#modes].width, modes[#modes].height
    toggleFullscreen()

    if arg[2] then info.filename = arg[2] end

    vis = "default"
    if arg[3] then vis = arg[3] end
    setVisualizer(vis)

    math.randomseed(os.time())

    -- load images
    -- resources:addImage("logo", "logo.png")

    -- load fonts
    resources:addFont("lcd", "liquidcrystal.otf", 40)
    resources:addFont("small", "bankgthd.ttf", 24)
    resources:addFont("normal", "bankgthd.ttf", 32)

    resources:load()
    loadTrack()

    --[[renderinfo = {}
    renderinfo.width = 1920
    renderinfo.height = 1080
    renderinfo.frameRate = 25
    render(renderinfo, 1, info.length)
    love.event.quit()]]

end

function processAudio()
    local gF, gA = currentVisualizerInfo.generateFFT, currentVisualizerInfo.generateAmplitude
    local tO = currentVisualizerInfo.timeOffset

    if gF then
        local buffer = {}
        for i = 1, BUFFER do
            buffer[i] = soundData:getSample((info.sample + tO * info.sampleRate + i)  * info.channels)
        end
        info.fft = FftData(buffer)
    end

    if gA then
        local ampBuffer = 32
        local amp = 0

        for i = 1, ampBuffer do
            local s = soundData:getSample((info.sample + tO * info.sampleRate + i) * info.channels)
            amp = amp + math.abs(s)
        end
        info.amplitude = amp / ampBuffer
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
        love.graphics.print(info.title, 20, love.graphics.getHeight() - 100)

        -- ARTIST
        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.setFont(resources.fonts.small)
        love.graphics.print(info.artist, 20, love.graphics.getHeight() - 65)

        -- TIME
        s = clock(info.position)  .. " - " .. clock(info.duration)
        love.graphics.print(s, 20, love.graphics.getHeight() - 40)
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
            love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth(s) / 2,
            love.graphics.getHeight() / 2 - love.graphics.getFont():getHeight() / 2)
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
            love.graphics.rectangle("fill",
                love.graphics.getWidth() / 2 - w / 2,
                0, -- love.graphics.getHeight() / 2 - h / 2,
                w,
                h)
            love.graphics.setColor(255, 255, 255, a * 255)
            love.graphics.setFont(resources.fonts.normal)
            love.graphics.print(currentVisualizerInfo.name,
                love.graphics.getWidth() / 2 - nameWidth / 2,
                20)

            love.graphics.setColor(255, 255, 255, a * 128)
            love.graphics.setFont(resources.fonts.small)

            love.graphics.print(currentVisualizerInfo.author,
                love.graphics.getWidth() / 2 - authorWidth / 2,
                50)
        end

        drawMetainfo()
    end
end

function toggleFullscreen()
    if isFullscreen then
        love.graphics.setMode(defaultWidth, defaultHeight, false)
    else
        love.graphics.setMode(fullscreenWidth, fullscreenHeight, true)
    end
    isFullscreen = not isFullscreen
end

function love.keypressed(k, u)
    if k == "escape" then
        love.event.quit()
    elseif k == "F11" or k == "f" then
        toggleFullscreen()
    elseif k == "i" then
        infoFade = 5
    elseif k == "p" then
        saveFrame(frame)
        frame = frame + 1
    elseif k == "right" then
        nextVisualizer()
    elseif k == "left" then
        previousVisualizer()
    end
end

function love.quit()
end

function loadTrack()
    local decoder = love.sound.newDecoder(info.filename)
    soundData = love.sound.newSoundData(decoder)

    print("Loaded " .. soundData:getSize() .. " bytes of music.")
    soundSource = love.audio.newSource(soundData)
    soundSource:play()

    local ptr, size = soundData:getPointer()
    local ids = id3.readtags(info.filename) or {}

    info.title = ids.title or info.filename
    info.album = ids.album or ""
    info.artist = ids.artist or ""
    info.comment = ids.comment or ""
    info.genre = ids.genre or ""
    info.track = ids.track or 0
    info.year = ids.year or 0

    info.channels = soundData:getChannels()
    info.length = soundData:getSize() * 8 / soundData:getBits() / info.channels
    info.sampleRate = soundData:getSampleRate()
    info.duration = info.length / info.sampleRate
end

function render(renderinfo, sampleStart, sampleEnd)
    soundSource:pause()
    debug = false
    love.graphics.setMode(renderinfo.width, renderinfo.height, false, false)
    local frameRate = renderinfo.frameRate
    local samplesPerFrame = info.sampleRate / frameRate
    local frames = (sampleEnd - sampleStart) / samplesPerFrame
    local startFrame = sampleStart / samplesPerFrame
    print("Starting render")
    print("")

    local startTime = love.timer.getTime()

    for frame = startFrame, startFrame + frames do
        local t = love.timer.getTime() - startTime
        local fps = frame / t
        io.write(string.format("\rRendering frame: %04.f of %04.f (%.04f%%) - %03.1f FPS - ETA %s", frame, frames, frame / frames * 100, fps, clock(frames / fps)))
        io.flush()

        -- fake audio position
        info.sample = math.floor(sampleStart + frame * samplesPerFrame)
        info.position = info.sample / info.sampleRate
        processAudio()
        currentVisualizer:update(1 / frameRate)
        currentVisualizer:draw()
        drawMetainfo()
        love.graphics.present()

        -- render to PNG
        saveFrame(frame)
    end
    print()
    print("Rendering done")
end

function saveFrame(frame)
    local s = love.graphics.newScreenshot()
    s:encode(string.format("%04.f.png", frame))
end
