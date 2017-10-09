local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Stance", { "./Localization", "./Debug", "./Profiler", "./Ovale", "./Requirement" }, function(__exports, __Localization, __Debug, __Profiler, __Ovale, __Requirement)
local OvaleStanceBase = __Ovale.Ovale:NewModule("OvaleStance", "AceEvent-3.0")
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
local druidCatForm = API_GetSpellInfo(768)
local druidTravelForm = API_GetSpellInfo(783)
local druidAquaticForm = API_GetSpellInfo(1066)
local druidBearForm = API_GetSpellInfo(5487)
local druidMoonkinForm = API_GetSpellInfo(24858)
local druid_flight_form = API_GetSpellInfo(33943)
local druid_swift_flight_form = API_GetSpellInfo(40120)
local rogue_stealth = API_GetSpellInfo(1784)
local SPELL_NAME_TO_STANCE = {
    [druidCatForm] = "druid_cat_form",
    [druidTravelForm] = "druid_travel_form",
    [druidAquaticForm] = "druid_aquatic_form",
    [druidBearForm] = "druid_bear_form",
    [druidMoonkinForm] = "druid_moonkin_form",
    [druid_flight_form] = "druid_flight_form",
    [druid_swift_flight_form] = "druid_swift_flight_form",
    [rogue_stealth] = "rogue_stealth"
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
            name = __Localization.L["Stances"],
            type = "group",
            args = {
                stance = {
                    name = __Localization.L["Stances"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvaleStance:DebugStances()
                    end

                }
            }
        }
    }
    for k, v in _pairs(debugOptions) do
        __Debug.OvaleDebug.options.args[k] = v
    end
end
local array = {}
local OvaleStanceClass = __class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleStanceBase)), {
    constructor = function(self)
        self.ready = false
        self.stanceList = {}
        self.stanceId = {}
        self.stance = nil
        self.STANCE_NAME = STANCE_NAME
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleStanceBase)).constructor(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances")
        self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
        self:RegisterMessage("Ovale_SpellsChanged", "UpdateStances")
        self:RegisterMessage("Ovale_TalentsChanged", "UpdateStances")
        __Requirement.RegisterRequirement("stance", "RequireStanceHandler", self)
    end,
    OnDisable = function(self)
        __Requirement.UnregisterRequirement("stance")
        self:UnregisterEvent("PLAYER_ALIVE")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
        self:UnregisterMessage("Ovale_SpellsChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    PLAYER_TALENT_UPDATE = function(self, event)
        self.stance = nil
        self:UpdateStances()
    end,
    UPDATE_SHAPESHIFT_FORM = function(self, event)
        self:ShapeshiftEventHandler()
    end,
    UPDATE_SHAPESHIFT_FORMS = function(self, event)
        self:ShapeshiftEventHandler()
    end,
    CreateStanceList = function(self)
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
    end,
    DebugStances = function(self)
        _wipe(array)
        for k, v in _pairs(self.stanceList) do
            if self.stance == k then
                tinsert(array, v .. " (active)")
            else
                tinsert(array, v)
            end
        end
        tsort(array)
        return tconcat(array, "\n")
    end,
    GetStance = function(self, stanceId)
        stanceId = stanceId or self.stance
        return self.stanceList[stanceId]
    end,
    IsStance = function(self, name)
        if name and self.stance then
            if _type(name) == "number" then
                return name == self.stance
            else
                return name == __exports.OvaleStance:GetStance(self.stance)
            end
        end
        return false
    end,
    IsStanceSpell = function(self, spellId)
        local name = API_GetSpellInfo(spellId)
        return  not  not (name and SPELL_NAME_TO_STANCE[name])
    end,
    ShapeshiftEventHandler = function(self)
        self:StartProfiling("OvaleStance_ShapeshiftEventHandler")
        local oldStance = self.stance
        local newStance = API_GetShapeshiftForm()
        if oldStance ~= newStance then
            self.stance = newStance
            __Ovale.Ovale:needRefresh()
            self:SendMessage("Ovale_StanceChanged", self:GetStance(newStance), self:GetStance(oldStance))
        end
        self:StopProfiling("OvaleStance_ShapeshiftEventHandler")
    end,
    UpdateStances = function(self)
        self:CreateStanceList()
        self:ShapeshiftEventHandler()
        self.ready = true
    end,
    RequireStanceHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
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
            __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement)
        end
        return verified, requirement, index
    end,
})
__exports.OvaleStance = OvaleStanceClass()
end)
