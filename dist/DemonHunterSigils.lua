local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./DemonHunterSigils", { "./Profiler", "./Ovale", "./PaperDoll", "./SpellBook", "./State" }, function(__exports, __Profiler, __Ovale, __PaperDoll, __SpellBook, __State)
local OvaleSigilBase = __Ovale.Ovale:NewModule("OvaleSigil", "AceEvent-3.0")
local _ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime
local UPDATE_DELAY = 0.5
local SIGIL_ACTIVATION_TIME = math.huge
local activated_sigils = {}
local sigil_start = {
    [204596] = {
        type = "flame"
    },
    [189110] = {
        type = "flame",
        talent = 8
    },
    [202137] = {
        type = "silence"
    },
    [207684] = {
        type = "misery"
    },
    [202138] = {
        type = "chains"
    }
}
local sigil_end = {
    [204598] = {
        type = "flame"
    },
    [204490] = {
        type = "silence"
    },
    [207685] = {
        type = "misery"
    },
    [204834] = {
        type = "chains"
    }
}
local QUICKENED_SIGILS_TALENT = 15
local OvaleSigilClass = __class(__Profiler.OvaleProfiler:RegisterProfiling(OvaleSigilBase), {
    OnInitialize = function(self)
        activated_sigils["flame"] = {}
        activated_sigils["silence"] = {}
        activated_sigils["misery"] = {}
        activated_sigils["chains"] = {}
    end,
    OnEnable = function(self)
        if __Ovale.Ovale.playerClass == "DEMONHUNTER" then
            self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "DEMONHUNTER" then
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spellName, spellRank, guid, spellId, ...)
        if ( not __PaperDoll.OvalePaperDoll:IsSpecialization("vengeance")) then
            return 
        end
        if (unitId == nil or unitId ~= "player") then
            return 
        end
        local id = tonumber(spellId)
        if (sigil_start[id] ~= nil) then
            local s = sigil_start[id]
            local t = s.type
            local tal = s.talent or nil
            if (tal == nil or __SpellBook.OvaleSpellBook:GetTalentPoints(tal) > 0) then
                tinsert(activated_sigils[t], API_GetTime())
            end
        end
        if (sigil_end[id] ~= nil) then
            local s = sigil_end[id]
            local t = s.type
            tremove(activated_sigils[t], 1)
        end
    end,
})
local SigilState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    IsSigilCharging = function(self, type, atTime)
        atTime = atTime or __State.baseState.currentTime
        if (#activated_sigils[type] == 0) then
            return false
        end
        local charging = false
        for _, v in _ipairs(activated_sigils[type]) do
            local activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY
            if (__SpellBook.OvaleSpellBook:GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0) then
                activation_time = activation_time - 1
            end
            charging = charging or atTime < v + activation_time
        end
        return charging
    end,
})
__exports.OvaleSigil = OvaleSigilClass()
__exports.sigilState = SigilState()
__State.OvaleState:RegisterState(__exports.sigilState)
end)
