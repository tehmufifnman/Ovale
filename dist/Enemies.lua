local __addonName, __addon = ...
            __addon.require("./Enemies", { "./Debug", "./Profiler", "./Ovale", "./GUID", "./State" }, function(__exports, __Debug, __Profiler, __Ovale, __GUID, __State)
local OvaleEnemiesBase = __Ovale.Ovale:NewModule("OvaleEnemies", "AceEvent-3.0", "AceTimer-3.0")
local bit_band = bit.band
local bit_bor = bit.bor
local _ipairs = ipairs
local _pairs = pairs
local strfind = string.find
local _wipe = wipe
local API_GetTime = GetTime
local _COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local _COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
local _COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
local _COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local GROUP_MEMBER = bit_bor(_COMBATLOG_OBJECT_AFFILIATION_MINE, _COMBATLOG_OBJECT_AFFILIATION_PARTY, _COMBATLOG_OBJECT_AFFILIATION_RAID)
local CLEU_TAG_SUFFIXES = {
    [1] = "_DAMAGE",
    [2] = "_MISSED",
    [3] = "_AURA_APPLIED",
    [4] = "_AURA_APPLIED_DOSE",
    [5] = "_AURA_REFRESH",
    [6] = "_CAST_START",
    [7] = "_INTERRUPT",
    [8] = "_DISPEL",
    [9] = "_DISPEL_FAILED",
    [10] = "_STOLEN",
    [11] = "_DRAIN",
    [12] = "_LEECH"
}
local CLEU_AUTOATTACK = {
    RANGED_DAMAGE = true,
    RANGED_MISSED = true,
    SWING_DAMAGE = true,
    SWING_MISSED = true
}
local CLEU_UNIT_REMOVED = {
    UNIT_DESTROYED = true,
    UNIT_DIED = true,
    UNIT_DISSIPATES = true
}
local self_enemyName = {}
local self_enemyLastSeen = {}
local self_taggedEnemyLastSeen = {}
local self_reaperTimer = nil
local REAP_INTERVAL = 3
local IsTagEvent = function(cleuEvent)
    local isTagEvent = false
    if CLEU_AUTOATTACK[cleuEvent] then
        isTagEvent = true
    else
        for _, suffix in _ipairs(CLEU_TAG_SUFFIXES) do
            if strfind(cleuEvent, suffix .. "$") then
                isTagEvent = true
                break
            end
        end
    end
    return isTagEvent
end

local IsFriendly = function(unitFlags, isGroupMember)
    return bit_band(unitFlags, _COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 and ( not isGroupMember or bit_band(unitFlags, GROUP_MEMBER) > 0)
end

local OvaleEnemiesClass = __addon.__class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleEnemiesBase)), {
    constructor = function(self)
        self.activeEnemies = 0
        self.taggedEnemies = 0
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleEnemiesBase)).constructor(self)
        if  not self_reaperTimer then
            self_reaperTimer = self:ScheduleRepeatingTimer("RemoveInactiveEnemies", REAP_INTERVAL)
        end
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
    end,
    OnDisable = function(self)
        if  not self_reaperTimer then
            self:CancelTimer(self_reaperTimer)
            self_reaperTimer = nil
        end
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        if CLEU_UNIT_REMOVED[cleuEvent] then
            local now = API_GetTime()
            self:RemoveEnemy(cleuEvent, destGUID, now, true)
        elseif sourceGUID and sourceGUID ~= "" and sourceName and sourceFlags and destGUID and destGUID ~= "" and destName and destFlags then
            if  not IsFriendly(sourceFlags) and IsFriendly(destFlags, true) then
                if  not (cleuEvent == "SPELL_PERIODIC_DAMAGE" and IsTagEvent(cleuEvent)) then
                    local now = API_GetTime()
                    self:AddEnemy(cleuEvent, sourceGUID, sourceName, now)
                end
            elseif IsFriendly(sourceFlags, true) and  not IsFriendly(destFlags) and IsTagEvent(cleuEvent) then
                local now = API_GetTime()
                local isPlayerTag = (sourceGUID == __Ovale.Ovale.playerGUID) or __GUID.OvaleGUID:IsPlayerPet(sourceGUID)
                self:AddEnemy(cleuEvent, destGUID, destName, now, isPlayerTag)
            end
        end
    end,
    PLAYER_REGEN_DISABLED = function(self)
        _wipe(self_enemyName)
        _wipe(self_enemyLastSeen)
        _wipe(self_taggedEnemyLastSeen)
        self.activeEnemies = 0
        self.taggedEnemies = 0
    end,
    RemoveInactiveEnemies = function(self)
        self:StartProfiling("OvaleEnemies_RemoveInactiveEnemies")
        local now = API_GetTime()
        for guid, timestamp in _pairs(self_enemyLastSeen) do
            if now - timestamp > REAP_INTERVAL then
                self:RemoveEnemy("REAPED", guid, now)
            end
        end
        for guid, timestamp in _pairs(self_taggedEnemyLastSeen) do
            if now - timestamp > REAP_INTERVAL then
                self:RemoveTaggedEnemy("REAPED", guid, now)
            end
        end
        self:StopProfiling("OvaleEnemies_RemoveInactiveEnemies")
    end,
    AddEnemy = function(self, cleuEvent, guid, name, timestamp, isTagged)
        self:StartProfiling("OvaleEnemies_AddEnemy")
        if guid then
            self_enemyName[guid] = name
            local changed = false
            do
                if  not self_enemyLastSeen[guid] then
                    self.activeEnemies = self.activeEnemies + 1
                    changed = true
                end
                self_enemyLastSeen[guid] = timestamp
            end
            if isTagged then
                if  not self_taggedEnemyLastSeen[guid] then
                    self.taggedEnemies = self.taggedEnemies + 1
                    changed = true
                end
                self_taggedEnemyLastSeen[guid] = timestamp
            end
            if changed then
                self:DebugTimestamp("%s: %d/%d enemy seen: %s (%s)", cleuEvent, self.taggedEnemies, self.activeEnemies, guid, name)
                __Ovale.Ovale:needRefresh()
            end
        end
        self:StopProfiling("OvaleEnemies_AddEnemy")
    end,
    RemoveEnemy = function(self, cleuEvent, guid, timestamp, isDead)
        self:StartProfiling("OvaleEnemies_RemoveEnemy")
        if guid then
            local name = self_enemyName[guid]
            local changed = false
            if self_enemyLastSeen[guid] then
                self_enemyLastSeen[guid] = nil
                if self.activeEnemies > 0 then
                    self.activeEnemies = self.activeEnemies - 1
                    changed = true
                end
            end
            if self_taggedEnemyLastSeen[guid] then
                self_taggedEnemyLastSeen[guid] = nil
                if self.taggedEnemies > 0 then
                    self.taggedEnemies = self.taggedEnemies - 1
                    changed = true
                end
            end
            if changed then
                self:DebugTimestamp("%s: %d/%d enemy %s: %s (%s)", cleuEvent, self.taggedEnemies, self.activeEnemies, isDead and "died" or "removed", guid, name)
                __Ovale.Ovale:needRefresh()
                self:SendMessage("Ovale_InactiveUnit", guid, isDead)
            end
        end
        self:StopProfiling("OvaleEnemies_RemoveEnemy")
    end,
    RemoveTaggedEnemy = function(self, cleuEvent, guid, timestamp)
        self:StartProfiling("OvaleEnemies_RemoveTaggedEnemy")
        if guid then
            local name = self_enemyName[guid]
            local tagged = self_taggedEnemyLastSeen[guid]
            if tagged then
                self_taggedEnemyLastSeen[guid] = nil
                if self.taggedEnemies > 0 then
                    self.taggedEnemies = self.taggedEnemies - 1
                end
                self:DebugTimestamp("%s: %d/%d enemy removed: %s (%s), last tagged at %f", cleuEvent, self.taggedEnemies, self.activeEnemies, guid, name, tagged)
                __Ovale.Ovale:needRefresh()
            end
        end
        self:StopProfiling("OvaleEnemies_RemoveEnemy")
    end,
    DebugEnemies = function(self)
        for guid, seen in _pairs(self_enemyLastSeen) do
            local name = self_enemyName[guid]
            local tagged = self_taggedEnemyLastSeen[guid]
            if tagged then
                self:Print("Tagged enemy %s (%s) last seen at %f", guid, name, tagged)
            else
                self:Print("Enemy %s (%s) last seen at %f", guid, name, seen)
            end
        end
        self:Print("Total enemies: %d", self.activeEnemies)
        self:Print("Total tagged enemies: %d", self.taggedEnemies)
    end,
})
local EnemiesStateClass = __addon.__class(nil, {
    InitializeState = function(self)
        self.enemies = nil
    end,
    ResetState = function(self)
        __exports.OvaleEnemies:StartProfiling("OvaleEnemies_ResetState")
        self.activeEnemies = __exports.OvaleEnemies.activeEnemies
        self.taggedEnemies = __exports.OvaleEnemies.taggedEnemies
        __exports.OvaleEnemies:StopProfiling("OvaleEnemies_ResetState")
    end,
    CleanState = function(self)
        self.activeEnemies = nil
        self.taggedEnemies = nil
        self.enemies = nil
    end,
    constructor = function(self)
        self.activeEnemies = nil
        self.taggedEnemies = nil
        self.enemies = nil
    end
})
__exports.OvaleEnemies = OvaleEnemiesClass()
__exports.EnemiesState = EnemiesStateClass()
__State.OvaleState:RegisterState(__exports.EnemiesState)
end)
