-- helpers for lua coding

-- simplifies OOP
--[[
function class(name, superclass)
    local cls = superclass and superclass() or {}
    cls.__name = name or ""
    cls.__super = superclass
    return setmetatable(cls, {__call = function (c, ...)
        local self = setmetatable({__class = cls}, cls)
        if cls.__init then
            cls.__init(self, ...)
        end
        for k,v in pairs(cls) do
            self[k] = v
        end
        return self
    end})
end
]]--

function class(name, super)
    -- main metadata
    local cls = {}
    cls.__name = name
    cls.__super = super

    -- copy the members of the superclass
    if super then
        for k,v in pairs(super) do
            cls[k] = v
        end
    end

    -- when the class object is being called,
    -- create a new object containing the class'
    -- members, calling its __init with the given
    -- params
    cls = setmetatable(cls, {__call = function(c, ...)
        local obj = {}
        for k,v in pairs(cls) do
            --if not k == "__call" then
                obj[k] = v
            --end
        end
        if obj.__init then obj:__init(...) end
        return obj
    end})
    return cls
end


-- Converts HSL to RGB (input and output range: 0 - 255)
function hsl2rgb(h, s, l)
   if s == 0 then return l,l,l end
   h, s, l = h/256*6, s/255, l/255
   local c = (1-math.abs(2*l-1))*s
   local x = (1-math.abs(h%2-1))*c
   local m,r,g,b = (l-.5*c), 0,0,0
   if h < 1     then r,g,b = c,x,0
   elseif h < 2 then r,g,b = x,c,0
   elseif h < 3 then r,g,b = 0,c,x
   elseif h < 4 then r,g,b = 0,x,c
   elseif h < 5 then r,g,b = x,0,c
   else              r,g,b = c,0,x
   end
   return math.ceil((r+m)*256),math.ceil((g+m)*256),math.ceil((b+m)*256)
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

-- transforms to logarithmic scale
function logF(f, w)
    local maxFreq = info.sampleRate / 2
    local minFreq = info.sampleRate / BUFFER
    return math.log10(f - minFreq + 1) / math.log10(maxFreq - minFreq + 1) * w
end

-----------------------------
-- HSV > RGB color conversion
-----------------------------
-- adapted from:
-- http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
-----------------------------
function hsv2rgb(h, s, v)
  local r, g, b

  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)

  local switch = i % 6
  if switch == 0 then
    r = v g = t b = p
  elseif switch == 1 then
    r = q g = v b = p
  elseif switch == 2 then
    r = p g = v b = t
  elseif switch == 3 then
    r = p g = q b = v
  elseif switch == 4 then
    r = t g = p b = v
  elseif switch == 5 then
    r = v g = p b = q
  end

  return math.floor(r*255), math.floor(g*255), math.floor(b*255)

end



function clock(seconds)
    if seconds <= 0 then
        --return nil;
        return "00:00";
    else
        local h = string.format("%02.f", math.floor(seconds/3600));
        local m = string.format("%02.f", math.floor(seconds/60 - (h*60)));
        local s = string.format("%02.f", math.floor(seconds - h*3600 - m *60));

        local r = ""
        if h ~= "00" then r = h .. ":" end
        return r .. m .. ":" .. s
    end
end

function table_slice (values, start, length)
    local res = {}
    local k = 1
    for i = start, start + length do
        res[k] = values[i]
        k = k + 1
    end
    return res
end
