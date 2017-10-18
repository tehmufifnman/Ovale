local __addonName, __addon = ...
            __addon.require("./Future", { "./Debug", "./Profiler", "./Ovale", "./Aura", "./Data", "./GUID", "./PaperDoll", "./SpellBook", "./LastSpell", "AceEvent-3.0" }, function(__exports, __Debug, __Profiler, __Ovale, __Aura, __Data, __GUID, __PaperDoll, __SpellBook, __LastSpell, aceEvent)
local OvaleFutureBase = __Ovale.Ovale:NewModule("OvaleFuture", aceEvent)
local _ipairs = ipairs
local _pairs = pairs
local strsub = string.sub
local tinsert = table.insert
local tremove = table.remove
local _type = type
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitExists = UnitExists
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName
local self_timeAuraAdded = nil
local CLEU_AURA_EVENT = {
    SPELL_AURA_APPLIED = "hit",
    SPELL_AURA_APPLIED_DOSE = "hit",
    SPELL_AURA_BROKEN = "hit",
    SPELL_AURA_BROKEN_SPELL = "hit",
    SPELL_AURA_REFRESH = "hit",
    SPELL_AURA_REMOVED = "hit",
    SPELL_AURA_REMOVED_DOSE = "hit"
}
local CLEU_SPELLCAST_FINISH_EVENT = {
    SPELL_DAMAGE = "hit",
    SPELL_DISPEL = "hit",
    SPELL_DISPEL_FAILED = "miss",
    SPELL_HEAL = "hit",
    SPELL_INTERRUPT = "hit",
    SPELL_MISSED = "miss",
    SPELL_STOLEN = "hit"
}
local CLEU_SPELLCAST_EVENT = {
    SPELL_CAST_FAILED = true,
    SPELL_CAST_START = true,
    SPELL_CAST_SUCCESS = true
}
do
    for cleuEvent, v in _pairs(CLEU_AURA_EVENT) do
        CLEU_SPELLCAST_FINISH_EVENT[cleuEvent] = v
    end
    for cleuEvent in _pairs(CLEU_SPELLCAST_FINISH_EVENT) do
        CLEU_SPELLCAST_EVENT[cleuEvent] = true
    end
end
local SPELLCAST_AURA_ORDER = {
    [1] = "target",
    [2] = "pet"
}
local SPELLAURALIST_AURA_VALUE = {
    count = true,
    extend = true,
    refresh = true,
    refresh_keep_snapshot = true
}
local WHITE_ATTACK = {
    [75] = true,
    [5019] = true,
    [6603] = true
}
local WHITE_ATTACK_NAME = {}
do
    for spellId in _pairs(WHITE_ATTACK) do
        local name = API_GetSpellInfo(spellId)
        if name then
            WHITE_ATTACK_NAME[name] = true
        end
    end
end
local IsSameSpellcast = function(a, b)
    local boolean = (a.spellId == b.spellId and a.queued == b.queued)
    if boolean then
        if a.channel or b.channel then
            if a.channel ~= b.channel then
                boolean = false
            end
        elseif a.lineId ~= b.lineId then
            boolean = false
        end
    end
    return boolean
end

local eventDebug = false
local OvaleFutureClass = __addon.__class(__Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleFutureBase)), {
    constructor = function(self)
        self.inCombat = nil
        self.combatStartTime = nil
        self.lastCastTime = {}
        self.lastOffGCDSpellcast = {}
        self.counter = {}
        __Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleFutureBase)).constructor(self)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
        self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_SENT")
        self:RegisterEvent("UNIT_SPELLCAST_START")
        self:RegisterEvent("UNIT_SPELLCAST_STOP", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:RegisterMessage("Ovale_AuraAdded")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
        self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
        self:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
        self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:UnregisterEvent("UNIT_SPELLCAST_SENT")
        self:UnregisterEvent("UNIT_SPELLCAST_START")
        self:UnregisterEvent("UNIT_SPELLCAST_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:UnregisterMessage("Ovale_AuraAdded")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, _, _, _, _, _, _, _, _, _, _, arg24, arg25 = ...
        if sourceGUID == __Ovale.Ovale.playerGUID or __GUID.OvaleGUID:IsPlayerPet(sourceGUID) then
            self:StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
            if CLEU_SPELLCAST_EVENT[cleuEvent] then
                local now = API_GetTime()
                local spellId, spellName = arg12, arg13
                local eventDebug = false
                local delta = 0
                if strsub(cleuEvent, 1, 11) == "SPELL_CAST_" and (destName and destName ~= "") then
                    if  not eventDebug then
                        self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                        eventDebug = true
                    end
                    local spellcast = self:GetSpellcast(spellName, spellId, nil, now)
                    if spellcast and spellcast.targetName and spellcast.targetName == destName and spellcast.target ~= destGUID then
                        self:Debug("Disambiguating target of spell %s (%d) to %s (%s).", spellName, spellId, destName, destGUID)
                        spellcast.target = destGUID
                    end
                end
                local finish = CLEU_SPELLCAST_FINISH_EVENT[cleuEvent]
                if cleuEvent == "SPELL_DAMAGE" or cleuEvent == "SPELL_HEAL" then
                    local isOffHand, multistrike = arg24, arg25
                    if isOffHand or multistrike then
                        finish = nil
                    end
                end
                if finish then
                    local anyFinished = false
                    for i = #__LastSpell.lastSpell.queue, 1, -1 do
                        local spellcast = __LastSpell.lastSpell.queue[i]
                        if spellcast.success and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
                            if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
                                anyFinished = true
                            end
                        end
                    end
                    if  not anyFinished then
                        self:Debug("No spell found for %s (%d)", spellName, spellId)
                        for i = #__LastSpell.lastSpell.queue, 1, -1 do
                            local spellcast = __LastSpell.lastSpell.queue[i]
                            if spellcast.success and (spellcast.spellName == spellName) then
                                if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
                                    anyFinished = true
                                end
                            end
                        end
                        if  not anyFinished then
                            self:Debug("No spell found for %s", spellName, spellId)
                        end
                    end
                end
            end
            self:StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    FinishSpell = function(self, spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i)
        local finished = false
        if  not spellcast.auraId then
            if  not eventDebug then
                self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                eventDebug = true
            end
            if  not spellcast.channel then
                self:Debug("Finished (%s) spell %s (%d) queued at %s due to %s.", finish, spellName, spellId, spellcast.queued, cleuEvent)
                finished = true
            end
        elseif CLEU_AURA_EVENT[cleuEvent] and spellcast.auraGUID and destGUID == spellcast.auraGUID then
            if  not eventDebug then
                self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                eventDebug = true
            end
            self:Debug("Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID)
            finished = true
        end
        if finished then
            local now = API_GetTime()
            if self_timeAuraAdded then
                if IsSameSpellcast(spellcast, __LastSpell.lastSpell.lastGCDSpellcast) then
                    self:UpdateSpellcastSnapshot(__LastSpell.lastSpell.lastGCDSpellcast, self_timeAuraAdded)
                end
                if IsSameSpellcast(spellcast, self.lastOffGCDSpellcast) then
                    self:UpdateSpellcastSnapshot(self.lastOffGCDSpellcast, self_timeAuraAdded)
                end
            end
            local delta = now - spellcast.stop
            local targetGUID = spellcast.target
            self:Debug("Spell %s (%d) was in flight for %s seconds.", spellName, spellId, delta)
            tremove(__LastSpell.lastSpell.queue, i)
            __LastSpell.self_pool:Release(spellcast)
            __Ovale.Ovale:needRefresh()
            self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
        end
        return finished
    end,
    PLAYER_ENTERING_WORLD = function(self, event)
        self:StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
        self:Debug(event)
        self:StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
    end,
    PLAYER_REGEN_DISABLED = function(self, event)
        self:StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
        self:Debug(event, "Entering combat.")
        local now = API_GetTime()
        __Ovale.Ovale.inCombat = true
        self.combatStartTime = now
        __Ovale.Ovale:needRefresh()
        self:SendMessage("Ovale_CombatStarted", now)
        self:StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
    end,
    PLAYER_REGEN_ENABLED = function(self, event)
        self:StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
        self:Debug(event, "Leaving combat.")
        local now = API_GetTime()
        __Ovale.Ovale.inCombat = false
        __Ovale.Ovale:needRefresh()
        self:SendMessage("Ovale_CombatEnded", now)
        self:StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
    end,
    UNIT_SPELLCAST_CHANNEL_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, nil, now)
            if spellcast then
                local name, _, _, _, startTime, endTime = API_UnitChannelInfo(unitId)
                if name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    spellcast.channel = true
                    spellcast.spellId = spellId
                    spellcast.success = now
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    local delta = now - spellcast.queued
                    self:Debug("Channelling spell %s (%d): start = %s (+%s), ending = %s", spell, spellId, startTime, delta, endTime)
                    self:SaveSpellcastInfo(spellcast, now)
                    self:UpdateLastSpellcast(now, spellcast)
                    self:UpdateCounters(spellId, spellcast.start, spellcast.target)
                    __Ovale.Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not channelling a spell.")
                else
                    self:Debug("Warning: channelling unexpected spell %s", name)
                end
            else
                self:Debug("Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
        end
    end,
    UNIT_SPELLCAST_CHANNEL_STOP = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast, index = self:GetSpellcast(spell, spellId, nil, now)
            if spellcast and spellcast.channel then
                self:Debug("Finished channelling spell %s (%d) queued at %s.", spell, spellId, spellcast.queued)
                spellcast.stop = now
                self:UpdateLastSpellcast(now, spellcast)
                local targetGUID = spellcast.target
                tremove(__LastSpell.lastSpell.queue, index)
                __LastSpell.self_pool:Release(spellcast)
                __Ovale.Ovale:needRefresh()
                self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit")
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
        end
    end,
    UNIT_SPELLCAST_CHANNEL_UPDATE = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, nil, now)
            if spellcast and spellcast.channel then
                local name, _, _, _, startTime, endTime = API_UnitChannelInfo(unitId)
                if name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    local delta = endTime - spellcast.stop
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    self:Debug("Updating channelled spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
                    __Ovale.Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not channelling a spell.")
                else
                    self:Debug("Warning: delaying unexpected channelled spell %s.", name)
                end
            else
                self:Debug("Warning: no queued, channelled spell %s (%d) found to update.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
        end
    end,
    UNIT_SPELLCAST_DELAYED = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local name, _, _, _, startTime, endTime, _, castId = API_UnitCastingInfo(unitId)
                if lineId == castId and name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    local delta = endTime - spellcast.stop
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    self:Debug("Delaying spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
                    __Ovale.Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not casting a spell.")
                else
                    self:Debug("Warning: delaying unexpected spell %s.", name)
                end
            else
                self:Debug("Warning: no queued spell %s (%d) found to delay.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
        end
    end,
    UNIT_SPELLCAST_SENT = function(self, event, unitId, spell, rank, targetName, lineId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK_NAME[spell] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
            self:DebugTimestamp(event, unitId, spell, rank, targetName, lineId)
            local now = API_GetTime()
            local caster = __GUID.OvaleGUID:UnitGUID(unitId)
            local spellcast = __LastSpell.self_pool:Get()
            spellcast.lineId = lineId
            spellcast.caster = caster
            spellcast.spellName = spell
            spellcast.queued = now
            tinsert(__LastSpell.lastSpell.queue, spellcast)
            if targetName == "" then
                self:Debug("Queueing (%d) spell %s with no target.", #__LastSpell.lastSpell.queue, spell)
            else
                spellcast.targetName = targetName
                local targetGUID, nextGUID = __GUID.OvaleGUID:NameGUID(targetName)
                if nextGUID then
                    local name = __GUID.OvaleGUID:UnitName("target")
                    if name == targetName then
                        targetGUID = __GUID.OvaleGUID:UnitGUID("target")
                    else
                        name = __GUID.OvaleGUID:UnitName("focus")
                        if name == targetName then
                            targetGUID = __GUID.OvaleGUID:UnitGUID("focus")
                        elseif API_UnitExists("mouseover") then
                            name = API_UnitName("mouseover")
                            if name == targetName then
                                targetGUID = API_UnitGUID("mouseover")
                            end
                        end
                    end
                    spellcast.target = targetGUID
                    self:Debug("Queueing (%d) spell %s to %s (possibly %s).", #__LastSpell.lastSpell.queue, spell, targetName, targetGUID)
                else
                    spellcast.target = targetGUID
                    self:Debug("Queueing (%d) spell %s to %s (%s).", #__LastSpell.lastSpell.queue, spell, targetName, targetGUID)
                end
            end
            self:SaveSpellcastInfo(spellcast, now)
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
        end
    end,
    UNIT_SPELLCAST_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_START")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local name, _, _, _, startTime, endTime, _, castId = API_UnitCastingInfo(unitId)
                if lineId == castId and name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    spellcast.spellId = spellId
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    spellcast.channel = false
                    local delta = now - spellcast.queued
                    self:Debug("Casting spell %s (%d): start = %s (+%s), ending = %s.", spell, spellId, startTime, delta, endTime)
                    local auraId, auraGUID = self:GetAuraFinish(spell, spellId, spellcast.target, now)
                    if auraId and auraGUID then
                        spellcast.auraId = auraId
                        spellcast.auraGUID = auraGUID
                        self:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
                    end
                    self:SaveSpellcastInfo(spellcast, now)
                    __Ovale.Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not casting a spell.")
                else
                    self:Debug("Warning: casting unexpected spell %s.", name)
                end
            else
                self:Debug("Warning: casting spell %s (%d) without previous sent data.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_START")
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local success = false
                if  not spellcast.success and spellcast.start and spellcast.stop and  not spellcast.channel then
                    self:Debug("Succeeded casting spell %s (%d) at %s, now in flight.", spell, spellId, spellcast.stop)
                    spellcast.success = now
                    self:UpdateSpellcastSnapshot(spellcast, now)
                    success = true
                else
                    local name = API_UnitChannelInfo(unitId)
                    if  not name then
                        local now = API_GetTime()
                        spellcast.spellId = spellId
                        spellcast.start = now
                        spellcast.stop = now
                        spellcast.channel = false
                        spellcast.success = now
                        local delta = now - spellcast.queued
                        self:Debug("Instant-cast spell %s (%d): start = %s (+%s).", spell, spellId, now, delta)
                        local auraId, auraGUID = self:GetAuraFinish(spell, spellId, spellcast.target, now)
                        if auraId and auraGUID then
                            spellcast.auraId = auraId
                            spellcast.auraGUID = auraGUID
                            self:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
                        end
                        self:SaveSpellcastInfo(spellcast, now)
                        success = true
                    else
                        self:Debug("Succeeded casting spell %s (%d) but it is channelled.", spell, spellId)
                    end
                end
                if success then
                    local targetGUID = spellcast.target
                    self:UpdateLastSpellcast(now, spellcast)
                    self:UpdateCounters(spellId, spellcast.stop, targetGUID)
                    local finished = false
                    local finish = "miss"
                    if  not spellcast.targetName then
                        self:Debug("Finished spell %s (%d) with no target queued at %s.", spell, spellId, spellcast.queued)
                        finished = true
                        finish = "hit"
                    elseif targetGUID == __Ovale.Ovale.playerGUID and __SpellBook.OvaleSpellBook:IsHelpfulSpell(spellId) then
                        self:Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued)
                        finished = true
                        finish = "hit"
                    end
                    if finished then
                        tremove(__LastSpell.lastSpell.queue, index)
                        __LastSpell.self_pool:Release(spellcast)
                        __Ovale.Ovale:needRefresh()
                        self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
                    end
                end
            else
                self:Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    Ovale_AuraAdded = function(self, event, atTime, guid, auraId, caster)
        if guid == __Ovale.Ovale.playerGUID then
            self_timeAuraAdded = atTime
            self:UpdateSpellcastSnapshot(__LastSpell.lastSpell.lastGCDSpellcast, atTime)
            self:UpdateSpellcastSnapshot(self.lastOffGCDSpellcast, atTime)
        end
    end,
    UnitSpellcastEnded = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UnitSpellcastEnded")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = API_GetTime()
            local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                self:Debug("End casting spell %s (%d) queued at %s due to %s.", spell, spellId, spellcast.queued, event)
                if  not spellcast.success then
                    tremove(__LastSpell.lastSpell.queue, index)
                    __LastSpell.self_pool:Release(spellcast)
                    __Ovale.Ovale:needRefresh()
                end
            elseif lineId then
                self:Debug("Warning: no queued spell %s (%d) found to end casting.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UnitSpellcastEnded")
        end
    end,
    GetSpellcast = function(self, spell, spellId, lineId, atTime)
        self:StartProfiling("OvaleFuture_GetSpellcast")
        local spellcast, index
        if  not lineId or lineId ~= "" then
            for i, sc in _ipairs(__LastSpell.lastSpell.queue) do
                if  not lineId or sc.lineId == lineId then
                    if spellId and sc.spellId == spellId then
                        spellcast = sc
                        index = i
                        break
                    elseif spell then
                        local spellName = sc.spellName or __SpellBook.OvaleSpellBook:GetSpellName(spellId)
                        if spell == spellName then
                            spellcast = sc
                            index = i
                            break
                        end
                    end
                end
            end
        end
        if spellcast then
            local spellName = spell or spellcast.spellName or __SpellBook.OvaleSpellBook:GetSpellName(spellId)
            if spellcast.targetName then
                self:Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued)
            else
                self:Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued)
            end
        end
        self:StopProfiling("OvaleFuture_GetSpellcast")
        return spellcast, index
    end,
    GetAuraFinish = function(self, spell, spellId, targetGUID, atTime)
        self:StartProfiling("OvaleFuture_GetAuraFinish")
        local auraId, auraGUID
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.aura then
            for _, unitId in _ipairs(SPELLCAST_AURA_ORDER) do
                for _, auraList in _pairs(si.aura[unitId]) do
                    for id, spellData in _pairs(auraList) do
                        local verified, value = __Data.OvaleData:CheckSpellAuraData(id, spellData, atTime, targetGUID)
                        if verified and (SPELLAURALIST_AURA_VALUE[value] or _type(value) == "number" and value > 0) then
                            auraId = id
                            auraGUID = __GUID.OvaleGUID:UnitGUID(unitId)
                            break
                        end
                    end
                    if auraId then
                        break
                    end
                end
                if auraId then
                    break
                end
            end
        end
        self:StopProfiling("OvaleFuture_GetAuraFinish")
        return auraId, auraGUID
    end,
    SaveSpellcastInfo = function(self, spellcast, atTime)
        self:StartProfiling("OvaleFuture_SaveSpellcastInfo")
        self:Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName)
        if spellcast.spellId then
            spellcast.damageMultiplier = self:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
        end
        for _, mod in _pairs(__LastSpell.lastSpell.modules) do
            local func = mod.SaveSpellcastInfo
            if func then
                func(mod, spellcast, atTime)
            end
        end
        self:StopProfiling("OvaleFuture_SaveSpellcastInfo")
    end,
    GetDamageMultiplier = function(self, spellId, targetGUID, atTime)
        atTime = atTime or self["currentTime"] or API_GetTime()
        local damageMultiplier = 1
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.aura and si.aura.damage then
            local CheckRequirements
            for filter, auraList in _pairs(si.aura.damage) do
                for auraId, spellData in _pairs(auraList) do
                    local index, multiplier
                    if _type(spellData) == "table" then
                        multiplier = spellData[1]
                        index = 2
                    else
                        multiplier = spellData
                    end
                    local verified
                    if index then
                        verified = CheckRequirements(spellId, atTime, spellData, index, targetGUID)
                    else
                        verified = true
                    end
                    if verified then
                        local aura = __Aura.OvaleAura:GetAuraByGUID(__Ovale.Ovale.playerGUID, auraId, filter)
                        local isActiveAura = __Aura.OvaleAura:IsActiveAura(aura, atTime)
                        if isActiveAura then
                            local siAura = __Data.OvaleData.spellInfo[auraId]
                            if siAura and siAura.stacking and siAura.stacking > 0 then
                                multiplier = 1 + (multiplier - 1) * aura.stacks
                            end
                            damageMultiplier = damageMultiplier * multiplier
                        end
                    end
                end
            end
        end
        return damageMultiplier
    end,
    UpdateCounters = function(self, spellId, atTime, targetGUID)
        local inccounter = __Data.OvaleData:GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID)
        if inccounter then
            local value = self.counter[inccounter] and self.counter[inccounter] or 0
            self.counter[inccounter] = value + 1
        end
        local resetcounter = __Data.OvaleData:GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID)
        if resetcounter then
            self.counter[resetcounter] = 0
        end
    end,
    IsActive = function(self, spellId)
        for _, spellcast in _ipairs(__LastSpell.lastSpell.queue) do
            if spellcast.spellId == spellId and spellcast.start then
                return true
            end
        end
        return false
    end,
    InFlight = function(self, spellId)
        return self:IsActive(spellId)
    end,
    UpdateLastSpellcast = function(self, atTime, spellcast)
        self:StartProfiling("OvaleFuture_UpdateLastSpellcast")
        self.lastCastTime[spellcast.spellId] = atTime
        if spellcast.offgcd then
            self:Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId)
            for k, v in _pairs(spellcast) do
                self.lastOffGCDSpellcast[k] = v
            end
            __LastSpell.lastSpell.lastSpellcast = self.lastOffGCDSpellcast
        else
            self:Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId)
            for k, v in _pairs(spellcast) do
                __LastSpell.lastSpell.lastGCDSpellcast[k] = v
            end
            __LastSpell.lastSpell.lastSpellcast = __LastSpell.lastSpell.lastGCDSpellcast
        end
        self:StopProfiling("OvaleFuture_UpdateLastSpellcast")
    end,
    UpdateSpellcastSnapshot = function(self, spellcast, atTime)
        if spellcast.queued and ( not spellcast.snapshotTime or (spellcast.snapshotTime < atTime and atTime < spellcast.stop + 1)) then
            if spellcast.targetName then
                self:Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued)
            else
                self:Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued)
            end
            __PaperDoll.OvalePaperDoll:UpdateSnapshot(__PaperDoll.OvalePaperDoll, spellcast, true)
            if spellcast.spellId then
                spellcast.damageMultiplier = self:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
                if spellcast.damageMultiplier ~= 1 then
                    self:Debug("        persistent multiplier = %f", spellcast.damageMultiplier)
                end
            end
        end
    end,
})
__exports.OvaleFuture = OvaleFutureClass()
end)
