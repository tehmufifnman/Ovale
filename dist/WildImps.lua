local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./WildImps", { "./State", "./Ovale" }, function(__exports, __State, __Ovale)
local OvaleWildImpsBase = __Ovale.Ovale:NewModule("OvaleWildImps", "AceEvent-3.0")
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
local OvaleWildImpsClass = __class(OvaleWildImpsBase, {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        if __Ovale.Ovale.playerClass == "WARLOCK" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self_demons = {}
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "WARLOCK" then
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId)
        self_serial = self_serial + 1
        __Ovale.Ovale.refreshNeeded[__Ovale.Ovale.playerGUID] = true
        if sourceGUID ~= __Ovale.Ovale.playerGUID then
            return 
        end
        if cleuEvent == "SPELL_SUMMON" then
            local _1, _2, _3, _4, _5, _6, _7, creatureId = destGUID:find("(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
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
            if spellId == 193396 then
                for k, d in pairs(self_demons) do
                    d.de = true
                end
            end
        end
    end,
})
local WildImpsState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    GetNotDemonicEmpoweredDemonsCount = function(self, creatureId, atTime)
        local count = 0
        for k, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId and  not d.de then
                count = count + 1
            end
        end
        return count
    end,
    GetDemonsCount = function(self, creatureId, atTime)
        local count = 0
        for k, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId then
                count = count + 1
            end
        end
        return count
    end,
    GetRemainingDemonDuration = function(self, creatureId, atTime)
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
    end,
})
__exports.wildImpsState = WildImpsState()
__State.OvaleState:RegisterState(__exports.wildImpsState)
__exports.OvaleWildImps = OvaleWildImpsClass()
end)
