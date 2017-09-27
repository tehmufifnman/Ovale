local OVALE, Ovale = ...
require(OVALE, Ovale, "Future", { "./OvaleDebug", "./OvalePool", "./OvaleProfiler" }, function(__exports, __OvaleDebug, __OvalePool, __OvaleProfiler)
local OvaleFuture = Ovale:NewModule("OvaleFuture", "AceEvent-3.0")
Ovale.OvaleFuture = OvaleFuture
local OvaleAura = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleScore = nil
local OvaleSpellBook = nil
local OvaleState = nil
local _assert = assert
local _ipairs = ipairs
local _pairs = pairs
local strsub = string.sub
local tinsert = table.insert
local tremove = table.remove
local _type = type
local _wipe = wipe
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitExists = UnitExists
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleFuture)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleFuture)
local self_playerGUID = nil
local self_pool = __OvalePool.OvalePool("OvaleFuture_pool")
local self_timeAuraAdded = nil
local self_modules = {}
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
    for cleuEvent, v in _pairs(CLEU_SPELLCAST_FINISH_EVENT) do
        CLEU_SPELLCAST_EVENT[cleuEvent] = true
    end
end
local SPELLCAST_AURA_ORDER = {
    1 = "target",
    2 = "pet"
}
local UNKNOWN_GUID = 0
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
local SIMULATOR_LAG = 0.005
OvaleFuture.inCombat = nil
OvaleFuture.combatStartTime = nil
OvaleFuture.queue = {}
OvaleFuture.lastCastTime = {}
OvaleFuture.lastSpellcast = nil
OvaleFuture.lastGCDSpellcast = {}
OvaleFuture.lastOffGCDSpellcast = {}
OvaleFuture.counter = {}
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
local OvaleFuture = __class()
function OvaleFuture:OnInitialize()
    OvaleAura = Ovale.OvaleAura
    OvaleCooldown = Ovale.OvaleCooldown
    OvaleData = Ovale.OvaleData
    OvaleGUID = Ovale.OvaleGUID
    OvalePaperDoll = Ovale.OvalePaperDoll
    OvaleScore = Ovale.OvaleScore
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleState = Ovale.OvaleState
end
function OvaleFuture:OnEnable()
    self_playerGUID = Ovale.playerGUID
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
    OvaleState:RegisterState(self, self.statePrototype)
end
function OvaleFuture:OnDisable()
    OvaleState:UnregisterState(self)
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
end
function OvaleFuture:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
    if sourceGUID == self_playerGUID or OvaleGUID:IsPlayerPet(sourceGUID) then
        self:StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
        if CLEU_SPELLCAST_EVENT[cleuEvent] then
            local now = API_GetTime()
            local spellId, spellName = arg12, arg13
            local eventDebug = false
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
                for i = #self.queue, 1, -1 do
                    local spellcast = self.queue[i]
                    if spellcast.success and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
                        if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
                            anyFinished = true
                        end
                    end
                end
                if  not anyFinished then
                    self:Debug("No spell found for %s (%d)", spellName, spellId)
                    for i = #self.queue, 1, -1 do
                        local spellcast = self.queue[i]
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
end
function OvaleFuture:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i)
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
            if IsSameSpellcast(spellcast, self.lastGCDSpellcast) then
                self:UpdateSpellcastSnapshot(self.lastGCDSpellcast, self_timeAuraAdded)
            end
            if IsSameSpellcast(spellcast, self.lastOffGCDSpellcast) then
                self:UpdateSpellcastSnapshot(self.lastOffGCDSpellcast, self_timeAuraAdded)
            end
        end
        local delta = now - spellcast.stop
        local targetGUID = spellcast.target
        self:Debug("Spell %s (%d) was in flight for %s seconds.", spellName, spellId, delta)
        tremove(self.queue, i)
        self_pool:Release(spellcast)
        Ovale.refreshNeeded[self_playerGUID] = true
        self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
    end
    return finished
end
function OvaleFuture:PLAYER_ENTERING_WORLD(event)
    self:StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
    self:Debug(event)
    self:StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
end
function OvaleFuture:PLAYER_REGEN_DISABLED(event)
    self:StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
    self:Debug(event, "Entering combat.")
    local now = API_GetTime()
    self.inCombat = true
    self.combatStartTime = now
    Ovale.refreshNeeded[self_playerGUID] = true
    self:SendMessage("Ovale_CombatStarted", now)
    self:StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
