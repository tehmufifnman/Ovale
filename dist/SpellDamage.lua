local OVALE, Ovale = ...
require(OVALE, Ovale, "SpellDamage", { "./OvaleProfiler" }, function(__exports, __OvaleProfiler)
local OvaleSpellDamage = Ovale:NewModule("OvaleSpellDamage", "AceEvent-3.0")
Ovale.OvaleSpellDamage = OvaleSpellDamage
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleSpellDamage)
local CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_AURA = true
}
local self_playerGUID = nil
OvaleSpellDamage.value = {}
local OvaleSpellDamage = __class()
function OvaleSpellDamage:OnEnable()
    self_playerGUID = Ovale.playerGUID
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
function OvaleSpellDamage:OnDisable()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
function OvaleSpellDamage:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
    if sourceGUID == self_playerGUID then
        self:StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
        if CLEU_DAMAGE_EVENT[cleuEvent] then
            local spellId, amount = arg12, arg15
            self.value[spellId] = amount
            Ovale.refreshNeeded[self_playerGUID] = true
        end
        self:StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
    end
end
function OvaleSpellDamage:Get(spellId)
    return self.value[spellId]
end
end))
