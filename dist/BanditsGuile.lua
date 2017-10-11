local __addonName, __addon = ...
            __addon.require("./BanditsGuile", { "./Debug", "./Ovale", "./Aura" }, function(__exports, __Debug, __Ovale, __Aura)
local OvaleBanditsGuileBase = __Ovale.Ovale:NewModule("OvaleBanditsGuile", "AceEvent-3.0")
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
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
local OvaleBanditsGuile = __addon.__class(__Debug.OvaleDebug:RegisterDebugging(OvaleBanditsGuileBase), {
    constructor = function(self)
        self.spellName = "Bandit's Guile"
        self.spellId = BANDITS_GUILE
        self.start = 0
        self.ending = 0
        self.duration = 15
        self.stacks = 0
        __Debug.OvaleDebug:RegisterDebugging(OvaleBanditsGuileBase).constructor(self)
        if __Ovale.Ovale.playerClass == "ROGUE" then
            self_playerGUID = __Ovale.Ovale.playerGUID
            self:RegisterMessage("Ovale_SpecializationChanged")
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "ROGUE" then
            self:UnregisterMessage("Ovale_SpecializationChanged")
        end
    end,
    Ovale_SpecializationChanged = function(self, event, specialization, previousSpecialization)
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
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, _, _, _, _, _, _, _, _, _, _, _, arg25 = ...
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
    end,
    Ovale_AuraAdded = function(self, event, timestamp, target, auraId, caster)
        if target == self_playerGUID then
            local auraName = INSIGHT_BUFF[auraId]
            if auraName then
                local playerAura = __Aura.OvaleAura:GetAura("player", auraId, "HELPFUL", true)
                self.start, self.ending = playerAura.start, playerAura.ending
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
    end,
    Ovale_AuraChanged = function(self, event, timestamp, target, auraId, caster)
        if target == self_playerGUID then
            local auraName = INSIGHT_BUFF[auraId]
            if auraName then
                local playerAura = __Aura.OvaleAura:GetAura("player", auraId, "HELPFUL", true)
                self.start, self.ending = playerAura.start, playerAura.ending
                self.stacks = self.stacks + 1
                self:Debug(event, auraName, self.stacks)
                self:GainedAura(timestamp)
            end
        end
    end,
    Ovale_AuraRemoved = function(self, event, timestamp, target, auraId, caster)
        if target == self_playerGUID then
            if ((auraId == SHALLOW_INSIGHT and self.stacks < 8) or (auraId == MODERATE_INSIGHT and self.stacks < 12) or auraId == DEEP_INSIGHT) and timestamp < self.ending then
                self.ending = timestamp
                self.stacks = 0
                self:Debug(event, INSIGHT_BUFF[auraId], self.stacks)
                __Aura.OvaleAura:LostAuraOnGUID(self_playerGUID, timestamp, self.spellId, self_playerGUID)
            end
        end
    end,
    GainedAura = function(self, atTime)
        __Aura.OvaleAura:GainedAuraOnGUID(self_playerGUID, atTime, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
    end,
    DebugBanditsGuile = function(self)
        local playerAura = __Aura.OvaleAura:GetAuraByGUID(self_playerGUID, self.spellId, "HELPFUL", true)
        if playerAura then
            self:Print("Player has Bandit's Guile aura with start=%s, end=%s, stacks=%d.", playerAura.start, playerAura.ending, playerAura.stacks)
        end
    end,
})
__exports.banditsGuile = OvaleBanditsGuile()
end)
