local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./SpellBook", { "./Localization", "./Debug", "./Profiler", "./Ovale", "./Requirement" }, function(__exports, __Localization, __Debug, __Profiler, __Ovale, __Requirement)
local _ipairs = ipairs
local _pairs = pairs
local strmatch = string.match
local tconcat = table.concat
local tinsert = table.insert
local _tonumber = tonumber
local _tostring = tostring
local tsort = table.sort
local _wipe = wipe
local _gsub = string.gsub
local API_GetActiveSpecGroup = GetActiveSpecGroup
local API_GetFlyoutInfo = GetFlyoutInfo
local API_GetFlyoutSlotInfo = GetFlyoutSlotInfo
local API_GetSpellBookItemInfo = GetSpellBookItemInfo
local API_GetSpellInfo = GetSpellInfo
local API_GetSpellCount = GetSpellCount
local API_GetSpellLink = GetSpellLink
local API_GetSpellTabInfo = GetSpellTabInfo
local API_GetSpellTexture = GetSpellTexture
local API_GetTalentInfo = GetTalentInfo
local API_HasPetSpells = HasPetSpells
local API_IsHarmfulSpell = IsHarmfulSpell
local API_IsHelpfulSpell = IsHelpfulSpell
local API_IsSpellInRange = IsSpellInRange
local API_IsUsableSpell = IsUsableSpell
local API_UnitIsFriend = UnitIsFriend
local _BOOKTYPE_PET = BOOKTYPE_PET
local _BOOKTYPE_SPELL = BOOKTYPE_SPELL
local _MAX_TALENT_TIERS = MAX_TALENT_TIERS
local _NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS
local MAX_NUM_TALENTS = _NUM_TALENT_COLUMNS * _MAX_TALENT_TIERS
local WARRIOR_INCERCEPT_SPELLID = 198304
local WARRIOR_HEROICTHROW_SPELLID = 57755
do
    local debugOptions = {
        spellbook = {
            name = __Localization.L["Spellbook"],
            type = "group",
            args = {
                spellbook = {
                    name = __Localization.L["Spellbook"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvaleSpellBook:DebugSpells()
                    end

                }
            }
        },
        talent = {
            name = __Localization.L["Talents"],
            type = "group",
            args = {
                talent = {
                    name = __Localization.L["Talents"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvaleSpellBook:DebugTalents()
                    end

                }
            }
        }
    }
    for k, v in _pairs(debugOptions) do
        __Debug.OvaleDebug.options.args[k] = v
    end
end
local ParseHyperlink = function(hyperlink)
    local color, linkType, linkData, text = strmatch(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d*):?%d?|?h?%[?([^%[%]]*)%]?|?h?|?r?")
    return color, linkType, linkData, text
end

local OutputTableValues = function(output, tbl)
    local array = {}
    for k, v in _pairs(tbl) do
        tinsert(array, _tostring(v) .. ": " .. _tostring(k))
    end
    tsort(array)
    for _, v in _ipairs(array) do
        output[#output + 1] = v
    end
end

local output = {}
local OvaleSpellBookBase = __Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(__Ovale.Ovale:NewModule("OvaleSpellBook", "AceEvent-3.0")))
local OvaleSpellBookClass = __class(OvaleSpellBookBase, {
    constructor = function(self)
        self.ready = false
        self.spell = {}
        self.spellbookId = {
            [_BOOKTYPE_PET] = {},
            [_BOOKTYPE_SPELL] = {}
        }
        self.isHarmful = {}
        self.isHelpful = {}
        self.texture = {}
        self.talent = {}
        self.talentPoints = {}
        OvaleSpellBookBase.constructor(self)
        self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Update")
        self:RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateTalents")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
        self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents")
        self:RegisterEvent("SPELLS_CHANGED", "UpdateSpells")
        self:RegisterEvent("UNIT_PET")
        __Requirement.RegisterRequirement("spellcount_min", "RequireSpellCountHandler", self)
        __Requirement.RegisterRequirement("spellcount_max", "RequireSpellCountHandler", self)
    end,
    OnDisable = function(self)
        __Requirement.UnregisterRequirement("spellcount_max")
        __Requirement.UnregisterRequirement("spellcount_min")
        self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_TALENT_UPDATE")
        self:UnregisterEvent("SPELLS_CHANGED")
        self:UnregisterEvent("UNIT_PET")
    end,
    UNIT_PET = function(self, unitId)
        if unitId == "player" then
            self:UpdateSpells()
        end
    end,
    Update = function(self)
        self:UpdateTalents()
        self:UpdateSpells()
        self.ready = true
    end,
    UpdateTalents = function(self)
        self:Debug("Updating talents.")
        _wipe(self.talent)
        _wipe(self.talentPoints)
        local activeTalentGroup = API_GetActiveSpecGroup()
        for i = 1, _MAX_TALENT_TIERS, 1 do
            for j = 1, _NUM_TALENT_COLUMNS, 1 do
                local talentId, name, _, selected, _, _, _, _, _, _, selectedByLegendary = API_GetTalentInfo(i, j, activeTalentGroup)
                if talentId then
                    local combinedSelected = selected or selectedByLegendary
                    local index = 3 * (i - 1) + j
                    if index <= MAX_NUM_TALENTS then
                        self.talent[index] = name
                        if combinedSelected then
                            self.talentPoints[index] = 1
                        else
                            self.talentPoints[index] = 0
                        end
                        self:Debug("    Talent %s (%d) is %s.", name, index, combinedSelected and "enabled" or "disabled")
                    end
                end
            end
        end
        __Ovale.Ovale:needRefresh()
        self:SendMessage("Ovale_TalentsChanged")
    end,
    UpdateSpells = function(self)
        _wipe(self.spell)
        _wipe(self.spellbookId[_BOOKTYPE_PET])
        _wipe(self.spellbookId[_BOOKTYPE_SPELL])
        _wipe(self.isHarmful)
        _wipe(self.isHelpful)
        _wipe(self.texture)
        for tab = 1, 2, 1 do
            local name, _, offset, numSpells = API_GetSpellTabInfo(tab)
            if name then
                self:ScanSpellBook(_BOOKTYPE_SPELL, numSpells, offset)
            end
        end
        local numPetSpells = API_HasPetSpells()
        if numPetSpells then
            self:ScanSpellBook(_BOOKTYPE_PET, numPetSpells)
        end
        __Ovale.Ovale:needRefresh()
        self:SendMessage("Ovale_SpellsChanged")
    end,
    ScanSpellBook = function(self, bookType, numSpells, offset)
        offset = offset or 0
        self:Debug("Updating '%s' spellbook starting at offset %d.", bookType, offset)
        for index = offset + 1, offset + numSpells, 1 do
            local skillType, spellId = API_GetSpellBookItemInfo(index, bookType)
            if skillType == "SPELL" or skillType == "PETACTION" then
                local spellLink = API_GetSpellLink(index, bookType)
                if spellLink then
                    local _, _, linkData, spellName = ParseHyperlink(spellLink)
                    local id = _tonumber(linkData)
                    self:Debug("    %s (%d) is at offset %d (%s).", spellName, id, index, _gsub(spellLink, "|", "_"))
                    self.spell[id] = spellName
                    self.isHarmful[id] = API_IsHarmfulSpell(index, bookType)
                    self.isHelpful[id] = API_IsHelpfulSpell(index, bookType)
                    self.texture[id] = API_GetSpellTexture(index, bookType)
                    self.spellbookId[bookType][id] = index
                    if spellId and id ~= spellId then
                        self:Debug("    %s (%d) is at offset %d.", spellName, spellId, index)
                        self.spell[spellId] = spellName
                        self.isHarmful[spellId] = self.isHarmful[id]
                        self.isHelpful[spellId] = self.isHelpful[id]
                        self.texture[spellId] = self.texture[id]
                        self.spellbookId[bookType][spellId] = index
                    end
                end
            elseif skillType == "FLYOUT" then
                local flyoutId = spellId
                local _, _, numSlots, isKnown = API_GetFlyoutInfo(flyoutId)
                if numSlots > 0 and isKnown then
                    for flyoutIndex = 1, numSlots, 1 do
                        local id, overrideId, isKnown, spellName = API_GetFlyoutSlotInfo(flyoutId, flyoutIndex)
                        if isKnown then
                            self:Debug("    %s (%d) is at offset %d.", spellName, id, index)
                            self.spell[id] = spellName
                            self.isHarmful[id] = API_IsHarmfulSpell(spellName)
                            self.isHelpful[id] = API_IsHelpfulSpell(spellName)
                            self.texture[id] = API_GetSpellTexture(index, bookType)
                            self.spellbookId[bookType][id] = nil
                            if id ~= overrideId then
                                self:Debug("    %s (%d) is at offset %d.", spellName, overrideId, index)
                                self.spell[overrideId] = spellName
                                self.isHarmful[overrideId] = self.isHarmful[id]
                                self.isHelpful[overrideId] = self.isHelpful[id]
                                self.texture[overrideId] = self.texture[id]
                                self.spellbookId[bookType][overrideId] = nil
                            end
                        end
                    end
                end
            elseif skillType == "FUTURESPELL" then
            elseif  not skillType then
                break
            end
        end
    end,
    GetCastTime = function(self, spellId)
        if spellId then
            local name, _, _, castTime = self:GetSpellInfo(spellId)
            if name then
                if castTime then
                    castTime = castTime / 1000
                else
                    castTime = 0
                end
            else
                castTime = nil
            end
            return castTime
        end
    end,
    GetSpellInfo = function(self, spellId)
        local index, bookType = self:GetSpellBookIndex(spellId)
        if index and bookType then
            return API_GetSpellInfo(index, bookType)
        else
            return API_GetSpellInfo(spellId)
        end
    end,
    GetSpellCount = function(self, spellId)
        local index, bookType = self:GetSpellBookIndex(spellId)
        if index and bookType then
            local spellCount = API_GetSpellCount(index, bookType)
            self:Debug("GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s", index, bookType, spellId, spellCount)
            return spellCount
        else
            local spellName = __exports.OvaleSpellBook:GetSpellName(spellId)
            local spellCount = API_GetSpellCount(spellName)
            self:Debug("GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s", spellName, spellId, spellCount)
            return spellCount
        end
    end,
    GetSpellName = function(self, spellId)
        if spellId then
            local spellName = self.spell[spellId]
            if  not spellName then
                spellName = self:GetSpellInfo(spellId)
            end
            return spellName
        end
    end,
    GetSpellTexture = function(self, spellId)
        return self.texture[spellId]
    end,
    GetTalentPoints = function(self, talentId)
        local points = 0
        if talentId and self.talentPoints[talentId] then
            points = self.talentPoints[talentId]
        end
        return points
    end,
    AddSpell = function(self, spellId, name)
        if spellId and name then
            self.spell[spellId] = name
        end
    end,
    IsHarmfulSpell = function(self, spellId)
        return (spellId and self.isHarmful[spellId]) and true or false
    end,
    IsHelpfulSpell = function(self, spellId)
        return (spellId and self.isHelpful[spellId]) and true or false
    end,
    IsKnownSpell = function(self, spellId)
        return (spellId and self.spell[spellId]) and true or false
    end,
    IsKnownTalent = function(self, talentId)
        return (talentId and self.talentPoints[talentId]) and true or false
    end,
    GetSpellBookIndex = function(self, spellId)
        local bookType = _BOOKTYPE_SPELL
        while true do
            local index = self.spellbookId[bookType][spellId]
            if index then
                return index, bookType
            elseif bookType == _BOOKTYPE_SPELL then
                bookType = _BOOKTYPE_PET
            else
                break
            end
        end
    end,
    IsPetSpell = function(self, spellId)
        local _, bookType = self:GetSpellBookIndex(spellId)
        return bookType == _BOOKTYPE_PET
    end,
    IsSpellInRange = function(self, spellId, unitId)
        local index, bookType = self:GetSpellBookIndex(spellId)
        local returnValue = nil
        if index and bookType then
            returnValue = API_IsSpellInRange(index, bookType, unitId)
        elseif self:IsKnownSpell(spellId) then
            local name = self:GetSpellName(spellId)
            returnValue = API_IsSpellInRange(name, unitId)
        end
        if (returnValue == 1 and spellId == WARRIOR_INCERCEPT_SPELLID) then
            return (API_UnitIsFriend("player", unitId) == 1 or __exports.OvaleSpellBook:IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId) == 1) and 1 or 0
        end
        return returnValue
    end,
    IsUsableSpell = function(self, spellId)
        local index, bookType = self:GetSpellBookIndex(spellId)
        if index and bookType then
            return API_IsUsableSpell(index, bookType)
        elseif self:IsKnownSpell(spellId) then
            local name = self:GetSpellName(spellId)
            return API_IsUsableSpell(name)
        end
    end,
    DebugSpells = function(self)
        _wipe(output)
        OutputTableValues(output, self.spell)
        local total = 0
        for _ in _pairs(self.spell) do
            total = total + 1
        end
        output[#output + 1] = "Total spells: " .. total
        return tconcat(output, "\n")
    end,
    DebugTalents = function(self)
        _wipe(output)
        OutputTableValues(output, self.talent)
        return tconcat(output, "\n")
    end,
    RequireSpellCountHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        local verified = false
        local count = tokens
        if index then
            count = tokens[index]
            index = index + 1
        end
        if count then
            count = _tonumber(count) or 1
            local actualCount = __exports.OvaleSpellBook:GetSpellCount(spellId)
            verified = (requirement == "spellcount_min" and count <= actualCount) or (requirement == "spellcount_max" and count >= actualCount)
        else
            __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' is missing a count argument.", requirement)
        end
        return verified, requirement, index
    end,
})
__exports.OvaleSpellBook = OvaleSpellBookClass()
end)
