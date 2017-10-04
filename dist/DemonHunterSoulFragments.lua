local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./DemonHunterSoulFragments", { "./Ovale", "./Debug", "./State" }, function(__exports, __Ovale, __Debug, __State)
local OvaleDemonHunterSoulFragmentsBase = __Ovale.Ovale:NewModule("OvaleDemonHunterSoulFragments", "AceEvent-3.0")
local _ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime
local API_GetSpellCount = GetSpellCount
local SOUL_FRAGMENTS_BUFF_ID = 228477
local SOUL_FRAGMENTS_SPELL_HEAL_ID = 203794
local SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID = 204255
local SOUL_FRAGMENT_FINISHERS = {
    [228477] = true,
    [247454] = true,
    [227225] = true
}
local OvaleDemonHunterSoulFragmentsClass = __class(__Debug.OvaleDebug:RegisterDebugging(OvaleDemonHunterSoulFragmentsBase), {
    OnInitialize = function(self)
        self:SetCurrentSoulFragments(0)
    end,
    OnEnable = function(self)
        if __Ovale.Ovale.playerClass == "DEMONHUNTER" then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("PLAYER_REGEN_DISABLED")
        end
    end,
    OnDisable = function(self)
        if __Ovale.Ovale.playerClass == "DEMONHUNTER" then
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self:UnregisterEvent("PLAYER_REGEN_DISABLED")
        end
    end,
    PLAYER_REGEN_ENABLED = function(self)
        self:SetCurrentSoulFragments()
    end,
    PLAYER_REGEN_DISABLED = function(self)
        self.soul_fragments = {}
        self.last_checked = nil
        self:SetCurrentSoulFragments()
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, _2, subtype, _4, sourceGUID, _6, _7, _8, _9, _10, _11, _12, spellID, spellName)
        local me = __Ovale.Ovale.playerGUID
        if sourceGUID == me then
            local current_sould_fragment_count = self.last_soul_fragment_count
            if subtype == "SPELL_HEAL" and spellID == SOUL_FRAGMENTS_SPELL_HEAL_ID then
                self:SetCurrentSoulFragments(self.last_soul_fragment_count.fragments - 1)
            end
            if subtype == "SPELL_CAST_SUCCESS" and spellID == SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID then
                self:SetCurrentSoulFragments(self.last_soul_fragment_count.fragments + 1)
            end
            if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_FINISHERS[spellID] then
                self:SetCurrentSoulFragments(0)
            end
            local now = API_GetTime()
            if self.last_checked == nil or now - self.last_checked >= 1.5 then
                self:SetCurrentSoulFragments()
            end
        end
    end,
    SetCurrentSoulFragments = function(self, count)
        local now = API_GetTime()
        self.last_checked = now
        self.soul_fragments = self.soul_fragments or {}
        if type(count) ~= "number" then
            count = API_GetSpellCount(SOUL_FRAGMENTS_BUFF_ID) or 0
        end
        if count < 0 then
            count = 0
        end
        if self.last_soul_fragment_count == nil or self.last_soul_fragment_count.fragments ~= count then
            local entry = {
                timestamp = now,
                fragments = count
            }
            self:Debug("Setting current soul fragment count to '%d' (at: %s)", entry.fragments, entry.timestamp)
            self.last_soul_fragment_count = entry
            tinsert(self.soul_fragments, entry)
        end
    end,
    DebugSoulFragments = function(self)
    end,
})
local spairs = function(t, order)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    if order then
        table:sort(keys, function(a, b)
            return order(t, a, b)
        end
)
    else
        table:sort(keys)
    end
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end

end

local DemonHunterSoulFragmentsState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    SoulFragments = function(self, atTime)
        local currentTime = nil
        local count = nil
        for k, v in pairs(__exports.OvaleDemonHunterSoulFragments.soul_fragments) do
            if v.timestamp >= atTime and (currentTime == nil or v.timestamp < currentTime) then
                currentTime = v.timestamp
                count = v.fragments
            end
        end
        if count then
            return count
        end
        return (__exports.OvaleDemonHunterSoulFragments.last_soul_fragment_count ~= nil and __exports.OvaleDemonHunterSoulFragments.last_soul_fragment_count.fragments) or 0
    end,
})
__exports.demonHunterSoulFragmentsState = DemonHunterSoulFragmentsState()
__State.OvaleState:RegisterState(__exports.demonHunterSoulFragmentsState)
end)
