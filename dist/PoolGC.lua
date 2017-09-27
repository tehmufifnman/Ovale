local OVALE, Ovale = ...
local OvalePoolGC = {}
Ovale.OvalePoolGC = OvalePoolGC
local _setmetatable = setmetatable
local _tostring = tostring
OvalePoolGC.name = "OvalePoolGC"
OvalePoolGC.size = 0
OvalePoolGC.__index = OvalePoolGC
do
    _setmetatable(OvalePoolGC, {
        __call = function(self, ...)
            return self:NewPool(...)
        end
    })
end
local OvalePoolGC = __class()
function OvalePoolGC:NewPool(name)
    name = name or self.name
    return _setmetatable({
        name = name
    }, self)
end
function OvalePoolGC:Get()
    self.size = self.size + 1
    return {}
end
function OvalePoolGC:Release(item)
    self:Clean(item)
end
function OvalePoolGC:Clean(item)
end
function OvalePoolGC:Drain()
    self.size = 0
end
function OvalePoolGC:DebuggingInfo()
    Ovale:Print("Pool %s has size %d.", _tostring(self.name), self.size)
end
