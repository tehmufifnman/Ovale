local OVALE, Ovale = ...
require(OVALE, Ovale, "Debug", { "./L", "./OvaleOptions", "./db" }, function(__exports, __L, __OvaleOptions, __db)
local OvaleDebug = Ovale:NewModule("OvaleDebug", "AceTimer-3.0")
Ovale.OvaleDebug = OvaleDebug
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibTextDump = LibStub("LibTextDump-1.0")
local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local _next = next
local _pairs = pairs
local strlen = string.len
local _tonumber = tonumber
local _tostring = tostring
local _type = type
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local self_traced = false
local self_traceLog = nil
local OVALE_TRACELOG_MAXLINES = 4096
do
    local actions = {
        debug = {
            name = __L.L["Debug"],
            type = "execute",
            func = function()
                local appName = OvaleDebug:GetName()
                AceConfigDialog:SetDefaultSize(appName, 800, 550)
                AceConfigDialog:Open(appName)
            end
        }
    }
    for k, v in _pairs(actions) do
        __OvaleOptions.OvaleOptions.options.args.actions.args[k] = v
    end
    __OvaleOptions.OvaleOptions.defaultDB.global = __OvaleOptions.OvaleOptions.defaultDB.global or {}
    __OvaleOptions.OvaleOptions.defaultDB.global.debug = {}
    __OvaleOptions.OvaleOptions:RegisterOptions(OvaleDebug)
end
OvaleDebug.options = {
    name = OVALE + " " + __L.L["Debug"],
    type = "group",
    args = {
        toggles = {
            name = __L.L["Options"],
            type = "group",
            order = 10,
            args = {},
            get = function(info)
                return (__db.value ~= nil)
            end,
            set = function(info, __db.value)
                __db.value = __db.value or nil
                Ovale.db.global.debug[info[#info]] = __db.value
            end
        },
        trace = {
            name = __L.L["Trace"],
            type = "group",
            order = 20,
            args = {
                trace = {
                    order = 10,
                    type = "execute",
                    name = __L.L["Trace"],
                    desc = __L.L["Trace the next frame update."],
                    func = function()
                        OvaleDebug:DoTrace(true)
                    end
                },
                traceLog = {
                    order = 20,
                    type = "execute",
                    name = __L.L["Show Trace Log"],
                    func = function()
                        OvaleDebug:DisplayTraceLog()
                    end
                }
            }
        }
    }
}
OvaleDebug.bug = false
OvaleDebug.trace = false
local OvaleDebug = __class()
function OvaleDebug:OnInitialize()
    local appName = self:GetName()
    AceConfig:RegisterOptionsTable(appName, self.options)
    AceConfigDialog:AddToBlizOptions(appName, __L.L["Debug"], OVALE)
end
function OvaleDebug:OnEnable()
    self_traceLog = LibTextDump:New(OVALE + " - " + __L.L["Trace Log"], 750, 500)
end
function OvaleDebug:DoTrace(displayLog)
    self_traceLog:Clear()
    self.trace = true
    self:Log("=== Trace @%f", API_GetTime())
    if displayLog then
        self:ScheduleTimer("DisplayTraceLog", 0.5)
    end
end
function OvaleDebug:ResetTrace()
    self.bug = false
    self.trace = false
    self_traced = false
end
function OvaleDebug:UpdateTrace()
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
end
function OvaleDebug:RegisterDebugging(addon)
    local name = addon:GetName()
    self.options.args.toggles.args[name] = {
        name = name,
        desc = format(__L.L["Enable debugging messages for the %s module."], name),
        type = "toggle"
    }
    addon.Debug = self.Debug
    addon.DebugTimestamp = self.DebugTimestamp
end
function OvaleDebug:Debug(...)
    local name = self:GetName()
    if Ovale.db.global.debug[name] then
        _DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, Ovale:MakeString(...)))
    end
end
function OvaleDebug:DebugTimestamp(...)
    local name = self:GetName()
    if Ovale.db.global.debug[name] then
        local now = API_GetTime()
        local s = format("|cffffff00%f|r %s", now, Ovale:MakeString(...))
        _DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
    end
end
function OvaleDebug:Log(...)
    if self.trace then
        local N = self_traceLog:Lines()
        if N < OVALE_TRACELOG_MAXLINES - 1 then
            self_traceLog:AddLine(Ovale:MakeString(...))
        elseif N == OVALE_TRACELOG_MAXLINES - 1 then
            self_traceLog:AddLine("WARNING: Maximum length of trace log has been reached.")
        end
    end
end
function OvaleDebug:DisplayTraceLog()
    if self_traceLog:Lines() == 0 then
        self_traceLog:AddLine("Trace log is empty.")
    end
    self_traceLog:Display()
end
do
    local NEW_DEBUG_NAMES = {
        action_bar = "OvaleActionBar",
        aura = "OvaleAura",
        combo_points = "OvaleComboPoints",
        compile = "OvaleCompile",
        damage_taken = "OvaleDamageTaken",
        enemy = "OvaleEnemies",
        guid = "OvaleGUID",
        missing_spells = false,
        paper_doll = "OvalePaperDoll",
        power = "OvalePower",
        snapshot = false,
        spellbook = "OvaleSpellBook",
        state = "OvaleState",
        steady_focus = "OvaleSteadyFocus",
        unknown_spells = false
    }
local OvaleDebug = __class()
    function OvaleDebug:UpgradeSavedVariables()
    end
end
end))
