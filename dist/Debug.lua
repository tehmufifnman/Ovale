local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Debug", { "AceConfig-3.0", "AceConfigDialog-3.0", "./Localization", "LibTextDump-1.0", "./Options", "./Ovale" }, function(__exports, AceConfig, AceConfigDialog, __Localization, LibTextDump, __Options, __Ovale)
local OvaleDebugBase = __Ovale.Ovale:NewModule("OvaleDebug", "AceTimer-3.0")
local format = string.format
local _pairs = pairs
local API_GetTime = GetTime
local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local self_traced = false
local self_traceLog = nil
local OVALE_TRACELOG_MAXLINES = 4096
local OvaleDebugClass = __class(OvaleDebugBase, {
    constructor = function(self)
        self.options = {
            name = __Ovale.Ovale:GetName() .. " " .. __Localization.L["Debug"],
            type = "group",
            args = {
                toggles = {
                    name = __Localization.L["Options"],
                    type = "group",
                    order = 10,
                    args = {},
                    get = function(info)
                        local value = __Ovale.Ovale.db.global.debug[info[#info]]
                        return (value ~= nil)
                    end
,
                    set = function(info, value)
                        value = value or nil
                        __Ovale.Ovale.db.global.debug[info[#info]] = value
                    end

                },
                trace = {
                    name = __Localization.L["Trace"],
                    type = "group",
                    order = 20,
                    args = {
                        trace = {
                            order = 10,
                            type = "execute",
                            name = __Localization.L["Trace"],
                            desc = __Localization.L["Trace the next frame update."],
                            func = function()
                                self:DoTrace(true)
                            end
                        },
                        traceLog = {
                            order = 20,
                            type = "execute",
                            name = __Localization.L["Show Trace Log"],
                            func = function()
                                self:DisplayTraceLog()
                            end
                        }
                    }
                }
            }
        }
        self.bug = false
        self.trace = false
        OvaleDebugBase.constructor(self)
        local actions = {
            debug = {
                name = __Localization.L["Debug"],
                type = "execute",
                func = function()
                    local appName = self:GetName()
                    AceConfigDialog:SetDefaultSize(appName, 800, 550)
                    AceConfigDialog:Open(appName)
                end
            }
        }
        for k, v in _pairs(actions) do
            __Options.OvaleOptions.options.args.actions.args[k] = v
        end
        __Options.OvaleOptions.defaultDB.global = __Options.OvaleOptions.defaultDB.global or {}
        __Options.OvaleOptions.defaultDB.global.debug = {}
        __Options.OvaleOptions:RegisterOptions(self)
        local appName = self:GetName()
        AceConfig:RegisterOptionsTable(appName, self.options)
        AceConfigDialog:AddToBlizOptions(appName, __Localization.L["Debug"], __Ovale.Ovale:GetName())
        self_traceLog = LibTextDump:New(__Ovale.Ovale:GetName() .. " - " .. __Localization.L["Trace Log"], 750, 500)
    end,
    DoTrace = function(self, displayLog)
        self_traceLog:Clear()
        self.trace = true
        _DEFAULT_CHAT_FRAME:AddMessage(string.format("=== Trace @%f", API_GetTime()))
        if displayLog then
            self:ScheduleTimer("DisplayTraceLog", 0.5)
        end
    end,
    ResetTrace = function(self)
        self.bug = false
        self.trace = false
        self_traced = false
    end,
    UpdateTrace = function(self)
        if self.trace then
            self_traced = true
        end
        if self.bug then
            self.trace = true
        end
        if self.trace and self_traced then
            self_traced = false
            self.trace = false
        end
    end,
    RegisterDebugging = function(self, addon)
        local debug = self
        return __class(addon, {
            constructor = function(self, args)
                addon.constructor(self, args)
                local name = self:GetName()
                debug.options.args.toggles.args[name] = {
                    name = name,
                    desc = format(__Localization.L["Enable debugging messages for the %s module."], name),
                    type = "toggle"
                }
            end,
            Debug = function(self, ...)
                local name = self:GetName()
                if __Ovale.Ovale.db.global.debug[name] then
                    _DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, __Ovale.MakeString(...)))
                end
            end,
            DebugTimestamp = function(self, ...)
                local name = self:GetName()
                if __Ovale.Ovale.db.global.debug[name] then
                    local now = API_GetTime()
                    local s = format("|cffffff00%f|r %s", now, __Ovale.MakeString(...))
                    _DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
                end
            end,
            Log = function(self, ...)
                if debug.trace then
                    local N = self_traceLog:Lines()
                    if N < OVALE_TRACELOG_MAXLINES - 1 then
                        self_traceLog:AddLine(__Ovale.MakeString(...))
                    elseif N == OVALE_TRACELOG_MAXLINES - 1 then
                        self_traceLog:AddLine("WARNING: Maximum length of trace log has been reached.")
                    end
                end
            end,
            Error = function(self, ...)
                local s = __Ovale.MakeString(...)
                self:Print("Fatal error: %s", s)
                __exports.OvaleDebug.bug = true
            end,
            Print = function(self, ...)
                local name = self:GetName()
                local s = __Ovale.MakeString(...)
                _DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
            end,
        })
    end,
    DisplayTraceLog = function(self)
        if self_traceLog:Lines() == 0 then
            self_traceLog:AddLine("Trace log is empty.")
        end
        self_traceLog:Display()
    end,
})
__exports.OvaleDebug = OvaleDebugClass()
end)
