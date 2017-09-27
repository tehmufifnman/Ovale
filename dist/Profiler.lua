local OVALE, Ovale = ...
require(OVALE, Ovale, "Profiler", { "./L", "./OvaleOptions", "./db" }, function(__exports, __L, __OvaleOptions, __db)
local OvaleProfiler = Ovale:NewModule("OvaleProfiler")
Ovale.OvaleProfiler = OvaleProfiler
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibTextDump = LibStub("LibTextDump-1.0")
local _debugprofilestop = debugprofilestop
local format = string.format
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local tconcat = table.concat
local tinsert = table.insert
local tsort = table.sort
local _wipe = wipe
local API_GetTime = GetTime
local self_timestamp = _debugprofilestop()
local self_stack = {}
local self_stackSize = 0
local self_timeSpent = {}
local self_timesInvoked = {}
local self_profilingOutput = nil
do
    local actions = {
        profiling = {
            name = __L.L["Profiling"],
            type = "execute",
            func = function()
                local appName = OvaleProfiler:GetName()
                AceConfigDialog:SetDefaultSize(appName, 800, 550)
                AceConfigDialog:Open(appName)
            end
        }
    }
    for k, v in _pairs(actions) do
        __OvaleOptions.OvaleOptions.options.args.actions.args[k] = v
    end
    __OvaleOptions.OvaleOptions.defaultDB.global = __OvaleOptions.OvaleOptions.defaultDB.global or {}
    __OvaleOptions.OvaleOptions.defaultDB.global.profiler = {}
    __OvaleOptions.OvaleOptions:RegisterOptions(OvaleProfiler)
end
OvaleProfiler.options = {
    name = OVALE + " " + __L.L["Profiling"],
    type = "group",
    args = {
        profiling = {
            name = __L.L["Profiling"],
            type = "group",
            args = {
                modules = {
                    name = __L.L["Modules"],
                    type = "group",
                    inline = true,
                    order = 10,
                    args = {},
                    get = function(info)
                        local name = info[#info]
                        return (__db.value ~= nil)
                    end,
                    set = function(info, __db.value)
                        __db.value = __db.value or nil
                        local name = info[#info]
                        Ovale.db.global.profiler[name] = __db.value
                        if __db.value then
                            OvaleProfiler:EnableProfiling(name)
                        else
                            OvaleProfiler:DisableProfiling(name)
                        end
                    end
                },
                reset = {
                    name = __L.L["Reset"],
                    desc = __L.L["Reset the profiling statistics."],
                    type = "execute",
                    order = 20,
                    func = function()
                        OvaleProfiler:ResetProfiling()
                    end
                },
                show = {
                    name = __L.L["Show"],
                    desc = __L.L["Show the profiling statistics."],
                    type = "execute",
                    order = 30,
                    func = function()
                        self_profilingOutput:Clear()
                        local s = OvaleProfiler:GetProfilingInfo()
                        if s then
                            self_profilingOutput:AddLine(s)
                            self_profilingOutput:Display()
                        end
                    end
                }
            }
        }
    }
}
local DoNothing = function()
end
local StartProfiling = function(_, tag)
    local newTimestamp = _debugprofilestop()
    if self_stackSize > 0 then
        local delta = newTimestamp - self_timestamp
        local previous = self_stack[self_stackSize]
        local timeSpent = self_timeSpent[previous] or 0
        timeSpent = timeSpent + delta
        self_timeSpent[previous] = timeSpent
    end
    self_timestamp = newTimestamp
    self_stackSize = self_stackSize + 1
    self_stack[self_stackSize] = tag
    do
        local timesInvoked = self_timesInvoked[tag] or 0
        timesInvoked = timesInvoked + 1
        self_timesInvoked[tag] = timesInvoked
    end
end
local StopProfiling = function(_, tag)
    if self_stackSize > 0 then
        local currentTag = self_stack[self_stackSize]
        if currentTag == tag then
            local newTimestamp = _debugprofilestop()
            local delta = newTimestamp - self_timestamp
            local timeSpent = self_timeSpent[currentTag] or 0
            timeSpent = timeSpent + delta
            self_timeSpent[currentTag] = timeSpent
            self_timestamp = newTimestamp
            self_stackSize = self_stackSize - 1
        end
    end
end
local OvaleProfiler = __class()
function OvaleProfiler:OnInitialize()
    local appName = self:GetName()
    AceConfig:RegisterOptionsTable(appName, self.options)
    AceConfigDialog:AddToBlizOptions(appName, __L.L["Profiling"], OVALE)
end
function OvaleProfiler:OnEnable()
    if  not self_profilingOutput then
        self_profilingOutput = LibTextDump:New(OVALE + " - " + __L.L["Profiling"], 750, 500)
    end
end
function OvaleProfiler:OnDisable()
    self_profilingOutput:Clear()
end
function OvaleProfiler:RegisterProfiling(addon, name)
    name = name or addon:GetName()
    self.options.args.profiling.args.modules.args[name] = {
        name = name,
        desc = format(__L.L["Enable profiling for the %s module."], name),
        type = "toggle"
    }
    self:DisableProfiling(name)
end
function OvaleProfiler:EnableProfiling(name)
    local addon = Ovale[name]
    if addon then
        addon.StartProfiling = StartProfiling
        addon.StopProfiling = StopProfiling
    end
end
function OvaleProfiler:DisableProfiling(name)
    local addon = Ovale[name]
    if addon then
        addon.StartProfiling = DoNothing
        addon.StopProfiling = DoNothing
    end
end
function OvaleProfiler:ResetProfiling()
    for tag in _pairs(self_timeSpent) do
        self_timeSpent[tag] = nil
    end
    for tag in _pairs(self_timesInvoked) do
        self_timesInvoked[tag] = nil
    end
end
do
    local array = {}
local OvaleProfiler = __class()
    function OvaleProfiler:GetProfilingInfo()
        if _next(self_timeSpent) then
            local width = 1
            do
                local tenPower = 10
                for _, timesInvoked in _pairs(self_timesInvoked) do
                    while timesInvoked > tenPowerdo
                        width = width + 1
                        tenPower = tenPower * 10
end
                end
            end
            _wipe(array)
            local formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width)
            for tag, timeSpent in _pairs(self_timeSpent) do
                local timesInvoked = self_timesInvoked[tag]
                tinsert(array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag))
            end
            if _next(array) then
                tsort(array)
                local now = API_GetTime()
                tinsert(array, 1, format("Profiling statistics at %f:", now))
                return tconcat(array, "\n")
            end
        end
    end
end
local OvaleProfiler = __class()
function OvaleProfiler:DebuggingInfo()
    Ovale:Print("Profiler stack size = %d", self_stackSize)
    local index = self_stackSize
    while index > 0 and self_stackSize - index < 10do
        local tag = self_stack[index]
        Ovale:Print("    [%d] %s", index, tag)
        index = index - 1
end
end
end))
