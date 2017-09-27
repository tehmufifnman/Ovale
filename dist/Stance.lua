local OVALE, Ovale = ...
require(OVALE, Ovale, "Stance", { "./L", "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __L, __OvaleDebug, __OvaleProfiler)
local OvaleStance = Ovale:NewModule("OvaleStance", "AceEvent-3.0")
Ovale.OvaleStance = OvaleStance
local OvaleData = nil
local OvaleState = nil
local _ipairs = ipairs
local _pairs = pairs
local substr = string.sub
local tconcat = table.concat
local tinsert = table.insert
local _tonumber = tonumber
local tsort = table.sort
local _type = type
local _wipe = wipe
local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetShapeshiftForm = GetShapeshiftForm
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo
local API_GetSpellInfo = GetSpellInfo
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleStance)
local SPELL_NAME_TO_STANCE = {
    [API_GetSpellInfo(768)] = "druid_cat_form",
    [API_GetSpellInfo(783)] = "druid_travel_form",
    [API_GetSpellInfo(1066)] = "druid_aquatic_form",
    [API_GetSpellInfo(5487)] = "druid_bear_form",
    [API_GetSpellInfo(24858)] = "druid_moonkin_form",
    [API_GetSpellInfo(33943)] = "druid_flight_form",
    [API_GetSpellInfo(40120)] = "druid_swift_flight_form",
    [API_GetSpellInfo(1784)] = "rogue_stealth"
}
local STANCE_NAME = {}
do
    for _, name in _pairs(SPELL_NAME_TO_STANCE) do
        STANCE_NAME[name] = true
    end
end
do
    local debugOptions = {
        stance = {
            name = __L.L["Stances"],
            type = "group",
            args = {
                stance = {
                    name = __L.L["Stances"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return OvaleStance:DebugStances()
                    end
                }
            }
        }
    }
    for k, v in _pairs(debugOptions) do
        __OvaleDebug.OvaleDebug.options.args[k] = v
    end
end
OvaleStance.ready = false
OvaleStance.stanceList = {}
OvaleStance.stanceId = {}
OvaleStance.stance = nil
OvaleStance.STANCE_NAME = STANCE_NAME
local OvaleStance = __class()
function OvaleStance:OnInitialize()
    OvaleData = Ovale.OvaleData
    OvaleState = Ovale.OvaleState
end
function OvaleStance:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    self:RegisterMessage("Ovale_SpellsChanged", "UpdateStances")
    self:RegisterMessage("Ovale_TalentsChanged", "UpdateStances")
    OvaleData:RegisterRequirement("stance", "RequireStanceHandler", self)
    OvaleState:RegisterState(self, self.statePrototype)
end
function OvaleStance:OnDisable()
    OvaleState:UnregisterState(self)
    OvaleData:UnregisterRequirement("stance")
    self:UnregisterEvent("PLAYER_ALIVE")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
    self:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
    self:UnregisterMessage("Ovale_SpellsChanged")
    self:UnregisterMessage("Ovale_TalentsChanged")
end
function OvaleStance:PLAYER_TALENT_UPDATE(event)
    self.stance = nil
    self:UpdateStances()
end
function OvaleStance:UPDATE_SHAPESHIFT_FORM(event)
    self:ShapeshiftEventHandler()
end
function OvaleStance:UPDATE_SHAPESHIFT_FORMS(event)
    self:ShapeshiftEventHandler()
end
function OvaleStance:CreateStanceList()
    self:StartProfiling("OvaleStance_CreateStanceList")
    _wipe(self.stanceList)
    _wipe(self.stanceId)
    local _, name, stanceName
    for i = 1, API_GetNumShapeshiftForms(), 1 do
        _, name = API_GetShapeshiftFormInfo(i)
        stanceName = SPELL_NAME_TO_STANCE[name]
        if stanceName then
            self.stanceList[i] = stanceName
            self.stanceId[stanceName] = i
        end
    end
    self:StopProfiling("OvaleStance_CreateStanceList")
end
do
    local array = {}
local OvaleStance = __class()
    function OvaleStance:DebugStances()
        _wipe(array)
        for k, v in _pairs(self.stanceList) do
            if self.stance == k then
                tinsert(array, v + " (active)")
            else
                tinsert(array, v)
            end
        end
        tsort(array)
        return tconcat(array, "\n")
    end
end
local OvaleStance = __class()
function OvaleStance:GetStance(stanceId)
    stanceId = stanceId or self.stance
    return self.stanceList[stanceId]
end
function OvaleStance:IsStance(name)
    if name and self.stance then
        if _type(name) == "number" then
            return name == self.stance
        else
            return name == OvaleStance:GetStance(self.stance)
        end
    end
    return false
end
function OvaleStance:IsStanceSpell(spellId)
    local name = API_GetSpellInfo(spellId)
    return  not  not (name and SPELL_NAME_TO_STANCE[name])
end
function OvaleStance:ShapeshiftEventHandler()
    self:StartProfiling("OvaleStance_ShapeshiftEventHandler")
    local oldStance = self.stance
    local newStance = API_GetShapeshiftForm()
    if oldStance ~= newStance then
        self.stance = newStance
        Ovale.refreshNeeded[Ovale.playerGUID] = true
        self:SendMessage("Ovale_StanceChanged", self:GetStance(newStance), self:GetStance(oldStance))
    end
    self:StopProfiling("OvaleStance_ShapeshiftEventHandler")
end
function OvaleStance:UpdateStances()
    self:CreateStanceList()
    self:ShapeshiftEventHandler()
    self.ready = true
end
function OvaleStance:RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    local verified = false
    local stance = tokens
    if index then
        stance = tokens[index]
        index = index + 1
    end
    if stance then
        local isBang = false
        if substr(stance, 1, 1) == "!" then
            isBang = true
            stance = substr(stance, 2)
        end
        stance = _tonumber(stance) or stance
        local isStance = self:IsStance(stance)
        if  not isBang and isStance or isBang and  not isStance then
            verified = true
        end
        local result = verified and "passed" or "FAILED"
        if isBang then
            self:Log("    Require NOT stance '%s': %s", stance, result)
        else
            self:Log("    Require stance '%s': %s", stance, result)
        end
    else
        Ovale:OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement)
    end
    return verified, requirement, index
end
OvaleStance.statePrototype = {}
local statePrototype = OvaleStance.statePrototype
statePrototype.stance = nil
local OvaleStance = __class()
function OvaleStance:InitializeState(state)
    state.stance = nil
end
function OvaleStance:ResetState(state)
    self:StartProfiling("OvaleStance_ResetState")
    state.stance = self.stance or 0
    self:StopProfiling("OvaleStance_ResetState")
end
function OvaleStance:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvaleStance_ApplySpellAfterCast")
    local stance = state:GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID)
    if stance then
        if _type(stance) == "string" then
            stance = self.stanceId[stance]
        end
        state.stance = stance
    end
    self:StopProfiling("OvaleStance_ApplySpellAfterCast")
end
statePrototype.IsStance = OvaleStance.IsStance
statePrototype.RequireStanceHandler = OvaleStance.RequireStanceHandler
end))