end
function OvaleFuture:PLAYER_REGEN_ENABLED(event)
    self:StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
    self:Debug(event, "Leaving combat.")
    local now = API_GetTime()
    self.inCombat = false
    Ovale.refreshNeeded[self_playerGUID] = true
    self:SendMessage("Ovale_CombatEnded", now)
    self:StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
end
function OvaleFuture:UNIT_SPELLCAST_CHANNEL_START(event, unitId, spell, rank, lineId, spellId)
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
                OvaleScore:ScoreSpell(spellId)
                Ovale.refreshNeeded[self_playerGUID] = true
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
end
function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unitId, spell, rank, lineId, spellId)
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
            tremove(self.queue, index)
            self_pool:Release(spellcast)
            Ovale.refreshNeeded[self_playerGUID] = true
            self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit")
        end
        self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
    end
end
function OvaleFuture:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unitId, spell, rank, lineId, spellId)
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
                Ovale.refreshNeeded[self_playerGUID] = true
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
end
function OvaleFuture:UNIT_SPELLCAST_DELAYED(event, unitId, spell, rank, lineId, spellId)
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
                Ovale.refreshNeeded[self_playerGUID] = true
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
end
function OvaleFuture:UNIT_SPELLCAST_SENT(event, unitId, spell, rank, targetName, lineId)
    if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK_NAME[spell] then
        self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
        self:DebugTimestamp(event, unitId, spell, rank, targetName, lineId)
        local now = API_GetTime()
        local caster = OvaleGUID:UnitGUID(unitId)
        local spellcast = self_pool:Get()
        spellcast.lineId = lineId
        spellcast.caster = caster
        spellcast.spellName = spell
        spellcast.queued = now
        tinsert(self.queue, spellcast)
        if targetName == "" then
            self:Debug("Queueing (%d) spell %s with no target.", #self.queue, spell)
        else
            spellcast.targetName = targetName
            local targetGUID, nextGUID = OvaleGUID:NameGUID(targetName)
            if nextGUID then
                local name = OvaleGUID:UnitName("target")
                if name == targetName then
                    targetGUID = OvaleGUID:UnitGUID("target")
                else
                    name = OvaleGUID:UnitName("focus")
                    if name == targetName then
                        targetGUID = OvaleGUID:UnitGUID("focus")
                    elseif API_UnitExists("mouseover") then
                        name = API_UnitName("mouseover")
                        if name == targetName then
                            targetGUID = API_UnitGUID("mouseover")
                        end
                    end
                end
                spellcast.target = targetGUID
                self:Debug("Queueing (%d) spell %s to %s (possibly %s).", #self.queue, spell, targetName, targetGUID)
            else
                spellcast.target = targetGUID
                self:Debug("Queueing (%d) spell %s to %s (%s).", #self.queue, spell, targetName, targetGUID)
            end
        end
        self:SaveSpellcastInfo(spellcast, now)
        self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
    end
end
function OvaleFuture:UNIT_SPELLCAST_START(event, unitId, spell, rank, lineId, spellId)
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
                OvaleScore:ScoreSpell(spellId)
                Ovale.refreshNeeded[self_playerGUID] = true
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
end
function OvaleFuture:UNIT_SPELLCAST_SUCCEEDED(event, unitId, spell, rank, lineId, spellId)
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
                    OvaleScore:ScoreSpell(spellId)
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
                elseif targetGUID == self_playerGUID and OvaleSpellBook:IsHelpfulSpell(spellId) then
                    self:Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued)
                    finished = true
                    finish = "hit"
                end
                if finished then
                    tremove(self.queue, index)
                    self_pool:Release(spellcast)
                    Ovale.refreshNeeded[self_playerGUID] = true
                    self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
                end
            end
        else
            self:Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId)
        end
        self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
    end
end
function OvaleFuture:Ovale_AuraAdded(event, atTime, guid, auraId, caster)
    if guid == self_playerGUID then
        self_timeAuraAdded = atTime
        self:UpdateSpellcastSnapshot(self.lastGCDSpellcast, atTime)
        self:UpdateSpellcastSnapshot(self.lastOffGCDSpellcast, atTime)
    end
end
function OvaleFuture:UnitSpellcastEnded(event, unitId, spell, rank, lineId, spellId)
    if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
        self:StartProfiling("OvaleFuture_UnitSpellcastEnded")
        self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
        local now = API_GetTime()
        local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
        if spellcast then
            self:Debug("End casting spell %s (%d) queued at %s due to %s.", spell, spellId, spellcast.queued, event)
            if  not spellcast.success then
                tremove(self.queue, index)
                self_pool:Release(spellcast)
                Ovale.refreshNeeded[self_playerGUID] = true
            end
        elseif lineId then
            self:Debug("Warning: no queued spell %s (%d) found to end casting.", spell, spellId)
        end
        self:StopProfiling("OvaleFuture_UnitSpellcastEnded")
    end
end
function OvaleFuture:GetSpellcast(spell, spellId, lineId, atTime)
    self:StartProfiling("OvaleFuture_GetSpellcast")
    local spellcast, index
    if  not lineId or lineId ~= "" then
        for i, sc in _ipairs(self.queue) do
            if  not lineId or sc.lineId == lineId then
                if spellId and sc.spellId == spellId then
                    spellcast = sc
                    index = i
                    break
                elseif spell then
                    local spellName = sc.spellName or OvaleSpellBook:GetSpellName(spellId)
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
        local spellName = spell or spellcast.spellName or OvaleSpellBook:GetSpellName(spellId)
        if spellcast.targetName then
            self:Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued)
        else
            self:Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued)
        end
    end
    self:StopProfiling("OvaleFuture_GetSpellcast")
    return spellcast, index
