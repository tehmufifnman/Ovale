local OVALE, Ovale = ...
require(OVALE, Ovale, "Runes", { "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __OvaleDebug, __OvaleProfiler)
local OvaleRunes = Ovale:NewModule("OvaleRunes", "AceEvent-3.0")
Ovale.OvaleRunes = OvaleRunes
local OvaleData = nil
local OvaleEquipment = nil
local OvalePower = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local OvaleState = nil
local _ipairs = ipairs
local _pairs = pairs
local _type = type
local _wipe = wipe
local API_GetRuneCooldown = GetRuneCooldown
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local INFINITY = math.huge
local _sort = sort
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleRunes)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleRunes)
local EMPOWER_RUNE_WEAPON = 47568
local RUNE_SLOTS = 6
OvaleRunes.rune = {}
local IsActiveRune = function(rune, atTime)
    return (rune.startCooldown == 0 or rune.endCooldown <= atTime)
end
local OvaleRunes = __class()
function OvaleRunes:OnInitialize()
    OvaleData = Ovale.OvaleData
    OvaleEquipment = Ovale.OvaleEquipment
    OvalePower = Ovale.OvalePower
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleStance = Ovale.OvaleStance
    OvaleState = Ovale.OvaleState
end
function OvaleRunes:OnEnable()
    if Ovale.playerClass == "DEATHKNIGHT" then
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
        OvaleState:RegisterState(self, self.statePrototype)
        self:UpdateAllRunes()
    end
end
function OvaleRunes:OnDisable()
    if Ovale.playerClass == "DEATHKNIGHT" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("RUNE_POWER_UPDATE")
        self:UnregisterEvent("RUNE_TYPE_UPDATE")
        self:UnregisterEvent("UNIT_RANGEDDAMAGE")
        self:UnregisterEvent("UNIT_SPELL_HASTE")
        OvaleState:UnregisterState(self)
        self.rune = {}
    end
end
function OvaleRunes:RUNE_POWER_UPDATE(event, slot, usable)
    self:Debug(event, slot, usable)
    self:UpdateRune(slot)
end
function OvaleRunes:RUNE_TYPE_UPDATE(event, slot)
    self:Debug(event, slot)
    self:UpdateRune(slot)
end
function OvaleRunes:UNIT_RANGEDDAMAGE(event, unitId)
    if unitId == "player" then
        self:Debug(event)
        self:UpdateAllRunes()
    end
end
function OvaleRunes:UpdateRune(slot)
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
        Ovale.refreshNeeded[Ovale.playerGUID] = true
    else
        self:Debug("Warning: rune information for slot %d not available.", slot)
    end
    self:StopProfiling("OvaleRunes_UpdateRune")
end
function OvaleRunes:UpdateAllRunes(event)
    self:Debug(event)
    for slot = 1, RUNE_SLOTS, 1 do
        self:UpdateRune(slot)
    end
end
function OvaleRunes:DebugRunes()
    local now = API_GetTime()
    for slot = 1, RUNE_SLOTS, 1 do
        local rune = self.rune[slot]
        if rune:IsActiveRune(now) then
            self:Print("rune[%d] is active.", slot)
        else
            self:Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
        end
    end
end
OvaleRunes.statePrototype = {}
local statePrototype = OvaleRunes.statePrototype
statePrototype.rune = nil
local OvaleRunes = __class()
function OvaleRunes:InitializeState(state)
    state.rune = {}
    for slot in _ipairs(self.rune) do
        state.rune[slot] = {}
    end
end
function OvaleRunes:ResetState(state)
    self:StartProfiling("OvaleRunes_ResetState")
    for slot, rune in _ipairs(self.rune) do
        local stateRune = state.rune[slot]
        for k, v in _pairs(rune) do
            stateRune[k] = v
        end
    end
    self:StopProfiling("OvaleRunes_ResetState")
end
function OvaleRunes:CleanState(state)
    for slot, rune in _ipairs(state.rune) do
        for k in _pairs(rune) do
            rune[k] = nil
        end
        state.rune[slot] = nil
    end
