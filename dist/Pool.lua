local OVALE, Ovale = ...
require(OVALE, Ovale, "Pool", { "./OvaleProfiler" }, function(__exports, __OvaleProfiler)
local OvalePool = {}
Ovale.OvalePool = OvalePool
local _assert = assert
local _setmetatable = setmetatable
local tinsert = table.insert
local _tostring = tostring
local tremove = table.remove
local _wipe = wipe
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvalePool, "OvalePool")
OvalePool.name = "OvalePool"
OvalePool.pool = nil
OvalePool.size = 0
OvalePool.unused = 0
OvalePool.__index = OvalePool
do
    _setmetatable(OvalePool, {
        __call = function(self, ...)
            return self:NewPool(...)
        end
    })
end
local OvalePool = __class()
function OvalePool:NewPool(name)
    name = name or self.name
    local obj = _setmetatable({
        name = name
    }, self)
    obj:Drain()
    return obj
end
function OvalePool:Get()
    OvalePool:StartProfiling(self.name)
    _assert(self.pool)
    local item = tremove(self.pool)
    if item then
        self.unused = self.unused - 1
    else
        self.size = self.size + 1
        item = {}
    end
    OvalePool:StopProfiling(self.name)
    return item
end
function OvalePool:Release(item)
    OvalePool:StartProfiling(self.name)
    _assert(self.pool)
    self:Clean(item)
    _wipe(item)
    tinsert(self.pool, item)
    self.unused = self.unused + 1
    OvalePool:StopProfiling(self.name)
end
function OvalePool:Clean(item)
end
function OvalePool:Drain()
    OvalePool:StartProfiling(self.name)
    self.pool = {}
    self.size = self.size - self.unused
    self.unused = 0
    OvalePool:StopProfiling(self.name)
end
function OvalePool:DebuggingInfo()
    Ovale:Print("Pool %s has size %d with %d item(s).", _tostring(self.name), self.size, self.unused)
end
end))
