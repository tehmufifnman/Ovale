local OVALE, Ovale = ...
require(OVALE, Ovale, "BanditsGuile", { "./OvaleDebug" }, function(__exports, __OvaleDebug)
local OvaleBanditsGuile = Ovale:NewModule("OvaleBanditsGuile", "AceEvent-3.0")
Ovale.OvaleBanditsGuile = OvaleBanditsGuile
local OvaleAura = nil
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleBanditsGuile)
local self_playerGUID = nil
local SHALLOW_INSIGHT = 84745
local MODERATE_INSIGHT = 84746
local DEEP_INSIGHT = 84747
local INSIGHT_BUFF = {
    [SHALLOW_INSIGHT] = API_GetSpellInfo(SHALLOW_INSIGHT),
    [MODERATE_INSIGHT] = API_GetSpellInfo(MODERATE_INSIGHT),
    [DEEP_INSIGHT] = API_GetSpellInfo(DEEP_INSIGHT)
}
local BANDITS_GUILE = 84654
local BANDITS_GUILE_ATTACK = {
    [1752] = API_GetSpellInfo(1752)
}
OvaleBanditsGuile.spellName = "Bandit's Guile"
OvaleBanditsGuile.spellId = BANDITS_GUILE
OvaleBanditsGuile.start = 0
OvaleBanditsGuile.ending = 0
OvaleBanditsGuile.duration = 15
OvaleBanditsGuile.stacks = 0
local OvaleBanditsGuile = __class()
function OvaleBanditsGuile:OnInitialize()
    OvaleAura = Ovale.OvaleAura
end
function OvaleBanditsGuile:OnEnable()
    if Ovale.playerClass == "ROGUE" then
        self_playerGUID = Ovale.playerGUID
        self:RegisterMessage("Ovale_SpecializationChanged")
    end
end
function OvaleBanditsGuile:OnDisable()
    if Ovale.playerClass == "ROGUE" then
        self:UnregisterMessage("Ovale_SpecializationChanged")
    end
end
function OvaleBanditsGuile:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
    self:Debug(event, specialization, previousSpecialization)
    if specialization == "combat" then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterMessage("Ovale_AuraAdded")
        self:RegisterMessage("Ovale_AuraChanged")
        self:RegisterMessage("Ovale_AuraRemoved")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:UnregisterMessage("Ovale_AuraAdded")
        self:UnregisterMessage("Ovale_AuraChanged")
        self:UnregisterMessage("Ovale_AuraRemoved")
    end
end
function OvaleBanditsGuile:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
    if sourceGUID == self_playerGUID and cleuEvent == "SPELL_DAMAGE" then
        local spellId, spellName, multistrike = arg12, arg13, arg25
        if BANDITS_GUILE_ATTACK[spellId] and  not multistrike then
            local now = API_GetTime()
            if self.ending < now then
                self.stacks = 0
            end
            if self.stacks < 3 then
                self.start = now
                self.ending = self.start + self.duration
                self.stacks = self.stacks + 1
                self:Debug(cleuEvent, spellName, spellId, self.stacks)
                self:GainedAura(now)
            end
        end
    end
end
function OvaleBanditsGuile:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
    if target == self_playerGUID then
        local auraName = INSIGHT_BUFF[auraId]
        if auraName then
            local aura = OvaleAura:GetAura("player", auraId, "HELPFUL", true)
            self.start, self.ending = aura.start, aura.ending
            if auraId == SHALLOW_INSIGHT then
                self.stacks = 4
            elseif auraId == MODERATE_INSIGHT then
                self.stacks = 8
            elseif auraId == DEEP_INSIGHT then
                self.stacks = 12
            end
            self:Debug(event, auraName, self.stacks)
            self:GainedAura(timestamp)
        end
    end
end
function OvaleBanditsGuile:Ovale_AuraChanged(event, timestamp, target, auraId, caster)
    if target == self_playerGUID then
        local auraName = INSIGHT_BUFF[auraId]
        if auraName then
            local aura = OvaleAura:GetAura("player", auraId, "HELPFUL", true)
            self.start, self.ending = aura.start, aura.ending
            self.stacks = self.stacks + 1
            self:Debug(event, auraName, self.stacks)
            self:GainedAura(timestamp)
        end
    end
end
function OvaleBanditsGuile:Ovale_AuraRemoved(event, timestamp, target, auraId, caster)
    if target == self_playerGUID then
        if ((auraId == SHALLOW_INSIGHT and self.stacks < 8) or (auraId == MODERATE_INSIGHT and self.stacks < 12) or auraId == DEEP_INSIGHT) and timestamp < self.ending then
            self.ending = timestamp
            self.stacks = 0
            self:Debug(event, INSIGHT_BUFF[auraId], self.stacks)
            OvaleAura:LostAuraOnGUID(self_playerGUID, timestamp, self.spellId, self_playerGUID)
        end
    end
end
function OvaleBanditsGuile:GainedAura(atTime)
    OvaleAura:GainedAuraOnGUID(self_playerGUID, atTime, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
end
function OvaleBanditsGuile:DebugBanditsGuile()
    local aura = OvaleAura:GetAuraByGUID(self_playerGUID, self.spellId, "HELPFUL", true)
    if aura then
        self:Print("Player has Bandit's Guile aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
    end
end
end))
