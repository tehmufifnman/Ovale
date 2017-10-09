local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./SpellBookState", { "./State", "./SpellBook", "./Data", "./DataState", "./Power", "./CooldownState", "./Runes" }, function(__exports, __State, __SpellBook, __Data, __DataState, __Power, __CooldownState, __Runes)
local _type = type
local API_IsUsableItem = IsUsableItem
local SpellBookState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    IsUsableItem = function(self, itemId, atTime)
        __SpellBook.OvaleSpellBook:StartProfiling("OvaleSpellBook_state_IsUsableItem")
        local isUsable = API_IsUsableItem(itemId)
        local ii = __Data.OvaleData:ItemInfo(itemId)
        if ii then
            if isUsable then
                local unusable = __DataState.dataState:GetItemInfoProperty(itemId, atTime, "unusable")
                if unusable and unusable > 0 then
                    __SpellBook.OvaleSpellBook:Log("Item ID '%s' is flagged as unusable.", itemId)
                    isUsable = false
                end
            end
        end
        __SpellBook.OvaleSpellBook:StopProfiling("OvaleSpellBook_state_IsUsableItem")
        return isUsable
    end,
    IsUsableSpell = function(self, spellId, atTime, targetGUID)
        __SpellBook.OvaleSpellBook:StartProfiling("OvaleSpellBook_state_IsUsableSpell")
        if _type(atTime) == "string" and  not targetGUID then
            atTime, targetGUID = nil, atTime
        end
        atTime = atTime or __State.baseState.currentTime
        local isUsable = __SpellBook.OvaleSpellBook:IsKnownSpell(spellId)
        local noMana = false
        local si = __Data.OvaleData.spellInfo[spellId]
        if si then
            if isUsable then
                local unusable = __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID)
                if unusable and unusable > 0 then
                    __SpellBook.OvaleSpellBook:Log("Spell ID '%s' is flagged as unusable.", spellId)
                    isUsable = false
                end
            end
            if isUsable then
                local requirement
                isUsable, requirement = __DataState.dataState:CheckSpellInfo(spellId, atTime, targetGUID)
                if  not isUsable then
                    if __Power.OvalePower.PRIMARY_POWER[requirement] then
                        noMana = true
                    end
                    if noMana then
                        __SpellBook.OvaleSpellBook:Log("Spell ID '%s' does not have enough %s.", spellId, requirement)
                    else
                        __SpellBook.OvaleSpellBook:Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement)
                    end
                end
            end
        else
            isUsable, noMana = __SpellBook.OvaleSpellBook:IsUsableSpell(spellId)
        end
        __SpellBook.OvaleSpellBook:StopProfiling("OvaleSpellBook_state_IsUsableSpell")
        return isUsable, noMana
    end,
    GetTimeToSpell = function(self, spellId, atTime, targetGUID, extraPower)
        if _type(atTime) == "string" and  not targetGUID then
            atTime, targetGUID = nil, atTime
        end
        atTime = atTime or __State.baseState.currentTime
        local timeToSpell = 0
        do
            local start, duration = __CooldownState.cooldownState:GetSpellCooldown(spellId)
            local seconds = (duration > 0) and (start + duration - atTime) or 0
            if timeToSpell < seconds then
                timeToSpell = seconds
            end
        end
        do
            local seconds = __Power.powerState:TimeToPower(spellId, atTime, targetGUID, nil, extraPower)
            if timeToSpell < seconds then
                timeToSpell = seconds
            end
        end
        do
            local runes = __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "runes", targetGUID)
            if runes then
                local seconds = __Runes.runesState:GetRunesCooldown(atTime, runes)
                if timeToSpell < seconds then
                    timeToSpell = seconds
                end
            end
        end
        return timeToSpell
    end,
    RequireSpellCountHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        return __SpellBook.OvaleSpellBook:RequireSpellCountHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    end,
})
__exports.spellBookState = SpellBookState()
__State.OvaleState:RegisterState(__exports.spellBookState)
end)
