require("util/helper")
luafft = require("luafft")

FftData = class("FftData")

function FftData:__init(buffer)
    self.data = fft(buffer, false)
    self.frequencies = {}
    for i = 1, #self.data / 2 do
        local a = math.sqrt(self.data[i][1] ^ 2 + self.data[i][2] ^ 2)
        local f = i * info.sampleRate / BUFFER
        self.frequencies[f] = a
    end
end

function FftData:rangeValue(from, to)
    local values = {}
    for f, a in pairs(self.frequencies) do
        if f >= from and f <= to then
            values[f] = a
        end
    end
    return average(values)
end
