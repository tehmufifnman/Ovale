local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Version", { "./Localization", "./Debug", "./Options", "./Ovale" }, function(__exports, __Localization, __Debug, __Options, __Ovale)
local OvaleVersionBase = __Ovale.Ovale:NewModule("OvaleVersion", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")
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
local self_printTable = {}
local self_userVersion = {}
local self_timer
local MSG_PREFIX = __Ovale.Ovale.MSG_PREFIX
local OVALE_VERSION = "@project-version@"
local REPOSITORY_KEYWORD = "project-version"
do
    local actions = {
        ping = {
            name = __Localization.L["Ping for Ovale users in group"],
            type = "execute",
            func = function()
                __exports.OvaleVersion:VersionCheck()
            end

        },
        version = {
            name = __Localization.L["Show version number"],
            type = "execute",
            func = function()
                __exports.OvaleVersion:Print(__exports.OvaleVersion.version)
            end

        }
    }
    for k, v in _pairs(actions) do
        __Options.OvaleOptions.options.args.actions.args[k] = v
    end
    __Options.OvaleOptions:RegisterOptions(__exports.OvaleVersion)
end
local OvaleVersionClass = __class(__Debug.OvaleDebug:RegisterDebugging(OvaleVersionBase), {
    OnEnable = function(self)
        self:RegisterComm(MSG_PREFIX)
    end,
    OnCommReceived = function(self, prefix, message, channel, sender)
        if prefix == MSG_PREFIX then
            local ok, msgType, version = self:Deserialize(message)
            if ok then
                self:Debug(msgType, version, channel, sender)
                if msgType == "V" then
                    local msg = self:Serialize("VR", self.version)
                    self:SendCommMessage(MSG_PREFIX, msg, channel)
                elseif msgType == "VR" then
                    self_userVersion[sender] = version
                end
            end
        end
    end,
    VersionCheck = function(self)
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
                self:SendCommMessage(MSG_PREFIX, message, channel)
            end
            self_timer = self:ScheduleTimer("PrintVersionCheck", 3)
        end
    end,
    PrintVersionCheck = function(self)
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
    end,
})
__exports.OvaleVersion = OvaleVersionClass()
end)
