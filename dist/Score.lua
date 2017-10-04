local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Score", { "./Ovale", "./Localization", "./Debug" }, function(__exports, __Ovale, __Localization, __Debug)
local OvaleFuture = nil
local OvaleScoreBase = __Ovale.Ovale:NewModule("OvaleScore", "AceEvent-3.0", "AceSerializer-3.0")
local _pairs = pairs
local _type = type
local API_IsInGroup = IsInGroup
local API_SendAddonMessage = SendAddonMessage
local API_UnitName = UnitName
local _LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local MSG_PREFIX = __Ovale.Ovale.MSG_PREFIX
local self_playerGUID = nil
local self_name = nil
local OvaleScoreClass = __class(__Debug.OvaleDebug:RegisterDebugging(OvaleScoreBase), {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        self_playerGUID = __Ovale.Ovale.playerGUID
        self_name = API_UnitName("player")
        self:RegisterEvent("CHAT_MSG_ADDON")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("CHAT_MSG_ADDON")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    end,
    CHAT_MSG_ADDON = function(self, event, ...)
        local prefix, message, channel, sender = ...
        if prefix == MSG_PREFIX then
            local ok, msgType, scored, scoreMax, guid = self:Deserialize(message)
            if ok and msgType == "S" then
                self:SendScore(sender, guid, scored, scoreMax)
            end
        end
    end,
    PLAYER_REGEN_ENABLED = function(self)
        if self.maxScore > 0 and API_IsInGroup() then
            local message = self:Serialize("score", self.score, self.maxScore, self_playerGUID)
            local channel = API_IsInGroup(_LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
            API_SendAddonMessage(MSG_PREFIX, message, channel)
        end
    end,
    PLAYER_REGEN_DISABLED = function(self)
        self.score = 0
        self.maxScore = 0
    end,
    RegisterDamageMeter = function(self, moduleName, addon, func)
        if  not func then
            func = addon
        elseif addon then
            self.damageMeter[moduleName] = addon
        end
        self.damageMeterMethod[moduleName] = func
    end,
    UnregisterDamageMeter = function(self, moduleName)
        self.damageMeter[moduleName] = nil
        self.damageMeterMethod[moduleName] = nil
    end,
    AddSpell = function(self, spellId)
        self.scoredSpell[spellId] = true
    end,
    ScoreSpell = function(self, spellId)
        if OvaleFuture.inCombat and self.scoredSpell[spellId] then
            local scored = __Ovale.Ovale.frame:GetScore(spellId)
            self:DebugTimestamp("Scored %s for %d.", scored, spellId)
            if scored then
                self.score = self.score + scored
                self.maxScore = self.maxScore + 1
                self:SendScore(self_name, self_playerGUID, scored, 1)
            end
        end
    end,
    SendScore = function(self, name, guid, scored, scoreMax)
        for moduleName, method in _pairs(self.damageMeterMethod) do
            local addon = self.damageMeter[moduleName]
            if addon then
                addon[method](addon, name, guid, scored, scoreMax)
            elseif _type(method) == "function" then
                method(name, guid, scored, scoreMax)
            end
        end
    end,
})
__exports.OvaleScore = OvaleScoreClass()
end)
