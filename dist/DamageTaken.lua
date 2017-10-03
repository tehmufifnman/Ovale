local __addonName, __addon = ...
__addon.require(__addonName, __addon, "DamageTaken", { "./Localization", "./Debug", "./Pool", "./Profiler", "./Queue", "./Ovale" }, function(__exports, __Localization, __Debug, __Pool, __Profiler, __Queue, __Ovale)
local OvaleDamageTakenBase = __Ovale.Ovale:NewModule("OvaleDamageTaken", "AceEvent-3.0")
local bit_band = bit.band
local bit_bor = bit.bor
local strsub = string.sub
local API_GetTime = GetTime
local _SCHOOL_MASK_ARCANE = SCHOOL_MASK_ARCANE
local _SCHOOL_MASK_FIRE = SCHOOL_MASK_FIRE
local _SCHOOL_MASK_FROST = SCHOOL_MASK_FROST
local _SCHOOL_MASK_HOLY = SCHOOL_MASK_HOLY
local _SCHOOL_MASK_NATURE = SCHOOL_MASK_NATURE
local _SCHOOL_MASK_NONE = SCHOOL_MASK_NONE
local _SCHOOL_MASK_PHYSICAL = SCHOOL_MASK_PHYSICAL
local _SCHOOL_MASK_SHADOW = SCHOOL_MASK_SHADOW
local self_playerGUID = nil
local self_pool = __Pool.OvalePool("OvaleDamageTaken_pool")
local DAMAGE_TAKEN_WINDOW = 20
local SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW)
local OvaleDamageTakenClass = __class(__Ovale.RegisterPrinter(__Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleDamageTakenBase))), {
    OnEnable = function(self)
        self_playerGUID = __Ovale.Ovale.playerGUID
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self_pool:Drain()
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
        if destGUID == self_playerGUID and strsub(cleuEvent, -7) == "_DAMAGE" then
            self:StartProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
            local now = API_GetTime()
            local eventPrefix = strsub(cleuEvent, 1, 6)
            if eventPrefix == "SWING_" then
                local amount = arg12
                self:Debug("%s caused %d damage.", cleuEvent, amount)
                self:AddDamageTaken(now, amount)
            elseif eventPrefix == "RANGE_" or eventPrefix == "SPELL_" then
                local spellName, spellSchool, amount = arg13, arg14, arg15
                local isMagicDamage = (bit_band(spellSchool, SCHOOL_MASK_MAGIC) > 0)
                if isMagicDamage then
                    self:Debug("%s (%s) caused %d magic damage.", cleuEvent, spellName, amount)
                else
                    self:Debug("%s (%s) caused %d damage.", cleuEvent, spellName, amount)
                end
                self:AddDamageTaken(now, amount, isMagicDamage)
            end
            self:StopProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    PLAYER_REGEN_ENABLED = function(self, event)
        self_pool:Drain()
    end,
    AddDamageTaken = function(self, timestamp, damage, isMagicDamage)
        self:StartProfiling("OvaleDamageTaken_AddDamageTaken")
        local event = self_pool:Get()
        event.timestamp = timestamp
        event.damage = damage
        event.magic = isMagicDamage
        self.damageEvent:InsertFront(event)
        self:RemoveExpiredEvents(timestamp)
        __Ovale.Ovale.refreshNeeded[self_playerGUID] = true
        self:StopProfiling("OvaleDamageTaken_AddDamageTaken")
    end,
    GetRecentDamage = function(self, interval)
        local now = API_GetTime()
        local lowerBound = now - interval
        self:RemoveExpiredEvents(now)
        local total, totalMagic = 0, 0
        local iterator = self.damageEvent:FrontToBackIterator()
        while iterator:Next() do
            local event = iterator.value
            if event.timestamp < lowerBound then
                break
            end
            total = total + event.damage
            if event.magic then
                totalMagic = totalMagic + event.damage
            end
        end
        return total, totalMagic
    end,
    RemoveExpiredEvents = function(self, timestamp)
        self:StartProfiling("OvaleDamageTaken_RemoveExpiredEvents")
        while true do
            local event = self.damageEvent:Back()
            if  not event then
                break
            end
            if event then
                if timestamp - event.timestamp < DAMAGE_TAKEN_WINDOW then
                    break
                end
                self.damageEvent:RemoveBack()
                self_pool:Release(event)
                __Ovale.Ovale.refreshNeeded[self_playerGUID] = true
            end
        end
        self:StopProfiling("OvaleDamageTaken_RemoveExpiredEvents")
    end,
    DebugDamageTaken = function(self)
        self.damageEvent:DebuggingInfo()
        local iterator = self.damageEvent:BackToFrontIterator()
        while iterator:Next() do
            local event = iterator.value
            self:Print("%d: %d damage", event.timestamp, event.damage)
        end
    end,
})
__exports.OvaleDamageTaken = OvaleDamageTakenClass()
end)
