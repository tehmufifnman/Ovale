local __addonName, __addon = ...
__addon.require(__addonName, __addon, "conditions", { "LibBabble-CreatureType-3.0", "LibRangeCheck-2.0", "./BestAction", "./Compile", "./Condition", "./Cooldown", "./DamageTaken", "./Data", "./Equipment", "./Future", "./GUID", "./Health", "./Power", "./Runes", "./SpellBook", "./SpellDamage", "./Artifact", "./BossMod", "./Ovale", "./State", "./PaperDoll", "./Aura", "./ComboPoints", "./WildImps", "./Enemies", "./Stance", "./Totem", "./DemonHunterSigils", "./DemonHunterSoulFragments" }, function(__exports, LibBabbleCreatureType, LibRangeCheck, __BestAction, __Compile, __Condition, __Cooldown, __DamageTaken, __Data, __Equipment, __Future, __GUID, __Health, __Power, __Runes, __SpellBook, __SpellDamage, __Artifact, __BossMod, __Ovale, __State, __PaperDoll, __Aura, __ComboPoints, __WildImps, __Enemies, __Stance, __Totem, __DemonHunterSigils, __DemonHunterSoulFragments)
local floor = math.floor
local _ipairs = ipairs
local _pairs = pairs
local _tonumber = tonumber
local _tostring = tostring
local _type = type
local _wipe = wipe
local API_GetBuildInfo = GetBuildInfo
local API_GetItemCooldown = GetItemCooldown
local API_GetItemCount = GetItemCount
local API_GetNumTrackingTypes = GetNumTrackingTypes
local API_GetTime = GetTime
local API_GetTrackingInfo = GetTrackingInfo
local API_GetUnitSpeed = GetUnitSpeed
local API_GetWeaponEnchantInfo = GetWeaponEnchantInfo
local API_HasFullControl = HasFullControl
local API_IsSpellOverlayed = IsSpellOverlayed
local API_IsStealthed = IsStealthed
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitClass = UnitClass
local API_UnitClassification = UnitClassification
local API_UnitCreatureFamily = UnitCreatureFamily
local API_UnitCreatureType = UnitCreatureType
local API_UnitDetailedThreatSituation = UnitDetailedThreatSituation
local API_UnitExists = UnitExists
local API_UnitInRaid = UnitInRaid
local API_UnitIsDead = UnitIsDead
local API_UnitIsFriend = UnitIsFriend
local API_UnitIsPVP = UnitIsPVP
local API_UnitIsUnit = UnitIsUnit
local API_UnitLevel = UnitLevel
local API_UnitName = UnitName
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitRace = UnitRace
local API_UnitStagger = UnitStagger
local INFINITY = math.huge
local BossArmorDamageReduction = function(target, state)
    local armor = 24835
    local constant = 4037.5 * __PaperDoll.paperDollState.level - 317117.5
    if constant < 0 then
        constant = 0
    end
    return armor / (armor + constant)
end

local ComputeParameter = function(spellId, paramName, state, atTime)
    local si = __Data.OvaleData:GetSpellInfo(spellId)
    if si and si[paramName] then
        local name = si[paramName]
        local node = __Compile.OvaleCompile:GetFunctionNode(name)
        if node then
            local timeSpan, element = __BestAction.OvaleBestAction:Compute(node.child[1], state, atTime)
            if element and element.type == "value" then
                local value = element.value + (state.currentTime - element.origin) * element.rate
                return value
            end
        else
            return si[paramName]
        end
    end
    return nil
end

local GetHastedTime = function(seconds, haste, state)
    seconds = seconds or 0
    local multiplier = __PaperDoll.paperDollState:GetHasteMultiplier(haste)
    return seconds / multiplier
end

do
    local AfterWhiteHit = function(positionalParams, namedParams, state, atTime)
        local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 0
        __Ovale.Ovale:OneTimeMessage("Warning: 'AfterWhiteHit()' is not implemented.")
        return __Condition.TestValue(0, INFINITY, value, state.currentTime, -1, comparator, _tonumber(limit))
    end

end
do
    local ArmorSetBonus = function(positionalParams, namedParams, state, atTime)
        local armorSet, count = positionalParams[1], positionalParams[2]
        local value = (__Equipment.OvaleEquipment:GetArmorSetCount(armorSet) >= count) and 1 or 0
        return 0, INFINITY, value, 0, 0
    end

    __Condition.OvaleCondition:RegisterCondition("armorsetbonus", false, ArmorSetBonus)
end
do
    local ArmorSetParts = function(positionalParams, namedParams, state, atTime)
        local armorSet, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __Equipment.OvaleEquipment:GetArmorSetCount(armorSet)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("armorsetparts", false, ArmorSetParts)
end
do
    local ArtifactTraitRank = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __Artifact.OvaleArtifact:TraitRank(spellId)
        return __Condition.Compare(value, comparator, limit)
    end

    local HasArtifactTrait = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local value = __Artifact.OvaleArtifact:HasTrait(spellId)
        return __Condition.TestBoolean(value, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("hasartifacttrait", false, HasArtifactTrait)
    __Condition.OvaleCondition:RegisterCondition("artifacttraitrank", false, ArtifactTraitRank)
end
do
    local BaseDuration = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value
        if (__Data.OvaleData.buffSpellList[auraId]) then
            local spellList = __Data.OvaleData.buffSpellList[auraId]
            local count = 0
            for id in _pairs(spellList) do
                value = __Data.OvaleData:GetBaseDuration(id, state)
                if value ~= math.huge then
                    break
                end
            end
        else
            value = __Data.OvaleData:GetBaseDuration(auraId, state)
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("baseduration", false, BaseDuration)
    __Condition.OvaleCondition:RegisterCondition("buffdurationifapplied", false, BaseDuration)
    __Condition.OvaleCondition:RegisterCondition("debuffdurationifapplied", false, BaseDuration)
end
do
    local BuffAmount = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value = namedParams.value or 1
        local statName = "value1"
        if value == 1 then
            statName = "value1"
        elseif value == 2 then
            statName = "value2"
        elseif value == 3 then
            statName = "value3"
        end
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = aura[statName] or 0
            return __Condition.TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffamount", false, BuffAmount)
    __Condition.OvaleCondition:RegisterCondition("debuffamount", false, BuffAmount)
    __Condition.OvaleCondition:RegisterCondition("tickvalue", false, BuffAmount)
end
do
    local BuffComboPoints = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = aura and aura.combo or 0
            return __Condition.TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffcombopoints", false, BuffComboPoints)
    __Condition.OvaleCondition:RegisterCondition("debuffcombopoints", false, BuffComboPoints)
end
do
    local BuffCooldown = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain, cooldownEnding = aura.gain, aura.cooldownEnding
            cooldownEnding = aura.cooldownEnding or 0
            return __Condition.TestValue(gain, INFINITY, 0, cooldownEnding, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffcooldown", false, BuffCooldown)
    __Condition.OvaleCondition:RegisterCondition("debuffcooldown", false, BuffCooldown)
end
do
    local BuffCount = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local spellList = __Data.OvaleData.buffSpellList[auraId]
        local count = 0
        for id in _pairs(spellList) do
            local si = __Data.OvaleData.spellInfo[id]
            local aura = __Aura.auraState:GetAura(target, id, filter, mine)
            if __Aura.auraState:IsActiveAura(aura, atTime) then
                count = count + 1
            end
        end
        return __Condition.Compare(count, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffcount", false, BuffCount)
end
do
    local BuffCooldownDuration = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local minCooldown = INFINITY
        if __Data.OvaleData.buffSpellList[auraId] then
            for id in _pairs(__Data.OvaleData.buffSpellList[auraId]) do
                local si = __Data.OvaleData.spellInfo[id]
                local cd = si and si.buff_cd
                if cd and minCooldown > cd then
                    minCooldown = cd
                end
            end
        else
            minCooldown = 0
        end
        return __Condition.Compare(minCooldown, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffcooldownduration", false, BuffCooldownDuration)
    __Condition.OvaleCondition:RegisterCondition("debuffcooldownduration", false, BuffCooldownDuration)
end
do
    local BuffCountOnAny = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local excludeUnitId = (namedParams.excludeTarget == 1) and state.defaultTarget or nil
        local fractional = (namedParams.count == 0) and true or false
        local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = __Aura.auraState:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
        if count > 0 and startChangeCount < INFINITY and fractional then
            local origin = startChangeCount
            local rate = -1 / (endingChangeCount - startChangeCount)
            local start, ending = startFirst, endingLast
            return __Condition.TestValue(start, ending, count, origin, rate, comparator, limit)
        end
        return __Condition.Compare(count, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffcountonany", false, BuffCountOnAny)
    __Condition.OvaleCondition:RegisterCondition("debuffcountonany", false, BuffCountOnAny)
end
do
    local BuffDirection = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain, start, ending, direction = aura.gain, aura.start, aura.ending, aura.direction
            return __Condition.TestValue(gain, INFINITY, direction, gain, 0, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffdirection", false, BuffDirection)
    __Condition.OvaleCondition:RegisterCondition("debuffdirection", false, BuffDirection)
end
do
    local BuffDuration = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = ending - start
            return __Condition.TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffduration", false, BuffDuration)
    __Condition.OvaleCondition:RegisterCondition("debuffduration", false, BuffDuration)
end
do
    local BuffExpires = function(positionalParams, namedParams, state, atTime)
        local auraId, seconds = positionalParams[1], positionalParams[2]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            seconds = GetHastedTime(seconds, namedParams.haste, state)
            if ending - seconds <= gain then
                return gain, INFINITY
            else
                return ending - seconds, INFINITY
            end
        end
        return 0, INFINITY
    end

    __Condition.OvaleCondition:RegisterCondition("buffexpires", false, BuffExpires)
    __Condition.OvaleCondition:RegisterCondition("debuffexpires", false, BuffExpires)
    local BuffPresent = function(positionalParams, namedParams, state, atTime)
        local auraId, seconds = positionalParams[1], positionalParams[2]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            seconds = GetHastedTime(seconds, namedParams.haste, state)
            if ending - seconds <= gain then
                return nil
            else
                return gain, ending - seconds
            end
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("buffpresent", false, BuffPresent)
    __Condition.OvaleCondition:RegisterCondition("debuffpresent", false, BuffPresent)
end
do
    local BuffGain = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain = aura.gain or 0
            return __Condition.TestValue(gain, INFINITY, 0, gain, 1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffgain", false, BuffGain)
    __Condition.OvaleCondition:RegisterCondition("debuffgain", false, BuffGain)
end
do
    local BuffPersistentMultiplier = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = aura.damageMultiplier or 1
            return __Condition.TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return __Condition.Compare(1, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffpersistentmultiplier", false, BuffPersistentMultiplier)
    __Condition.OvaleCondition:RegisterCondition("debuffpersistentmultiplier", false, BuffPersistentMultiplier)
end
do
    local BuffRemaining = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            return __Condition.TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffremaining", false, BuffRemaining)
    __Condition.OvaleCondition:RegisterCondition("debuffremaining", false, BuffRemaining)
    __Condition.OvaleCondition:RegisterCondition("buffremains", false, BuffRemaining)
    __Condition.OvaleCondition:RegisterCondition("debuffremains", false, BuffRemaining)
end
do
    local BuffRemainingOnAny = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local excludeUnitId = (namedParams.excludeTarget == 1) and state.defaultTarget or nil
        local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = __Aura.auraState:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
        if count > 0 then
            local start, ending = startFirst, endingLast
            return __Condition.TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffremainingonany", false, BuffRemainingOnAny)
    __Condition.OvaleCondition:RegisterCondition("debuffremainingonany", false, BuffRemainingOnAny)
    __Condition.OvaleCondition:RegisterCondition("buffremainsonany", false, BuffRemainingOnAny)
    __Condition.OvaleCondition:RegisterCondition("debuffremainsonany", false, BuffRemainingOnAny)
end
do
    local BuffStacks = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = aura.stacks or 0
            return __Condition.TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffstacks", false, BuffStacks)
    __Condition.OvaleCondition:RegisterCondition("debuffstacks", false, BuffStacks)
end
do
    local BuffStacksOnAny = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local excludeUnitId = (namedParams.excludeTarget == 1) and state.defaultTarget or nil
        local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = __Aura.auraState:AuraCount(auraId, filter, mine, 1, atTime, excludeUnitId)
        if count > 0 then
            local start, ending = startFirst, endingChangeCount
            return __Condition.TestValue(start, ending, stacks, start, 0, comparator, limit)
        end
        return __Condition.Compare(count, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("buffstacksonany", false, BuffStacksOnAny)
    __Condition.OvaleCondition:RegisterCondition("debuffstacksonany", false, BuffStacksOnAny)
end
do
    local BuffStealable = function(positionalParams, namedParams, state, atTime)
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        return __Aura.auraState:GetAuraWithProperty(target, "stealable", "HELPFUL", atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("buffstealable", false, BuffStealable)
end
do
    local CanCast = function(positionalParams, namedParams, state, atTime)
        local spellId = positionalParams[1]
        local start, duration = __Cooldown.cooldownState:GetSpellCooldown(spellId)
        return start + duration, INFINITY
    end

    __Condition.OvaleCondition:RegisterCondition("cancast", true, CanCast)
end
do
    local CastTime = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local castTime = __SpellBook.OvaleSpellBook:GetCastTime(spellId) or 0
        return __Condition.Compare(castTime, comparator, limit)
    end

    local ExecuteTime = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local castTime = __SpellBook.OvaleSpellBook:GetCastTime(spellId) or 0
        local gcd = __Cooldown.cooldownState:GetGCD()
        local t = (castTime > gcd) and castTime or gcd
        return __Condition.Compare(t, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("casttime", true, CastTime)
    __Condition.OvaleCondition:RegisterCondition("executetime", true, ExecuteTime)
end
do
    local Casting = function(positionalParams, namedParams, state, atTime)
        local spellId = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local start, ending, castSpellId, castSpellName
        if target == "player" then
            start = __Future.futureState.startCast
            ending = __Future.futureState.endCast
            castSpellId = __Future.futureState.currentSpellId
            castSpellName = __SpellBook.OvaleSpellBook:GetSpellName(castSpellId)
        else
            local spellName, _1, _2, _3, startTime, endTime = API_UnitCastingInfo(target)
            if  not spellName then
                spellName, _1, _2, _3, startTime, endTime = API_UnitChannelInfo(target)
            end
            if spellName then
                castSpellName = spellName
                start = startTime / 1000
                ending = endTime / 1000
            end
        end
        if castSpellId or castSpellName then
            if  not spellId then
                return start, ending
            elseif __Data.OvaleData.buffSpellList[spellId] then
                for id in _pairs(__Data.OvaleData.buffSpellList[spellId]) do
                    if id == castSpellId or __SpellBook.OvaleSpellBook:GetSpellName(id) == castSpellName then
                        return start, ending
                    end
                end
            elseif spellId == "harmful" and __SpellBook.OvaleSpellBook:IsHarmfulSpell(spellId) then
                return start, ending
            elseif spellId == "helpful" and __SpellBook.OvaleSpellBook:IsHelpfulSpell(spellId) then
                return start, ending
            elseif spellId == castSpellId then
                return start, ending
            elseif _type(spellId) == "number" and __SpellBook.OvaleSpellBook:GetSpellName(spellId) == castSpellName then
                return start, ending
            end
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("casting", false, Casting)
end
do
    local CheckBoxOff = function(positionalParams, namedParams, state, atTime)
        for _, id in _ipairs(positionalParams) do
            if __Ovale.Ovale:IsChecked(id) then
                return nil
            end
        end
        return 0, INFINITY
    end

    local CheckBoxOn = function(positionalParams, namedParams, state, atTime)
        for _, id in _ipairs(positionalParams) do
            if  not __Ovale.Ovale:IsChecked(id) then
                return nil
            end
        end
        return 0, INFINITY
    end

    __Condition.OvaleCondition:RegisterCondition("checkboxoff", false, CheckBoxOff)
    __Condition.OvaleCondition:RegisterCondition("checkboxon", false, CheckBoxOn)
end
do
    local Class = function(positionalParams, namedParams, state, atTime)
        local className, yesno = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local _, classToken = API_UnitClass(target)
        local boolean = (classToken == className)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("class", false, Class)
end
do
    local IMBUED_BUFF_ID = 214336
    local Classification = function(positionalParams, namedParams, state, atTime)
        local classification, yesno = positionalParams[1], positionalParams[2]
        local targetClassification
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        if API_UnitLevel(target) < 0 then
            targetClassification = "worldboss"
        elseif API_UnitExists("boss1") and __GUID.OvaleGUID:UnitGUID(target) == __GUID.OvaleGUID:UnitGUID("boss1") then
            targetClassification = "worldboss"
        else
            local aura = __Aura.auraState:GetAura(target, IMBUED_BUFF_ID, "debuff", false)
            if __Aura.auraState:IsActiveAura(aura, atTime) then
                targetClassification = "worldboss"
            else
                targetClassification = API_UnitClassification(target)
                if targetClassification == "rareelite" then
                    targetClassification = "elite"
                elseif targetClassification == "rare" then
                    targetClassification = "normal"
                end
            end
        end
        local boolean = (targetClassification == classification)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("classification", false, Classification)
end
do
    local ComboPoints = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = __ComboPoints.comboPointsState.combo
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("combopoints", false, ComboPoints)
end
do
    local Counter = function(positionalParams, namedParams, state, atTime)
        local counter, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __Future.futureState:GetCounterValue(counter)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("counter", false, Counter)
end
do
    local CreatureFamily = function(positionalParams, namedParams, state, atTime)
        local name, yesno = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local family = API_UnitCreatureFamily(target)
        local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
        local boolean = (lookupTable and family == lookupTable[name])
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("creaturefamily", false, CreatureFamily)
end
do
    local CreatureType = function(positionalParams, namedParams, state, atTime)
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local creatureType = API_UnitCreatureType(target)
        local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
        if lookupTable then
            for _, name in _ipairs(positionalParams) do
                if creatureType == lookupTable[name] then
                    return 0, INFINITY
                end
            end
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("creaturetype", false, CreatureType)
end
do
    local AMPLIFICATION = 146051
    local INCREASED_CRIT_EFFECT_3_PERCENT = 44797
    local CritDamage = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local value = ComputeParameter(spellId, "damage", state, atTime) or 0
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.physical == 1 then
            value = value * (1 - BossArmorDamageReduction(target, state))
        end
        local critMultiplier = 2
        do
            local aura = __Aura.auraState:GetAura("player", AMPLIFICATION, "HELPFUL")
            if __Aura.auraState:IsActiveAura(aura, atTime) then
                critMultiplier = critMultiplier + aura.value1
            end
        end
        do
            local aura = __Aura.auraState:GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, "HELPFUL")
            if __Aura.auraState:IsActiveAura(aura, atTime) then
                critMultiplier = critMultiplier * aura.value1
            end
        end
        value = critMultiplier * value
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("critdamage", false, CritDamage)
    local Damage = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local value = ComputeParameter(spellId, "damage", state, atTime) or 0
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.physical == 1 then
            value = value * (1 - BossArmorDamageReduction(target, state))
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("damage", false, Damage)
end
do
    local DamageTaken = function(positionalParams, namedParams, state, atTime)
        local interval, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 0
        if interval > 0 then
            local total, totalMagic = __DamageTaken.OvaleDamageTaken:GetRecentDamage(interval)
            if namedParams.magic == 1 then
                value = totalMagic
            elseif namedParams.physical == 1 then
                value = total - totalMagic
            else
                value = total
            end
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("damagetaken", false, DamageTaken)
    __Condition.OvaleCondition:RegisterCondition("incomingdamage", false, DamageTaken)
end
do
    local Demons = function(positionalParams, namedParams, state, atTime)
        local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __WildImps.wildImpsState:GetDemonsCount(creatureId, atTime)
        return __Condition.Compare(value, comparator, limit)
    end

    local NotDeDemons = function(positionalParams, namedParams, state, atTime)
        local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __WildImps.wildImpsState:GetNotDemonicEmpoweredDemonsCount(creatureId, atTime)
        return __Condition.Compare(value, comparator, limit)
    end

    local DemonDuration = function(positionalParams, namedParams, state, atTime)
        local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __WildImps.wildImpsState:GetRemainingDemonDuration(creatureId, atTime)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("demons", false, Demons)
    __Condition.OvaleCondition:RegisterCondition("notdedemons", false, NotDeDemons)
    __Condition.OvaleCondition:RegisterCondition("demonduration", false, DemonDuration)
end
do
    local NECROTIC_PLAGUE_TALENT = 19
    local NECROTIC_PLAGUE_DEBUFF = 155159
    local BLOOD_PLAGUE_DEBUFF = 55078
    local FROST_FEVER_DEBUFF = 55095
    local GetDiseases = function(target, state)
        local npAura, bpAura, ffAura
        local talented = (__SpellBook.OvaleSpellBook:GetTalentPoints(NECROTIC_PLAGUE_TALENT) > 0)
        if talented then
            npAura = __Aura.auraState:GetAura(target, NECROTIC_PLAGUE_DEBUFF, "HARMFUL", true)
        else
            bpAura = __Aura.auraState:GetAura(target, BLOOD_PLAGUE_DEBUFF, "HARMFUL", true)
            ffAura = __Aura.auraState:GetAura(target, FROST_FEVER_DEBUFF, "HARMFUL", true)
        end
        return talented, npAura, bpAura, ffAura
    end

    local DiseasesRemaining = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local talented, npAura, bpAura, ffAura = GetDiseases(target, state)
        local aura
        if talented and __Aura.auraState:IsActiveAura(npAura, atTime) then
            aura = npAura
        elseif  not talented and __Aura.auraState:IsActiveAura(bpAura, atTime) and __Aura.auraState:IsActiveAura(ffAura, atTime) then
            aura = (bpAura.ending < ffAura.ending) and bpAura or ffAura
        end
        if aura then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            return __Condition.TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    local DiseasesTicking = function(positionalParams, namedParams, state, atTime)
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local talented, npAura, bpAura, ffAura = GetDiseases(target, state)
        local gain, start, ending
        if talented and npAura then
            gain, start, ending = npAura.gain, npAura.start, npAura.ending
        elseif  not talented and bpAura and ffAura then
            gain = (bpAura.gain > ffAura.gain) and bpAura.gain or ffAura.gain
            start = (bpAura.start > ffAura.start) and bpAura.start or ffAura.start
            ending = (bpAura.ending < ffAura.ending) and bpAura.ending or ffAura.ending
        end
        if gain and ending and ending > gain then
            return gain, ending
        end
        return nil
    end

    local DiseasesAnyTicking = function(positionalParams, namedParams, state, atTime)
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local talented, npAura, bpAura, ffAura = GetDiseases(target, state)
        local aura
        if talented and npAura then
            aura = npAura
        elseif  not talented and (bpAura or ffAura) then
            aura = bpAura or ffAura
            if bpAura and ffAura then
                aura = (bpAura.ending > ffAura.ending) and bpAura or ffAura
            end
        end
        if aura then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            if ending > gain then
                return gain, ending
            end
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("diseasesremaining", false, DiseasesRemaining)
    __Condition.OvaleCondition:RegisterCondition("diseasesticking", false, DiseasesTicking)
    __Condition.OvaleCondition:RegisterCondition("diseasesanyticking", false, DiseasesAnyTicking)
end
do
    local Distance = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value = LibRangeCheck and LibRangeCheck:GetRange(target) or 0
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("distance", false, Distance)
end
do
    local Enemies = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = __Enemies.enemiesState.enemies
        if  not value then
            local useTagged = __Ovale.Ovale.db.profile.apparence.taggedEnemies
            if namedParams.tagged == 0 then
                useTagged = false
            elseif namedParams.tagged == 1 then
                useTagged = true
            end
            value = useTagged and __Enemies.enemiesState.taggedEnemies or __Enemies.enemiesState.activeEnemies
        end
        if value < 1 then
            value = 1
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("enemies", false, Enemies)
end
do
    local EnergyRegenRate = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = __Power.powerState.powerRate.energy
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("energyregen", false, EnergyRegenRate)
    __Condition.OvaleCondition:RegisterCondition("energyregenrate", false, EnergyRegenRate)
end
do
    local EnrageRemaining = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local start, ending = __Aura.auraState:GetAuraWithProperty(target, "enrage", "HELPFUL", atTime)
        if start and ending then
            return __Condition.TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("enrageremaining", false, EnrageRemaining)
end
do
    local Exists = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitExists(target)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("exists", false, Exists)
end
do
    local False = function(positionalParams, namedParams, state, atTime)
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("false", false, False)
end
do
    local FocusRegenRate = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = __Power.powerState.powerRate.focus
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("focusregen", false, FocusRegenRate)
    __Condition.OvaleCondition:RegisterCondition("focusregenrate", false, FocusRegenRate)
end
do
    local STEADY_FOCUS = 177668
    local FocusCastingRegen = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local regenRate = __Power.powerState.powerRate.focus
        local power = 0
        local castTime = __SpellBook.OvaleSpellBook:GetCastTime(spellId) or 0
        local gcd = __Cooldown.cooldownState:GetGCD()
        local castSeconds = (castTime > gcd) and castTime or gcd
        power = power + regenRate * castSeconds
        local aura = __Aura.auraState:GetAura("player", STEADY_FOCUS, "HELPFUL", true)
        if aura then
            local seconds = aura.ending - state.currentTime
            if seconds <= 0 then
                seconds = 0
            elseif seconds > castSeconds then
                seconds = castSeconds
            end
            power = power + regenRate * 1.5 * seconds
        end
        return __Condition.Compare(power, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("focuscastingregen", false, FocusCastingRegen)
end
do
    local GCD = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = __Cooldown.cooldownState:GetGCD()
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("gcd", false, GCD)
end
do
    local GCDRemaining = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        if __Future.futureState.lastSpellId then
            local duration = __Cooldown.cooldownState:GetGCD(__Future.futureState.lastSpellId, atTime, __GUID.OvaleGUID:UnitGUID(target))
            local spellcast = __Future.OvaleFuture:LastInFlightSpell()
            local start = (spellcast and spellcast.start) or 0
            local ending = start + duration
            if atTime < ending then
                return __Condition.TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("gcdremaining", false, GCDRemaining)
end
do
    local GetState = function(positionalParams, namedParams, state, atTime)
        local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = state:GetState(name)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("getstate", false, GetState)
end
do
    local GetStateDuration = function(positionalParams, namedParams, state, atTime)
        local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = state:GetStateDuration(name)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("getstateduration", false, GetStateDuration)
end
do
    local Glyph = function(positionalParams, namedParams, state, atTime)
        local stub, yesno = positionalParams[1], positionalParams[2]
        return __Condition.TestBoolean(false, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("glyph", false, Glyph)
end
do
    local HasEquippedItem = function(positionalParams, namedParams, state, atTime)
        local itemId, yesno = positionalParams[1], positionalParams[2]
        local ilevel, slot = namedParams.ilevel, namedParams.slot
        local boolean = false
        local slotId
        if _type(itemId) == "number" then
            slotId = __Equipment.OvaleEquipment:HasEquippedItem(itemId, slot)
            if slotId then
                if  not ilevel or (ilevel and ilevel == __Equipment.OvaleEquipment:GetEquippedItemLevel(slotId)) then
                    boolean = true
                end
            end
        elseif __Data.OvaleData.itemList[itemId] then
            for _, v in _pairs(__Data.OvaleData.itemList[itemId]) do
                slotId = __Equipment.OvaleEquipment:HasEquippedItem(v, slot)
                if slotId then
                    if  not ilevel or (ilevel and ilevel == __Equipment.OvaleEquipment:GetEquippedItemLevel(slotId)) then
                        boolean = true
                        break
                    end
                end
            end
        end
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("hasequippeditem", false, HasEquippedItem)
end
do
    local HasFullControl = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local boolean = API_HasFullControl()
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("hasfullcontrol", false, HasFullControl)
end
do
    local HasShield = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local boolean = __Equipment.OvaleEquipment:HasShield()
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("hasshield", false, HasShield)
end
do
    local HasTrinket = function(positionalParams, namedParams, state, atTime)
        local trinketId, yesno = positionalParams[1], positionalParams[2]
        local boolean = false
        if _type(trinketId) == "number" then
            boolean = __Equipment.OvaleEquipment:HasTrinket(trinketId)
        elseif __Data.OvaleData.itemList[trinketId] then
            for _, v in _pairs(__Data.OvaleData.itemList[trinketId]) do
                boolean = __Equipment.OvaleEquipment:HasTrinket(v)
                if boolean then
                    break
                end
            end
        end
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("hastrinket", false, HasTrinket)
end
do
    local HasWeapon = function(positionalParams, namedParams, state, atTime)
        local hand, yesno = positionalParams[1], positionalParams[2]
        local weaponType = namedParams.type
        local boolean = false
        if weaponType == "one_handed" then
            weaponType = 1
        elseif weaponType == "two_handed" then
            weaponType = 2
        end
        if hand == "offhand" or hand == "off" then
            boolean = __Equipment.OvaleEquipment:HasOffHandWeapon(weaponType)
        elseif hand == "mainhand" or hand == "main" then
            boolean = __Equipment.OvaleEquipment:HasMainHandWeapon(weaponType)
        end
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("hasweapon", false, HasWeapon)
end
do
    local Health = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local health = __Health.OvaleHealth:UnitHealth(target) or 0
        if health > 0 then
            local now = API_GetTime()
            local timeToDie = __Health.OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = health, now, -1 * health / timeToDie
            local start, ending = now, INFINITY
            return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("health", false, Health)
    __Condition.OvaleCondition:RegisterCondition("life", false, Health)
    local HealthMissing = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local health = __Health.OvaleHealth:UnitHealth(target) or 0
        local maxHealth = __Health.OvaleHealth:UnitHealthMax(target) or 1
        if health > 0 then
            local now = API_GetTime()
            local missing = maxHealth - health
            local timeToDie = __Health.OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = missing, now, health / timeToDie
            local start, ending = now, INFINITY
            return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        return __Condition.Compare(maxHealth, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("healthmissing", false, HealthMissing)
    __Condition.OvaleCondition:RegisterCondition("lifemissing", false, HealthMissing)
    local HealthPercent = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local health = __Health.OvaleHealth:UnitHealth(target) or 0
        if health > 0 then
            local now = API_GetTime()
            local maxHealth = __Health.OvaleHealth:UnitHealthMax(target) or 1
            local healthPercent = health / maxHealth * 100
            local timeToDie = __Health.OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = healthPercent, now, -1 * healthPercent / timeToDie
            local start, ending = now, INFINITY
            return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("healthpercent", false, HealthPercent)
    __Condition.OvaleCondition:RegisterCondition("lifepercent", false, HealthPercent)
    local MaxHealth = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value = __Health.OvaleHealth:UnitHealthMax(target)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("maxhealth", false, MaxHealth)
    local TimeToDie = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local now = API_GetTime()
        local timeToDie = __Health.OvaleHealth:UnitTimeToDie(target)
        local value, origin, rate = timeToDie, now, -1
        local start, ending = now, now + timeToDie
        return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("deadin", false, TimeToDie)
    __Condition.OvaleCondition:RegisterCondition("timetodie", false, TimeToDie)
    local TimeToHealthPercent = function(positionalParams, namedParams, state, atTime)
        local percent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local health = __Health.OvaleHealth:UnitHealth(target) or 0
        if health > 0 then
            local maxHealth = __Health.OvaleHealth:UnitHealthMax(target) or 1
            local healthPercent = health / maxHealth * 100
            if healthPercent >= percent then
                local now = API_GetTime()
                local timeToDie = __Health.OvaleHealth:UnitTimeToDie(target)
                local t = timeToDie * (healthPercent - percent) / healthPercent
                local value, origin, rate = t, now, -1
                local start, ending = now, now + t
                return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("timetohealthpercent", false, TimeToHealthPercent)
    __Condition.OvaleCondition:RegisterCondition("timetolifepercent", false, TimeToHealthPercent)
end
do
    local InCombat = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local boolean = state.inCombat
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("incombat", false, InCombat)
end
do
    local InFlightToTarget = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (__Future.futureState.currentSpellId == spellId) or __Future.OvaleFuture:InFlight(spellId)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("inflighttotarget", false, InFlightToTarget)
end
do
    local InRange = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = (__SpellBook.OvaleSpellBook:IsSpellInRange(spellId, target) == 1)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("inrange", false, InRange)
end
do
    local IsAggroed = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitDetailedThreatSituation("player", target)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isaggroed", false, IsAggroed)
end
do
    local IsDead = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitIsDead(target)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isdead", false, IsDead)
end
do
    local IsEnraged = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        return __Aura.auraState:GetAuraWithProperty(target, "enrage", "HELPFUL", atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("isenraged", false, IsEnraged)
end
do
    local IsFeared = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local aura = __Aura.auraState:GetAura("player", "fear_debuff", "HARMFUL")
        local boolean =  not API_HasFullControl() and __Aura.auraState:IsActiveAura(aura, atTime)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isfeared", false, IsFeared)
end
do
    local IsFriend = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitIsFriend("player", target)
        return __Condition.TestBoolean(boolean == 1, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isfriend", false, IsFriend)
end
do
    local IsIncapacitated = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local aura = __Aura.auraState:GetAura("player", "incapacitate_debuff", "HARMFUL")
        local boolean =  not API_HasFullControl() and __Aura.auraState:IsActiveAura(aura, atTime)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isincapacitated", false, IsIncapacitated)
end
do
    local IsInterruptible = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local name, _1, _2, _3, _4, _5, _6, _7, notInterruptible = API_UnitCastingInfo(target)
        if  not name then
            name, _1, _2, _3, _4, _5, _6, notInterruptible = API_UnitChannelInfo(target)
        end
        local boolean = notInterruptible ~= nil and  not notInterruptible
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isinterruptible", false, IsInterruptible)
end
do
    local IsPVP = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitIsPVP(target)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("ispvp", false, IsPVP)
end
do
    local IsRooted = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local aura = __Aura.auraState:GetAura("player", "root_debuff", "HARMFUL")
        local boolean = __Aura.auraState:IsActiveAura(aura, atTime)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isrooted", false, IsRooted)
end
do
    local IsStunned = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local aura = __Aura.auraState:GetAura("player", "stun_debuff", "HARMFUL")
        local boolean =  not API_HasFullControl() and __Aura.auraState:IsActiveAura(aura, atTime)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isstunned", false, IsStunned)
end
do
    local ItemCharges = function(positionalParams, namedParams, state, atTime)
        local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = API_GetItemCount(itemId, false, true)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("itemcharges", false, ItemCharges)
end
do
    local ItemCooldown = function(positionalParams, namedParams, state, atTime)
        local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        if itemId and _type(itemId) ~= "number" then
            itemId = __Equipment.OvaleEquipment:GetEquippedItem(itemId)
        end
        if itemId then
            local start, duration = API_GetItemCooldown(itemId)
            if start > 0 and duration > 0 then
                return __Condition.TestValue(start, start + duration, duration, start, -1, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("itemcooldown", false, ItemCooldown)
end
do
    local ItemCount = function(positionalParams, namedParams, state, atTime)
        local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = API_GetItemCount(itemId)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("itemcount", false, ItemCount)
end
do
    local LastDamage = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __SpellDamage.OvaleSpellDamage:Get(spellId)
        if value then
            return __Condition.Compare(value, comparator, limit)
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("lastdamage", false, LastDamage)
    __Condition.OvaleCondition:RegisterCondition("lastspelldamage", false, LastDamage)
end
do
    local Level = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value
        if target == "player" then
            value = __PaperDoll.paperDollState.level
        else
            value = API_UnitLevel(target)
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("level", false, Level)
end
do
    local List = function(positionalParams, namedParams, state, atTime)
        local name, value = positionalParams[1], positionalParams[2]
        if name and __Ovale.Ovale:GetListValue(name) == value then
            return 0, INFINITY
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("list", false, List)
end
do
    local Name = function(positionalParams, namedParams, state, atTime)
        local name, yesno = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        if _type(name) == "number" then
            name = __SpellBook.OvaleSpellBook:GetSpellName(name)
        end
        local targetName = API_UnitName(target)
        local boolean = (name == targetName)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("name", false, Name)
end
do
    local PTR = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local _1, _2, _3, uiVersion = API_GetBuildInfo()
        local value = (uiVersion > 70200) and 1 or 0
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("ptr", false, PTR)
end
do
    local PersistentMultiplier = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local value = __Future.futureState:GetDamageMultiplier(spellId, __GUID.OvaleGUID:UnitGUID(target), atTime)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("persistentmultiplier", false, PersistentMultiplier)
end
do
    local PetPresent = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local name = namedParams.name
        local target = "pet"
        local boolean = API_UnitExists(target) and  not API_UnitIsDead(target) and (name == nil or name == API_UnitName(target))
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("petpresent", false, PetPresent)
end
do
    local MaxPower = function(powerType, positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value
        if target == "player" then
            value = __Power.OvalePower.maxPower[powerType]
        else
            local powerInfo = __Power.OvalePower.POWER_INFO[powerType]
            value = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments)
        end
        return __Condition.Compare(value, comparator, limit)
    end

    local Power = function(powerType, positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        if target == "player" then
            local value, origin, rate = state[powerType], state.currentTime, __Power.powerState.powerRate[powerType]
            local start, ending = state.currentTime, INFINITY
            return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
        else
            local powerInfo = __Power.OvalePower.POWER_INFO[powerType]
            local value = API_UnitPower(target, powerInfo.id)
            return __Condition.Compare(value, comparator, limit)
        end
    end

    local PowerDeficit = function(powerType, positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        if target == "player" then
            local powerMax = __Power.OvalePower.maxPower[powerType] or 0
            if powerMax > 0 then
                local value, origin, rate = powerMax - state[powerType], state.currentTime, -1 * __Power.powerState.powerRate[powerType]
                local start, ending = state.currentTime, INFINITY
                return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        else
            local powerInfo = __Power.OvalePower.POWER_INFO[powerType]
            local powerMax = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
            if powerMax > 0 then
                local power = API_UnitPower(target, powerInfo.id)
                local value = powerMax - power
                return __Condition.Compare(value, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    local PowerPercent = function(powerType, positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        if target == "player" then
            local powerMax = __Power.OvalePower.maxPower[powerType] or 0
            if powerMax > 0 then
                local conversion = 100 / powerMax
                local value, origin, rate = state[powerType] * conversion, state.currentTime, __Power.powerState.powerRate[powerType] * conversion
                if rate > 0 and value >= 100 or rate < 0 and value == 0 then
                    rate = 0
                end
                local start, ending = state.currentTime, INFINITY
                return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        else
            local powerInfo = __Power.OvalePower.POWER_INFO[powerType]
            local powerMax = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
            if powerMax > 0 then
                local conversion = 100 / powerMax
                local value = API_UnitPower(target, powerInfo.id) * conversion
                return __Condition.Compare(value, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    local PrimaryResource = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local primaryPowerType
        local si = __Data.OvaleData:GetSpellInfo(spellId)
        if si then
            for powerType in _pairs(__Power.OvalePower.PRIMARY_POWER) do
                if si[powerType] then
                    primaryPowerType = powerType
                    break
                end
            end
        end
        if  not primaryPowerType then
            local _, powerType = __Power.OvalePower:GetSpellCost(spellId)
            if powerType then
                primaryPowerType = powerType
            end
        end
        if primaryPowerType then
            local value, origin, rate = state[primaryPowerType], state.currentTime, __Power.powerState.powerRate[primaryPowerType]
            local start, ending = state.currentTime, INFINITY
            return __Condition.TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("primaryresource", true, PrimaryResource)
    local AlternatePower = function(positionalParams, namedParams, state, atTime)
        return Power("alternate", positionalParams, namedParams, state, atTime)
    end

    local AstralPower = function(positionalParams, namedParams, state, atTime)
        return Power("astralpower", positionalParams, namedParams, state, atTime)
    end

    local Chi = function(positionalParams, namedParams, state, atTime)
        return Power("chi", positionalParams, namedParams, state, atTime)
    end

    local Energy = function(positionalParams, namedParams, state, atTime)
        return Power("energy", positionalParams, namedParams, state, atTime)
    end

    local Focus = function(positionalParams, namedParams, state, atTime)
        return Power("focus", positionalParams, namedParams, state, atTime)
    end

    local Fury = function(positionalParams, namedParams, state, atTime)
        return Power("fury", positionalParams, namedParams, state, atTime)
    end

    local HolyPower = function(positionalParams, namedParams, state, atTime)
        return Power("holy", positionalParams, namedParams, state, atTime)
    end

    local Insanity = function(positionalParams, namedParams, state, atTime)
        return Power("insanity", positionalParams, namedParams, state, atTime)
    end

    local Mana = function(positionalParams, namedParams, state, atTime)
        return Power("mana", positionalParams, namedParams, state, atTime)
    end

    local Maelstrom = function(positionalParams, namedParams, state, atTime)
        return Power("maelstrom", positionalParams, namedParams, state, atTime)
    end

    local Pain = function(positionalParams, namedParams, state, atTime)
        return Power("pain", positionalParams, namedParams, state, atTime)
    end

    local Rage = function(positionalParams, namedParams, state, atTime)
        return Power("rage", positionalParams, namedParams, state, atTime)
    end

    local RunicPower = function(positionalParams, namedParams, state, atTime)
        return Power("runicpower", positionalParams, namedParams, state, atTime)
    end

    local ShadowOrbs = function(positionalParams, namedParams, state, atTime)
        return Power("shadoworbs", positionalParams, namedParams, state, atTime)
    end

    local SoulShards = function(positionalParams, namedParams, state, atTime)
        return Power("soulshards", positionalParams, namedParams, state, atTime)
    end

    local ArcaneCharges = function(positionalParams, namedParams, state, atTime)
        return Power("arcanecharges", positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("alternatepower", false, AlternatePower)
    __Condition.OvaleCondition:RegisterCondition("arcanecharges", false, ArcaneCharges)
    __Condition.OvaleCondition:RegisterCondition("astralpower", false, AstralPower)
    __Condition.OvaleCondition:RegisterCondition("chi", false, Chi)
    __Condition.OvaleCondition:RegisterCondition("energy", false, Energy)
    __Condition.OvaleCondition:RegisterCondition("focus", false, Focus)
    __Condition.OvaleCondition:RegisterCondition("fury", false, Fury)
    __Condition.OvaleCondition:RegisterCondition("holypower", false, HolyPower)
    __Condition.OvaleCondition:RegisterCondition("insanity", false, Insanity)
    __Condition.OvaleCondition:RegisterCondition("maelstrom", false, Maelstrom)
    __Condition.OvaleCondition:RegisterCondition("mana", false, Mana)
    __Condition.OvaleCondition:RegisterCondition("pain", false, Pain)
    __Condition.OvaleCondition:RegisterCondition("rage", false, Rage)
    __Condition.OvaleCondition:RegisterCondition("runicpower", false, RunicPower)
    __Condition.OvaleCondition:RegisterCondition("shadoworbs", false, ShadowOrbs)
    __Condition.OvaleCondition:RegisterCondition("soulshards", false, SoulShards)
    local AlternatePowerDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("alternatepower", positionalParams, namedParams, state, atTime)
    end

    local AstralPowerDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("astralpower", positionalParams, namedParams, state, atTime)
    end

    local ChiDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("chi", positionalParams, namedParams, state, atTime)
    end

    local ComboPointsDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("combopoints", positionalParams, namedParams, state, atTime)
    end

    local EnergyDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("energy", positionalParams, namedParams, state, atTime)
    end

    local FocusDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("focus", positionalParams, namedParams, state, atTime)
    end

    local FuryDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("fury", positionalParams, namedParams, state, atTime)
    end

    local HolyPowerDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("holypower", positionalParams, namedParams, state, atTime)
    end

    local ManaDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("mana", positionalParams, namedParams, state, atTime)
    end

    local PainDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("pain", positionalParams, namedParams, state, atTime)
    end

    local RageDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("rage", positionalParams, namedParams, state, atTime)
    end

    local RunicPowerDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("runicpower", positionalParams, namedParams, state, atTime)
    end

    local ShadowOrbsDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("shadoworbs", positionalParams, namedParams, state, atTime)
    end

    local SoulShardsDeficit = function(positionalParams, namedParams, state, atTime)
        return PowerDeficit("soulshards", positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("alternatepowerdeficit", false, AlternatePowerDeficit)
    __Condition.OvaleCondition:RegisterCondition("astralpowerdeficit", false, AstralPowerDeficit)
    __Condition.OvaleCondition:RegisterCondition("chideficit", false, ChiDeficit)
    __Condition.OvaleCondition:RegisterCondition("combopointsdeficit", false, ComboPointsDeficit)
    __Condition.OvaleCondition:RegisterCondition("energydeficit", false, EnergyDeficit)
    __Condition.OvaleCondition:RegisterCondition("focusdeficit", false, FocusDeficit)
    __Condition.OvaleCondition:RegisterCondition("furydeficit", false, FuryDeficit)
    __Condition.OvaleCondition:RegisterCondition("holypowerdeficit", false, HolyPowerDeficit)
    __Condition.OvaleCondition:RegisterCondition("manadeficit", false, ManaDeficit)
    __Condition.OvaleCondition:RegisterCondition("paindeficit", false, PainDeficit)
    __Condition.OvaleCondition:RegisterCondition("ragedeficit", false, RageDeficit)
    __Condition.OvaleCondition:RegisterCondition("runicpowerdeficit", false, RunicPowerDeficit)
    __Condition.OvaleCondition:RegisterCondition("shadoworbsdeficit", false, ShadowOrbsDeficit)
    __Condition.OvaleCondition:RegisterCondition("soulshardsdeficit", false, SoulShardsDeficit)
    local ManaPercent = function(positionalParams, namedParams, state, atTime)
        return PowerPercent("mana", positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("manapercent", false, ManaPercent)
    local MaxAlternatePower = function(positionalParams, namedParams, state, atTime)
        return MaxPower("alternate", positionalParams, namedParams, state, atTime)
    end

    local MaxChi = function(positionalParams, namedParams, state, atTime)
        return MaxPower("chi", positionalParams, namedParams, state, atTime)
    end

    local MaxComboPoints = function(positionalParams, namedParams, state, atTime)
        return MaxPower("combopoints", positionalParams, namedParams, state, atTime)
    end

    local MaxEnergy = function(positionalParams, namedParams, state, atTime)
        return MaxPower("energy", positionalParams, namedParams, state, atTime)
    end

    local MaxFocus = function(positionalParams, namedParams, state, atTime)
        return MaxPower("focus", positionalParams, namedParams, state, atTime)
    end

    local MaxFury = function(positionalParams, namedParams, state, atTime)
        return MaxPower("fury", positionalParams, namedParams, state, atTime)
    end

    local MaxHolyPower = function(positionalParams, namedParams, state, atTime)
        return MaxPower("holy", positionalParams, namedParams, state, atTime)
    end

    local MaxMana = function(positionalParams, namedParams, state, atTime)
        return MaxPower("mana", positionalParams, namedParams, state, atTime)
    end

    local MaxPain = function(positionalParams, namedParams, state, atTime)
        return MaxPower("pain", positionalParams, namedParams, state, atTime)
    end

    local MaxRage = function(positionalParams, namedParams, state, atTime)
        return MaxPower("rage", positionalParams, namedParams, state, atTime)
    end

    local MaxRunicPower = function(positionalParams, namedParams, state, atTime)
        return MaxPower("runicpower", positionalParams, namedParams, state, atTime)
    end

    local MaxShadowOrbs = function(positionalParams, namedParams, state, atTime)
        return MaxPower("shadoworbs", positionalParams, namedParams, state, atTime)
    end

    local MaxSoulShards = function(positionalParams, namedParams, state, atTime)
        return MaxPower("soulshards", positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("maxalternatepower", false, MaxAlternatePower)
    __Condition.OvaleCondition:RegisterCondition("maxchi", false, MaxChi)
    __Condition.OvaleCondition:RegisterCondition("maxcombopoints", false, MaxComboPoints)
    __Condition.OvaleCondition:RegisterCondition("maxenergy", false, MaxEnergy)
    __Condition.OvaleCondition:RegisterCondition("maxfocus", false, MaxFocus)
    __Condition.OvaleCondition:RegisterCondition("maxfury", false, MaxFury)
    __Condition.OvaleCondition:RegisterCondition("maxholypower", false, MaxHolyPower)
    __Condition.OvaleCondition:RegisterCondition("maxmana", false, MaxMana)
    __Condition.OvaleCondition:RegisterCondition("maxpain", false, MaxPain)
    __Condition.OvaleCondition:RegisterCondition("maxrage", false, MaxRage)
    __Condition.OvaleCondition:RegisterCondition("maxrunicpower", false, MaxRunicPower)
    __Condition.OvaleCondition:RegisterCondition("maxshadoworbs", false, MaxShadowOrbs)
    __Condition.OvaleCondition:RegisterCondition("maxsoulshards", false, MaxSoulShards)
end
do
    local PowerCost = function(powerType, positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local maxCost = (namedParams.max == 1)
        local value = __Power.powerState:PowerCost(spellId, powerType, atTime, target, maxCost) or 0
        return __Condition.Compare(value, comparator, limit)
    end

    local EnergyCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost("energy", positionalParams, namedParams, state, atTime)
    end

    local FocusCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost("focus", positionalParams, namedParams, state, atTime)
    end

    local ManaCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost("mana", positionalParams, namedParams, state, atTime)
    end

    local RageCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost("rage", positionalParams, namedParams, state, atTime)
    end

    local RunicPowerCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost("runicpower", positionalParams, namedParams, state, atTime)
    end

    local AstralPowerCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost("astralpower", positionalParams, namedParams, state, atTime)
    end

    local MainPowerCost = function(positionalParams, namedParams, state, atTime)
        return PowerCost(__Power.OvalePower.powerType, positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("powercost", true, MainPowerCost)
    __Condition.OvaleCondition:RegisterCondition("astralpowercost", true, AstralPowerCost)
    __Condition.OvaleCondition:RegisterCondition("energycost", true, EnergyCost)
    __Condition.OvaleCondition:RegisterCondition("focuscost", true, FocusCost)
    __Condition.OvaleCondition:RegisterCondition("manacost", true, ManaCost)
    __Condition.OvaleCondition:RegisterCondition("ragecost", true, RageCost)
    __Condition.OvaleCondition:RegisterCondition("runicpowercost", true, RunicPowerCost)
end
do
    local Present = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitExists(target) and  not API_UnitIsDead(target)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("present", false, Present)
end
do
    local PreviousGCDSpell = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local count = namedParams.count
        local boolean
        if count and count > 1 then
            boolean = (spellId == __Future.futureState.lastGCDSpellIds[#__Future.futureState.lastGCDSpellIds - count + 2])
        else
            boolean = (spellId == __Future.futureState.lastGCDSpellId)
        end
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("previousgcdspell", true, PreviousGCDSpell)
end
do
    local PreviousOffGCDSpell = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (spellId == __Future.futureState.lastOffGCDSpellId)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("previousoffgcdspell", true, PreviousOffGCDSpell)
end
do
    local PreviousSpell = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (spellId == __Future.futureState.lastSpellId)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("previousspell", true, PreviousSpell)
end
do
    local RelativeLevel = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value, level
        if target == "player" then
            level = __PaperDoll.paperDollState.level
        else
            level = API_UnitLevel(target)
        end
        if level < 0 then
            value = 3
        else
            value = level - __PaperDoll.paperDollState.level
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("relativelevel", false, RelativeLevel)
end
do
    local Refreshable = function(positionalParams, namedParams, state, atTime)
        local auraId = positionalParams[1]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local baseDuration = __Data.OvaleData:GetBaseDuration(auraId)
            local extensionDuration = 0.3 * baseDuration
            return aura.ending - extensionDuration, INFINITY
        end
        return 0, INFINITY
    end

    __Condition.OvaleCondition:RegisterCondition("refreshable", false, Refreshable)
    __Condition.OvaleCondition:RegisterCondition("debuffrefreshable", false, Refreshable)
    __Condition.OvaleCondition:RegisterCondition("buffrefreshable", false, Refreshable)
end
do
    local RemainingCastTime = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local _1, _2, _3, _4, startTime, endTime = API_UnitCastingInfo(target)
        if startTime and endTime then
            startTime = startTime / 1000
            endTime = endTime / 1000
            return __Condition.TestValue(startTime, endTime, 0, endTime, -1, comparator, limit)
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("remainingcasttime", false, RemainingCastTime)
end
do
    local Rune = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local count, startCooldown, endCooldown = __Runes.runesState:RuneCount(atTime)
        if startCooldown < INFINITY then
            local origin = startCooldown
            local rate = 1 / (endCooldown - startCooldown)
            local start, ending = startCooldown, INFINITY
            return __Condition.TestValue(start, ending, count, origin, rate, comparator, limit)
        end
        return __Condition.Compare(count, comparator, limit)
    end

    local RuneCount = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local count, startCooldown, endCooldown = __Runes.runesState:RuneCount(atTime)
        if startCooldown < INFINITY then
            local start, ending = startCooldown, endCooldown
            return __Condition.TestValue(start, ending, count, start, 0, comparator, limit)
        end
        return __Condition.Compare(count, comparator, limit)
    end

    local TimeToRunes = function(positionalParams, namedParams, state, atTime)
        local runes, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local seconds = __Runes.runesState:GetRunesCooldown(atTime, runes)
        if seconds < 0 then
            seconds = 0
        end
        return __Condition.Compare(seconds, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("rune", false, Rune)
    __Condition.OvaleCondition:RegisterCondition("runecount", false, RuneCount)
    __Condition.OvaleCondition:RegisterCondition("timetorunes", false, TimeToRunes)
end
do
    local Snapshot = function(statName, defaultValue, positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = state[statName] or defaultValue
        return __Condition.Compare(value, comparator, limit)
    end

    local SnapshotCritChance = function(statName, defaultValue, positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = state[statName] or defaultValue
        if namedParams.unlimited ~= 1 and value > 100 then
            value = 100
        end
        return __Condition.Compare(value, comparator, limit)
    end

    local Agility = function(positionalParams, namedParams, state, atTime)
        return Snapshot("agility", 0, positionalParams, namedParams, state, atTime)
    end

    local AttackPower = function(positionalParams, namedParams, state, atTime)
        return Snapshot("attackPower", 0, positionalParams, namedParams, state, atTime)
    end

    local CritRating = function(positionalParams, namedParams, state, atTime)
        return Snapshot("critRating", 0, positionalParams, namedParams, state, atTime)
    end

    local HasteRating = function(positionalParams, namedParams, state, atTime)
        return Snapshot("hasteRating", 0, positionalParams, namedParams, state, atTime)
    end

    local Intellect = function(positionalParams, namedParams, state, atTime)
        return Snapshot("intellect", 0, positionalParams, namedParams, state, atTime)
    end

    local MasteryEffect = function(positionalParams, namedParams, state, atTime)
        return Snapshot("masteryEffect", 0, positionalParams, namedParams, state, atTime)
    end

    local MasteryRating = function(positionalParams, namedParams, state, atTime)
        return Snapshot("masteryRating", 0, positionalParams, namedParams, state, atTime)
    end

    local MeleeCritChance = function(positionalParams, namedParams, state, atTime)
        return SnapshotCritChance("meleeCrit", 0, positionalParams, namedParams, state, atTime)
    end

    local MeleeHaste = function(positionalParams, namedParams, state, atTime)
        return Snapshot("meleeHaste", 0, positionalParams, namedParams, state, atTime)
    end

    local MultistrikeChance = function(positionalParams, namedParams, state, atTime)
        return Snapshot("multistrike", 0, positionalParams, namedParams, state, atTime)
    end

    local RangedCritChance = function(positionalParams, namedParams, state, atTime)
        return SnapshotCritChance("rangedCrit", 0, positionalParams, namedParams, state, atTime)
    end

    local SpellCritChance = function(positionalParams, namedParams, state, atTime)
        return SnapshotCritChance("spellCrit", 0, positionalParams, namedParams, state, atTime)
    end

    local SpellHaste = function(positionalParams, namedParams, state, atTime)
        return Snapshot("spellHaste", 0, positionalParams, namedParams, state, atTime)
    end

    local Spellpower = function(positionalParams, namedParams, state, atTime)
        return Snapshot("spellBonusDamage", 0, positionalParams, namedParams, state, atTime)
    end

    local Spirit = function(positionalParams, namedParams, state, atTime)
        return Snapshot("spirit", 0, positionalParams, namedParams, state, atTime)
    end

    local Stamina = function(positionalParams, namedParams, state, atTime)
        return Snapshot("stamina", 0, positionalParams, namedParams, state, atTime)
    end

    local Strength = function(positionalParams, namedParams, state, atTime)
        return Snapshot("strength", 0, positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("agility", false, Agility)
    __Condition.OvaleCondition:RegisterCondition("attackpower", false, AttackPower)
    __Condition.OvaleCondition:RegisterCondition("critrating", false, CritRating)
    __Condition.OvaleCondition:RegisterCondition("hasterating", false, HasteRating)
    __Condition.OvaleCondition:RegisterCondition("intellect", false, Intellect)
    __Condition.OvaleCondition:RegisterCondition("mastery", false, MasteryEffect)
    __Condition.OvaleCondition:RegisterCondition("masteryeffect", false, MasteryEffect)
    __Condition.OvaleCondition:RegisterCondition("masteryrating", false, MasteryRating)
    __Condition.OvaleCondition:RegisterCondition("meleecritchance", false, MeleeCritChance)
    __Condition.OvaleCondition:RegisterCondition("meleehaste", false, MeleeHaste)
    __Condition.OvaleCondition:RegisterCondition("multistrikechance", false, MultistrikeChance)
    __Condition.OvaleCondition:RegisterCondition("rangedcritchance", false, RangedCritChance)
    __Condition.OvaleCondition:RegisterCondition("spellcritchance", false, SpellCritChance)
    __Condition.OvaleCondition:RegisterCondition("spellhaste", false, SpellHaste)
    __Condition.OvaleCondition:RegisterCondition("spellpower", false, Spellpower)
    __Condition.OvaleCondition:RegisterCondition("spirit", false, Spirit)
    __Condition.OvaleCondition:RegisterCondition("stamina", false, Stamina)
    __Condition.OvaleCondition:RegisterCondition("strength", false, Strength)
end
do
    local Speed = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local value = API_GetUnitSpeed(target) * 100 / 7
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("speed", false, Speed)
end
do
    local SpellChargeCooldown = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local charges, maxCharges, start, duration = __Cooldown.cooldownState:GetSpellCharges(spellId, atTime)
        if charges and charges < maxCharges then
            return __Condition.TestValue(start, start + duration, duration, start, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("spellchargecooldown", true, SpellChargeCooldown)
end
do
    local SpellCharges = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local charges, maxCharges, start, duration = __Cooldown.cooldownState:GetSpellCharges(spellId, atTime)
        if  not charges then
            return nil
        end
        charges = charges or 0
        maxCharges = maxCharges or 1
        if namedParams.count == 0 and charges < maxCharges then
            return __Condition.TestValue(state.currentTime, INFINITY, charges + 1, start + duration, 1 / duration, comparator, limit)
        end
        return __Condition.Compare(charges, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("charges", true, SpellCharges)
    __Condition.OvaleCondition:RegisterCondition("spellcharges", true, SpellCharges)
end
do
    local SpellCooldown = function(positionalParams, namedParams, state, atTime)
        local comparator, limit
        local usable = (namedParams.usable == 1)
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local earliest = INFINITY
        for i, spellId in _ipairs(positionalParams) do
            if __Condition.OvaleCondition.COMPARATOR[spellId] then
                comparator, limit = spellId, positionalParams[i + 1]
                break
            elseif  not usable or __SpellBook.spellBookState:IsUsableSpell(spellId, atTime, __GUID.OvaleGUID:UnitGUID(target)) then
                local start, duration = __Cooldown.cooldownState:GetSpellCooldown(spellId)
                local t = 0
                if start > 0 and duration > 0 then
                    t = start + duration
                end
                if earliest > t then
                    earliest = t
                end
            end
        end
        if earliest == INFINITY then
            return __Condition.Compare(0, comparator, limit)
        elseif earliest > 0 then
            return __Condition.TestValue(0, earliest, 0, earliest, -1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("spellcooldown", true, SpellCooldown)
end
do
    local SpellCooldownDuration = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local duration = __Cooldown.cooldownState:GetSpellCooldownDuration(spellId, atTime, target)
        return __Condition.Compare(duration, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("spellcooldownduration", true, SpellCooldownDuration)
end
do
    local SpellRechargeDuration = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local cd = __Cooldown.cooldownState:GetCD(spellId)
        local duration = cd.chargeDuration or __Cooldown.cooldownState:GetSpellCooldownDuration(spellId, atTime, target)
        return __Condition.Compare(duration, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("spellrechargeduration", true, SpellRechargeDuration)
end
do
    local SpellData = function(positionalParams, namedParams, state, atTime)
        local spellId, key, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
        local si = __Data.OvaleData.spellInfo[spellId]
        if si then
            local value = si[key]
            if value then
                return __Condition.Compare(value, comparator, limit)
            end
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("spelldata", false, SpellData)
end
do
    local SpellInfoProperty = function(positionalParams, namedParams, state, atTime)
        local spellId, key, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
        local value = __Data.dataState:GetSpellInfoProperty(spellId, atTime, key)
        if value then
            return __Condition.Compare(value, comparator, limit)
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("spellinfoproperty", false, SpellInfoProperty)
end
do
    local SpellCount = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local spellCount = __SpellBook.OvaleSpellBook:GetSpellCount(spellId)
        return __Condition.Compare(spellCount, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("spellcount", true, SpellCount)
end
do
    local SpellKnown = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = __SpellBook.OvaleSpellBook:IsKnownSpell(spellId)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("spellknown", true, SpellKnown)
end
do
    local SpellMaxCharges = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local charges, maxCharges, start, duration = __Cooldown.cooldownState:GetSpellCharges(spellId, atTime)
        if  not maxCharges then
            return nil
        end
        maxCharges = maxCharges or 1
        return __Condition.Compare(maxCharges, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("spellmaxcharges", true, SpellMaxCharges)
end
do
    local SpellUsable = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local isUsable, noMana = __SpellBook.spellBookState:IsUsableSpell(spellId, atTime, __GUID.OvaleGUID:UnitGUID(target))
        local boolean = isUsable or noMana
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("spellusable", true, SpellUsable)
end
do
    local LIGHT_STAGGER = 124275
    local MODERATE_STAGGER = 124274
    local HEAVY_STAGGER = 124273
    local StaggerRemaining = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, HEAVY_STAGGER, "HARMFUL")
        if  not __Aura.auraState:IsActiveAura(aura, atTime) then
            aura = __Aura.auraState:GetAura(target, MODERATE_STAGGER, "HARMFUL")
        end
        if  not __Aura.auraState:IsActiveAura(aura, atTime) then
            aura = __Aura.auraState:GetAura(target, LIGHT_STAGGER, "HARMFUL")
        end
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local stagger = API_UnitStagger(target)
            local rate = -1 * stagger / (ending - start)
            return __Condition.TestValue(gain, ending, 0, ending, rate, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("staggerremaining", false, StaggerRemaining)
    __Condition.OvaleCondition:RegisterCondition("staggerremains", false, StaggerRemaining)
end
do
    local Stance = function(positionalParams, namedParams, state, atTime)
        local stance, yesno = positionalParams[1], positionalParams[2]
        local boolean = __Stance.stanceState:IsStance(stance)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("stance", false, Stance)
end
do
    local Stealthed = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local boolean = __Aura.auraState:GetAura("player", "stealthed_buff") or API_IsStealthed()
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("isstealthed", false, Stealthed)
    __Condition.OvaleCondition:RegisterCondition("stealthed", false, Stealthed)
end
do
    local LastSwing = function(positionalParams, namedParams, state, atTime)
        local swing = positionalParams[1]
        local comparator, limit
        local start
        if swing and swing == "main" or swing == "off" then
            comparator, limit = positionalParams[2], positionalParams[3]
            start = 0
        else
            comparator, limit = positionalParams[1], positionalParams[2]
            start = 0
        end
        __Ovale.Ovale:OneTimeMessage("Warning: 'LastSwing()' is not implemented.")
        return __Condition.TestValue(start, INFINITY, 0, start, 1, comparator, limit)
    end

    local NextSwing = function(positionalParams, namedParams, state, atTime)
        local swing = positionalParams[1]
        local comparator, limit
        local ending
        if swing and swing == "main" or swing == "off" then
            comparator, limit = positionalParams[2], positionalParams[3]
            ending = 0
        else
            comparator, limit = positionalParams[1], positionalParams[2]
            ending = 0
        end
        __Ovale.Ovale:OneTimeMessage("Warning: 'NextSwing()' is not implemented.")
        return __Condition.TestValue(0, ending, 0, ending, -1, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("lastswing", false, LastSwing)
    __Condition.OvaleCondition:RegisterCondition("nextswing", false, NextSwing)
end
do
    local Talent = function(positionalParams, namedParams, state, atTime)
        local talentId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (__SpellBook.OvaleSpellBook:GetTalentPoints(talentId) > 0)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("talent", false, Talent)
end
do
    local TalentPoints = function(positionalParams, namedParams, state, atTime)
        local talent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = __SpellBook.OvaleSpellBook:GetTalentPoints(talent)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("talentpoints", false, TalentPoints)
end
do
    local TargetIsPlayer = function(positionalParams, namedParams, state, atTime)
        local yesno = positionalParams[1]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state)
        local boolean = API_UnitIsUnit("player", target)
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("istargetingplayer", false, TargetIsPlayer)
    __Condition.OvaleCondition:RegisterCondition("targetisplayer", false, TargetIsPlayer)
end
do
    local Threat = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local _1, _2, value = API_UnitDetailedThreatSituation("player", target)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("threat", false, Threat)
end
do
    local TickTime = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        local tickTime
        if __Aura.auraState:IsActiveAura(aura, atTime) then
            tickTime = aura.tick
        else
            tickTime = __Data.OvaleData:GetTickLength(auraId, state)
        end
        if tickTime and tickTime > 0 then
            return __Condition.Compare(tickTime, comparator, limit)
        end
        return __Condition.Compare(INFINITY, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("ticktime", false, TickTime)
end
do
    local TicksRemaining = function(positionalParams, namedParams, state, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = __Condition.ParseCondition(positionalParams, namedParams, state)
        local aura = __Aura.auraState:GetAura(target, auraId, filter, mine)
        if aura then
            local gain, start, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
            if tick and tick > 0 then
                return __Condition.TestValue(gain, INFINITY, 1, ending, -1 / tick, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("ticksremaining", false, TicksRemaining)
    __Condition.OvaleCondition:RegisterCondition("ticksremain", false, TicksRemaining)
end
do
    local TimeInCombat = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        if state.inCombat then
            local start = __Future.futureState.combatStartTime
            return __Condition.TestValue(start, INFINITY, 0, start, 1, comparator, limit)
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("timeincombat", false, TimeInCombat)
end
do
    local TimeSincePreviousSpell = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local t = __Future.futureState:TimeOfLastCast(spellId)
        return __Condition.TestValue(0, INFINITY, 0, t, 1, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("timesincepreviousspell", false, TimeSincePreviousSpell)
end
do
    local TimeToBloodlust = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 3600
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("timetobloodlust", false, TimeToBloodlust)
end
do
    local TimeToEclipse = function(positionalParams, namedParams, state, atTime)
        local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 3600 * 24 * 7
        __Ovale.Ovale:OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.")
        return __Condition.TestValue(0, INFINITY, value, atTime, -1, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("timetoeclipse", false, TimeToEclipse)
end
do
    local TimeToPower = function(powerType, level, comparator, limit, state, atTime)
        level = level or 0
        local power = state[powerType] or 0
        local powerRegen = __Power.powerState.powerRate[powerType] or 1
        if powerRegen == 0 then
            if power == level then
                return __Condition.Compare(0, comparator, limit)
            end
            return __Condition.Compare(INFINITY, comparator, limit)
        else
            local t = (level - power) / powerRegen
            if t > 0 then
                local ending = state.currentTime + t
                return __Condition.TestValue(0, ending, 0, ending, -1, comparator, limit)
            end
            return __Condition.Compare(0, comparator, limit)
        end
    end

    local TimeToEnergy = function(positionalParams, namedParams, state, atTime)
        local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        return TimeToPower("energy", level, comparator, limit, state, atTime)
    end

    local TimeToMaxEnergy = function(positionalParams, namedParams, state, atTime)
        local powerType = "energy"
        local comparator, limit = positionalParams[1], positionalParams[2]
        local level = __Power.OvalePower.maxPower[powerType] or 0
        return TimeToPower(powerType, level, comparator, limit, state, atTime)
    end

    local TimeToFocus = function(positionalParams, namedParams, state, atTime)
        local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        return TimeToPower("focus", level, comparator, limit, state, atTime)
    end

    local TimeToMaxFocus = function(positionalParams, namedParams, state, atTime)
        local powerType = "focus"
        local comparator, limit = positionalParams[1], positionalParams[2]
        local level = __Power.OvalePower.maxPower[powerType] or 0
        return TimeToPower(powerType, level, comparator, limit, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("timetoenergy", false, TimeToEnergy)
    __Condition.OvaleCondition:RegisterCondition("timetofocus", false, TimeToFocus)
    __Condition.OvaleCondition:RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy)
    __Condition.OvaleCondition:RegisterCondition("timetomaxfocus", false, TimeToMaxFocus)
end
do
    local TimeToPowerFor = function(powerType, positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        if  not powerType then
            local _, pt = __Power.OvalePower:GetSpellCost(spellId)
            powerType = pt
        end
        local seconds = __Power.powerState:TimeToPower(spellId, atTime, __GUID.OvaleGUID:UnitGUID(target), powerType)
        if seconds == 0 then
            return __Condition.Compare(0, comparator, limit)
        elseif seconds < INFINITY then
            return __Condition.TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit)
        else
            return __Condition.Compare(INFINITY, comparator, limit)
        end
    end

    local TimeToEnergyFor = function(positionalParams, namedParams, state, atTime)
        return TimeToPowerFor("energy", positionalParams, namedParams, state, atTime)
    end

    local TimeToFocusFor = function(positionalParams, namedParams, state, atTime)
        return TimeToPowerFor("focus", positionalParams, namedParams, state, atTime)
    end

    __Condition.OvaleCondition:RegisterCondition("timetoenergyfor", true, TimeToEnergyFor)
    __Condition.OvaleCondition:RegisterCondition("timetofocusfor", true, TimeToFocusFor)
end
do
    local TimeToSpell = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local seconds = __SpellBook.spellBookState:GetTimeToSpell(spellId, atTime, __GUID.OvaleGUID:UnitGUID(target))
        if seconds == 0 then
            return __Condition.Compare(0, comparator, limit)
        elseif seconds < INFINITY then
            return __Condition.TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit)
        else
            return __Condition.Compare(INFINITY, comparator, limit)
        end
    end

    __Condition.OvaleCondition:RegisterCondition("timetospell", true, TimeToSpell)
end
do
    local TimeWithHaste = function(positionalParams, namedParams, state, atTime)
        local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local haste = namedParams.haste or "spell"
        local value = GetHastedTime(seconds, haste, state)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("timewithhaste", false, TimeWithHaste)
end
do
    local TotemExpires = function(positionalParams, namedParams, state, atTime)
        local id, seconds = positionalParams[1], positionalParams[2]
        seconds = seconds or 0
        if _type(id) == "string" then
            local _, name, startTime, duration = __Totem.totemState:GetTotemInfo(id)
            if startTime then
                return startTime + duration - seconds, INFINITY
            end
        else
            local count, start, ending = __Totem.totemState:GetTotemCount(id, atTime)
            if count > 0 then
                return ending - seconds, INFINITY
            end
        end
        return 0, INFINITY
    end

    local TotemPresent = function(positionalParams, namedParams, state, atTime)
        local id = positionalParams[1]
        if _type(id) == "string" then
            local _, name, startTime, duration = __Totem.totemState:GetTotemInfo(id)
            if startTime and duration > 0 then
                return startTime, startTime + duration
            end
        else
            local count, start, ending = __Totem.totemState:GetTotemCount(id, atTime)
            if count > 0 then
                return start, ending
            end
        end
        return nil
    end

    __Condition.OvaleCondition:RegisterCondition("totemexpires", false, TotemExpires)
    __Condition.OvaleCondition:RegisterCondition("totempresent", false, TotemPresent)
    local TotemRemaining = function(positionalParams, namedParams, state, atTime)
        local id, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        if _type(id) == "string" then
            local _, name, startTime, duration = __Totem.totemState:GetTotemInfo(id)
            if startTime and duration > 0 then
                local start, ending = startTime, startTime + duration
                return __Condition.TestValue(start, ending, 0, ending, -1, comparator, limit)
            end
        else
            local count, start, ending = __Totem.totemState:GetTotemCount(id, atTime)
            if count > 0 then
                return __Condition.TestValue(start, ending, 0, ending, -1, comparator, limit)
            end
        end
        return __Condition.Compare(0, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("totemremaining", false, TotemRemaining)
    __Condition.OvaleCondition:RegisterCondition("totemremains", false, TotemRemaining)
end
do
    local Tracking = function(positionalParams, namedParams, state, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local spellName = __SpellBook.OvaleSpellBook:GetSpellName(spellId)
        local numTrackingTypes = API_GetNumTrackingTypes()
        local boolean = false
        for i = 1, numTrackingTypes, 1 do
            local name, _, active = API_GetTrackingInfo(i)
            if name and name == spellName then
                boolean = (active == 1)
                break
            end
        end
        return __Condition.TestBoolean(boolean, yesno)
    end

    __Condition.OvaleCondition:RegisterCondition("tracking", false, Tracking)
end
do
    local TravelTime = function(positionalParams, namedParams, state, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = __Condition.ParseCondition(positionalParams, namedParams, state, "target")
        local si = spellId and __Data.OvaleData.spellInfo[spellId]
        local travelTime = 0
        if si then
            travelTime = si.travel_time or si.max_travel_time or 0
        end
        if travelTime > 0 then
            local estimatedTravelTime = 1
            if travelTime < estimatedTravelTime then
                travelTime = estimatedTravelTime
            end
        end
        return __Condition.Compare(travelTime, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("traveltime", true, TravelTime)
    __Condition.OvaleCondition:RegisterCondition("maxtraveltime", true, TravelTime)
end
do
    local True = function(positionalParams, namedParams, state, atTime)
        return 0, INFINITY
    end

    __Condition.OvaleCondition:RegisterCondition("true", false, True)
end
do
    local WeaponDamage = function(positionalParams, namedParams, state, atTime)
        local hand = positionalParams[1]
        local comparator, limit
        local value = 0
        if hand == "offhand" or hand == "off" then
            comparator, limit = positionalParams[2], positionalParams[3]
            value = __PaperDoll.paperDollState.offHandWeaponDamage
        elseif hand == "mainhand" or hand == "main" then
            comparator, limit = positionalParams[2], positionalParams[3]
            value = __PaperDoll.paperDollState.mainHandWeaponDamage
        else
            comparator, limit = positionalParams[1], positionalParams[2]
            value = __PaperDoll.paperDollState.mainHandWeaponDamage
        end
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("weapondamage", false, WeaponDamage)
end
do
    local WeaponEnchantExpires = function(positionalParams, namedParams, state, atTime)
        local hand, seconds = positionalParams[1], positionalParams[2]
        seconds = seconds or 0
        local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = API_GetWeaponEnchantInfo()
        local now = API_GetTime()
        if hand == "mainhand" or hand == "main" then
            if hasMainHandEnchant then
                mainHandExpiration = mainHandExpiration / 1000
                return now + mainHandExpiration - seconds, INFINITY
            end
        elseif hand == "offhand" or hand == "off" then
            if hasOffHandEnchant then
                offHandExpiration = offHandExpiration / 1000
                return now + offHandExpiration - seconds, INFINITY
            end
        end
        return 0, INFINITY
    end

    __Condition.OvaleCondition:RegisterCondition("weaponenchantexpires", false, WeaponEnchantExpires)
end
do
    local SigilCharging = function(positionalParams, namedParams, state, atTime)
        local charging = false
        for _, v in _ipairs(positionalParams) do
            charging = charging or __DemonHunterSigils.sigilState:IsSigilCharging(v, atTime)
        end
        return __Condition.TestBoolean(charging, "yes")
    end

    __Condition.OvaleCondition:RegisterCondition("sigilcharging", false, SigilCharging)
end
do
    local IsBossFight = function(positionalParams, namedParams, state, atTime)
        local bossEngaged = state.inCombat and __BossMod.OvaleBossMod:IsBossEngaged(state)
        return __Condition.TestBoolean(bossEngaged, "yes")
    end

    __Condition.OvaleCondition:RegisterCondition("isbossfight", false, IsBossFight)
end
do
    local Race = function(positionalParams, namedParams, state, atTime)
        local isRace = false
        local target = namedParams.target or "player"
        local _, targetRaceId = API_UnitRace(target)
        for _, v in _ipairs(positionalParams) do
            isRace = isRace or (v == targetRaceId)
        end
        return __Condition.TestBoolean(isRace, "yes")
    end

    __Condition.OvaleCondition:RegisterCondition("race", false, Race)
end
do
    local UnitInRaid = function(positionalParams, namedParams, state, atTime)
        local target = namedParams.target or "player"
        local raidIndex = API_UnitInRaid(target)
        return __Condition.TestBoolean(raidIndex ~= nil, "yes")
    end

    __Condition.OvaleCondition:RegisterCondition("unitinraid", false, UnitInRaid)
end
do
    local SoulFragments = function(positionalParams, namedParams, state, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = __DemonHunterSoulFragments.demonHunterSoulFragmentsState:SoulFragments(atTime)
        return __Condition.Compare(value, comparator, limit)
    end

    __Condition.OvaleCondition:RegisterCondition("soulfragments", false, SoulFragments)
end
end)