end
function OvaleFuture:GetAuraFinish(spell, spellId, targetGUID, atTime)
    self:StartProfiling("OvaleFuture_GetAuraFinish")
    local auraId, auraGUID
    local si = OvaleData.spellInfo[spellId]
    if si and si.aura then
        for _, unitId in _ipairs(SPELLCAST_AURA_ORDER) do
            for filter, auraList in _pairs(si.aura[unitId]) do
                for id, spellData in _pairs(auraList) do
                    local verified, value, data = OvaleData:CheckSpellAuraData(id, spellData, atTime, targetGUID)
                    if verified and (SPELLAURALIST_AURA_VALUE[value] or _type(value) == "number" and value > 0) then
                        auraId = id
                        auraGUID = OvaleGUID:UnitGUID(unitId)
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
end
function OvaleFuture:RegisterSpellcastInfo(mod)
    tinsert(self_modules, mod)
end
function OvaleFuture:UnregisterSpellcastInfo(mod)
    for i = #self_modules, 1, -1 do
        if self_modules[i] == mod then
            tremove(self_modules, i)
        end
    end
end
function OvaleFuture:CopySpellcastInfo(spellcast, dest)
    self:StartProfiling("OvaleFuture_CopySpellcastInfo")
    if spellcast.damageMultiplier then
        dest.damageMultiplier = spellcast.damageMultiplier
    end
    for _, mod in _pairs(self_modules) do
        local func = mod.CopySpellcastInfo
        if func then
            func(mod, spellcast, dest)
        end
    end
    self:StopProfiling("OvaleFuture_CopySpellcastInfo")
end
function OvaleFuture:SaveSpellcastInfo(spellcast, atTime)
    self:StartProfiling("OvaleFuture_SaveSpellcastInfo")
    self:Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName)
    if spellcast.spellId then
        spellcast.damageMultiplier = OvaleFuture:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
    end
    for _, mod in _pairs(self_modules) do
        local func = mod.SaveSpellcastInfo
        if func then
            func(mod, spellcast, atTime)
        end
    end
    self:StopProfiling("OvaleFuture_SaveSpellcastInfo")
