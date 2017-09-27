local OVALE, Ovale = ...
require(OVALE, Ovale, "Score", { "./L", "./OvaleDebug", "./MSG_PREFIX", "./frame" }, function(__exports, __L, __OvaleDebug, __MSG_PREFIX, __frame)
local OvaleScore = Ovale:NewModule("OvaleScore", "AceEvent-3.0", "AceSerializer-3.0")
Ovale.OvaleScore = OvaleScore
local OvaleFuture = nil
local _pairs = pairs
local _type = type
local API_IsInGroup = IsInGroup
local API_SendAddonMessage = SendAddonMessage
local API_UnitName = UnitName
local _LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local self_playerGUID = nil
local self_name = nil
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleScore)
OvaleScore.damageMeter = {}
OvaleScore.damageMeterMethod = {}
OvaleScore.score = 0
OvaleScore.maxScore = 0
OvaleScore.scoredSpell = {}
local OvaleScore = __class()
function OvaleScore:OnInitialize()
    OvaleFuture = Ovale.OvaleFuture
end
function OvaleScore:OnEnable()
    self_playerGUID = Ovale.playerGUID
    self_name = API_UnitName("player")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
end
function OvaleScore:OnDisable()
    self:UnregisterEvent("CHAT_MSG_ADDON")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end
function OvaleScore:CHAT_MSG_ADDON(event, ...)
    local prefix, message, channel, sender = ...
    if prefix == __MSG_PREFIX.MSG_PREFIX then
        local ok, msgType, scored, scoreMax, guid = self:Deserialize(message)
        if ok and msgType == "S" then
            self:SendScore(sender, guid, scored, scoreMax)
        end
    end
end
function OvaleScore:PLAYER_REGEN_ENABLED()
    if self.maxScore > 0 and API_IsInGroup() then
        local message = self:Serialize("score", self.score, self.maxScore, self_playerGUID)
        local channel = API_IsInGroup(_LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
        API_SendAddonMessage(__MSG_PREFIX.MSG_PREFIX, message, channel)
    end
end
function OvaleScore:PLAYER_REGEN_DISABLED()
    self.score = 0
    self.maxScore = 0
end
function OvaleScore:RegisterDamageMeter(moduleName, addon, func)
    if  not func then
        func = addon
    elseif addon then
        self.damageMeter[moduleName] = addon
    end
    self.damageMeterMethod[moduleName] = func
end
function OvaleScore:UnregisterDamageMeter(moduleName)
    self.damageMeter[moduleName] = nil
    self.damageMeterMethod[moduleName] = nil
end
function OvaleScore:AddSpell(spellId)
    self.scoredSpell[spellId] = true
end
function OvaleScore:ScoreSpell(spellId)
    if OvaleFuture.inCombat and self.scoredSpell[spellId] then
        self:DebugTimestamp("Scored %s for %d.", __frame.scored, spellId)
        if __frame.scored then
            self.score = self.score + __frame.scored
            self.maxScore = self.maxScore + 1
            self:SendScore(self_name, self_playerGUID, __frame.scored, 1)
        end
    end
end
function OvaleScore:SendScore(name, guid, __frame.scored, scoreMax)
    for moduleName, method in _pairs(self.damageMeterMethod) do
        local addon = self.damageMeter[moduleName]
        if addon then
            addon[method](addon, name, guid, __frame.scored, scoreMax)
        elseif _type(method) == "function" then
            method(name, guid, __frame.scored, scoreMax)
        end
    end
end
end))
