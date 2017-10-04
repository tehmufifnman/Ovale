local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./DemonHunterDemonic", { "./Ovale", "./Debug", "./Aura" }, function(__exports, __Ovale, __Debug, __Aura)
local OvaleDemonHunterDemonicBase = __Ovale.Ovale:NewModule("OvaleDemonHunterDemonic", "AceEvent-3.0")
local API_GetSpecialization = GetSpecialization
local API_GetSpecializationInfo = GetSpecializationInfo
local API_GetTime = GetTime
local API_GetTalentInfoByID = GetTalentInfoByID
local INFINITY = math.huge
local HAVOC_DEMONIC_TALENT_ID = 22547
local HAVOC_SPEC_ID = 577
local HAVOC_EYE_BEAM_SPELL_ID = 198013
local HAVOC_META_BUFF_ID = 162264
local HIDDEN_BUFF_ID = -HAVOC_DEMONIC_TALENT_ID
local HIDDEN_BUFF_DURATION = INFINITY
local HIDDEN_BUFF_EXTENDED_BY_DEMONIC = "Extended by Demonic"
local OvaleDemonHunterDemonicClass = __class(__Debug.OvaleDebug:RegisterDebugging(OvaleDemonHunterDemonicBase), {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        self.playerGUID = nil
        self.isDemonHunter = __Ovale.Ovale.playerClass == "DEMONHUNTER" and true or false
        self.isHavoc = false
        self.hasDemonic = false
        if self.isDemonHunter then
            self:Debug("playerGUID: (%s)", __Ovale.Ovale.playerGUID)
            self.playerGUID = __Ovale.Ovale.playerGUID
            self:RegisterMessage("Ovale_TalentsChanged")
        end
    end,
    OnDisable = function(self)
        self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    Ovale_TalentsChanged = function(self, event)
        self.isHavoc = self.isDemonHunter and API_GetSpecializationInfo(API_GetSpecialization()) == HAVOC_SPEC_ID and true or false
        self.hasDemonic = self.isHavoc and select(10, API_GetTalentInfoByID(HAVOC_DEMONIC_TALENT_ID, HAVOC_SPEC_ID)) and true or false
        if self.isHavoc and self.hasDemonic then
            self:Debug("We are a havoc DH with Demonic.")
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            if  not self.isHavoc then
                self:Debug("We are not a havoc DH.")
            elseif  not self.hasDemonic then
                self:Debug("We don't have the Demonic talent.")
            end
            self:DropAura()
            self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
        if sourceGUID == self.playerGUID and cleuEvent == "SPELL_CAST_SUCCESS" then
            local spellId, spellName = arg12, arg13
            if HAVOC_EYE_BEAM_SPELL_ID == spellId then
                self:Debug("Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).", spellId, spellName)
                self:GainAura()
            end
        end
        if sourceGUID == self.playerGUID and cleuEvent == "SPELL_AURA_REMOVED" then
            local spellId, spellName = arg12, arg13
            if HAVOC_META_BUFF_ID == spellId then
                self:Debug("Aura %d (%s) is removed. Dropping Aura.", spellId, spellName)
                self:DropAura()
            end
        end
    end,
    GainAura = function(self)
        local now = API_GetTime()
        local aura_meta = __Aura.OvaleAura:GetAura("player", HAVOC_META_BUFF_ID, "HELPFUL", true)
        if __Aura.OvaleAura:IsActiveAura(aura_meta, now) then
            self:Debug("Adding '%s' (%d) buff to player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, self.playerGUID)
            local duration = HIDDEN_BUFF_DURATION
            local ending = now + HIDDEN_BUFF_DURATION
            __Aura.OvaleAura:GainedAuraOnGUID(self.playerGUID, now, HIDDEN_BUFF_ID, self.playerGUID, "HELPFUL", nil, nil, 1, nil, duration, ending, nil, HIDDEN_BUFF_EXTENDED_BY_DEMONIC, nil, nil, nil)
        else
            self:Debug("Aura 'Metamorphosis' (%d) is not present.", HAVOC_META_BUFF_ID)
        end
    end,
    DropAura = function(self)
        local now = API_GetTime()
        self:Debug("Removing '%s' (%d) buff on player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, self.playerGUID)
        __Aura.OvaleAura:LostAuraOnGUID(self.playerGUID, now, HIDDEN_BUFF_ID, self.playerGUID)
    end,
})
__exports.OvaleDemonHunterDemonic = OvaleDemonHunterDemonicClass()
end)