end
function OvaleFuture:GetDamageMultiplier(spellId, targetGUID, atTime)
    atTime = atTime or self["currentTime"] or API_GetTime()
    local damageMultiplier = 1
    local si = OvaleData.spellInfo[spellId]
    if si and si.aura and si.aura.damage then
        local CheckRequirements
        local GetAuraByGUID, IsActiveAura
        local auraModule, dataModule
        CheckRequirements, dataModule = self:GetMethod("CheckRequirements", OvaleData)
        GetAuraByGUID, auraModule = self:GetMethod("GetAuraByGUID", OvaleAura)
        IsActiveAura, auraModule = self:GetMethod("IsActiveAura", OvaleAura)
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
                    verified = CheckRequirements(dataModule, spellId, atTime, spellData, index, targetGUID)
                else
                    verified = true
                end
                if verified then
                    local aura = GetAuraByGUID(auraModule, self_playerGUID, auraId, filter)
                    local isActiveAura = IsActiveAura(auraModule, aura, atTime)
                    if isActiveAura then
                        local siAura = OvaleData.spellInfo[auraId]
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
end
function OvaleFuture:UpdateCounters(spellId, atTime, targetGUID)
    local inccounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID)
    if inccounter then
        local value = self.counter[inccounter] and self.counter[inccounter] or 0
        self.counter[inccounter] = value + 1
    end
    local resetcounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID)
    if resetcounter then
        self.counter[resetcounter] = 0
    end
end
function OvaleFuture:IsActive(spellId)
    for _, spellcast in _ipairs(self.queue) do
        if spellcast.spellId == spellId and spellcast.start then
            return true
        end
    end
    return false
end
OvaleFuture.InFlight = OvaleFuture.IsActive
local OvaleFuture = __class()
function OvaleFuture:LastInFlightSpell()
    local spellcast
    if self.lastGCDSpellcast.success then
        spellcast = self.lastGCDSpellcast
    end
    for i = #self.queue, 1, -1 do
        local sc = self.queue[i]
        if sc.success then
            if  not spellcast or spellcast.success < sc.success then
                spellcast = sc
            end
            break
        end
    end
    return spellcast
end
function OvaleFuture:LastSpellSent()
    local spellcast = nil
    if self.lastGCDSpellcast.success then
        spellcast = self.lastGCDSpellcast
    end
    for i = #self.queue, 1, -1 do
        local sc = self.queue[i]
        if sc.success then
            if  not spellcast or (spellcast.success and spellcast.success < sc.success) or ( not spellcast.success and spellcast.queued < sc.success) then
                spellcast = sc
            end
        elseif  not sc.start and  not sc.stop then
            if spellcast.success and spellcast.success < sc.queued then
                spellcast = sc
            elseif spellcast.queued < sc.queued then
                spellcast = sc
            end
        end
    end
    return spellcast
end
function OvaleFuture:ApplyInFlightSpells(state)
    self:StartProfiling("OvaleFuture_ApplyInFlightSpells")
    local now = API_GetTime()
    local index = 1
    while index <= #self.queuedo
        local spellcast = self.queue[index]
        if spellcast.stop then
            local isValid = false
            local description
            if now < spellcast.stop then
                isValid = true
                description = spellcast.channel and "channelling" or "being cast"
            elseif now < spellcast.stop + 5 then
                isValid = true
                description = "in flight"
            end
            if isValid then
                if spellcast.target then
                    state:Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop)
                else
                    state:Log("Active spell %s (%d) is %s, now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop)
                end
                state:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast)
            else
                if spellcast.target then
                    self:Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target)
                else
                    self:Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId)
                end
                tremove(self.queue, index)
                self_pool:Release(spellcast)
                index = index - 1
            end
        end
        index = index + 1
end
    self:StopProfiling("OvaleFuture_ApplyInFlightSpells")
end
function OvaleFuture:UpdateLastSpellcast(atTime, spellcast)
    self:StartProfiling("OvaleFuture_UpdateLastSpellcast")
    self.lastCastTime[spellcast.spellId] = atTime
    if spellcast.offgcd then
        self:Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId)
        for k, v in _pairs(spellcast) do
            self.lastOffGCDSpellcast[k] = v
        end
        self.lastSpellcast = self.lastOffGCDSpellcast
    else
        self:Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId)
        for k, v in _pairs(spellcast) do
            self.lastGCDSpellcast[k] = v
        end
        self.lastSpellcast = self.lastGCDSpellcast
    end
    self:StopProfiling("OvaleFuture_UpdateLastSpellcast")
end
function OvaleFuture:UpdateSpellcastSnapshot(spellcast, atTime)
    if spellcast.queued and ( not spellcast.snapshotTime or (spellcast.snapshotTime < atTime and atTime < spellcast.stop + 1)) then
        if spellcast.targetName then
            self:Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued)
        else
            self:Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued)
        end
        OvalePaperDoll:UpdateSnapshot(spellcast, true)
        if spellcast.spellId then
            spellcast.damageMultiplier = OvaleFuture:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
            if spellcast.damageMultiplier ~= 1 then
                self:Debug("        persistent multiplier = %f", spellcast.damageMultiplier)
            end
        end
    end
