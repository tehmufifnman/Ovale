local OVALE, Ovale = ...
require(OVALE, Ovale, "Totem", { "./OvaleProfiler" }, function(__exports, __OvaleProfiler)
local OvaleTotem = Ovale:NewModule("OvaleTotem", "AceEvent-3.0")
Ovale.OvaleTotem = OvaleTotem
local OvaleData = nil
local OvaleSpellBook = nil
local OvaleState = nil
local _ipairs = ipairs
local _pairs = pairs
local API_GetTotemInfo = GetTotemInfo
local _AIR_TOTEM_SLOT = AIR_TOTEM_SLOT
local _EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT
local _FIRE_TOTEM_SLOT = FIRE_TOTEM_SLOT
local INFINITY = math.huge
local _MAX_TOTEMS = MAX_TOTEMS
local _WATER_TOTEM_SLOT = WATER_TOTEM_SLOT
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleTotem)
local self_serial = 0
local TOTEM_CLASS = {
    DRUID = true,
    MAGE = true,
    MONK = true,
    SHAMAN = true
}
local TOTEM_SLOT = {
    air = _AIR_TOTEM_SLOT,
    earth = _EARTH_TOTEM_SLOT,
    fire = _FIRE_TOTEM_SLOT,
    water = _WATER_TOTEM_SLOT,
    spirit_wolf = 1
}
local TOTEMIC_RECALL = 36936
OvaleTotem.totem = {}
local OvaleTotem = __class()
function OvaleTotem:OnInitialize()
    OvaleData = Ovale.OvaleData
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleState = Ovale.OvaleState
end
function OvaleTotem:OnEnable()
    if TOTEM_CLASS[Ovale.playerClass] then
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
        self:RegisterEvent("PLAYER_TALENT_UPDATE", "Update")
        self:RegisterEvent("PLAYER_TOTEM_UPDATE", "Update")
        self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update")
        OvaleState:RegisterState(self, self.statePrototype)
    end
