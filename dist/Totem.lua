local __addonName, __addon = ...
            __addon.require("./Totem", { "./Profiler", "./Ovale", "./Data", "./SpellBook", "./State", "./Aura", "./DataState", "AceEvent-3.0" }, function(__exports, __Profiler, __Ovale, __Data, __SpellBook, __State, __Aura, __DataState, aceEvent)
local OvaleTotemBase = __Ovale.Ovale:NewModule("OvaleTotem", aceEvent)
local _ipairs = ipairs
local _pairs = pairs
local API_GetTotemInfo = GetTotemInfo
local _AIR_TOTEM_SLOT = AIR_TOTEM_SLOT
local _EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT
local _FIRE_TOTEM_SLOT = FIRE_TOTEM_SLOT
local INFINITY = math.huge
local _MAX_TOTEMS = MAX_TOTEMS
local _WATER_TOTEM_SLOT = WATER_TOTEM_SLOT
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
local OvaleTotemClass = __addon.__class(__Profiler.OvaleProfiler:RegisterProfiling(OvaleTotemBase), {
    constructor = function(self)
        self.totem = {}
        __Profiler.OvaleProfiler:RegisterProfiling(OvaleTotemBase).constructor(self)
        if TOTEM_CLASS[__Ovale.Ovale.playerClass] then
            self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
            self:RegisterEvent("PLAYER_TALENT_UPDATE", "Update")
            self:RegisterEvent("PLAYER_TOTEM_UPDATE", "Update")
            self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update")
        end
    end,
    OnDisable = function(self)
        if TOTEM_CLASS[__Ovale.Ovale.playerClass] then
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:UnregisterEvent("PLAYER_TALENT_UPDATE")
            self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
            self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        end
    end,
    Update = function(self)
        self_serial = self_serial + 1
        __Ovale.Ovale:needRefresh()
    end,
})
local TotemState = __addon.__class(nil, {
    InitializeState = function(self)
        self.totem = {}
        for slot = 1, _MAX_TOTEMS, 1 do
            self.totem[slot] = {}
        end
    end,
    ResetState = function(self)
    end,
    CleanState = function(self)
        for slot, totem in _pairs(self.totem) do
            for k in _pairs(totem) do
                totem[k] = nil
            end
            self.totem[slot] = nil
        end
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_ApplySpellAfterCast")
        if __Ovale.Ovale.playerClass == "SHAMAN" and spellId == TOTEMIC_RECALL then
            for slot in _ipairs(self.totem) do
                self:DestroyTotem(slot, endCast)
            end
        else
            local atTime = endCast
            local slot = self:GetTotemSlot(spellId, atTime)
            if slot then
                self:SummonTotem(spellId, slot, atTime)
            end
        end
        __exports.OvaleTotem:StopProfiling("OvaleTotem_ApplySpellAfterCast")
    end,
    IsActiveTotem = function(self, totem, atTime)
        atTime = atTime or __State.baseState.currentTime
        local boolean = false
        if totem and (totem.serial == self_serial) and totem.start and totem.duration and totem.start < atTime and atTime < totem.start + totem.duration then
            boolean = true
        end
        return boolean
    end,
    GetTotem = function(self, slot)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_GetTotem")
        slot = TOTEM_SLOT[slot] or slot
        local totem = self.totem[slot]
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
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_GetTotem")
        return totem
    end,
    GetTotemInfo = function(self, slot)
        local haveTotem, name, startTime, duration, icon
        slot = TOTEM_SLOT[slot] or slot
        local totem = self:GetTotem(slot)
        if totem then
            haveTotem = self:IsActiveTotem(totem)
            name = totem.name
            startTime = totem.start
            duration = totem.duration
            icon = totem.icon
        end
        return haveTotem, name, startTime, duration, icon
    end,
    GetTotemCount = function(self, spellId, atTime)
        atTime = atTime or __State.baseState.currentTime
        local start, ending
        local count = 0
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.totem then
            local buffPresent = true
            if si.buff_totem then
                local aura = __Aura.auraState:GetAura("player", si.buff_totem)
                buffPresent = __Aura.auraState:IsActiveAura(aura, atTime)
            end
            if buffPresent then
                local texture = __SpellBook.OvaleSpellBook:GetSpellTexture(spellId)
                local maxTotems = si.max_totems or 1
                for slot in _ipairs(self.totem) do
                    local totem = self:GetTotem(slot)
                    if self:IsActiveTotem(totem, atTime) and totem.icon == texture then
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
    end,
    GetTotemSlot = function(self, spellId, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_GetTotemSlot")
        atTime = atTime or __State.baseState.currentTime
        local totemSlot
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.totem then
            totemSlot = TOTEM_SLOT[si.totem]
            if  not totemSlot then
                local availableSlot
                for slot in _ipairs(self.totem) do
                    local totem = self:GetTotem(slot)
                    if  not self:IsActiveTotem(totem, atTime) then
                        availableSlot = slot
                        break
                    end
                end
                local texture = __SpellBook.OvaleSpellBook:GetSpellTexture(spellId)
                local maxTotems = si.max_totems or 1
                local count = 0
                local start = INFINITY
                for slot in _ipairs(self.totem) do
                    local totem = self:GetTotem(slot)
                    if self:IsActiveTotem(totem, atTime) and totem.icon == texture then
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
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_GetTotemSlot")
        return totemSlot
    end,
    SummonTotem = function(self, spellId, slot, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_SummonTotem")
        atTime = atTime or __State.baseState.currentTime
        slot = TOTEM_SLOT[slot] or slot
        local name, _, icon = __SpellBook.OvaleSpellBook:GetSpellInfo(spellId)
        local duration = __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "duration")
        local totem = self.totem[slot]
        totem.name = name
        totem.start = atTime
        totem.duration = duration or 15
        totem.icon = icon
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_SummonTotem")
    end,
    DestroyTotem = function(self, slot, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_DestroyTotem")
        atTime = atTime or __State.baseState.currentTime
        slot = TOTEM_SLOT[slot] or slot
        local totem = self.totem[slot]
        local duration = atTime - totem.start
        if duration < 0 then
            duration = 0
        end
        totem.duration = duration
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_DestroyTotem")
    end,
    constructor = function(self)
        self.totem = nil
    end
})
__exports.totemState = TotemState()
__State.OvaleState:RegisterState(__exports.totemState)
__exports.OvaleTotem = OvaleTotemClass()
end)
