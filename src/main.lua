require("util/resources")
luafft = require("luafft")
id3 = require("id3")

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
info.fft = {}

BUFFER = 2048

currentVisualizer = nil
currentVisualizerInfo = {}

isFullscreen = false
infoFade = 0

function setVisualizer(v)
    local cls = require("visualizers/" .. v .. "/main")
    currentVisualizer = cls()
    currentVisualizer:load()
    currentVisualizerInfo = currentVisualizer:conf()
    infoFade = 5
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

    --[[ renderinfo = {}
    renderinfo.width = 800
    renderinfo.height = 600
    renderinfo.frameRate = 25
    render(renderinfo, 1, info.sampleRate * 3)
    love.event.quit()
    ]]
end

function processAudio()
    if currentVisualizerInfo.generateFFT then
        buffer = {}
        for i = 1, BUFFER do
            buffer[i] = soundData:getSample(info.sample + i)
        end

        info.fft = fft(buffer, false)
        info.fftFreq = {}
        for i = 1, #info.fft / 2 do
            local a = math.sqrt(info.fft[i][1] ^ 2 + info.fft[i][2] ^ 2)
            local f = i * info.sampleRate / BUFFER
            info.fftFreq[f] = a
        end
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
    if currentVisualizerInfo.drawMetainfo then
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
end

function love.draw()
    if not soundData then
        s = "loading"
        love.graphics.print(s,
            love.graphics.getWidth() / 2 - love.graphics.getFont():getWidth(s) / 2,
            love.graphics.getHeight() / 2 - love.graphics.getFont():getHeight() / 2)
        loadFile = true
    elseif fftData then

        for k,v in pairs(fftData) do
            -- print (k .. "\t=> " .. v)
        end
    end

    love.graphics.setColor(255, 255, 255, 100)
    love.graphics.setFont(resources.fonts.lcd)
    love.graphics.print(string.format("%03.f", love.timer.getFPS()), 5, 5)

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
    local ids = id3.readtags(info.filename)

    info.title = ids.title or info.filename
    info.album = ids.album or ""
    info.artist = ids.artist or ""
    info.comment = ids.comment or ""
    info.genre = ids.genre or ""
    info.track = ids.track or 0
    info.year = ids.year or 0

    info.length = soundData:getSize() * 8 / soundData:getBits() / soundData:getChannels()
    info.sampleRate = soundData:getSampleRate()
    info.duration = info.length / info.sampleRate
end

function render(renderinfo, sampleStart, sampleEnd)
    soundSource:pause()
    love.graphics.setMode(renderinfo.width, renderinfo.height, false, false)
    local frameRate = renderinfo.frameRate
    local samplesPerFrame = info.sampleRate / frameRate
    local frames = (sampleEnd - sampleStart) / samplesPerFrame
    local startFrame = sampleStart / samplesPerFrame
    print("Starting render")
    print("")

    for frame = startFrame, startFrame + frames do
        io.write(string.format("\rRendering frame: %04.f of %04.f (%.04f%%)", frame, frames, frame / frames * 100))
        -- fake audio position
        info.sample = math.floor(sampleStart + frame * samplesPerFrame)
        info.position = info.sample / info.sampleRate
        processAudio()
        currentVisualizer:update(1 / frameRate)
        currentVisualizer:draw()
        drawMetainfo()

        -- render to PNG
        local s = love.graphics.newScreenshot()
        s:encode(string.format("%04.f.png", frame))
    end
    print()
    print("Rendering done")
end

