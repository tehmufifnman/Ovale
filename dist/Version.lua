local OVALE, Ovale = ...
require(OVALE, Ovale, "Version", { "./L", "./OvaleDebug", "./OvaleOptions", "./MSG_PREFIX" }, function(__exports, __L, __OvaleDebug, __OvaleOptions, __MSG_PREFIX)
local OvaleVersion = Ovale:NewModule("OvaleVersion", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")
Ovale.OvaleVersion = OvaleVersion
local format = string.format
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local tinsert = table.insert
local tsort = table.sort
local _wipe = wipe
local API_IsInGroup = IsInGroup
local API_IsInGuild = IsInGuild
local API_IsInRaid = IsInRaid
local _LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleVersion)
local self_printTable = {}
local self_userVersion = {}
local self_timer
local OVALE_VERSION = "7.3.0.2"
local REPOSITORY_KEYWORD = "@" + "project-version" + "@"
do
    local actions = {
        ping = {
            name = __L.L["Ping for Ovale users in group"],
            type = "execute",
            func = function()
                OvaleVersion:VersionCheck()
            end
        },
        version = {
            name = __L.L["Show version number"],
            type = "execute",
            func = function()
                OvaleVersion:Print(OvaleVersion.version)
            end
        }
    }
    for k, v in _pairs(actions) do
        __OvaleOptions.OvaleOptions.options.args.actions.args[k] = v
    end
    __OvaleOptions.OvaleOptions:RegisterOptions(OvaleVersion)
end
OvaleVersion.version = (OVALE_VERSION == REPOSITORY_KEYWORD) and "development version" or OVALE_VERSION
OvaleVersion.warned = false
local OvaleVersion = __class()
function OvaleVersion:OnEnable()
    self:RegisterComm(__MSG_PREFIX.MSG_PREFIX)
end
function OvaleVersion:OnCommReceived(prefix, message, channel, sender)
    if prefix == __MSG_PREFIX.MSG_PREFIX then
        local ok, msgType, version = self:Deserialize(message)
        if ok then
            self:Debug(msgType, version, channel, sender)
            if msgType == "V" then
                local msg = self:Serialize("VR", self.version)
                self:SendCommMessage(__MSG_PREFIX.MSG_PREFIX, msg, channel)
            elseif msgType == "VR" then
                self_userVersion[sender] = version
            end
        end
    end
end
function OvaleVersion:VersionCheck()
    if  not self_timer then
        _wipe(self_userVersion)
        local message = self:Serialize("V", self.version)
        local channel
        if API_IsInGroup(_LE_PARTY_CATEGORY_INSTANCE) then
            channel = "INSTANCE_CHAT"
        elseif API_IsInRaid() then
            channel = "RAID"
        elseif API_IsInGroup() then
            channel = "PARTY"
        elseif API_IsInGuild() then
            channel = "GUILD"
        end
        if channel then
            self:SendCommMessage(__MSG_PREFIX.MSG_PREFIX, message, channel)
        end
        self_timer = self:ScheduleTimer("PrintVersionCheck", 3)
    end
end
function OvaleVersion:PrintVersionCheck()
    if _next(self_userVersion) then
        _wipe(self_printTable)
        for sender, version in _pairs(self_userVersion) do
            tinsert(self_printTable, format(">>> %s is using Ovale %s", sender, version))
        end
        tsort(self_printTable)
        for _, v in _ipairs(self_printTable) do
            self:Print(v)
        end
    else
        self:Print(">>> No other Ovale users present.")
    end
    self_timer = nil
end
end))
