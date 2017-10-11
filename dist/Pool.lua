local __addonName, __addon = ...
            __addon.require("./Pool", { "./Profiler", "./Ovale" }, function(__exports, __Profiler, __Ovale)
local _assert = assert
local _setmetatable = setmetatable
local tinsert = table.insert
local _tostring = tostring
local tremove = table.remove
local _wipe = wipe
__exports.OvalePool = __addon.__class(nil, {
    constructor = function(self, name)
        self.pool = nil
        self.size = 0
        self.unused = 0
        self.name = name or "OvalePool"
        self:Drain()
    end,
    Get = function(self)
        _assert(self.pool)
        local item = tremove(self.pool)
        if item then
            self.unused = self.unused - 1
        else
            self.size = self.size + 1
            item = {}
        end
        return item
    end,
    Release = function(self, item)
        _assert(self.pool)
        self:Clean(item)
        _wipe(item)
        tinsert(self.pool, item)
        self.unused = self.unused + 1
    end,
    Drain = function(self)
        self.pool = {}
        self.size = self.size - self.unused
        self.unused = 0
    end,
    DebuggingInfo = function(self)
        __Ovale.Ovale:Print("Pool %s has size %d with %d item(s).", _tostring(self.name), self.size, self.unused)
    end,
    Clean = function(self, item)
    end,
})
end)
