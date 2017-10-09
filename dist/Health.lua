local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Health", { "./Debug", "./Profiler", "./Ovale", "./GUID", "./State", "./Requirement" }, function(__exports, __Debug, __Profiler, __Ovale, __GUID, __State, __Requirement)
local OvaleHealthBase = __Ovale.Ovale:NewModule("OvaleHealth", "AceEvent-3.0")
local strsub = string.sub
local _tonumber = tonumber
local _wipe = wipe
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local INFINITY = math.huge
local CLEU_DAMAGE_EVENT = {
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true,
    RANGE_DAMAGE = true,
    SPELL_BUILDING_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    SWING_DAMAGE = true,
    ENVIRONMENTAL_DAMAGE = true
}
local CLEU_HEAL_EVENT = {
    SPELL_HEAL = true,
    SPELL_PERIODIC_HEAL = true
}
local OvaleHealthClass = __class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleHealthBase)), {
    constructor = function(self)
        self.health = {}
        self.maxHealth = {}
        self.totalDamage = {}
        self.totalHealing = {}
        self.firstSeen = {}
        self.lastUpdated = {}
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleHealthBase)).constructor(self)
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("UNIT_HEALTH_FREQUENT", "UpdateHealth")
        self:RegisterEvent("UNIT_MAXHEALTH", "UpdateHealth")
        self:RegisterMessage("Ovale_UnitChanged")
        __Requirement.RegisterRequirement("health_pct", "RequireHealthPercentHandler", self)
        __Requirement.RegisterRequirement("pet_health_pct", "RequireHealthPercentHandler", self)
        __Requirement.RegisterRequirement("target_health_pct", "RequireHealthPercentHandler", self)
    end,
    OnDisable = function(self)
        __Requirement.UnregisterRequirement("health_pct")
        __Requirement.UnregisterRequirement("pet_health_pct")
        __Requirement.UnregisterRequirement("target_health_pct")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
        self:UnregisterEvent("UNIT_MAXHEALTH")
        self:UnregisterMessage("Ovale_UnitChanged")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, _, arg15, _, _, _, _, _, _, _, _, _ = ...
        self:StartProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED")
        local healthUpdate = false
        if CLEU_DAMAGE_EVENT[cleuEvent] then
            local amount
            if cleuEvent == "SWING_DAMAGE" then
                amount = arg12
            elseif cleuEvent == "ENVIRONMENTAL_DAMAGE" then
                amount = arg13
            else
                amount = arg15
            end
            self:Debug(cleuEvent, destGUID, amount)
            local total = self.totalDamage[destGUID] or 0
            self.totalDamage[destGUID] = total + amount
            healthUpdate = true
        elseif CLEU_HEAL_EVENT[cleuEvent] then
            local amount = arg15
            self:Debug(cleuEvent, destGUID, amount)
            local total = self.totalHealing[destGUID] or 0
            self.totalHealing[destGUID] = total + amount
            healthUpdate = true
        end
        if healthUpdate then
            if  not self.firstSeen[destGUID] then
                self.firstSeen[destGUID] = timestamp
            end
            self.lastUpdated[destGUID] = timestamp
        end
        self:StopProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED")
    end,
    PLAYER_REGEN_DISABLED = function(self, event)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    PLAYER_REGEN_ENABLED = function(self, event)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        _wipe(self.totalDamage)
        _wipe(self.totalHealing)
        _wipe(self.firstSeen)
        _wipe(self.lastUpdated)
    end,
    Ovale_UnitChanged = function(self, event, unitId, guid)
        self:StartProfiling("Ovale_UnitChanged")
        if unitId == "target" or unitId == "focus" then
            self:Debug(event, unitId, guid)
            self:UpdateHealth("UNIT_HEALTH_FREQUENT", unitId)
            self:UpdateHealth("UNIT_MAXHEALTH", unitId)
            self:StopProfiling("Ovale_UnitChanged")
        end
    end,
    UpdateHealth = function(self, event, unitId)
        if  not unitId then
            return 
        end
        self:StartProfiling("OvaleHealth_UpdateHealth")
        local func = API_UnitHealth
        local db = self.health
        if event == "UNIT_MAXHEALTH" then
            func = API_UnitHealthMax
            db = self.maxHealth
        end
        local amount = func(unitId)
        if amount then
            local guid = __GUID.OvaleGUID:UnitGUID(unitId)
            self:Debug(event, unitId, guid, amount)
            if guid then
                if amount > 0 then
                    db[guid] = amount
                else
                    db[guid] = nil
                    self.firstSeen[guid] = nil
                    self.lastUpdated[guid] = nil
                end
                __Ovale.Ovale.refreshNeeded[guid] = true
            end
        end
        self:StopProfiling("OvaleHealth_UpdateHealth")
    end,
    UnitHealth = function(self, unitId, guid)
        local amount
        if unitId then
            guid = guid or __GUID.OvaleGUID:UnitGUID(unitId)
            if guid then
                if unitId == "target" or unitId == "focus" then
                    amount = self.health[guid] or 0
                else
                    amount = API_UnitHealth(unitId)
                    self.health[guid] = amount
                end
            else
                amount = 0
            end
        end
        return amount
    end,
    UnitHealthMax = function(self, unitId, guid)
        local amount
        if unitId then
            guid = guid or __GUID.OvaleGUID:UnitGUID(unitId)
            if guid then
                if unitId == "target" or unitId == "focus" then
                    amount = self.maxHealth[guid] or 0
                else
                    amount = API_UnitHealthMax(unitId)
                    self.maxHealth[guid] = amount
                end
            else
                amount = 0
            end
        end
        return amount
    end,
    UnitTimeToDie = function(self, unitId, guid)
        self:StartProfiling("OvaleHealth_UnitTimeToDie")
        local timeToDie = INFINITY
        guid = guid or __GUID.OvaleGUID:UnitGUID(unitId)
        if guid then
            local health = self:UnitHealth(unitId, guid)
            local maxHealth = self:UnitHealthMax(unitId, guid)
            if health and maxHealth then
                if health == 0 then
                    timeToDie = 0
                    self.firstSeen[guid] = nil
                    self.lastUpdated[guid] = nil
                elseif maxHealth > 5 then
                    local firstSeen, lastUpdated = self.firstSeen[guid], self.lastUpdated[guid]
                    local damage = self.totalDamage[guid] or 0
                    local healing = self.totalHealing[guid] or 0
                    if firstSeen and lastUpdated and lastUpdated > firstSeen and damage > healing then
                        timeToDie = health * (lastUpdated - firstSeen) / (damage - healing)
                    end
                end
            end
        end
        self:StopProfiling("OvaleHealth_UnitTimeToDie")
        return timeToDie
    end,
    RequireHealthPercentHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        local verified = false
        local threshold = tokens
        if index then
            threshold = tokens[index]
            index = index + 1
        end
        if threshold then
            local isBang = false
            if strsub(threshold, 1, 1) == "!" then
                isBang = true
                threshold = strsub(threshold, 2)
            end
            threshold = _tonumber(threshold) or 0
            local guid, unitId
            if strsub(requirement, 1, 7) == "target_" then
                if targetGUID then
                    guid = targetGUID
                    unitId = __GUID.OvaleGUID:GUIDUnit(guid)
                else
                    unitId = __State.baseState.defaultTarget or "target"
                end
            elseif strsub(requirement, 1, 4) == "pet_" then
                unitId = "pet"
            else
                unitId = "player"
            end
            guid = guid or __GUID.OvaleGUID:UnitGUID(unitId)
            local health = __exports.OvaleHealth:UnitHealth(unitId, guid) or 0
            local maxHealth = __exports.OvaleHealth:UnitHealthMax(unitId, guid) or 0
            local healthPercent = (maxHealth > 0) and (health / maxHealth * 100) or 100
            if  not isBang and healthPercent <= threshold or isBang and healthPercent > threshold then
                verified = true
            end
            local result = verified and "passed" or "FAILED"
            if isBang then
                self:Log("    Require %s health > %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result)
            else
                self:Log("    Require %s health <= %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result)
            end
        else
            __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' is missing a threshold argument.", requirement)
        end
        return verified, requirement, index
    end,
})
local HealthState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    RequireHealthPercentHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        return __exports.OvaleHealth:RequireHealthPercentHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    end,
})
__exports.healthState = HealthState()
__State.OvaleState:RegisterState(__exports.healthState)
__exports.OvaleHealth = OvaleHealthClass()
end)