end
function OvaleTotem:OnDisable()
    if TOTEM_CLASS[Ovale.playerClass] then
        OvaleState:UnregisterState(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_TALENT_UPDATE")
        self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
    end
end
function OvaleTotem:Update()
    self_serial = self_serial + 1
    Ovale.refreshNeeded[Ovale.playerGUID] = true
end
OvaleTotem.statePrototype = {}
local statePrototype = OvaleTotem.statePrototype
statePrototype.totem = nil
local OvaleTotem = __class()
function OvaleTotem:InitializeState(state)
    state.totem = {}
    for slot = 1, _MAX_TOTEMS, 1 do
        state.totem[slot] = {}
    end
end
function OvaleTotem:CleanState(state)
    for slot, totem in _pairs(state.totem) do
        for k in _pairs(totem) do
            totem[k] = nil
        end
        state.totem[slot] = nil
    end
end
function OvaleTotem:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvaleTotem_ApplySpellAfterCast")
    if Ovale.playerClass == "SHAMAN" and spellId == TOTEMIC_RECALL then
        for slot in _ipairs(state.totem) do
            state:DestroyTotem(slot, endCast)
        end
    else
        local atTime = endCast
        local slot = state:GetTotemSlot(spellId, atTime)
        if slot then
            state:SummonTotem(spellId, slot, atTime)
        end
    end
    self:StopProfiling("OvaleTotem_ApplySpellAfterCast")
end
statePrototype.IsActiveTotem = function(state, totem, atTime)
    atTime = atTime or state.currentTime
    local boolean = false
    if totem and (totem.serial == self_serial) and totem.start and totem.duration and totem.start < atTime and atTime < totem.start + totem.duration then
        boolean = true
    end
    return boolean
end
statePrototype.GetTotem = function(state, slot)
    OvaleTotem:StartProfiling("OvaleTotem_state_GetTotem")
    slot = TOTEM_SLOT[slot] or slot
    local totem = state.totem[slot]
    if totem and ( not totem.serial or totem.serial < self_serial) then
        local haveTotem, name, startTime, duration, icon = API_GetTotemInfo(slot)
        if haveTotem then
            totem.name = name
            totem.start = startTime
            totem.duration = duration
            totem.icon = icon
        else
            totem.name = ""
            totem.start = 0
            totem.duration = 0
            totem.icon = ""
        end
        totem.serial = self_serial
    end
    OvaleTotem:StopProfiling("OvaleTotem_state_GetTotem")
    return totem
end
statePrototype.GetTotemInfo = function(state, slot)
    local haveTotem, name, startTime, duration, icon
    slot = TOTEM_SLOT[slot] or slot
    local totem = state:GetTotem(slot)
    if totem then
        haveTotem = state:IsActiveTotem(totem)
        name = totem.name
        startTime = totem.start
        duration = totem.duration
        icon = totem.icon
    end
    return haveTotem, name, startTime, duration, icon
end
statePrototype.GetTotemCount = function(state, spellId, atTime)
    atTime = atTime or state.currentTime
    local start, ending
    local count = 0
    local si = OvaleData.spellInfo[spellId]
    if si and si.totem then
        local buffPresent = true
        if si.buff_totem then
            local aura = state:GetAura("player", si.buff_totem)
            buffPresent = state:IsActiveAura(aura, atTime)
        end
        if buffPresent then
            local texture = OvaleSpellBook:GetSpellTexture(spellId)
            local maxTotems = si.max_totems or 1
            for slot in _ipairs(state.totem) do
                local totem = state:GetTotem(slot)
                if state:IsActiveTotem(totem, atTime) and totem.icon == texture then
                    count = count + 1
                    if  not start or start > totem.start then
                        start = totem.start
                    end
                    if  not ending or ending < totem.start + totem.duration then
                        ending = totem.start + totem.duration
                    end
                end
                if count >= maxTotems then
                    break
                end
            end
        end
    end
    return count, start, ending
end
statePrototype.GetTotemSlot = function(state, spellId, atTime)
    OvaleTotem:StartProfiling("OvaleTotem_state_GetTotemSlot")
    atTime = atTime or state.currentTime
    local totemSlot
    local si = OvaleData.spellInfo[spellId]
    if si and si.totem then
        totemSlot = TOTEM_SLOT[si.totem]
        if  not totemSlot then
            local availableSlot
            for slot in _ipairs(state.totem) do
                local totem = state:GetTotem(slot)
                if  not state:IsActiveTotem(totem, atTime) then
                    availableSlot = slot
                    break
                end
            end
            local texture = OvaleSpellBook:GetSpellTexture(spellId)
            local maxTotems = si.max_totems or 1
            local count = 0
            local start = INFINITY
            for slot in _ipairs(state.totem) do
                local totem = state:GetTotem(slot)
                if state:IsActiveTotem(totem, atTime) and totem.icon == texture then
                    count = count + 1
                    if start > totem.start then
                        start = totem.start
                        totemSlot = slot
                    end
                end
            end
            if count < maxTotems then
                totemSlot = availableSlot
            end
        end
        totemSlot = totemSlot or 1
    end
    OvaleTotem:StopProfiling("OvaleTotem_state_GetTotemSlot")
    return totemSlot
end
statePrototype.SummonTotem = function(state, spellId, slot, atTime)
    OvaleTotem:StartProfiling("OvaleTotem_state_SummonTotem")
    atTime = atTime or state.currentTime
    slot = TOTEM_SLOT[slot] or slot
    state:Log("Spell %d summons totem into slot %d.", spellId, slot)
    local name, _, icon = OvaleSpellBook:GetSpellInfo(spellId)
    local duration = state:GetSpellInfoProperty(spellId, atTime, "duration")
    local totem = state.totem[slot]
    totem.name = name
    totem.start = atTime
    totem.duration = duration or 15
    totem.icon = icon
    OvaleTotem:StopProfiling("OvaleTotem_state_SummonTotem")
end
statePrototype.DestroyTotem = function(state, slot, atTime)
    OvaleTotem:StartProfiling("OvaleTotem_state_DestroyTotem")
    atTime = atTime or state.currentTime
    slot = TOTEM_SLOT[slot] or slot
    state:Log("Destroying totem in slot %d.", slot)
    local totem = state.totem[slot]
    local duration = atTime - totem.start
    if duration < 0 then
        duration = 0
    end
    totem.duration = duration
    OvaleTotem:StopProfiling("OvaleTotem_state_DestroyTotem")
end
end))