end
OvaleFuture.statePrototype = {}
local statePrototype = OvaleFuture.statePrototype
statePrototype.inCombat = nil
statePrototype.combatStartTime = nil
statePrototype.currentTime = nil
statePrototype.currentSpellId = nil
statePrototype.startCast = nil
statePrototype.endCast = nil
statePrototype.nextCast = nil
statePrototype.lastCast = nil
statePrototype.channel = nil
statePrototype.lastSpellId = nil
statePrototype.lastGCDSpellId = nil
statePrototype.lastGCDSpellIds = {}
statePrototype.lastOffGCDSpellId = nil
statePrototype.counter = nil
local OvaleFuture = __class()
function OvaleFuture:InitializeState(state)
    state.lastCast = {}
    state.counter = {}
end
function OvaleFuture:ResetState(state)
    self:StartProfiling("OvaleFuture_ResetState")
    local now = API_GetTime()
    state.currentTime = now
    state:Log("Reset state with current time = %f", state.currentTime)
    state.inCombat = self.inCombat
    state.combatStartTime = self.combatStartTime or 0
    state.nextCast = now
    local reason = ""
    local start, duration = OvaleCooldown:GetGlobalCooldown(now)
    if start and start > 0 then
        local ending = start + duration
        if state.nextCast < ending then
            state.nextCast = ending
            reason = " (waiting for GCD)"
        end
    end
    local lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound
    for i = #self.queue, 1, -1 do
        local spellcast = self.queue[i]
        if spellcast.spellId and spellcast.start then
            state:Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop)
            if  not lastSpellcastFound then
                state.lastSpellId = spellcast.spellId
                if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                    state.currentSpellId = spellcast.spellId
                    state.startCast = spellcast.start
                    state.endCast = spellcast.stop
                    state.channel = spellcast.channel
                end
                lastSpellcastFound = true
            end
            if  not lastGCDSpellcastFound and  not spellcast.offgcd then
                state:PushGCDSpellId(spellcast.spellId)
                if spellcast.stop and state.nextCast < spellcast.stop then
                    state.nextCast = spellcast.stop
                    reason = " (waiting for spellcast)"
                end
                lastGCDSpellcastFound = true
            end
            if  not lastOffGCDSpellcastFound and spellcast.offgcd then
                state.lastOffGCDSpellId = spellcast.spellId
                lastOffGCDSpellcastFound = true
            end
        end
        if lastGCDSpellcastFound and lastOffGCDSpellcastFound and lastSpellcastFound then
            break
        end
    end
    if  not lastSpellcastFound then
        local spellcast = self.lastSpellcast
        if spellcast then
            state.lastSpellId = spellcast.spellId
            if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                state.currentSpellId = spellcast.spellId
                state.startCast = spellcast.start
                state.endCast = spellcast.stop
                state.channel = spellcast.channel
            end
        end
    end
    if  not lastGCDSpellcastFound then
        local spellcast = self.lastGCDSpellcast
        if spellcast then
            state.lastGCDSpellId = spellcast.spellId
            if spellcast.stop and state.nextCast < spellcast.stop then
                state.nextCast = spellcast.stop
                reason = " (waiting for spellcast)"
            end
        end
    end
    if  not lastOffGCDSpellcastFound then
        local spellcast = self.lastOffGCDSpellcast
        if spellcast then
            state.lastOffGCDSpellId = spellcast.spellId
        end
    end
    state:Log("    lastSpellId = %s, lastGCDSpellId = %s, lastOffGCDSpellId = %s", state.lastSpellId, state.lastGCDSpellId, state.lastOffGCDSpellId)
    state:Log("    nextCast = %f%s", state.nextCast, reason)
    _wipe(state.lastCast)
    for k, v in _pairs(self.counter) do
        state.counter[k] = v
    end
    self:StopProfiling("OvaleFuture_ResetState")
end
function OvaleFuture:CleanState(state)
    for k in _pairs(state.lastCast) do
        state.lastCast[k] = nil
    end
    for k in _pairs(state.counter) do
        state.counter[k] = nil
    end
