local OVALE, Ovale = ...
require(OVALE, Ovale, "DemonHunterSigils", { "./OvaleProfiler" }, function(__exports, __OvaleProfiler)
local OvaleSigil = Ovale:NewModule("OvaleSigil", "AceEvent-3.0")
Ovale.OvaleSigil = OvaleSigil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleState = nil
local _ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime
local UPDATE_DELAY = 0.5
local SIGIL_ACTIVATION_TIME = math.huge
local activated_sigils = {}
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleSigil)
local OvaleSigil = __class()
function OvaleSigil:OnInitialize()
    OvalePaperDoll = Ovale.OvalePaperDoll
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleState = Ovale.OvaleState
    activated_sigils["flame"] = {}
    activated_sigils["silence"] = {}
    activated_sigils["misery"] = {}
    activated_sigils["chains"] = {}
end
function OvaleSigil:OnEnable()
    if Ovale.playerClass == "DEMONHUNTER" then
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        OvaleState:RegisterState(self, self.statePrototype)
    end
end
function OvaleSigil:OnDisable()
    if Ovale.playerClass == "DEMONHUNTER" then
        OvaleState:UnregisterState(self)
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
end
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
local OvaleSigil = __class()
function OvaleSigil:UNIT_SPELLCAST_SUCCEEDED(event, unitId, spellName, spellRank, guid, spellId, ...)
    if ( not OvalePaperDoll:IsSpecialization("vengeance")) then
        break
    end
    if (unitId == nil or unitId ~= "player") then
        break
    end
    local id = tonumber(spellId)
    if (sigil_start[id] ~= nil) then
        local s = sigil_start[id]
        local t = s.type
        local tal = s.talent or nil
        if (tal == nil or OvaleSpellBook:GetTalentPoints(tal) > 0) then
            tinsert(activated_sigils[t], API_GetTime())
        end
    end
    if (sigil_end[id] ~= nil) then
        local s = sigil_end[id]
        local t = s.type
        tremove(activated_sigils[t], 1)
    end
end
OvaleSigil.statePrototype = {}
local statePrototype = OvaleSigil.statePrototype
statePrototype.IsSigilCharging = function(state, type, atTime)
    atTime = atTime or state.currentTime
    if (#activated_sigils[type] == 0) then
        return false
    end
    local charging = false
    for _, v in _ipairs(activated_sigils[type]) do
        local activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY
        if (OvaleSpellBook:GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0) then
            activation_time = activation_time - 1
        end
        charging = charging or atTime < v + activation_time
    end
    return charging
end
end))
