local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./WarriorCharge", { "./Debug", "./Aura", "./Ovale" }, function(__exports, __Debug, __Aura, __Ovale)
local OvaleWarriorChargeBase = __Ovale.Ovale:NewModule("OvaleWarriorCharge", "AceEvent-3.0")
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local INFINITY = math.huge
local self_playerGUID = nil
local CHARGED = 100
local CHARGED_NAME = "Charged"
local CHARGED_DURATION = INFINITY
local CHARGED_ATTACKS = {
    [100] = API_GetSpellInfo(100)
}
local OvaleWarriorChargeClass = __class(__Debug.OvaleDebug:RegisterDebugging(OvaleWarriorChargeBase), {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        if __Ovale.Ovale.playerClass == "WARRIOR" then
            self_playerGUID = __Ovale.Ovale.playerGUID
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "WARRIOR" then
            self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
        if sourceGUID == self_playerGUID and cleuEvent == "SPELL_CAST_SUCCESS" then
            local spellId, spellName = arg12, arg13
            if CHARGED_ATTACKS[spellId] and destGUID ~= self.targetGUID then
                self:Debug("Spell %d (%s) on new target %s.", spellId, spellName, destGUID)
                local now = API_GetTime()
                if self.targetGUID then
                    self:Debug("Removing Charged debuff on previous target %s.", self.targetGUID)
                    __Aura.OvaleAura:LostAuraOnGUID(self.targetGUID, now, CHARGED, self_playerGUID)
                end
                self:Debug("Adding Charged debuff to %s.", destGUID)
                local duration = CHARGED_DURATION
                local ending = now + CHARGED_DURATION
                __Aura.OvaleAura:GainedAuraOnGUID(destGUID, now, CHARGED, self_playerGUID, "HARMFUL", nil, nil, 1, nil, duration, ending, nil, CHARGED_NAME, nil, nil, nil)
                self.targetGUID = destGUID
            end
        end
    end,
    constructor = function(self)
        self.targetGUID = nil
    end
})
__exports.OvaleWarriorCharge = OvaleWarriorChargeClass()
end)
