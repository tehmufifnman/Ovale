local OVALE, Ovale = ...
local OvaleShadowWordDeath = Ovale:NewModule("OvaleShadowWordDeath", "AceEvent-3.0")
Ovale.OvaleShadowWordDeath = OvaleShadowWordDeath
local OvaleAura = nil
local API_GetTime = GetTime
local self_playerGUID = nil
local SHADOW_WORD_DEATH = {
    [32379] = true,
    [129176] = true
}
OvaleShadowWordDeath.spellName = "Shadow Word: Death Reset Cooldown"
OvaleShadowWordDeath.spellId = 125927
OvaleShadowWordDeath.start = 0
OvaleShadowWordDeath.ending = 0
OvaleShadowWordDeath.duration = 9
OvaleShadowWordDeath.stacks = 0
local OvaleShadowWordDeath = __class()
function OvaleShadowWordDeath:OnInitialize()
    OvaleAura = Ovale.OvaleAura
end
function OvaleShadowWordDeath:OnEnable()
    if Ovale.playerClass == "PRIEST" then
        self_playerGUID = Ovale.playerGUID
        self:RegisterMessage("Ovale_SpecializationChanged")
    end
end
function OvaleShadowWordDeath:OnDisable()
    if Ovale.playerClass == "PRIEST" then
        self:UnregisterMessage("Ovale_SpecializationChanged")
    end
end
function OvaleShadowWordDeath:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
    if specialization == "shadow" then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end
function OvaleShadowWordDeath:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
    if sourceGUID == self_playerGUID then
        if cleuEvent == "SPELL_DAMAGE" then
            local spellId, overkill = arg12, arg16
            if SHADOW_WORD_DEATH[spellId] and  not (overkill and overkill > 0) then
                local now = API_GetTime()
                self.start = now
                self.ending = now + self.duration
                self.stacks = 1
                OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
            end
        end
    end
end
