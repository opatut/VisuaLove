require("util/helper")
require("util/resources")

Visualizer = class("Visualizer")

function Visualizer:__init() 
    self.resources = Resources("visualizers/" .. self:conf().identity .. "/")
end

function Visualizer:update(dt) end
function Visualizer:draw()end
function Visualizer:load()end

function Visualizer:conf()
    print("Visualizer:conf() not overwritten - please refer to the default visualizer as example")
    return nil

    --[[conf = {}
    conf.displayMetainfo = true
    conf.displayTime = true
    conf.name = "Default Visualizer"
    conf.identity = "default"
    conf.author = "opatut"
    conf.generateFFT = true
    conf.generateAmplitude = true
    return conf]]
end