end
function OvaleFuture:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
    self:StartProfiling("OvaleFuture_ApplySpellStartCast")
    if channel then
        state:UpdateCounters(spellId, startCast, targetGUID)
    end
    self:StopProfiling("OvaleFuture_ApplySpellStartCast")
end
function OvaleFuture:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
    self:StartProfiling("OvaleFuture_ApplySpellAfterCast")
    if  not channel then
        state:UpdateCounters(spellId, endCast, targetGUID)
    end
    self:StopProfiling("OvaleFuture_ApplySpellAfterCast")
end
statePrototype.GetCounter = function(state, id)
    return state.counter[id] or 0
end
statePrototype.GetCounterValue = statePrototype.GetCounter
statePrototype.TimeOfLastCast = function(state, spellId)
    return state.lastCast[spellId] or OvaleFuture.lastCastTime[spellId] or 0
end
statePrototype.IsChanneling = function(state, atTime)
    atTime = atTime or state.currentTime
    return state.channel and (atTime < state.endCast)
end
do
    local staticSpellcast = {}
    statePrototype.PushGCDSpellId = function(state, spellId)
        if state.lastGCDSpellId then
            tinsert(state.lastGCDSpellIds, state.lastGCDSpellId)
            if #state.lastGCDSpellIds > 5 then
                tremove(state.lastGCDSpellIds, 1)
            end
        end
        state.lastGCDSpellId = spellId
    end
    statePrototype.ApplySpell = function(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
        OvaleFuture:StartProfiling("OvaleFuture_state_ApplySpell")
        if spellId then
            if  not targetGUID then
                targetGUID = Ovale.playerGUID
            end
            local castTime
            if startCast and endCast then
                castTime = endCast - startCast
            else
                castTime = OvaleSpellBook:GetCastTime(spellId) or 0
                startCast = startCast or state.nextCast
                endCast = endCast or (startCast + castTime)
            end
            if  not spellcast then
                spellcast = staticSpellcast
                _wipe(spellcast)
                spellcast.caster = self_playerGUID
                spellcast.spellId = spellId
                spellcast.spellName = OvaleSpellBook:GetSpellName(spellId)
                spellcast.target = targetGUID
                spellcast.targetName = OvaleGUID:GUIDName(targetGUID)
                spellcast.start = startCast
                spellcast.stop = endCast
                spellcast.channel = channel
                state:UpdateSnapshot(spellcast)
                local atTime = channel and startCast or endCast
                for _, mod in _pairs(self_modules) do
                    local func = mod.SaveSpellcastInfo
                    if func then
                        func(mod, spellcast, atTime, state)
                    end
                end
            end
            state.lastSpellId = spellId
            state.startCast = startCast
            state.endCast = endCast
            state.lastCast[spellId] = endCast
            state.channel = channel
            local gcd = state:GetGCD(spellId, startCast, targetGUID)
            local nextCast = (castTime > gcd) and endCast or (startCast + gcd)
            if state.nextCast < nextCast then
                state.nextCast = nextCast
            end
            if gcd > 0 then
                state:PushGCDSpellId(spellId)
            else
                state.lastOffGCDSpellId = spellId
            end
            local now = API_GetTime()
            if startCast >= now then
                state.currentTime = startCast + SIMULATOR_LAG
            else
                state.currentTime = now
            end
            state:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, state.currentTime, nextCast, endCast, targetGUID)
            if  not state.inCombat and OvaleSpellBook:IsHarmfulSpell(spellId) then
                state.inCombat = true
                if channel then
                    state.combatStartTime = startCast
                else
                    state.combatStartTime = endCast
                end
            end
            if startCast > now then
                OvaleState:InvokeMethod("ApplySpellStartCast", state, spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            if endCast > now then
                OvaleState:InvokeMethod("ApplySpellAfterCast", state, spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            OvaleState:InvokeMethod("ApplySpellOnHit", state, spellId, targetGUID, startCast, endCast, channel, spellcast)
        end
        OvaleFuture:StopProfiling("OvaleFuture_state_ApplySpell")
    end
end
statePrototype.GetDamageMultiplier = OvaleFuture.GetDamageMultiplier
statePrototype.UpdateCounters = OvaleFuture.UpdateCounters
end))
