local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Runes", { "./Debug", "./Profiler", "./Ovale", "./Data", "./Equipment", "./Power", "./Stance", "./State", "./PaperDoll" }, function(__exports, __Debug, __Profiler, __Ovale, __Data, __Equipment, __Power, __Stance, __State, __PaperDoll)
local OvaleRunesBase = __Ovale.Ovale:NewModule("OvaleRunes", "AceEvent-3.0")
local _ipairs = ipairs
local _pairs = pairs
local _type = type
local _wipe = wipe
local API_GetRuneCooldown = GetRuneCooldown
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local INFINITY = math.huge
local _sort = table.sort
local EMPOWER_RUNE_WEAPON = 47568
local RUNE_SLOTS = 6
local IsActiveRune = function(rune, atTime)
    return (rune.startCooldown == 0 or rune.endCooldown <= atTime)
end

local OvaleRunesClass = __class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleRunesBase)), {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        if __Ovale.Ovale.playerClass == "DEATHKNIGHT" then
            for slot = 1, RUNE_SLOTS, 1 do
                self.rune[slot] = {
                    slot = slot,
                    IsActiveRune = IsActiveRune
                }
            end
            self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllRunes")
            self:RegisterEvent("RUNE_POWER_UPDATE")
            self:RegisterEvent("RUNE_TYPE_UPDATE")
            self:RegisterEvent("UNIT_RANGEDDAMAGE")
            self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
            self:UpdateAllRunes()
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "DEATHKNIGHT" then
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:UnregisterEvent("RUNE_POWER_UPDATE")
            self:UnregisterEvent("RUNE_TYPE_UPDATE")
            self:UnregisterEvent("UNIT_RANGEDDAMAGE")
            self:UnregisterEvent("UNIT_SPELL_HASTE")
            self.rune = {}
        end
    end,
    RUNE_POWER_UPDATE = function(self, event, slot, usable)
        self:Debug(event, slot, usable)
        self:UpdateRune(slot)
    end,
    RUNE_TYPE_UPDATE = function(self, event, slot)
        self:Debug(event, slot)
        self:UpdateRune(slot)
    end,
    UNIT_RANGEDDAMAGE = function(self, event, unitId)
        if unitId == "player" then
            self:Debug(event)
            self:UpdateAllRunes()
        end
    end,
    UpdateRune = function(self, slot)
        self:StartProfiling("OvaleRunes_UpdateRune")
        local rune = self.rune[slot]
        local start, duration, runeReady = API_GetRuneCooldown(slot)
        if start and duration then
            if start > 0 then
                rune.startCooldown = start
                rune.endCooldown = start + duration
            else
                rune.startCooldown = 0
                rune.endCooldown = 0
            end
            __Ovale.Ovale.refreshNeeded[__Ovale.Ovale.playerGUID] = true
        else
            self:Debug("Warning: rune information for slot %d not available.", slot)
        end
        self:StopProfiling("OvaleRunes_UpdateRune")
    end,
    UpdateAllRunes = function(self)
        for slot = 1, RUNE_SLOTS, 1 do
            self:UpdateRune(slot)
        end
    end,
    DebugRunes = function(self)
        local now = API_GetTime()
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.rune[slot]
            if rune:IsActiveRune(now) then
                self:Print("rune[%d] is active.", slot)
            else
                self:Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
            end
        end
    end,
})
local count = {}
local usedRune = {}
local RunesState = __class(nil, {
    InitializeState = function(self)
        self.rune = {}
        for slot in _ipairs(self.rune) do
            self.rune[slot] = {}
        end
    end,
    ResetState = function(self)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_ResetState")
        for slot, rune in _ipairs(self.rune) do
            local stateRune = self.rune[slot]
            for k, v in _pairs(rune) do
                stateRune[k] = v
            end
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_ResetState")
    end,
    CleanState = function(self)
        for slot, rune in _ipairs(self.rune) do
            for k in _pairs(rune) do
                rune[k] = nil
            end
            self.rune[slot] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_ApplySpellStartCast")
        if isChanneled then
            self:ApplyRuneCost(spellId, startCast, spellcast)
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyRuneCost(spellId, endCast, spellcast)
            if spellId == EMPOWER_RUNE_WEAPON then
                for slot in _ipairs(self.rune) do
                    self:ReactivateRune(slot, endCast)
                end
            end
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_ApplySpellAfterCast")
    end,
    DebugRunes = function(self)
        __exports.OvaleRunes:Print("Current rune state:")
        local now = __State.baseState.currentTime
        for slot, rune in _ipairs(self.rune) do
            if IsActiveRune(rune, now) then
                __exports.OvaleRunes:Print("    rune[%d] is active.", slot)
            else
                __exports.OvaleRunes:Print("    rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
            end
        end
    end,
    ApplyRuneCost = function(self, spellId, atTime, spellcast)
        local si = __Data.OvaleData.spellInfo[spellId]
        if si then
            local count = si.runes or 0
            while count > 0 do
                self:ConsumeRune(spellId, atTime, spellcast)
                count = count - 1
            end
        end
    end,
    ReactivateRune = function(self, slot, atTime)
        local rune = self.rune[slot]
        if atTime < __State.baseState.currentTime then
            atTime = __State.baseState.currentTime
        end
        if rune.startCooldown > atTime then
            rune.startCooldown = atTime
        end
        rune.endCooldown = atTime
    end,
    ConsumeRune = function(self, spellId, atTime, snapshot)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_state_ConsumeRune")
        local consumedRune
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.rune[slot]
            if IsActiveRune(rune, atTime) then
                consumedRune = rune
                break
            end
        end
        if consumedRune then
            local start = atTime
            for slot = 1, RUNE_SLOTS, 1 do
                local rune = self.rune[slot]
                if rune.endCooldown > start then
                    start = rune.endCooldown
                end
            end
            local duration = 10 / __PaperDoll.paperDollState:GetSpellHasteMultiplier(snapshot)
            consumedRune.startCooldown = start
            consumedRune.endCooldown = start + duration
            local runicpower = self.runicpower
            runicpower = runicpower + 10
            local maxi = __Power.OvalePower.maxPower.runicpower
            self.runicpower = (runicpower < maxi) and runicpower or maxi
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_state_ConsumeRune")
    end,
    RuneCount = function(self, atTime)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_state_RuneCount")
        atTime = atTime or __State.baseState.currentTime
        local count = 0
        local startCooldown, endCooldown = INFINITY, INFINITY
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.rune[slot]
            if IsActiveRune(rune, atTime) then
                count = count + 1
            elseif rune.endCooldown < endCooldown then
                startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
            end
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_state_RuneCount")
        return count, startCooldown, endCooldown
    end,
    GetRunesCooldown = function(self, atTime, runes)
        if runes <= 0 then
            return 0
        end
        if runes > RUNE_SLOTS then
            __exports.OvaleRunes:Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS)
            return 0
        end
        __exports.OvaleRunes:StartProfiling("OvaleRunes_state_GetRunesCooldown")
        atTime = atTime or __State.baseState.currentTime
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.rune[slot]
            usedRune[slot] = rune.endCooldown - atTime
        end
        _sort(usedRune)
        __exports.OvaleRunes:StopProfiling("OvaleRunes_state_GetRunesCooldown")
        return usedRune[runes]
    end,
})
__exports.runesState = RunesState()
__State.OvaleState:RegisterState(__exports.runesState)
__exports.OvaleRunes = OvaleRunesClass()
end)
