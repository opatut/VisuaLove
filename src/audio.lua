-- audio

function getFftAt(sample, channel)
    channel = channel or 0

    local buffer = {}
    for i = 1, BUFFER do
        buffer[i] = soundData:getSample((sample + i)  * info.channels + channel)
    end
    return FftData(buffer)
end

function getAmplitudeAt(sample, channel)
    local ampBuffer = 32
    local amp = 0

    channel = channel or 0

    for i = 1, ampBuffer do
        local s = soundData:getSample((sample + i) * info.channels + channel)
        amp = amp + math.abs(s)
    end
    return amp / ampBuffer
end

function processAudio()
    local sample = info.sample + currentVisualizerInfo.timeOffset * info.sampleRate

    if currentVisualizerInfo.generateFFT then
        info.fft = getFftAt(sample)
    end

    if currentVisualizerInfo.generateAmplitude then
        info.amplitude = getAmplitudeAt(sample)
    end
end

function copyTrack(from)
    print("Copying sound file from " .. from .. " to " .. info.filename)
    file = love.filesystem.newFile(info.filename)
    file:open("w")
    content = io.open(from):read("*all")
    file:write(content)
    file:close()
end

function loadTrack()
    local path = info.filename
    if not love.filesystem.isFile(info.filename) then
        print("Need to copy.")
        local fn = info.filename

        local i, l = string.find(fn, "%..*$")
        print(i, l)
        local ext = string.sub(fn, i)
        info.filename = "tmp" .. ext
        print("Found at", i, l, ext, info.filename)

        copyTrack(fn)
        path = love.filesystem.getSaveDirectory( ) .. "/" .. info.filename
    end

    file = love.filesystem.newFile(info.filename)

    if not file then
        print("Cannot load file: " .. info.filename)
        love.event.quit()
        return
    end

    local decoder = love.sound.newDecoder(file)
    soundData = love.sound.newSoundData(decoder)

    print("Loaded " .. soundData:getSize() .. " bytes of music.")
    soundSource = love.audio.newSource(soundData)
    soundSource:play()

    local ptr, size = soundData:getPointer()
    local ids = id3.readtags(path) or {}

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

    -- soundSource:seek(info.duration - 10, "seconds")
end