end
function OvaleRunes:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvaleRunes_ApplySpellStartCast")
    if isChanneled then
        state:ApplyRuneCost(spellId, startCast, spellcast)
    end
    self:StopProfiling("OvaleRunes_ApplySpellStartCast")
end
function OvaleRunes:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvaleRunes_ApplySpellAfterCast")
    if  not isChanneled then
        state:ApplyRuneCost(spellId, endCast, spellcast)
        if spellId == EMPOWER_RUNE_WEAPON then
            for slot in _ipairs(state.rune) do
                state:ReactivateRune(slot, endCast)
            end
        end
    end
    self:StopProfiling("OvaleRunes_ApplySpellAfterCast")
end
statePrototype.DebugRunes = function(state)
    OvaleRunes:Print("Current rune state:")
    local now = state.currentTime
    for slot, rune in _ipairs(state.rune) do
        if rune:IsActiveRune(now) then
            OvaleRunes:Print("    rune[%d] is active.", slot)
        else
            OvaleRunes:Print("    rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
        end
    end
end
statePrototype.ApplyRuneCost = function(state, spellId, atTime, spellcast)
    local si = OvaleData.spellInfo[spellId]
    if si then
        local count = si.runes or 0
        while count > 0do
            state:ConsumeRune(spellId, atTime, spellcast)
            count = count - 1
end
    end
end
statePrototype.ReactivateRune = function(state, slot, atTime)
    local rune = state.rune[slot]
    if atTime < state.currentTime then
        atTime = state.currentTime
    end
    if rune.startCooldown > atTime then
        rune.startCooldown = atTime
    end
    rune.endCooldown = atTime
end
statePrototype.ConsumeRune = function(state, spellId, atTime, snapshot)
    OvaleRunes:StartProfiling("OvaleRunes_state_ConsumeRune")
    local consumedRune
    for slot = 1, RUNE_SLOTS, 1 do
        local rune = state.rune[slot]
        if rune:IsActiveRune(atTime) then
            consumedRune = rune
            break
        end
    end
    if consumedRune then
        local start = atTime
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = state.rune[slot]
            if rune.endCooldown > start then
                start = rune.endCooldown
            end
        end
        local duration = 10 / state:GetSpellHasteMultiplier(snapshot)
        consumedRune.startCooldown = start
        consumedRune.endCooldown = start + duration
        local runicpower = state.runicpower
        runicpower = runicpower + 10
        local maxi = OvalePower.maxPower.runicpower
        state.runicpower = (runicpower < maxi) and runicpower or maxi
    else
        state:Log("No %s rune available at %f to consume for spell %d!", RUNE_NAME[runeType], atTime, spellId)
    end
    OvaleRunes:StopProfiling("OvaleRunes_state_ConsumeRune")
end
statePrototype.RuneCount = function(state, atTime)
    OvaleRunes:StartProfiling("OvaleRunes_state_RuneCount")
    atTime = atTime or state.currentTime
    local count = 0
    local startCooldown, endCooldown = INFINITY, INFINITY
    for slot = 1, RUNE_SLOTS, 1 do
        local rune = state.rune[slot]
        if rune:IsActiveRune(atTime) then
            count = count + 1
        elseif rune.endCooldown < endCooldown then
            startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
        end
    end
    OvaleRunes:StopProfiling("OvaleRunes_state_RuneCount")
    return count, startCooldown, endCooldown
end
statePrototype.GetRunesCooldown = nil
do
    local count = {}
    local usedRune = {}
    statePrototype.GetRunesCooldown = function(state, atTime, runes)
        if runes <= 0 then
            return 0
        end
        if runes > RUNE_SLOTS then
            state:Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS)
            return 0
        end
        OvaleRunes:StartProfiling("OvaleRunes_state_GetRunesCooldown")
        atTime = atTime or state.currentTime
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = state.rune[slot]
            usedRune[slot] = rune.endCooldown - atTime
        end
        _sort(usedRune)
        OvaleRunes:StopProfiling("OvaleRunes_state_GetRunesCooldown")
        return usedRune[runes]
    end
end
end))
