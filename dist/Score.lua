local __addonName, __addon = ...
            __addon.require("./Score", { "./Ovale", "./Debug", "./Future", "AceEvent-3.0", "AceSerializer-3.0" }, function(__exports, __Ovale, __Debug, __Future, aceEvent, AceSerializer)
local OvaleScoreBase = __Ovale.Ovale:NewModule("OvaleScore", aceEvent, AceSerializer)
local _pairs = pairs
local _type = type
local API_IsInGroup = IsInGroup
local API_SendAddonMessage = SendAddonMessage
local API_UnitName = UnitName
local _LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local MSG_PREFIX = __Ovale.Ovale.MSG_PREFIX
local self_playerGUID = nil
local self_name = nil
local API_GetTime = GetTime
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local OvaleScoreClass = __addon.__class(__Debug.OvaleDebug:RegisterDebugging(OvaleScoreBase), {
    constructor = function(self)
        self.damageMeter = {}
        self.damageMeterMethod = {}
        self.score = 0
        self.maxScore = 0
        self.scoredSpell = {}
        __Debug.OvaleDebug:RegisterDebugging(OvaleScoreBase).constructor(self)
        self_playerGUID = __Ovale.Ovale.playerGUID
        self_name = API_UnitName("player")
        self:RegisterEvent("CHAT_MSG_ADDON")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:RegisterEvent("UNIT_SPELLCAST_START")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("CHAT_MSG_ADDON")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self:UnregisterEvent("UNIT_SPELLCAST_START")
    end,
    CHAT_MSG_ADDON = function(self, event, ...)
        local prefix, message, _, sender = ...
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
    UNIT_SPELLCAST_CHANNEL_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" or unitId == "pet" then
            local now = API_GetTime()
            local spellcast = __Future.OvaleFuture:GetSpellcast(spell, spellId, nil, now)
            if spellcast then
                local name = API_UnitChannelInfo(unitId)
                if name == spell then
                    self:ScoreSpell(spellId)
                end
            end
        end
    end,
    UNIT_SPELLCAST_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" or unitId == "pet" then
            local now = API_GetTime()
            local spellcast = __Future.OvaleFuture:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local name, _, _, _, _, _, _, castId = API_UnitCastingInfo(unitId)
                if lineId == castId and name == spell then
                    self:ScoreSpell(spellId)
                end
            end
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" or unitId == "pet" then
            local now = API_GetTime()
            local spellcast = __Future.OvaleFuture:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                if spellcast.success or ( not spellcast.start) or ( not spellcast.stop) or spellcast.channel then
                    local name = API_UnitChannelInfo(unitId)
                    if  not name then
                        __exports.OvaleScore:ScoreSpell(spellId)
                    end
                end
            end
        end
    end,
})
__exports.OvaleScore = OvaleScoreClass()
end)
