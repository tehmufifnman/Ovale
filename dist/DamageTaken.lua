local OVALE, Ovale = ...
require(OVALE, Ovale, "DamageTaken", { "./L", "./OvaleDebug", "./OvalePool", "./OvaleProfiler", "./OvaleQueue" }, function(__exports, __L, __OvaleDebug, __OvalePool, __OvaleProfiler, __OvaleQueue)
local OvaleDamageTaken = Ovale:NewModule("OvaleDamageTaken", "AceEvent-3.0")
Ovale.OvaleDamageTaken = OvaleDamageTaken
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
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleDamageTaken)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleDamageTaken)
local self_playerGUID = nil
local self_pool = __OvalePool.OvalePool("OvaleDamageTaken_pool")
local DAMAGE_TAKEN_WINDOW = 20
local SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW)
OvaleDamageTaken.damageEvent = __OvaleQueue.OvaleQueue:NewDeque("OvaleDamageTaken_damageEvent")
local OvaleDamageTaken = __class()
function OvaleDamageTaken:OnEnable()
    self_playerGUID = Ovale.playerGUID
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end
function OvaleDamageTaken:OnDisable()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self_pool:Drain()
end
function OvaleDamageTaken:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
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
end
function OvaleDamageTaken:PLAYER_REGEN_ENABLED(event)
    self_pool:Drain()
end
function OvaleDamageTaken:AddDamageTaken(timestamp, damage, isMagicDamage)
    self:StartProfiling("OvaleDamageTaken_AddDamageTaken")
    local event = self_pool:Get()
    event.timestamp = timestamp
    event.damage = damage
    event.magic = isMagicDamage
    self.damageEvent:InsertFront(event)
    self:RemoveExpiredEvents(timestamp)
    Ovale.refreshNeeded[self_playerGUID] = true
    self:StopProfiling("OvaleDamageTaken_AddDamageTaken")
end
function OvaleDamageTaken:GetRecentDamage(interval)
    local now = API_GetTime()
    local lowerBound = now - interval
    self:RemoveExpiredEvents(now)
    local total, totalMagic = 0, 0
    for i, event in self.damageEvent:FrontToBackIterator() do
        if event.timestamp < lowerBound then
            break
        end
        total = total + event.damage
        if event.magic then
            totalMagic = totalMagic + event.damage
        end
    end
    return total, totalMagic
end
function OvaleDamageTaken:RemoveExpiredEvents(timestamp)
    self:StartProfiling("OvaleDamageTaken_RemoveExpiredEvents")
    while truedo
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
            Ovale.refreshNeeded[self_playerGUID] = true
        end
end
    self:StopProfiling("OvaleDamageTaken_RemoveExpiredEvents")
end
function OvaleDamageTaken:DebugDamageTaken()
    self.damageEvent:DebuggingInfo()
    for i, event in self.damageEvent:BackToFrontIterator() do
        self:Print("%d: %d damage", event.timestamp, event.damage)
    end
end
end))
