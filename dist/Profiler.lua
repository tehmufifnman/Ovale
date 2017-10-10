local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Profiler", { "AceConfig-3.0", "AceConfigDialog-3.0", "./Localization", "LibTextDump-1.0", "./Options", "./Ovale" }, function(__exports, AceConfig, AceConfigDialog, __Localization, LibTextDump, __Options, __Ovale)
local OvaleProfilerBase = __Ovale.Ovale:NewModule("OvaleProfiler")
local _debugprofilestop = debugprofilestop
local format = string.format
local _pairs = pairs
local _next = next
local _wipe = wipe
local tinsert = table.insert
local tsort = table.sort
local API_GetTime = GetTime
local tconcat = table.concat
local self_timestamp = _debugprofilestop()
local self_timeSpent = {}
local self_timesInvoked = {}
local self_stack = {}
local self_stackSize = 0
local OvaleProfilerClass = __class(OvaleProfilerBase, {
    constructor = function(self)
        self.self_profilingOutput = nil
        self.profiles = {}
        self.actions = {
            profiling = {
                name = __Localization.L["Profiling"],
                type = "execute",
                func = function()
                    local appName = self:GetName()
                    AceConfigDialog:SetDefaultSize(appName, 800, 550)
                    AceConfigDialog:Open(appName)
                end
            }
        }
        self.options = {
            name = __Ovale.Ovale:GetName() .. " " .. __Localization.L["Profiling"],
            type = "group",
            args = {
                profiling = {
                    name = __Localization.L["Profiling"],
                    type = "group",
                    args = {
                        modules = {
                            name = __Localization.L["Modules"],
                            type = "group",
                            inline = true,
                            order = 10,
                            args = {},
                            get = function(info)
                                local name = info[#info]
                                local value = __Ovale.Ovale.db.global.profiler[name]
                                return (value ~= nil)
                            end,
                            set = function(info, value)
                                value = value or nil
                                local name = info[#info]
                                __Ovale.Ovale.db.global.profiler[name] = value
                                if value then
                                    self:EnableProfiling(name)
                                else
                                    self:DisableProfiling(name)
                                end
                            end
                        },
                        reset = {
                            name = __Localization.L["Reset"],
                            desc = __Localization.L["Reset the profiling statistics."],
                            type = "execute",
                            order = 20,
                            func = function()
                                self:ResetProfiling()
                            end
                        },
                        show = {
                            name = __Localization.L["Show"],
                            desc = __Localization.L["Show the profiling statistics."],
                            type = "execute",
                            order = 30,
                            func = function()
                                self.self_profilingOutput:Clear()
                                local s = self:GetProfilingInfo()
                                if s then
                                    self.self_profilingOutput:AddLine(s)
                                    self.self_profilingOutput:Display()
                                end
                            end
                        }
                    }
                }
            }
        }
        self.DoNothing = function()
        end

        self.array = {}
        OvaleProfilerBase.constructor(self)
        for k, v in _pairs(self.actions) do
            __Options.OvaleOptions.options.args.actions.args[k] = v
        end
        __Options.OvaleOptions.defaultDB.global = __Options.OvaleOptions.defaultDB.global or {}
        __Options.OvaleOptions.defaultDB.global.profiler = {}
        __Options.OvaleOptions:RegisterOptions(OvaleProfilerClass)
        local appName = self:GetName()
        AceConfig:RegisterOptionsTable(appName, self.options)
        AceConfigDialog:AddToBlizOptions(appName, __Localization.L["Profiling"], __Ovale.Ovale:GetName())
        if  not self.self_profilingOutput then
            self.self_profilingOutput = LibTextDump:New(__Ovale.Ovale:GetName() .. " - " .. __Localization.L["Profiling"], 750, 500)
        end
    end,
    OnDisable = function(self)
        self.self_profilingOutput:Clear()
    end,
    RegisterProfiling = function(self, module, name)
        local profiler = self
        return __class(module, {
            constructor = function(self, ...)
                self.enabled = false
                module.constructor(self, ...)
                name = name or self:GetName()
                profiler.options.args.profiling.args.modules.args[name] = {
                    name = name,
                    desc = format(__Localization.L["Enable profiling for the %s module."], name),
                    type = "toggle"
                }
                profiler.profiles[name] = self
            end,
            StartProfiling = function(self, tag)
                if  not self.enabled then
                    return 
                end
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
            end,
            StopProfiling = function(self, tag)
                if  not self.enabled then
                    return 
                end
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
            end,
        })
    end,
    ResetProfiling = function(self)
        for tag in _pairs(self_timeSpent) do
            self_timeSpent[tag] = nil
        end
        for tag in _pairs(self_timesInvoked) do
            self_timesInvoked[tag] = nil
        end
    end,
    GetProfilingInfo = function(self)
        if _next(self_timeSpent) then
            local width = 1
            do
                local tenPower = 10
                for _, timesInvoked in _pairs(self_timesInvoked) do
                    while timesInvoked > tenPower do
                        width = width + 1
                        tenPower = tenPower * 10
                    end
                end
            end
            _wipe(self.array)
            local formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width)
            for tag, timeSpent in _pairs(self_timeSpent) do
                local timesInvoked = self_timesInvoked[tag]
                tinsert(self.array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag))
            end
            if _next(self.array) then
                tsort(self.array)
                local now = API_GetTime()
                tinsert(self.array, 1, format("Profiling statistics at %f:", now))
                return tconcat(self.array, "\n")
            end
        end
    end,
    DebuggingInfo = function(self)
        __Ovale.Ovale:Print("Profiler stack size = %d", self_stackSize)
        local index = self_stackSize
        while index > 0 and self_stackSize - index < 10 do
            local tag = self_stack[index]
            __Ovale.Ovale:Print("    [%d] %s", index, tag)
            index = index - 1
        end
    end,
    EnableProfiling = function(self, name)
        self.profiles[name].enabled = true
    end,
    DisableProfiling = function(self, name)
        self.profiles[name].enabled = false
    end,
})
__exports.OvaleProfiler = OvaleProfilerClass()
end)
