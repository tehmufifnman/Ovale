local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./src/ShadowWordDeath", { "./src/Ovale", "./src/Aura" }, function(__exports, __Ovale, __Aura)
local OvaleShadowWordDeathBase = __Ovale.Ovale:NewModule("OvaleShadowWordDeath", "AceEvent-3.0")
local API_GetTime = GetTime
local self_playerGUID = nil
local SHADOW_WORD_DEATH = {
    [32379] = true,
    [129176] = true
}
local OvaleShadowWordDeathClass = __class(OvaleShadowWordDeathBase, {
    constructor = function(self)
        self.spellName = "Shadow Word: Death Reset Cooldown"
        self.spellId = 125927
        self.start = 0
        self.ending = 0
        self.duration = 9
        self.stacks = 0
        OvaleShadowWordDeathBase.constructor(self)
        if __Ovale.Ovale.playerClass == "PRIEST" then
            self_playerGUID = __Ovale.Ovale.playerGUID
            self:RegisterMessage("Ovale_SpecializationChanged")
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "PRIEST" then
            self:UnregisterMessage("Ovale_SpecializationChanged")
        end
    end,
    Ovale_SpecializationChanged = function(self, event, specialization, previousSpecialization)
        if specialization == "shadow" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, _, _, _, arg16 = ...
        if sourceGUID == self_playerGUID then
            if cleuEvent == "SPELL_DAMAGE" then
                local spellId, overkill = arg12, arg16
                if SHADOW_WORD_DEATH[spellId] and  not (overkill and overkill > 0) then
                    local now = API_GetTime()
                    self.start = now
                    self.ending = now + self.duration
                    self.stacks = 1
                    __Aura.OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
                end
            end
        end
    end,
})
__exports.OvaleShadowWordDeath = OvaleShadowWordDeathClass()
end)
