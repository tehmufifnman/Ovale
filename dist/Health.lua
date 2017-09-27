local OVALE, Ovale = ...
require(OVALE, Ovale, "Health", { "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __OvaleDebug, __OvaleProfiler)
local OvaleHealth = Ovale:NewModule("OvaleHealth", "AceEvent-3.0")
Ovale.OvaleHealth = OvaleHealth
local OvaleData = nil
local OvaleGUID = nil
local OvaleState = nil
local strsub = string.sub
local _tonumber = tonumber
local _wipe = wipe
local API_GetTime = GetTime
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local INFINITY = math.huge
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleHealth)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleHealth)
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
OvaleHealth.health = {}
OvaleHealth.maxHealth = {}
OvaleHealth.totalDamage = {}
OvaleHealth.totalHealing = {}
OvaleHealth.firstSeen = {}
OvaleHealth.lastUpdated = {}
local OvaleHealth = __class()
function OvaleHealth:OnInitialize()
    OvaleData = Ovale.OvaleData
    OvaleGUID = Ovale.OvaleGUID
    OvaleState = Ovale.OvaleState
end
function OvaleHealth:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_HEALTH_FREQUENT", "UpdateHealth")
    self:RegisterEvent("UNIT_MAXHEALTH", "UpdateHealth")
    self:RegisterMessage("Ovale_UnitChanged")
    OvaleData:RegisterRequirement("health_pct", "RequireHealthPercentHandler", self)
    OvaleData:RegisterRequirement("pet_health_pct", "RequireHealthPercentHandler", self)
    OvaleData:RegisterRequirement("target_health_pct", "RequireHealthPercentHandler", self)
    OvaleState:RegisterState(self, self.statePrototype)
end
function OvaleHealth:OnDisable()
    OvaleState:UnregisterState(self)
    OvaleData:UnregisterRequirement("health_pct")
    OvaleData:UnregisterRequirement("pet_health_pct")
    OvaleData:UnregisterRequirement("target_health_pct")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
    self:UnregisterEvent("UNIT_MAXHEALTH")
    self:UnregisterMessage("Ovale_UnitChanged")
end
function OvaleHealth:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
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
end
function OvaleHealth:PLAYER_REGEN_DISABLED(event)
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
function OvaleHealth:PLAYER_REGEN_ENABLED(event)
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    _wipe(self.totalDamage)
    _wipe(self.totalHealing)
    _wipe(self.firstSeen)
    _wipe(self.lastUpdated)
end
function OvaleHealth:Ovale_UnitChanged(event, unitId, guid)
    self:StartProfiling("Ovale_UnitChanged")
    if unitId == "target" or unitId == "focus" then
        self:Debug(event, unitId, guid)
        self:UpdateHealth("UNIT_HEALTH_FREQUENT", unitId)
        self:UpdateHealth("UNIT_MAXHEALTH", unitId)
        self:StopProfiling("Ovale_UnitChanged")
    end
end
function OvaleHealth:UpdateHealth(event, unitId)
    if  not unitId then
        break
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
        local guid = OvaleGUID:UnitGUID(unitId)
        self:Debug(event, unitId, guid, amount)
        if guid then
            if amount > 0 then
                db[guid] = amount
            else
                db[guid] = nil
                self.firstSeen[guid] = nil
                self.lastUpdated[guid] = nil
            end
            Ovale.refreshNeeded[guid] = true
        end
    end
    self:StopProfiling("OvaleHealth_UpdateHealth")
end
function OvaleHealth:UnitHealth(unitId, guid)
    local amount
    if unitId then
        guid = guid or OvaleGUID:UnitGUID(unitId)
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
end
function OvaleHealth:UnitHealthMax(unitId, guid)
    local amount
    if unitId then
        guid = guid or OvaleGUID:UnitGUID(unitId)
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
end
function OvaleHealth:UnitTimeToDie(unitId, guid)
    self:StartProfiling("OvaleHealth_UnitTimeToDie")
    local timeToDie = INFINITY
    guid = guid or OvaleGUID:UnitGUID(unitId)
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
end
function OvaleHealth:RequireHealthPercentHandler(spellId, atTime, requirement, tokens, index, targetGUID)
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
                unitId = OvaleGUID:GUIDUnit(guid)
            else
                unitId = self.defaultTarget or "target"
            end
        elseif strsub(requirement, 1, 4) == "pet_" then
            unitId = "pet"
        else
            unitId = "player"
        end
        guid = guid or OvaleGUID:UnitGUID(unitId)
        local health = OvaleHealth:UnitHealth(unitId, guid) or 0
        local maxHealth = OvaleHealth:UnitHealthMax(unitId, guid) or 0
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
        Ovale:OneTimeMessage("Warning: requirement '%s' is missing a threshold argument.", requirement)
    end
    return verified, requirement, index
end
OvaleHealth.statePrototype = {}
local statePrototype = OvaleHealth.statePrototype
statePrototype.RequireHealthPercentHandler = OvaleHealth.RequireHealthPercentHandler
end))
