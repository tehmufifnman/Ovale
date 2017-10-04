local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./SteadyFocus", { "./Debug", "./Profiler", "./Ovale", "./Aura", "./SpellBook", "./State" }, function(__exports, __Debug, __Profiler, __Ovale, __Aura, __SpellBook, __State)
local OvaleSteadyFocusBase = __Ovale.Ovale:NewModule("OvaleSteadyFocus", "AceEvent-3.0")
local API_GetTime = GetTime
local INFINITY = math.huge
local self_playerGUID = nil
local PRE_STEADY_FOCUS = 177667
local STEADY_FOCUS_TALENT = 10
local STEADY_FOCUS = 177668
local STEADY_FOCUS_DURATION = 15
local STEADY_SHOT = {
    [56641] = "Steady Shot",
    [77767] = "Cobra Shot",
    [163485] = "Focusing Shot"
}
local RANGED_ATTACKS = {
    [2643] = "Multi-Shot",
    [3044] = "Arcane Shot",
    [19434] = "Aimed Shot",
    [19801] = "Tranquilizing Shot",
    [53209] = "Chimaera Shot",
    [53351] = "Kill Shot",
    [109259] = "Powershot",
    [117050] = "Glaive Toss",
    [120360] = "Barrage",
    [120361] = "Barrage",
    [120761] = "Glaive Toss",
    [121414] = "Glaive Toss"
}
local OvaleSteadyFocusClass = __class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleSteadyFocusBase)), {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        if __Ovale.Ovale.playerClass == "HUNTER" then
            self_playerGUID = __Ovale.Ovale.playerGUID
            self:RegisterMessage("Ovale_TalentsChanged")
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "HUNTER" then
            self:UnregisterMessage("Ovale_TalentsChanged")
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" then
            self:StartProfiling("OvaleSteadyFocus_UNIT_SPELLCAST_SUCCEEDED")
            if STEADY_SHOT[spellId] then
                self:DebugTimestamp("Spell %s (%d) successfully cast.", spell, spellId)
                if self.stacks == 0 then
                    local now = API_GetTime()
                    self:GainedAura(now)
                end
            elseif RANGED_ATTACKS[spellId] and self.stacks > 0 then
                local now = API_GetTime()
                self:DebugTimestamp("Spell %s (%d) successfully cast.", spell, spellId)
                self:LostAura(now)
            end
            self:StopProfiling("OvaleSteadyFocus_UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    Ovale_AuraAdded = function(self, event, timestamp, target, auraId, caster)
        if self.stacks > 0 and auraId == STEADY_FOCUS and target == self_playerGUID then
            self:DebugTimestamp("Gained Steady Focus buff.")
            self:LostAura(timestamp)
        end
    end,
    Ovale_TalentsChanged = function(self, event)
        self.hasSteadyFocus = (__SpellBook.OvaleSpellBook:GetTalentPoints(STEADY_FOCUS_TALENT) > 0)
        if self.hasSteadyFocus then
            self:Debug("Registering event handlers to track Steady Focus.")
            self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:RegisterMessage("Ovale_AuraAdded")
            self:RegisterMessage("Ovale_AuraChanged", "Ovale_AuraAdded")
        else
            self:Debug("Unregistering event handlers to track Steady Focus.")
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:UnregisterMessage("Ovale_AuraAdded")
            self:UnregisterMessage("Ovale_AuraChanged")
        end
    end,
    GainedAura = function(self, atTime)
        self:StartProfiling("OvaleSteadyFocus_GainedAura")
        self.start = atTime
        self.ending = self.start + self.duration
        self.stacks = self.stacks + 1
        self:Debug("Gaining %s buff at %s.", self.spellName, atTime)
        __Aura.OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
        self:StopProfiling("OvaleSteadyFocus_GainedAura")
    end,
    LostAura = function(self, atTime)
        self:StartProfiling("OvaleSteadyFocus_LostAura")
        self.ending = atTime
        self.stacks = 0
        self:Debug("Losing %s buff at %s.", self.spellName, atTime)
        __Aura.OvaleAura:LostAuraOnGUID(self_playerGUID, atTime, self.spellId, self_playerGUID)
        self:StopProfiling("OvaleSteadyFocus_LostAura")
    end,
    DebugSteadyFocus = function(self)
        local aura = __Aura.OvaleAura:GetAuraByGUID(self_playerGUID, self.spellId, "HELPFUL", true)
        if aura then
            self:Print("Player has pre-Steady Focus aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
        else
            self:Print("Player has no pre-Steady Focus aura!")
        end
    end,
})
local SteadyFocusState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        if __exports.OvaleSteadyFocus.hasSteadyFocus then
            __exports.OvaleSteadyFocus:StartProfiling("OvaleSteadyFocus_ApplySpellAfterCast")
            if STEADY_SHOT[spellId] then
                local aura = __Aura.auraState:GetAuraByGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, "HELPFUL", true)
                if __Aura.auraState:IsActiveAura(aura, endCast) then
                    __Aura.auraState:RemoveAuraOnGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, "HELPFUL", true, endCast)
                    aura = __Aura.auraState:GetAuraByGUID(self_playerGUID, STEADY_FOCUS, "HELPFUL", true)
                    if  not aura then
                        aura = __Aura.auraState:AddAuraToGUID(self_playerGUID, STEADY_FOCUS, self_playerGUID, "HELPFUL", nil, endCast, nil, spellcast)
                    end
                    aura.start = endCast
                    aura.duration = STEADY_FOCUS_DURATION
                    aura.ending = endCast + STEADY_FOCUS_DURATION
                    aura.gain = endCast
                else
                    local ending = endCast + __exports.OvaleSteadyFocus.duration
                    aura = __Aura.auraState:AddAuraToGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, self_playerGUID, "HELPFUL", nil, endCast, ending, spellcast)
                    aura.name = __exports.OvaleSteadyFocus.spellName
                end
            elseif RANGED_ATTACKS[spellId] then
                __Aura.auraState:RemoveAuraOnGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, "HELPFUL", true, endCast)
            end
            __exports.OvaleSteadyFocus:StopProfiling("OvaleSteadyFocus_ApplySpellAfterCast")
        end
    end,
})
__exports.steadyFocusState = SteadyFocusState()
__State.OvaleState:RegisterState(__exports.steadyFocusState)
__exports.OvaleSteadyFocus = OvaleSteadyFocusClass()
end)
