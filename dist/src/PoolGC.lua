local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./src/PoolGC", { "./src/Ovale" }, function(__exports, __Ovale)
local _setmetatable = setmetatable
local _tostring = tostring
__exports.OvalePoolGC = __class(nil, {
    constructor = function(self, name)
        self.name = "OvalePoolGC"
        self.size = 0
        self.__index = __exports.OvalePoolGC
        self.name = name
    end,
    Get = function(self)
        self.size = self.size + 1
        return {}
    end,
    Release = function(self, item)
        self:Clean(item)
    end,
    Clean = function(self, item)
    end,
    Drain = function(self)
        self.size = 0
    end,
    DebuggingInfo = function(self)
        __Ovale.Ovale:Print("Pool %s has size %d.", _tostring(self.name), self.size)
    end,
})
end)
