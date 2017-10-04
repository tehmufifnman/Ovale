local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./SpellDamage", { "./Profiler", "./Ovale" }, function(__exports, __Profiler, __Ovale)
local CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_AURA = true
}
local self_playerGUID = nil
local OvaleSpellDamageClass = __class(__Profiler.OvaleProfiler:RegisterProfiling(__Ovale.Ovale:NewModule("OvaleSpellDamage", "AceEvent-3.0")), {
    OnEnable = function(self)
        self_playerGUID = __Ovale.Ovale.playerGUID
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
        if sourceGUID == self_playerGUID then
            self:StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
            if CLEU_DAMAGE_EVENT[cleuEvent] then
                local spellId, amount = arg12, arg15
                self.value[spellId] = amount
                __Ovale.Ovale.refreshNeeded[self_playerGUID] = true
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
