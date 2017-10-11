local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./src/SpellDamage", { "./src/Profiler", "./src/Ovale" }, function(__exports, __Profiler, __Ovale)
local CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_AURA = true
}
local OvaleSpellDamageBase = __Profiler.OvaleProfiler:RegisterProfiling(__Ovale.Ovale:NewModule("OvaleSpellDamage", "AceEvent-3.0"))
local OvaleSpellDamageClass = __class(OvaleSpellDamageBase, {
    constructor = function(self)
        self.value = {}
        OvaleSpellDamageBase.constructor(self)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, _, _, arg15, _, _, _, _, _, _, _, _, _ = ...
        if sourceGUID == __Ovale.Ovale.playerGUID then
            self:StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
            if CLEU_DAMAGE_EVENT[cleuEvent] then
                local spellId, amount = arg12, arg15
                self.value[spellId] = amount
                __Ovale.Ovale:needRefresh()
            end
            self:StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    Get = function(self, spellId)
        return self.value[spellId]
    end,
})
__exports.OvaleSpellDamage = OvaleSpellDamageClass()
end)
