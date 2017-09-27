local OVALE, Ovale = ...
local OvaleWildImps = Ovale:NewModule("OvaleWildImps", "AceEvent-3.0")
Ovale.OvaleWildImps = OvaleWildImps
local OvaleState = nil
local tinsert = table.insert
local tremove = table.remove
local demonData = {
    [55659] = {
        duration = 12
    },
    [98035] = {
        duration = 12
    },
    [103673] = {
        duration = 12
    },
    [11859] = {
        duration = 25
    },
    [89] = {
        duration = 25
    }
}
local self_demons = {}
local self_serial = 1
local API_GetTime = GetTime
local OvaleWildImps = __class()
function OvaleWildImps:OnInitialize()
    OvaleState = Ovale.OvaleState
end
function OvaleWildImps:OnEnable()
    if Ovale.playerClass == "WARLOCK" then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        OvaleState:RegisterState(self, self.statePrototype)
        self_demons = {}
    end
end
function OvaleWildImps:OnDisable()
    if Ovale.playerClass == "WARLOCK" then
        OvaleState:UnregisterState(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end
function OvaleWildImps:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    self_serial = self_serial + 1
    Ovale.refreshNeeded[Ovale.playerGUID] = true
    if sourceGUID ~= Ovale.playerGUID then
        break
    end
    if cleuEvent == "SPELL_SUMMON" then
        local _, _, _, _, _, _, _, creatureId = destGUID:find("(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
        creatureId = tonumber(creatureId)
        local now = API_GetTime()
        for id, v in pairs(demonData) do
            if id == creatureId then
                self_demons[destGUID] = {
                    id = creatureId,
                    timestamp = now,
                    finish = now + v.duration
                }
                break
            end
        end
        for k, d in pairs(self_demons) do
            if d.finish < now then
                self_demons[k] = nil
            end
        end
    elseif cleuEvent == "SPELL_INSTAKILL" then
        if spellId == 196278 then
            self_demons[destGUID] = nil
        end
    elseif cleuEvent == "SPELL_CAST_SUCCESS" then
        local spellId = ...
        if spellId == 193396 then
            for k, d in pairs(self_demons) do
                d.de = true
            end
        end
    end
end
OvaleWildImps.statePrototype = {}
local statePrototype = OvaleWildImps.statePrototype
statePrototype.GetNotDemonicEmpoweredDemonsCount = function(state, creatureId, atTime)
    local count = 0
    for k, d in pairs(self_demons) do
        if d.finish >= atTime and d.id == creatureId and  not d.de then
            count = count + 1
        end
    end
    return count
end
statePrototype.GetDemonsCount = function(state, creatureId, atTime)
    local count = 0
    for k, d in pairs(self_demons) do
        if d.finish >= atTime and d.id == creatureId then
            count = count + 1
        end
    end
    return count
end
statePrototype.GetRemainingDemonDuration = function(state, creatureId, atTime)
    local max = 0
    for k, d in pairs(self_demons) do
        if d.finish >= atTime and d.id == creatureId then
            local remaining = d.finish - atTime
            if remaining > max then
                max = remaining
            end
        end
    end
    return max
end
