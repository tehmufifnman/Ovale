local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Ovale", { "AceAddon-3.0", "AceGUI-3.0", "./Localization" }, function(__exports, AceAddon, AceGUI, __Localization)
local _assert = assert
local format = string.format
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local _select = select
local strfind = string.find
local _strjoin = strjoin
local strlen = string.len
local strmatch = string.match
local _tostring = tostring
local _tostringall = tostringall
local _type = type
local _unpack = unpack
local _wipe = wipe
local API_GetTime = GetTime
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local INFINITY = math.huge
local OVALE_VERSION = "7.3.0.2"
local REPOSITORY_KEYWORD = "@" .. "project-version" .. "@"
local self_oneTimeMessage = {}
local MAX_REFRESH_INTERVALS = 500
local self_refreshIntervals = {}
local self_refreshIndex = 1
__exports.MakeString = function(s, ...)
    if s and strlen(s) > 0 then
        if ... then
            if strfind(s, "%%%.%d") or strfind(s, "%%[%w]") then
                s = format(s, _tostringall(...))
            else
                s = _strjoin(" ", s, _tostringall(...))
            end
        end
    else
        s = _tostring(nil)
    end
    return s
end
__exports.RegisterPrinter = function(base)
    return __class(base, {
        GetMethod = function(self, methodName, subModule)
            local func, arg = self[methodName], self
            if  not func then
                func, arg = subModule[methodName], subModule
            end
            _assert(func ~= nil)
            return func, arg
        end,
    })
end
local OvaleBase = AceAddon:NewAddon("Ovale", "AceEvent-3.0")
local OvaleClass = __class(OvaleBase, {
    constructor = function(self)
        self.playerClass = _select(2, API_UnitClass("player"))
        self.playerGUID = nil
        self.db = nil
        self.refreshNeeded = {}
        self.inCombat = false
        self.MSG_PREFIX = "Ovale"
        OvaleBase.constructor(self)
        _G["BINDING_HEADER_OVALE"] = "Ovale"
        local toggleCheckBox = __Localization.L["Inverser la boîte à cocher "]
        _G["BINDING_NAME_OVALE_CHECKBOX0"] = toggleCheckBox .. "(1)"
        _G["BINDING_NAME_OVALE_CHECKBOX1"] = toggleCheckBox .. "(2)"
        _G["BINDING_NAME_OVALE_CHECKBOX2"] = toggleCheckBox .. "(3)"
        _G["BINDING_NAME_OVALE_CHECKBOX3"] = toggleCheckBox .. "(4)"
        _G["BINDING_NAME_OVALE_CHECKBOX4"] = toggleCheckBox .. "(5)"
        self.playerGUID = API_UnitGUID("player")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    end,
    PLAYER_ENTERING_WORLD = function(self)
        _wipe(self_refreshIntervals)
        self_refreshIndex = 1
        self:ClearOneTimeMessages()
    end,
    IsPreloaded = function(self, moduleList)
        local preloaded = true
        for _, moduleName in _pairs(moduleList) do
            preloaded = preloaded and self[moduleName].ready
        end
        return preloaded
    end,
    AddRefreshInterval = function(self, milliseconds)
        if milliseconds < INFINITY then
            self_refreshIntervals[self_refreshIndex] = milliseconds
            self_refreshIndex = (self_refreshIndex < MAX_REFRESH_INTERVALS) and (self_refreshIndex + 1) or 1
        end
    end,
    GetRefreshIntervalStatistics = function(self)
        local sumRefresh, minRefresh, maxRefresh, count = 0, INFINITY, 0, 0
        for k, v in _ipairs(self_refreshIntervals) do
            if v > 0 then
                if minRefresh > v then
                    minRefresh = v
                end
                if maxRefresh < v then
                    maxRefresh = v
                end
                sumRefresh = sumRefresh + v
                count = count + 1
            end
        end
        local avgRefresh = (count > 0) and (sumRefresh / count) or 0
        return avgRefresh, minRefresh, maxRefresh, count
    end,
    OneTimeMessage = function(self, ...)
        local s = __exports.MakeString(...)
        if  not self_oneTimeMessage[s] then
            self_oneTimeMessage[s] = true
        end
    end,
    ClearOneTimeMessages = function(self)
        _wipe(self_oneTimeMessage)
    end,
    PrintOneTimeMessages = function(self)
        for s in _pairs(self_oneTimeMessage) do
            if self_oneTimeMessage[s] ~= "printed" then
                self:Print(s)
                self_oneTimeMessage[s] = "printed"
            end
        end
    end,
})
__exports.Ovale = OvaleClass()
end)
