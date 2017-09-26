import __addon from "addon";
let [OVALE, Ovale] = __addon;
let LibBabbleCreatureType = LibStub("LibBabble-CreatureType-3.0", true);
let LibRangeCheck = LibStub("LibRangeCheck-2.0", true);
import { OvaleBestAction } from "./OvaleBestAction";
import { OvaleCompile } from "./OvaleCompile";
import { OvaleCondition } from "./OvaleCondition";
import { OvaleCooldown } from "./OvaleCooldown";
import { OvaleDamageTaken } from "./OvaleDamageTaken";
import { OvaleData } from "./OvaleData";
import { OvaleEquipment } from "./OvaleEquipment";
import { OvaleFuture } from "./OvaleFuture";
import { OvaleGUID } from "./OvaleGUID";
import { OvaleHealth } from "./OvaleHealth";
import { OvalePower } from "./OvalePower";
import { OvaleRunes } from "./OvaleRunes";
import { OvaleSpellBook } from "./OvaleSpellBook";
import { OvaleSpellDamage } from "./OvaleSpellDamage";
import { OvaleArtifact } from "./OvaleArtifact";
import { OvaleBossMod } from "./OvaleBossMod";
let floor = math.floor;
let _ipairs = ipairs;
let _pairs = pairs;
let _tonumber = tonumber;
let _tostring = tostring;
let _type = type;
let _wipe = wipe;
let API_GetBuildInfo = GetBuildInfo;
let API_GetItemCooldown = GetItemCooldown;
let API_GetItemCount = GetItemCount;
let API_GetNumTrackingTypes = GetNumTrackingTypes;
let API_GetTime = GetTime;
let API_GetTrackingInfo = GetTrackingInfo;
let API_GetUnitSpeed = GetUnitSpeed;
let API_GetWeaponEnchantInfo = GetWeaponEnchantInfo;
let API_HasFullControl = HasFullControl;
let API_IsSpellOverlayed = IsSpellOverlayed;
let API_IsStealthed = IsStealthed;
let API_UnitCastingInfo = UnitCastingInfo;
let API_UnitChannelInfo = UnitChannelInfo;
let API_UnitClass = UnitClass;
let API_UnitClassification = UnitClassification;
let API_UnitCreatureFamily = UnitCreatureFamily;
let API_UnitCreatureType = UnitCreatureType;
let API_UnitDetailedThreatSituation = UnitDetailedThreatSituation;
let API_UnitExists = UnitExists;
let API_UnitInRaid = UnitInRaid;
let API_UnitIsDead = UnitIsDead;
let API_UnitIsFriend = UnitIsFriend;
let API_UnitIsPVP = UnitIsPVP;
let API_UnitIsUnit = UnitIsUnit;
let API_UnitLevel = UnitLevel;
let API_UnitName = UnitName;
let API_UnitPower = UnitPower;
let API_UnitPowerMax = UnitPowerMax;
let API_UnitRace = UnitRace;
let API_UnitStagger = UnitStagger;
let INFINITY = math.huge;
let Compare = OvaleCondition.Compare;
let ParseCondition = OvaleCondition.ParseCondition;
let TestBoolean = OvaleCondition.TestBoolean;
let TestValue = OvaleCondition.TestValue;
const BossArmorDamageReduction = function(target, state) {
    let armor = 24835;
    let constant = 4037.5 * state.level - 317117.5;
    if (constant < 0) {
        constant = 0;
    }
    return armor / (armor + constant);
}
const ComputeParameter = function(spellId, paramName, state, atTime) {
    let si = OvaleData.GetSpellInfo(spellId);
    if (si && si[paramName]) {
        let name = si[paramName];
        let node = OvaleCompile.GetFunctionNode(name);
        if (node) {
            let [timeSpan, element] = OvaleBestAction.Compute(node.child[1], state, atTime);
            if (element && element.type == "value") {
                let value = element.value + (state.currentTime - element.origin) * element.rate;
                return value;
            }
        } else {
            return si[paramName];
        }
    }
    return undefined;
}
const GetHastedTime = function(seconds, haste, state) {
    seconds = seconds || 0;
    let multiplier = state.GetHasteMultiplier(haste);
    return seconds / multiplier;
}
{
    const AfterWhiteHit = function(positionalParams, namedParams, state, atTime) {
        let [seconds, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 0;
        Ovale.OneTimeMessage("Warning: 'AfterWhiteHit()' is not implemented.");
        return TestValue(0, INFINITY, value, state.currentTime, -1, comparator, limit);
    }
}
{
    const ArmorSetBonus = function(positionalParams, namedParams, state, atTime) {
        let [armorSet, count] = [positionalParams[1], positionalParams[2]];
        let value = (OvaleEquipment.GetArmorSetCount(armorSet) >= count) && 1 || 0;
        return [0, INFINITY, value, 0, 0];
    }
    OvaleCondition.RegisterCondition("armorsetbonus", false, ArmorSetBonus);
}
{
    const ArmorSetParts = function(positionalParams, namedParams, state, atTime) {
        let [armorSet, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleEquipment.GetArmorSetCount(armorSet);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("armorsetparts", false, ArmorSetParts);
}
{
    const ArtifactTraitRank = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleArtifact.TraitRank(spellId);
        return Compare(value, comparator, limit);
    }
    const HasArtifactTrait = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let value = OvaleArtifact.HasTrait(spellId);
        return TestBoolean(value, yesno);
    }
    OvaleCondition.RegisterCondition("hasartifacttrait", false, HasArtifactTrait);
    OvaleCondition.RegisterCondition("artifacttraitrank", false, ArtifactTraitRank);
}
{
    const BaseDuration = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value;
        if ((OvaleData.buffSpellList[auraId])) {
            let spellList = OvaleData.buffSpellList[auraId];
            let count = 0;
            for (const [id] of _pairs(spellList)) {
                value = OvaleData.GetBaseDuration(id, state);
                if (value != math.huge) {
                    break;
                }
            }
        } else {
            value = OvaleData.GetBaseDuration(auraId, state);
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("baseduration", false, BaseDuration);
    OvaleCondition.RegisterCondition("buffdurationifapplied", false, BaseDuration);
    OvaleCondition.RegisterCondition("debuffdurationifapplied", false, BaseDuration);
}
{
    const BuffAmount = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let value = namedParams.value || 1;
        let statName = "value1";
        if (value == 1) {
            statName = "value1";
        } else if (value == 2) {
            statName = "value2";
        } else if (value == 3) {
            statName = "value3";
        }
        let aura = state.GetAura(target, auraId, filter, mine);
        if (state.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura[statName] || 0;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffamount", false, BuffAmount);
    OvaleCondition.RegisterCondition("debuffamount", false, BuffAmount);
    OvaleCondition.RegisterCondition("tickvalue", false, BuffAmount);
}
{
    const BuffComboPoints = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (state.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura && aura.combo || 0;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcombopoints", false, BuffComboPoints);
    OvaleCondition.RegisterCondition("debuffcombopoints", false, BuffComboPoints);
}
{
    const BuffCooldown = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let [gain, cooldownEnding] = [aura.gain, aura.cooldownEnding];
            cooldownEnding = aura.cooldownEnding || 0;
            return TestValue(gain, INFINITY, 0, cooldownEnding, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcooldown", false, BuffCooldown);
    OvaleCondition.RegisterCondition("debuffcooldown", false, BuffCooldown);
}
{
    const BuffCount = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let spellList = OvaleData.buffSpellList[auraId];
        let count = 0;
        for (const [id] of _pairs(spellList)) {
            let si = OvaleData.spellInfo[id];
            let aura = state.GetAura(target, id, filter, mine);
            if (state.IsActiveAura(aura, atTime)) {
                count = count + 1;
            }
        }
        return Compare(count, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcount", false, BuffCount);
}
{
    const BuffCooldownDuration = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let minCooldown = INFINITY;
        if (OvaleData.buffSpellList[auraId]) {
            for (const [id] of _pairs(OvaleData.buffSpellList[auraId])) {
                let si = OvaleData.spellInfo[id];
                let cd = si && si.buff_cd;
                if (cd && minCooldown > cd) {
                    minCooldown = cd;
                }
            }
        } else {
            minCooldown = 0;
        }
        return Compare(minCooldown, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcooldownduration", false, BuffCooldownDuration);
    OvaleCondition.RegisterCondition("debuffcooldownduration", false, BuffCooldownDuration);
}
{
    const BuffCountOnAny = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [_, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let excludeUnitId = (namedParams.excludeTarget == 1) && state.defaultTarget || undefined;
        let fractional = (namedParams.count == 0) && true || false;
        let [count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast] = state.AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId);
        if (count > 0 && startChangeCount < INFINITY && fractional) {
            let origin = startChangeCount;
            let rate = -1 / (endingChangeCount - startChangeCount);
            let [start, ending] = [startFirst, endingLast];
            return TestValue(start, ending, count, origin, rate, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcountonany", false, BuffCountOnAny);
    OvaleCondition.RegisterCondition("debuffcountonany", false, BuffCountOnAny);
}
{
    const BuffDirection = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let [gain, start, ending, direction] = [aura.gain, aura.start, aura.ending, aura.direction];
            return TestValue(gain, INFINITY, direction, gain, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffdirection", false, BuffDirection);
    OvaleCondition.RegisterCondition("debuffdirection", false, BuffDirection);
}
{
    const BuffDuration = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (state.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = ending - start;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffduration", false, BuffDuration);
    OvaleCondition.RegisterCondition("debuffduration", false, BuffDuration);
}
{
    const BuffExpires = function(positionalParams, namedParams, state, atTime) {
        let [auraId, seconds] = [positionalParams[1], positionalParams[2]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            seconds = GetHastedTime(seconds, namedParams.haste, state);
            if (ending - seconds <= gain) {
                return [gain, INFINITY];
            } else {
                return [ending - seconds, INFINITY];
            }
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("buffexpires", false, BuffExpires);
    OvaleCondition.RegisterCondition("debuffexpires", false, BuffExpires);
    const BuffPresent = function(positionalParams, namedParams, state, atTime) {
        let [auraId, seconds] = [positionalParams[1], positionalParams[2]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            seconds = GetHastedTime(seconds, namedParams.haste, state);
            if (ending - seconds <= gain) {
                return undefined;
            } else {
                return [gain, ending - seconds];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("buffpresent", false, BuffPresent);
    OvaleCondition.RegisterCondition("debuffpresent", false, BuffPresent);
}
{
    const BuffGain = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let gain = aura.gain || 0;
            return TestValue(gain, INFINITY, 0, gain, 1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffgain", false, BuffGain);
    OvaleCondition.RegisterCondition("debuffgain", false, BuffGain);
}
{
    const BuffPersistentMultiplier = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (state.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura.damageMultiplier || 1;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffpersistentmultiplier", false, BuffPersistentMultiplier);
    OvaleCondition.RegisterCondition("debuffpersistentmultiplier", false, BuffPersistentMultiplier);
}
{
    const BuffRemaining = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffremaining", false, BuffRemaining);
    OvaleCondition.RegisterCondition("debuffremaining", false, BuffRemaining);
    OvaleCondition.RegisterCondition("buffremains", false, BuffRemaining);
    OvaleCondition.RegisterCondition("debuffremains", false, BuffRemaining);
}
{
    const BuffRemainingOnAny = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [_, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let excludeUnitId = (namedParams.excludeTarget == 1) && state.defaultTarget || undefined;
        let [count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast] = state.AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId);
        if (count > 0) {
            let [start, ending] = [startFirst, endingLast];
            return TestValue(start, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffremainingonany", false, BuffRemainingOnAny);
    OvaleCondition.RegisterCondition("debuffremainingonany", false, BuffRemainingOnAny);
    OvaleCondition.RegisterCondition("buffremainsonany", false, BuffRemainingOnAny);
    OvaleCondition.RegisterCondition("debuffremainsonany", false, BuffRemainingOnAny);
}
{
    const BuffStacks = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (state.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura.stacks || 0;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffstacks", false, BuffStacks);
    OvaleCondition.RegisterCondition("debuffstacks", false, BuffStacks);
}
{
    const BuffStacksOnAny = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [_, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let excludeUnitId = (namedParams.excludeTarget == 1) && state.defaultTarget || undefined;
        let [count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast] = state.AuraCount(auraId, filter, mine, 1, atTime, excludeUnitId);
        if (count > 0) {
            let [start, ending] = [startFirst, endingChangeCount];
            return TestValue(start, ending, stacks, start, 0, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffstacksonany", false, BuffStacksOnAny);
    OvaleCondition.RegisterCondition("debuffstacksonany", false, BuffStacksOnAny);
}
{
    const BuffStealable = function(positionalParams, namedParams, state, atTime) {
        let target = ParseCondition(positionalParams, namedParams, state);
        return state.GetAuraWithProperty(target, "stealable", "HELPFUL", atTime);
    }
    OvaleCondition.RegisterCondition("buffstealable", false, BuffStealable);
}
{
    const CanCast = function(positionalParams, namedParams, state, atTime) {
        let spellId = positionalParams[1];
        let [start, duration] = state.GetSpellCooldown(spellId);
        return [start + duration, INFINITY];
    }
    OvaleCondition.RegisterCondition("cancast", true, CanCast);
}
{
    const CastTime = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
        return Compare(castTime, comparator, limit);
    }
    const ExecuteTime = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
        let gcd = state.GetGCD();
        let t = (castTime > gcd) && castTime || gcd;
        return Compare(t, comparator, limit);
    }
    OvaleCondition.RegisterCondition("casttime", true, CastTime);
    OvaleCondition.RegisterCondition("executetime", true, ExecuteTime);
}
{
    const Casting = function(positionalParams, namedParams, state, atTime) {
        let spellId = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let [start, ending, castSpellId, castSpellName];
        if (target == "player") {
            start = state.startCast;
            ending = state.endCast;
            castSpellId = state.currentSpellId;
            castSpellName = OvaleSpellBook.GetSpellName(castSpellId);
        } else {
            let [spellName, _, _, _, startTime, endTime] = API_UnitCastingInfo(target);
            if (!spellName) {
                [spellName, _, _, _, startTime, endTime] = API_UnitChannelInfo(target);
            }
            if (spellName) {
                castSpellName = spellName;
                start = startTime / 1000;
                ending = endTime / 1000;
            }
        }
        if (castSpellId || castSpellName) {
            if (!spellId) {
                return [start, ending];
            } else if (OvaleData.buffSpellList[spellId]) {
                for (const [id] of _pairs(OvaleData.buffSpellList[spellId])) {
                    if (id == castSpellId || OvaleSpellBook.GetSpellName(id) == castSpellName) {
                        return [start, ending];
                    }
                }
            } else if (spellId == "harmful" && OvaleSpellBook.IsHarmfulSpell(spellId)) {
                return [start, ending];
            } else if (spellId == "helpful" && OvaleSpellBook.IsHelpfulSpell(spellId)) {
                return [start, ending];
            } else if (spellId == castSpellId) {
                return [start, ending];
            } else if (_type(spellId) == "number" && OvaleSpellBook.GetSpellName(spellId) == castSpellName) {
                return [start, ending];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("casting", false, Casting);
}
{
    const CheckBoxOff = function(positionalParams, namedParams, state, atTime) {
        for (const [_, id] of _ipairs(positionalParams)) {
            if (Ovale.IsChecked(id)) {
                return undefined;
            }
        }
        return [0, INFINITY];
    }
    const CheckBoxOn = function(positionalParams, namedParams, state, atTime) {
        for (const [_, id] of _ipairs(positionalParams)) {
            if (!Ovale.IsChecked(id)) {
                return undefined;
            }
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("checkboxoff", false, CheckBoxOff);
    OvaleCondition.RegisterCondition("checkboxon", false, CheckBoxOn);
}
{
    const Class = function(positionalParams, namedParams, state, atTime) {
        let [class, yesno] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let [_, classToken] = API_UnitClass(target);
        let boolean = (classToken == class);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("class", false, Class);
}
{
    let IMBUED_BUFF_ID = 214336;
    const Classification = function(positionalParams, namedParams, state, atTime) {
        let [classification, yesno] = [positionalParams[1], positionalParams[2]];
        let targetClassification;
        let target = ParseCondition(positionalParams, namedParams, state);
        if (API_UnitLevel(target) < 0) {
            targetClassification = "worldboss";
        } else if (API_UnitExists("boss1") && OvaleGUID.UnitGUID(target) == OvaleGUID.UnitGUID("boss1")) {
            targetClassification = "worldboss";
        } else {
            let aura = state.GetAura(target, IMBUED_BUFF_ID, "debuff", false);
            if (state.IsActiveAura(aura, atTime)) {
                targetClassification = "worldboss";
            } else {
                targetClassification = API_UnitClassification(target);
                if (targetClassification == "rareelite") {
                    targetClassification = "elite";
                } else if (targetClassification == "rare") {
                    targetClassification = "normal";
                }
            }
        }
        let boolean = (targetClassification == classification);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("classification", false, Classification);
}
{
    const ComboPoints = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.combo;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("combopoints", false, ComboPoints);
}
{
    const Counter = function(positionalParams, namedParams, state, atTime) {
        let [counter, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = state.GetCounterValue(counter);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("counter", false, Counter);
}
{
    const CreatureFamily = function(positionalParams, namedParams, state, atTime) {
        let [name, yesno] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let family = API_UnitCreatureFamily(target);
        let lookupTable = LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        let boolean = (lookupTable && family == lookupTable[name]);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("creaturefamily", false, CreatureFamily);
}
{
    const CreatureType = function(positionalParams, namedParams, state, atTime) {
        let target = ParseCondition(positionalParams, namedParams, state);
        let creatureType = API_UnitCreatureType(target);
        let lookupTable = LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        if (lookupTable) {
            for (const [_, name] of _ipairs(positionalParams)) {
                if (creatureType == lookupTable[name]) {
                    return [0, INFINITY];
                }
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("creaturetype", false, CreatureType);
}
{
    let AMPLIFICATION = 146051;
    let INCREASED_CRIT_EFFECT_3_PERCENT = 44797;
    const CritDamage = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let value = ComputeParameter(spellId, "damage", state, atTime) || 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - BossArmorDamageReduction(target));
        }
        let critMultiplier = 2;
        {
            let aura = state.GetAura("player", AMPLIFICATION, "HELPFUL");
            if (state.IsActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier + aura.value1;
            }
        }
        {
            let aura = state.GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, "HELPFUL");
            if (state.IsActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier * aura.value1;
            }
        }
        value = critMultiplier * value;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("critdamage", false, CritDamage);
    const Damage = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let value = ComputeParameter(spellId, "damage", state, atTime) || 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - BossArmorDamageReduction(target));
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("damage", false, Damage);
}
{
    const DamageTaken = function(positionalParams, namedParams, state, atTime) {
        let [interval, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 0;
        if (interval > 0) {
            let [total, totalMagic] = OvaleDamageTaken.GetRecentDamage(interval);
            if (namedParams.magic == 1) {
                value = totalMagic;
            } else if (namedParams.physical == 1) {
                value = total - totalMagic;
            } else {
                value = total;
            }
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("damagetaken", false, DamageTaken);
    OvaleCondition.RegisterCondition("incomingdamage", false, DamageTaken);
}
{
    const Demons = function(positionalParams, namedParams, state, atTime) {
        let [creatureId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = state.GetDemonsCount(creatureId, atTime);
        return Compare(value, comparator, limit);
    }
    const NotDeDemons = function(positionalParams, namedParams, state, atTime) {
        let [creatureId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = state.GetNotDemonicEmpoweredDemonsCount(creatureId, atTime);
        return Compare(value, comparator, limit);
    }
    const DemonDuration = function(positionalParams, namedParams, state, atTime) {
        let [creatureId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = state.GetRemainingDemonDuration(creatureId, atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("demons", false, Demons);
    OvaleCondition.RegisterCondition("notdedemons", false, NotDeDemons);
    OvaleCondition.RegisterCondition("demonduration", false, DemonDuration);
}
{
    let NECROTIC_PLAGUE_TALENT = 19;
    let NECROTIC_PLAGUE_DEBUFF = 155159;
    let BLOOD_PLAGUE_DEBUFF = 55078;
    let FROST_FEVER_DEBUFF = 55095;
    const GetDiseases = function(target, state) {
        let [npAura, bpAura, ffAura];
        let talented = (OvaleSpellBook.GetTalentPoints(NECROTIC_PLAGUE_TALENT) > 0);
        if (talented) {
            npAura = state.GetAura(target, NECROTIC_PLAGUE_DEBUFF, "HARMFUL", true);
        } else {
            bpAura = state.GetAura(target, BLOOD_PLAGUE_DEBUFF, "HARMFUL", true);
            ffAura = state.GetAura(target, FROST_FEVER_DEBUFF, "HARMFUL", true);
        }
        return [talented, npAura, bpAura, ffAura];
    }
    const DiseasesRemaining = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let [talented, npAura, bpAura, ffAura] = GetDiseases(target, state);
        let aura;
        if (talented && state.IsActiveAura(npAura, atTime)) {
            aura = npAura;
        } else if (!talented && state.IsActiveAura(bpAura, atTime) && state.IsActiveAura(ffAura, atTime)) {
            aura = (bpAura.ending < ffAura.ending) && bpAura || ffAura;
        }
        if (aura) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    const DiseasesTicking = function(positionalParams, namedParams, state, atTime) {
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let [talented, npAura, bpAura, ffAura] = GetDiseases(target, state);
        let [gain, start, ending];
        if (talented && npAura) {
            [gain, start, ending] = [npAura.gain, npAura.start, npAura.ending];
        } else if (!talented && bpAura && ffAura) {
            gain = (bpAura.gain > ffAura.gain) && bpAura.gain || ffAura.gain;
            start = (bpAura.start > ffAura.start) && bpAura.start || ffAura.start;
            ending = (bpAura.ending < ffAura.ending) && bpAura.ending || ffAura.ending;
        }
        if (gain && ending && ending > gain) {
            return [gain, ending];
        }
        return undefined;
    }
    const DiseasesAnyTicking = function(positionalParams, namedParams, state, atTime) {
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let [talented, npAura, bpAura, ffAura] = GetDiseases(target, state);
        let aura;
        if (talented && npAura) {
            aura = npAura;
        } else if (!talented && (bpAura || ffAura)) {
            aura = bpAura || ffAura;
            if (bpAura && ffAura) {
                aura = (bpAura.ending > ffAura.ending) && bpAura || ffAura;
            }
        }
        if (aura) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            if (ending > gain) {
                return [gain, ending];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("diseasesremaining", false, DiseasesRemaining);
    OvaleCondition.RegisterCondition("diseasesticking", false, DiseasesTicking);
    OvaleCondition.RegisterCondition("diseasesanyticking", false, DiseasesAnyTicking);
}
{
    const Distance = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let value = LibRangeCheck && LibRangeCheck.GetRange(target) || 0;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("distance", false, Distance);
}
{
    const Eclipse = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.eclipse;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("eclipse", false, Eclipse);
}
{
    const EclipseDir = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.eclipseDirection;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("eclipsedir", false, EclipseDir);
}
{
    const EclipseEnergy = function(positionalParams, namedParams, state, atTime) {
        let [seconds, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 0;
        Ovale.OneTimeMessage("Warning: 'EclipseEnergy()' is not implemented.");
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("eclipseenergy", false, EclipseEnergy);
}
{
    const Enemies = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.enemies;
        if (!value) {
            import { useTagged } from "./db";
            if (namedParams.tagged == 0) {
                useTagged = false;
            } else if (namedParams.tagged == 1) {
                useTagged = true;
            }
            value = useTagged && state.taggedEnemies || state.activeEnemies;
        }
        if (value < 1) {
            value = 1;
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("enemies", false, Enemies);
}
{
    const EnergyRegenRate = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.powerRate.energy;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("energyregen", false, EnergyRegenRate);
    OvaleCondition.RegisterCondition("energyregenrate", false, EnergyRegenRate);
}
{
    const EnrageRemaining = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let [start, ending] = state.GetAuraWithProperty(target, "enrage", "HELPFUL", atTime);
        if (start && ending) {
            return TestValue(start, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("enrageremaining", false, EnrageRemaining);
}
{
    const Exists = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitExists(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("exists", false, Exists);
}
{
    const False = function(positionalParams, namedParams, state, atTime) {
        return undefined;
    }
    OvaleCondition.RegisterCondition("false", false, False);
}
{
    const FocusRegenRate = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.powerRate.focus;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("focusregen", false, FocusRegenRate);
    OvaleCondition.RegisterCondition("focusregenrate", false, FocusRegenRate);
}
{
    let STEADY_FOCUS = 177668;
    const FocusCastingRegen = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let regenRate = state.powerRate.focus;
        let power = 0;
        let castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
        let gcd = state.GetGCD();
        let castSeconds = (castTime > gcd) && castTime || gcd;
        power = power + regenRate * castSeconds;
        let aura = state.GetAura("player", STEADY_FOCUS, "HELPFUL", true);
        if (aura) {
            let seconds = aura.ending - state.currentTime;
            if (seconds <= 0) {
                seconds = 0;
            } else if (seconds > castSeconds) {
                seconds = castSeconds;
            }
            power = power + regenRate * 1.5 * seconds;
        }
        return Compare(power, comparator, limit);
    }
    OvaleCondition.RegisterCondition("focuscastingregen", false, FocusCastingRegen);
}
{
    const GCD = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.GetGCD();
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("gcd", false, GCD);
}
{
    const GCDRemaining = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        if (state.lastSpellId) {
            let duration = state.GetGCD(state.lastSpellId, atTime, OvaleGUID.UnitGUID(target));
            let spellcast = OvaleFuture.LastInFlightSpell();
            let start = (spellcast && spellcast.start) || 0;
            let ending = start + duration;
            if (atTime < ending) {
                return TestValue(start, INFINITY, 0, ending, -1, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("gcdremaining", false, GCDRemaining);
}
{
    const GetState = function(positionalParams, namedParams, state, atTime) {
        let [name, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = state.GetState(name);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("getstate", false, GetState);
}
{
    const GetStateDuration = function(positionalParams, namedParams, state, atTime) {
        let [name, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = state.GetStateDuration(name);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("getstateduration", false, GetStateDuration);
}
{
    const Glyph = function(positionalParams, namedParams, state, atTime) {
        let [stub, yesno] = [positionalParams[1], positionalParams[2]];
        return TestBoolean(false, yesno);
    }
    OvaleCondition.RegisterCondition("glyph", false, Glyph);
}
{
    const HasEquippedItem = function(positionalParams, namedParams, state, atTime) {
        let [itemId, yesno] = [positionalParams[1], positionalParams[2]];
        let [ilevel, slot] = [namedParams.ilevel, namedParams.slot];
        let boolean = false;
        let slotId;
        if (_type(itemId) == "number") {
            slotId = OvaleEquipment.HasEquippedItem(itemId, slot);
            if (slotId) {
                if (!ilevel || (ilevel && ilevel == OvaleEquipment.GetEquippedItemLevel(slotId))) {
                    boolean = true;
                }
            }
        } else if (OvaleData.itemList[itemId]) {
            for (const [_, v] of _pairs(OvaleData.itemList[itemId])) {
                slotId = OvaleEquipment.HasEquippedItem(v, slot);
                if (slotId) {
                    if (!ilevel || (ilevel && ilevel == OvaleEquipment.GetEquippedItemLevel(slotId))) {
                        boolean = true;
                        break;
                    }
                }
            }
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasequippeditem", false, HasEquippedItem);
}
{
    const HasFullControl = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let boolean = API_HasFullControl();
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasfullcontrol", false, HasFullControl);
}
{
    const HasShield = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let boolean = OvaleEquipment.HasShield();
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasshield", false, HasShield);
}
{
    const HasTrinket = function(positionalParams, namedParams, state, atTime) {
        let [trinketId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = false;
        if (_type(trinketId) == "number") {
            boolean = OvaleEquipment.HasTrinket(trinketId);
        } else if (OvaleData.itemList[trinketId]) {
            for (const [_, v] of _pairs(OvaleData.itemList[trinketId])) {
                boolean = OvaleEquipment.HasTrinket(v);
                if (boolean) {
                    break;
                }
            }
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hastrinket", false, HasTrinket);
}
{
    const HasWeapon = function(positionalParams, namedParams, state, atTime) {
        let [hand, yesno] = [positionalParams[1], positionalParams[2]];
        let weaponType = namedParams.type;
        let boolean = false;
        if (weaponType == "one_handed") {
            weaponType = 1;
        } else if (weaponType == "two_handed") {
            weaponType = 2;
        }
        if (hand == "offhand" || hand == "off") {
            boolean = OvaleEquipment.HasOffHandWeapon(weaponType);
        } else if (hand == "mainhand" || hand == "main") {
            boolean = OvaleEquipment.HasMainHandWeapon(weaponType);
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasweapon", false, HasWeapon);
}
{
    const Health = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            let now = API_GetTime();
            let timeToDie = OvaleHealth.UnitTimeToDie(target);
            let [value, origin, rate] = [health, now, -1 * health / timeToDie];
            let [start, ending] = [now, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("health", false, Health);
    OvaleCondition.RegisterCondition("life", false, Health);
    const HealthMissing = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
        if (health > 0) {
            let now = API_GetTime();
            let missing = maxHealth - health;
            let timeToDie = OvaleHealth.UnitTimeToDie(target);
            let [value, origin, rate] = [missing, now, health / timeToDie];
            let [start, ending] = [now, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(maxHealth, comparator, limit);
    }
    OvaleCondition.RegisterCondition("healthmissing", false, HealthMissing);
    OvaleCondition.RegisterCondition("lifemissing", false, HealthMissing);
    const HealthPercent = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            let now = API_GetTime();
            let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
            let healthPercent = health / maxHealth * 100;
            let timeToDie = OvaleHealth.UnitTimeToDie(target);
            let [value, origin, rate] = [healthPercent, now, -1 * healthPercent / timeToDie];
            let [start, ending] = [now, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("healthpercent", false, HealthPercent);
    OvaleCondition.RegisterCondition("lifepercent", false, HealthPercent);
    const TimeToHealthPercent = function(positionalParams, namedParams, state, atTime) {
        let [percent, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let now = API_GetTime();
        let health = OvaleHealth.UnitHealth(target) || 0;
        let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
        let healthPercent = health / maxHealth * 100;
        let timeToDie = OvaleHealth.UnitTimeToDie(target);
        let timeToPercent = timeToDie / healthPercent * (healthPercent - percent);
        if (timeToPercent < 0) {
            timeToPercent = 0;
        }
        let [value, origin, rate] = [timeToPercent, now, -1];
        let [start, ending] = [now, now + timeToPercent];
        return TestValue(start, ending, value, origin, rate, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetohealthpercent", false, TimeToHealthPercent);
    const MaxHealth = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let value = OvaleHealth.UnitHealthMax(target);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("maxhealth", false, MaxHealth);
    const TimeToDie = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let now = API_GetTime();
        let timeToDie = OvaleHealth.UnitTimeToDie(target);
        let [value, origin, rate] = [timeToDie, now, -1];
        let [start, ending] = [now, now + timeToDie];
        return TestValue(start, ending, value, origin, rate, comparator, limit);
    }
    OvaleCondition.RegisterCondition("deadin", false, TimeToDie);
    OvaleCondition.RegisterCondition("timetodie", false, TimeToDie);
    const TimeToHealthPercent = function(positionalParams, namedParams, state, atTime) {
        let [percent, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
            let healthPercent = health / maxHealth * 100;
            if (healthPercent >= percent) {
                let now = API_GetTime();
                let timeToDie = OvaleHealth.UnitTimeToDie(target);
                let t = timeToDie * (healthPercent - percent) / healthPercent;
                let [value, origin, rate] = [t, now, -1];
                let [start, ending] = [now, now + t];
                return TestValue(start, ending, value, origin, rate, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetohealthpercent", false, TimeToHealthPercent);
    OvaleCondition.RegisterCondition("timetolifepercent", false, TimeToHealthPercent);
}
{
    const InCombat = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let boolean = state.inCombat;
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("incombat", false, InCombat);
}
{
    const InFlightToTarget = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (state.currentSpellId == spellId) || OvaleFuture.InFlight(spellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("inflighttotarget", false, InFlightToTarget);
}
{
    const InRange = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = (OvaleSpellBook.IsSpellInRange(spellId, target) == 1);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("inrange", false, InRange);
}
{
    const IsAggroed = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitDetailedThreatSituation("player", target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isaggroed", false, IsAggroed);
}
{
    const IsDead = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitIsDead(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isdead", false, IsDead);
}
{
    const IsEnraged = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        return state.GetAuraWithProperty(target, "enrage", "HELPFUL", atTime);
    }
    OvaleCondition.RegisterCondition("isenraged", false, IsEnraged);
}
{
    const IsFeared = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let aura = state.GetAura("player", "fear_debuff", "HARMFUL");
        let boolean = !API_HasFullControl() && state.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isfeared", false, IsFeared);
}
{
    const IsFriend = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitIsFriend("player", target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isfriend", false, IsFriend);
}
{
    const IsIncapacitated = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let aura = state.GetAura("player", "incapacitate_debuff", "HARMFUL");
        let boolean = !API_HasFullControl() && state.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isincapacitated", false, IsIncapacitated);
}
{
    const IsInterruptible = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let [name, _, _, _, _, _, _, _, notInterruptible] = API_UnitCastingInfo(target);
        if (!name) {
            [name, _, _, _, _, _, _, notInterruptible] = API_UnitChannelInfo(target);
        }
        let boolean = notInterruptible != undefined && !notInterruptible;
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isinterruptible", false, IsInterruptible);
}
{
    const IsPVP = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitIsPVP(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("ispvp", false, IsPVP);
}
{
    const IsRooted = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let aura = state.GetAura("player", "root_debuff", "HARMFUL");
        let boolean = state.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isrooted", false, IsRooted);
}
{
    const IsStunned = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let aura = state.GetAura("player", "stun_debuff", "HARMFUL");
        let boolean = !API_HasFullControl() && state.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isstunned", false, IsStunned);
}
{
    const ItemCharges = function(positionalParams, namedParams, state, atTime) {
        let [itemId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = API_GetItemCount(itemId, false, true);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("itemcharges", false, ItemCharges);
}
{
    const ItemCooldown = function(positionalParams, namedParams, state, atTime) {
        let [itemId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        if (itemId && _type(itemId) != "number") {
            itemId = OvaleEquipment.GetEquippedItem(itemId);
        }
        if (itemId) {
            let [start, duration] = API_GetItemCooldown(itemId);
            if (start > 0 && duration > 0) {
                return TestValue(start, start + duration, duration, start, -1, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("itemcooldown", false, ItemCooldown);
}
{
    const ItemCount = function(positionalParams, namedParams, state, atTime) {
        let [itemId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = API_GetItemCount(itemId);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("itemcount", false, ItemCount);
}
{
    const LastDamage = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleSpellDamage.Get(spellId);
        if (value) {
            return Compare(value, comparator, limit);
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("lastdamage", false, LastDamage);
    OvaleCondition.RegisterCondition("lastspelldamage", false, LastDamage);
}
{
    const Level = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let value;
        if (target == "player") {
            value = state.level;
        } else {
            value = API_UnitLevel(target);
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("level", false, Level);
}
{
    const List = function(positionalParams, namedParams, state, atTime) {
        let [name, value] = [positionalParams[1], positionalParams[2]];
        if (name && Ovale.GetListValue(name) == value) {
            return [0, INFINITY];
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("list", false, List);
}
{
    const Name = function(positionalParams, namedParams, state, atTime) {
        let [name, yesno] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        if (_type(name) == "number") {
            name = OvaleSpellBook.GetSpellName(name);
        }
        let targetName = API_UnitName(target);
        let boolean = (name == targetName);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("name", false, Name);
}
{
    const PTR = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [_, _, _, uiVersion] = API_GetBuildInfo();
        let value = (uiVersion > 70200) && 1 || 0;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("ptr", false, PTR);
}
{
    const PersistentMultiplier = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let value = state.GetDamageMultiplier(spellId, OvaleGUID.UnitGUID(target), atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("persistentmultiplier", false, PersistentMultiplier);
}
{
    const PetPresent = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let name = namedParams.name;
        let target = "pet";
        let boolean = API_UnitExists(target) && !API_UnitIsDead(target) && (name == undefined || name == API_UnitName(target));
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("petpresent", false, PetPresent);
}
{
    const MaxPower = function(powerType, positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let value;
        if (target == "player") {
            value = OvalePower.maxPower[powerType];
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            value = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments);
        }
        return Compare(value, comparator, limit);
    }
    const Power = function(powerType, positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        if (target == "player") {
            let [value, origin, rate] = [state[powerType], state.currentTime, state.powerRate[powerType]];
            let [start, ending] = [state.currentTime, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            let value = API_UnitPower(target, powerInfo.id);
            return Compare(value, comparator, limit);
        }
    }
    const PowerDeficit = function(powerType, positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        if (target == "player") {
            let powerMax = OvalePower.maxPower[powerType] || 0;
            if (powerMax > 0) {
                let [value, origin, rate] = [powerMax - state[powerType], state.currentTime, -1 * state.powerRate[powerType]];
                let [start, ending] = [state.currentTime, INFINITY];
                return TestValue(start, ending, value, origin, rate, comparator, limit);
            }
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            let powerMax = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments) || 0;
            if (powerMax > 0) {
                let power = API_UnitPower(target, powerInfo.id);
                let value = powerMax - power;
                return Compare(value, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    const PowerPercent = function(powerType, positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        if (target == "player") {
            let powerMax = OvalePower.maxPower[powerType] || 0;
            if (powerMax > 0) {
                let conversion = 100 / powerMax;
                let [value, origin, rate] = [state[powerType] * conversion, state.currentTime, state.powerRate[powerType] * conversion];
                if (rate > 0 && value >= 100 || rate < 0 && value == 0) {
                    rate = 0;
                }
                let [start, ending] = [state.currentTime, INFINITY];
                return TestValue(start, ending, value, origin, rate, comparator, limit);
            }
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            let powerMax = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments) || 0;
            if (powerMax > 0) {
                let conversion = 100 / powerMax;
                let value = API_UnitPower(target, powerInfo.id) * conversion;
                return Compare(value, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    const PrimaryResource = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let primaryPowerType;
        let si = OvaleData.GetSpellInfo(spellId);
        if (si) {
            for (const [powerType] of _pairs(OvalePower.PRIMARY_POWER)) {
                if (si[powerType]) {
                    primaryPowerType = powerType;
                    break;
                }
            }
        }
        if (!primaryPowerType) {
            let [_, powerType] = OvalePower.GetSpellCost(spellId);
            if (powerType) {
                primaryPowerType = powerType;
            }
        }
        if (primaryPowerType) {
            let [value, origin, rate] = [state[primaryPowerType], state.currentTime, state.powerRate[primaryPowerType]];
            let [start, ending] = [state.currentTime, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("primaryresource", true, PrimaryResource);
    const AlternatePower = function(positionalParams, namedParams, state, atTime) {
        return Power("alternate", positionalParams, namedParams, state, atTime);
    }
    const AstralPower = function(positionalParams, namedParams, state, atTime) {
        return Power("astralpower", positionalParams, namedParams, state, atTime);
    }
    const Chi = function(positionalParams, namedParams, state, atTime) {
        return Power("chi", positionalParams, namedParams, state, atTime);
    }
    const Energy = function(positionalParams, namedParams, state, atTime) {
        return Power("energy", positionalParams, namedParams, state, atTime);
    }
    const Focus = function(positionalParams, namedParams, state, atTime) {
        return Power("focus", positionalParams, namedParams, state, atTime);
    }
    const Fury = function(positionalParams, namedParams, state, atTime) {
        return Power("fury", positionalParams, namedParams, state, atTime);
    }
    const HolyPower = function(positionalParams, namedParams, state, atTime) {
        return Power("holy", positionalParams, namedParams, state, atTime);
    }
    const Insanity = function(positionalParams, namedParams, state, atTime) {
        return Power("insanity", positionalParams, namedParams, state, atTime);
    }
    const Mana = function(positionalParams, namedParams, state, atTime) {
        return Power("mana", positionalParams, namedParams, state, atTime);
    }
    const Maelstrom = function(positionalParams, namedParams, state, atTime) {
        return Power("maelstrom", positionalParams, namedParams, state, atTime);
    }
    const Pain = function(positionalParams, namedParams, state, atTime) {
        return Power("pain", positionalParams, namedParams, state, atTime);
    }
    const Rage = function(positionalParams, namedParams, state, atTime) {
        return Power("rage", positionalParams, namedParams, state, atTime);
    }
    const RunicPower = function(positionalParams, namedParams, state, atTime) {
        return Power("runicpower", positionalParams, namedParams, state, atTime);
    }
    const ShadowOrbs = function(positionalParams, namedParams, state, atTime) {
        return Power("shadoworbs", positionalParams, namedParams, state, atTime);
    }
    const SoulShards = function(positionalParams, namedParams, state, atTime) {
        return Power("soulshards", positionalParams, namedParams, state, atTime);
    }
    const ArcaneCharges = function(positionalParams, namedParams, state, atTime) {
        return Power("arcanecharges", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("alternatepower", false, AlternatePower);
    OvaleCondition.RegisterCondition("arcanecharges", false, ArcaneCharges);
    OvaleCondition.RegisterCondition("astralpower", false, AstralPower);
    OvaleCondition.RegisterCondition("chi", false, Chi);
    OvaleCondition.RegisterCondition("energy", false, Energy);
    OvaleCondition.RegisterCondition("focus", false, Focus);
    OvaleCondition.RegisterCondition("fury", false, Fury);
    OvaleCondition.RegisterCondition("holypower", false, HolyPower);
    OvaleCondition.RegisterCondition("insanity", false, Insanity);
    OvaleCondition.RegisterCondition("maelstrom", false, Maelstrom);
    OvaleCondition.RegisterCondition("mana", false, Mana);
    OvaleCondition.RegisterCondition("pain", false, Pain);
    OvaleCondition.RegisterCondition("rage", false, Rage);
    OvaleCondition.RegisterCondition("runicpower", false, RunicPower);
    OvaleCondition.RegisterCondition("shadoworbs", false, ShadowOrbs);
    OvaleCondition.RegisterCondition("soulshards", false, SoulShards);
    const AlternatePowerDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("alternatepower", positionalParams, namedParams, state, atTime);
    }
    const AstralPowerDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("astralpower", positionalParams, namedParams, state, atTime);
    }
    const ChiDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("chi", positionalParams, namedParams, state, atTime);
    }
    const ComboPointsDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("combopoints", positionalParams, namedParams, state, atTime);
    }
    const EnergyDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("energy", positionalParams, namedParams, state, atTime);
    }
    const FocusDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("focus", positionalParams, namedParams, state, atTime);
    }
    const FuryDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("fury", positionalParams, namedParams, state, atTime);
    }
    const HolyPowerDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("holypower", positionalParams, namedParams, state, atTime);
    }
    const ManaDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("mana", positionalParams, namedParams, state, atTime);
    }
    const PainDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("pain", positionalParams, namedParams, state, atTime);
    }
    const RageDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("rage", positionalParams, namedParams, state, atTime);
    }
    const RunicPowerDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("runicpower", positionalParams, namedParams, state, atTime);
    }
    const ShadowOrbsDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("shadoworbs", positionalParams, namedParams, state, atTime);
    }
    const SoulShardsDeficit = function(positionalParams, namedParams, state, atTime) {
        return PowerDeficit("soulshards", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("alternatepowerdeficit", false, AlternatePowerDeficit);
    OvaleCondition.RegisterCondition("astralpowerdeficit", false, AstralPowerDeficit);
    OvaleCondition.RegisterCondition("chideficit", false, ChiDeficit);
    OvaleCondition.RegisterCondition("combopointsdeficit", false, ComboPointsDeficit);
    OvaleCondition.RegisterCondition("energydeficit", false, EnergyDeficit);
    OvaleCondition.RegisterCondition("focusdeficit", false, FocusDeficit);
    OvaleCondition.RegisterCondition("furydeficit", false, FuryDeficit);
    OvaleCondition.RegisterCondition("holypowerdeficit", false, HolyPowerDeficit);
    OvaleCondition.RegisterCondition("manadeficit", false, ManaDeficit);
    OvaleCondition.RegisterCondition("paindeficit", false, PainDeficit);
    OvaleCondition.RegisterCondition("ragedeficit", false, RageDeficit);
    OvaleCondition.RegisterCondition("runicpowerdeficit", false, RunicPowerDeficit);
    OvaleCondition.RegisterCondition("shadoworbsdeficit", false, ShadowOrbsDeficit);
    OvaleCondition.RegisterCondition("soulshardsdeficit", false, SoulShardsDeficit);
    const ManaPercent = function(positionalParams, namedParams, state, atTime) {
        return PowerPercent("mana", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("manapercent", false, ManaPercent);
    const MaxAlternatePower = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("alternate", positionalParams, namedParams, state, atTime);
    }
    const MaxChi = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("chi", positionalParams, namedParams, state, atTime);
    }
    const MaxComboPoints = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("combopoints", positionalParams, namedParams, state, atTime);
    }
    const MaxEnergy = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("energy", positionalParams, namedParams, state, atTime);
    }
    const MaxFocus = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("focus", positionalParams, namedParams, state, atTime);
    }
    const MaxFury = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("fury", positionalParams, namedParams, state, atTime);
    }
    const MaxHolyPower = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("holy", positionalParams, namedParams, state, atTime);
    }
    const MaxMana = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("mana", positionalParams, namedParams, state, atTime);
    }
    const MaxPain = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("pain", positionalParams, namedParams, state, atTime);
    }
    const MaxRage = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("rage", positionalParams, namedParams, state, atTime);
    }
    const MaxRunicPower = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("runicpower", positionalParams, namedParams, state, atTime);
    }
    const MaxShadowOrbs = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("shadoworbs", positionalParams, namedParams, state, atTime);
    }
    const MaxSoulShards = function(positionalParams, namedParams, state, atTime) {
        return MaxPower("soulshards", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("maxalternatepower", false, MaxAlternatePower);
    OvaleCondition.RegisterCondition("maxchi", false, MaxChi);
    OvaleCondition.RegisterCondition("maxcombopoints", false, MaxComboPoints);
    OvaleCondition.RegisterCondition("maxenergy", false, MaxEnergy);
    OvaleCondition.RegisterCondition("maxfocus", false, MaxFocus);
    OvaleCondition.RegisterCondition("maxfury", false, MaxFury);
    OvaleCondition.RegisterCondition("maxholypower", false, MaxHolyPower);
    OvaleCondition.RegisterCondition("maxmana", false, MaxMana);
    OvaleCondition.RegisterCondition("maxpain", false, MaxPain);
    OvaleCondition.RegisterCondition("maxrage", false, MaxRage);
    OvaleCondition.RegisterCondition("maxrunicpower", false, MaxRunicPower);
    OvaleCondition.RegisterCondition("maxshadoworbs", false, MaxShadowOrbs);
    OvaleCondition.RegisterCondition("maxsoulshards", false, MaxSoulShards);
}
{
    const PowerCost = function(powerType, positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let maxCost = (namedParams.max == 1);
        let value = state.PowerCost(spellId, powerType, atTime, target, maxCost) || 0;
        return Compare(value, comparator, limit);
    }
    const EnergyCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost("energy", positionalParams, namedParams, state, atTime);
    }
    const FocusCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost("focus", positionalParams, namedParams, state, atTime);
    }
    const ManaCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost("mana", positionalParams, namedParams, state, atTime);
    }
    const RageCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost("rage", positionalParams, namedParams, state, atTime);
    }
    const RunicPowerCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost("runicpower", positionalParams, namedParams, state, atTime);
    }
    const AstralPowerCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost("astralpower", positionalParams, namedParams, state, atTime);
    }
    const MainPowerCost = function(positionalParams, namedParams, state, atTime) {
        return PowerCost(OvalePower.powerType, positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("powercost", true, MainPowerCost);
    OvaleCondition.RegisterCondition("astralpowercost", true, AstralPowerCost);
    OvaleCondition.RegisterCondition("energycost", true, EnergyCost);
    OvaleCondition.RegisterCondition("focuscost", true, FocusCost);
    OvaleCondition.RegisterCondition("manacost", true, ManaCost);
    OvaleCondition.RegisterCondition("ragecost", true, RageCost);
    OvaleCondition.RegisterCondition("runicpowercost", true, RunicPowerCost);
}
{
    const Present = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitExists(target) && !API_UnitIsDead(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("present", false, Present);
}
{
    const PreviousGCDSpell = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let count = namedParams.count;
        let boolean;
        if (count && count > 1) {
            boolean = (spellId == state.lastGCDSpellIds[lualength(state.lastGCDSpellIds) - count + 2]);
        } else {
            boolean = (spellId == state.lastGCDSpellId);
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("previousgcdspell", true, PreviousGCDSpell);
}
{
    const PreviousOffGCDSpell = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (spellId == state.lastOffGCDSpellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("previousoffgcdspell", true, PreviousOffGCDSpell);
}
{
    const PreviousSpell = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (spellId == state.lastSpellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("previousspell", true, PreviousSpell);
}
{
    const RelativeLevel = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let [value, level];
        if (target == "player") {
            level = state.level;
        } else {
            level = API_UnitLevel(target);
        }
        if (level < 0) {
            value = 3;
        } else {
            value = level - state.level;
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("relativelevel", false, RelativeLevel);
}
{
    const Refreshable = function(positionalParams, namedParams, state, atTime) {
        let auraId = positionalParams[1];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let baseDuration = OvaleData.GetBaseDuration(auraId);
            let extensionDuration = 0.3 * baseDuration;
            return [aura.ending - extensionDuration, INFINITY];
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("refreshable", false, Refreshable);
    OvaleCondition.RegisterCondition("debuffrefreshable", false, Refreshable);
    OvaleCondition.RegisterCondition("buffrefreshable", false, Refreshable);
}
{
    const RemainingCastTime = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let [_, _, _, _, startTime, endTime] = API_UnitCastingInfo(target);
        if (startTime && endTime) {
            startTime = startTime / 1000;
            endTime = endTime / 1000;
            return TestValue(startTime, endTime, 0, endTime, -1, comparator, limit);
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("remainingcasttime", false, RemainingCastTime);
}
{
    const Rune = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [count, startCooldown, endCooldown] = state.RuneCount(atTime);
        if (startCooldown < INFINITY) {
            let origin = startCooldown;
            let rate = 1 / (endCooldown - startCooldown);
            let [start, ending] = [startCooldown, INFINITY];
            return TestValue(start, ending, count, origin, rate, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }
    const RuneCount = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [count, startCooldown, endCooldown] = state.RuneCount(atTime);
        if (startCooldown < INFINITY) {
            let [start, ending] = [startCooldown, endCooldown];
            return TestValue(start, ending, count, start, 0, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }
    const TimeToRunes = function(positionalParams, namedParams, state, atTime) {
        let [runes, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let seconds = state.GetRunesCooldown(atTime, runes);
        if (seconds < 0) {
            seconds = 0;
        }
        return Compare(seconds, comparator, limit);
    }
    OvaleCondition.RegisterCondition("rune", false, Rune);
    OvaleCondition.RegisterCondition("runecount", false, RuneCount);
    OvaleCondition.RegisterCondition("timetorunes", false, TimeToRunes);
}
{
    const Snapshot = function(statName, defaultValue, positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state[statName] || defaultValue;
        return Compare(value, comparator, limit);
    }
    const SnapshotCritChance = function(statName, defaultValue, positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state[statName] || defaultValue;
        if (namedParams.unlimited != 1 && value > 100) {
            value = 100;
        }
        return Compare(value, comparator, limit);
    }
    const Agility = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("agility", 0, positionalParams, namedParams, state, atTime);
    }
    const AttackPower = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("attackPower", 0, positionalParams, namedParams, state, atTime);
    }
    const CritRating = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("critRating", 0, positionalParams, namedParams, state, atTime);
    }
    const HasteRating = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("hasteRating", 0, positionalParams, namedParams, state, atTime);
    }
    const Intellect = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("intellect", 0, positionalParams, namedParams, state, atTime);
    }
    const MasteryEffect = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("masteryEffect", 0, positionalParams, namedParams, state, atTime);
    }
    const MasteryRating = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("masteryRating", 0, positionalParams, namedParams, state, atTime);
    }
    const MeleeCritChance = function(positionalParams, namedParams, state, atTime) {
        return SnapshotCritChance("meleeCrit", 0, positionalParams, namedParams, state, atTime);
    }
    const MeleeHaste = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("meleeHaste", 0, positionalParams, namedParams, state, atTime);
    }
    const MultistrikeChance = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("multistrike", 0, positionalParams, namedParams, state, atTime);
    }
    const RangedCritChance = function(positionalParams, namedParams, state, atTime) {
        return SnapshotCritChance("rangedCrit", 0, positionalParams, namedParams, state, atTime);
    }
    const SpellCritChance = function(positionalParams, namedParams, state, atTime) {
        return SnapshotCritChance("spellCrit", 0, positionalParams, namedParams, state, atTime);
    }
    const SpellHaste = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("spellHaste", 0, positionalParams, namedParams, state, atTime);
    }
    const Spellpower = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("spellBonusDamage", 0, positionalParams, namedParams, state, atTime);
    }
    const Spirit = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("spirit", 0, positionalParams, namedParams, state, atTime);
    }
    const Stamina = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("stamina", 0, positionalParams, namedParams, state, atTime);
    }
    const Strength = function(positionalParams, namedParams, state, atTime) {
        return Snapshot("strength", 0, positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("agility", false, Agility);
    OvaleCondition.RegisterCondition("attackpower", false, AttackPower);
    OvaleCondition.RegisterCondition("critrating", false, CritRating);
    OvaleCondition.RegisterCondition("hasterating", false, HasteRating);
    OvaleCondition.RegisterCondition("intellect", false, Intellect);
    OvaleCondition.RegisterCondition("mastery", false, MasteryEffect);
    OvaleCondition.RegisterCondition("masteryeffect", false, MasteryEffect);
    OvaleCondition.RegisterCondition("masteryrating", false, MasteryRating);
    OvaleCondition.RegisterCondition("meleecritchance", false, MeleeCritChance);
    OvaleCondition.RegisterCondition("meleehaste", false, MeleeHaste);
    OvaleCondition.RegisterCondition("multistrikechance", false, MultistrikeChance);
    OvaleCondition.RegisterCondition("rangedcritchance", false, RangedCritChance);
    OvaleCondition.RegisterCondition("spellcritchance", false, SpellCritChance);
    OvaleCondition.RegisterCondition("spellhaste", false, SpellHaste);
    OvaleCondition.RegisterCondition("spellpower", false, Spellpower);
    OvaleCondition.RegisterCondition("spirit", false, Spirit);
    OvaleCondition.RegisterCondition("stamina", false, Stamina);
    OvaleCondition.RegisterCondition("strength", false, Strength);
}
{
    const Speed = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let value = API_GetUnitSpeed(target) * 100 / 7;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("speed", false, Speed);
}
{
    const SpellChargeCooldown = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [charges, maxCharges, start, duration] = state.GetSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            return TestValue(start, start + duration, duration, start, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellchargecooldown", true, SpellChargeCooldown);
}
{
    const SpellCharges = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [charges, maxCharges, start, duration] = state.GetSpellCharges(spellId, atTime);
        if (!charges) {
            return undefined;
        }
        charges = charges || 0;
        maxCharges = maxCharges || 1;
        if (namedParams.count == 0 && charges < maxCharges) {
            return TestValue(state.currentTime, INFINITY, charges + 1, start + duration, 1 / duration, comparator, limit);
        }
        return Compare(charges, comparator, limit);
    }
    OvaleCondition.RegisterCondition("charges", true, SpellCharges);
    OvaleCondition.RegisterCondition("spellcharges", true, SpellCharges);
}
{
    const SpellCooldown = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit];
        let usable = (namedParams.usable == 1);
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let earliest = INFINITY;
        for (const [i, spellId] of _ipairs(positionalParams)) {
            if (OvaleCondition.COMPARATOR[spellId]) {
                [comparator, limit] = [spellId, positionalParams[i + 1]];
                break;
            } else if (!usable || state.IsUsableSpell(spellId, atTime, OvaleGUID.UnitGUID(target))) {
                let [start, duration] = state.GetSpellCooldown(spellId);
                let t = 0;
                if (start > 0 && duration > 0) {
                    t = start + duration;
                }
                if (earliest > t) {
                    earliest = t;
                }
            }
        }
        if (earliest == INFINITY) {
            return Compare(0, comparator, limit);
        } else if (earliest > 0) {
            return TestValue(0, earliest, 0, earliest, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellcooldown", true, SpellCooldown);
}
{
    const SpellCooldownDuration = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let duration = state.GetSpellCooldownDuration(spellId, atTime, target);
        return Compare(duration, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellcooldownduration", true, SpellCooldownDuration);
}
{
    const SpellRechargeDuration = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let cd = state.GetCD(spellId);
        let duration = cd.chargeDuration || state.GetSpellCooldownDuration(spellId, atTime, target);
        return Compare(duration, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellrechargeduration", true, SpellRechargeDuration);
}
{
    const SpellData = function(positionalParams, namedParams, state, atTime) {
        let [spellId, key, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]];
        let si = OvaleData.spellInfo[spellId];
        if (si) {
            let value = si[key];
            if (value) {
                return Compare(value, comparator, limit);
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("spelldata", false, SpellData);
}
{
    const SpellInfoProperty = function(positionalParams, namedParams, state, atTime) {
        let [spellId, key, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]];
        let value = state.GetSpellInfoProperty(spellId, atTime, key);
        if (value) {
            return Compare(value, comparator, limit);
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("spellinfoproperty", false, SpellInfoProperty);
}
{
    const SpellCount = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let spellCount = OvaleSpellBook.GetSpellCount(spellId);
        return Compare(spellCount, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellcount", true, SpellCount);
}
{
    const SpellKnown = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = OvaleSpellBook.IsKnownSpell(spellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("spellknown", true, SpellKnown);
}
{
    const SpellMaxCharges = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [charges, maxCharges, start, duration] = state.GetSpellCharges(spellId, atTime);
        if (!maxCharges) {
            return undefined;
        }
        maxCharges = maxCharges || 1;
        return Compare(maxCharges, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellmaxcharges", true, SpellMaxCharges);
}
{
    const SpellUsable = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let [isUsable, noMana] = state.IsUsableSpell(spellId, atTime, OvaleGUID.UnitGUID(target));
        let boolean = isUsable || noMana;
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("spellusable", true, SpellUsable);
}
{
    let LIGHT_STAGGER = 124275;
    let MODERATE_STAGGER = 124274;
    let HEAVY_STAGGER = 124273;
    const StaggerRemaining = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, HEAVY_STAGGER, "HARMFUL");
        if (!state.IsActiveAura(aura, atTime)) {
            aura = state.GetAura(target, MODERATE_STAGGER, "HARMFUL");
        }
        if (!state.IsActiveAura(aura, atTime)) {
            aura = state.GetAura(target, LIGHT_STAGGER, "HARMFUL");
        }
        if (state.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let stagger = API_UnitStagger(target);
            let rate = -1 * stagger / (ending - start);
            return TestValue(gain, ending, 0, ending, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("staggerremaining", false, StaggerRemaining);
    OvaleCondition.RegisterCondition("staggerremains", false, StaggerRemaining);
}
{
    const Stance = function(positionalParams, namedParams, state, atTime) {
        let [stance, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = state.IsStance(stance);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("stance", false, Stance);
}
{
    const Stealthed = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let boolean = state.GetAura("player", "stealthed_buff") || API_IsStealthed();
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isstealthed", false, Stealthed);
    OvaleCondition.RegisterCondition("stealthed", false, Stealthed);
}
{
    const LastSwing = function(positionalParams, namedParams, state, atTime) {
        let swing = positionalParams[1];
        let [comparator, limit];
        let start;
        if (swing && swing == "main" || swing == "off") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            start = 0;
        } else {
            [comparator, limit] = [positionalParams[1], positionalParams[2]];
            start = 0;
        }
        Ovale.OneTimeMessage("Warning: 'LastSwing()' is not implemented.");
        return TestValue(start, INFINITY, 0, start, 1, comparator, limit);
    }
    const NextSwing = function(positionalParams, namedParams, state, atTime) {
        let swing = positionalParams[1];
        let [comparator, limit];
        let ending;
        if (swing && swing == "main" || swing == "off") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            ending = 0;
        } else {
            [comparator, limit] = [positionalParams[1], positionalParams[2]];
            ending = 0;
        }
        Ovale.OneTimeMessage("Warning: 'NextSwing()' is not implemented.");
        return TestValue(0, ending, 0, ending, -1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("lastswing", false, LastSwing);
    OvaleCondition.RegisterCondition("nextswing", false, NextSwing);
}
{
    const Talent = function(positionalParams, namedParams, state, atTime) {
        let [talentId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (OvaleSpellBook.GetTalentPoints(talentId) > 0);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("talent", false, Talent);
}
{
    const TalentPoints = function(positionalParams, namedParams, state, atTime) {
        let [talent, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleSpellBook.GetTalentPoints(talent);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("talentpoints", false, TalentPoints);
}
{
    const TargetIsPlayer = function(positionalParams, namedParams, state, atTime) {
        let yesno = positionalParams[1];
        let target = ParseCondition(positionalParams, namedParams, state);
        let boolean = API_UnitIsUnit("player", target + "target");
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("istargetingplayer", false, TargetIsPlayer);
    OvaleCondition.RegisterCondition("targetisplayer", false, TargetIsPlayer);
}
{
    const Threat = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let [_, _, value] = API_UnitDetailedThreatSituation("player", target);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("threat", false, Threat);
}
{
    const TickTime = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        let tickTime;
        if (state.IsActiveAura(aura, atTime)) {
            tickTime = aura.tick;
        } else {
            tickTime = OvaleData.GetTickLength(auraId, state);
        }
        if (tickTime && tickTime > 0) {
            return Compare(tickTime, comparator, limit);
        }
        return Compare(INFINITY, comparator, limit);
    }
    OvaleCondition.RegisterCondition("ticktime", false, TickTime);
}
{
    const TicksRemaining = function(positionalParams, namedParams, state, atTime) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = state.GetAura(target, auraId, filter, mine);
        if (aura) {
            let [gain, start, ending, tick] = [aura.gain, aura.start, aura.ending, aura.tick];
            if (tick && tick > 0) {
                return TestValue(gain, INFINITY, 1, ending, -1 / tick, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("ticksremaining", false, TicksRemaining);
    OvaleCondition.RegisterCondition("ticksremain", false, TicksRemaining);
}
{
    const TimeInCombat = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        if (state.inCombat) {
            let start = state.combatStartTime;
            return TestValue(start, INFINITY, 0, start, 1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timeincombat", false, TimeInCombat);
}
{
    const TimeSincePreviousSpell = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let t = state.TimeOfLastCast(spellId);
        return TestValue(0, INFINITY, 0, t, 1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timesincepreviousspell", false, TimeSincePreviousSpell);
}
{
    const TimeToBloodlust = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 3600;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetobloodlust", false, TimeToBloodlust);
}
{
    const TimeToEclipse = function(positionalParams, namedParams, state, atTime) {
        let [seconds, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 3600 * 24 * 7;
        Ovale.OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.");
        return TestValue(0, INFINITY, value, atTime, -1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetoeclipse", false, TimeToEclipse);
}
{
    const TimeToPower = function(powerType, level, comparator, limit, state, atTime) {
        let level = level || 0;
        let power = state[powerType] || 0;
        let powerRegen = state.powerRate[powerType] || 1;
        if (powerRegen == 0) {
            if (power == level) {
                return Compare(0, comparator, limit);
            }
            return Compare(INFINITY, comparator, limit);
        } else {
            let t = (level - power) / powerRegen;
            if (t > 0) {
                let ending = state.currentTime + t;
                return TestValue(0, ending, 0, ending, -1, comparator, limit);
            }
            return Compare(0, comparator, limit);
        }
    }
    const TimeToEnergy = function(positionalParams, namedParams, state, atTime) {
        let [level, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        return TimeToPower("energy", level, comparator, limit, state, atTime);
    }
    const TimeToMaxEnergy = function(positionalParams, namedParams, state, atTime) {
        let powerType = "energy";
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let level = OvalePower.maxPower[powerType] || 0;
        return TimeToPower(powerType, level, comparator, limit, state, atTime);
    }
    const TimeToFocus = function(positionalParams, namedParams, state, atTime) {
        let [level, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        return TimeToPower("focus", level, comparator, limit, state, atTime);
    }
    const TimeToMaxFocus = function(positionalParams, namedParams, state, atTime) {
        let powerType = "focus";
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let level = OvalePower.maxPower[powerType] || 0;
        return TimeToPower(powerType, level, comparator, limit, state, atTime);
    }
    OvaleCondition.RegisterCondition("timetoenergy", false, TimeToEnergy);
    OvaleCondition.RegisterCondition("timetofocus", false, TimeToFocus);
    OvaleCondition.RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy);
    OvaleCondition.RegisterCondition("timetomaxfocus", false, TimeToMaxFocus);
}
{
    const TimeToPowerFor = function(powerType, positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        if (!powerType) {
            let [_, pt] = OvalePower.GetSpellCost(spellId);
            powerType = pt;
        }
        let seconds = state.TimeToPower(spellId, atTime, OvaleGUID.UnitGUID(target), powerType);
        if (seconds == 0) {
            return Compare(0, comparator, limit);
        } else if (seconds < INFINITY) {
            return TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit);
        } else {
            return Compare(INFINITY, comparator, limit);
        }
    }
    const TimeToEnergyFor = function(positionalParams, namedParams, state, atTime) {
        return TimeToPowerFor("energy", positionalParams, namedParams, state, atTime);
    }
    const TimeToFocusFor = function(positionalParams, namedParams, state, atTime) {
        return TimeToPowerFor("focus", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("timetoenergyfor", true, TimeToEnergyFor);
    OvaleCondition.RegisterCondition("timetofocusfor", true, TimeToFocusFor);
}
{
    const TimeToSpell = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let seconds = state.GetTimeToSpell(spellId, atTime, OvaleGUID.UnitGUID(target));
        if (seconds == 0) {
            return Compare(0, comparator, limit);
        } else if (seconds < INFINITY) {
            return TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit);
        } else {
            return Compare(INFINITY, comparator, limit);
        }
    }
    OvaleCondition.RegisterCondition("timetospell", true, TimeToSpell);
}
{
    const TimeWithHaste = function(positionalParams, namedParams, state, atTime) {
        let [seconds, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let haste = namedParams.haste || "spell";
        let value = GetHastedTime(seconds, haste, state);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timewithhaste", false, TimeWithHaste);
}
{
    const TotemExpires = function(positionalParams, namedParams, state, atTime) {
        let [id, seconds] = [positionalParams[1], positionalParams[2]];
        seconds = seconds || 0;
        if (_type(id) == "string") {
            let [_, name, startTime, duration] = state.GetTotemInfo(id);
            if (startTime) {
                return [startTime + duration - seconds, INFINITY];
            }
        } else {
            let [count, start, ending] = state.GetTotemCount(id, atTime);
            if (count > 0) {
                return [ending - seconds, INFINITY];
            }
        }
        return [0, INFINITY];
    }
    const TotemPresent = function(positionalParams, namedParams, state, atTime) {
        let id = positionalParams[1];
        if (_type(id) == "string") {
            let [_, name, startTime, duration] = state.GetTotemInfo(id);
            if (startTime && duration > 0) {
                return [startTime, startTime + duration];
            }
        } else {
            let [count, start, ending] = state.GetTotemCount(id, atTime);
            if (count > 0) {
                return [start, ending];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("totemexpires", false, TotemExpires);
    OvaleCondition.RegisterCondition("totempresent", false, TotemPresent);
    const TotemRemaining = function(positionalParams, namedParams, state, atTime) {
        let [id, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        if (_type(id) == "string") {
            let [_, name, startTime, duration] = state.GetTotemInfo(id);
            if (startTime && duration > 0) {
                let [start, ending] = [startTime, startTime + duration];
                return TestValue(start, ending, 0, ending, -1, comparator, limit);
            }
        } else {
            let [count, start, ending] = state.GetTotemCount(id, atTime);
            if (count > 0) {
                return TestValue(start, ending, 0, ending, -1, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("totemremaining", false, TotemRemaining);
    OvaleCondition.RegisterCondition("totemremains", false, TotemRemaining);
}
{
    const Tracking = function(positionalParams, namedParams, state, atTime) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let spellName = OvaleSpellBook.GetSpellName(spellId);
        let numTrackingTypes = API_GetNumTrackingTypes();
        let boolean = false;
        for (let i = 1; i <= numTrackingTypes; i += 1) {
            let [name, _, active] = API_GetTrackingInfo(i);
            if (name && name == spellName) {
                boolean = (active == 1);
                break;
            }
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("tracking", false, Tracking);
}
{
    const TravelTime = function(positionalParams, namedParams, state, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let si = spellId && OvaleData.spellInfo[spellId];
        let travelTime = 0;
        if (si) {
            travelTime = si.travel_time || si.max_travel_time || 0;
        }
        if (travelTime > 0) {
            let estimatedTravelTime = 1;
            if (travelTime < estimatedTravelTime) {
                travelTime = estimatedTravelTime;
            }
        }
        return Compare(travelTime, comparator, limit);
    }
    OvaleCondition.RegisterCondition("traveltime", true, TravelTime);
    OvaleCondition.RegisterCondition("maxtraveltime", true, TravelTime);
}
{
    const True = function(positionalParams, namedParams, state, atTime) {
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("true", false, True);
}
{
    const WeaponDamage = function(positionalParams, namedParams, state, atTime) {
        let hand = positionalParams[1];
        let [comparator, limit];
        let value = 0;
        if (hand == "offhand" || hand == "off") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            value = state.offHandWeaponDamage;
        } else if (hand == "mainhand" || hand == "main") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            value = state.mainHandWeaponDamage;
        } else {
            [comparator, limit] = [positionalParams[1], positionalParams[2]];
            value = state.mainHandWeaponDamage;
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("weapondamage", false, WeaponDamage);
}
{
    const WeaponEnchantExpires = function(positionalParams, namedParams, state, atTime) {
        let [hand, seconds] = [positionalParams[1], positionalParams[2]];
        seconds = seconds || 0;
        let [hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration] = API_GetWeaponEnchantInfo();
        let now = API_GetTime();
        if (hand == "mainhand" || hand == "main") {
            if (hasMainHandEnchant) {
                mainHandExpiration = mainHandExpiration / 1000;
                return [now + mainHandExpiration - seconds, INFINITY];
            }
        } else if (hand == "offhand" || hand == "off") {
            if (hasOffHandEnchant) {
                offHandExpiration = offHandExpiration / 1000;
                return [now + offHandExpiration - seconds, INFINITY];
            }
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("weaponenchantexpires", false, WeaponEnchantExpires);
}
{
    const SigilCharging = function(positionalParams, namedParams, state, atTime) {
        let charging = false;
        for (const [_, v] of _ipairs(positionalParams)) {
            charging = charging || state.IsSigilCharging(v, atTime);
        }
        return TestBoolean(charging, "yes");
    }
    OvaleCondition.RegisterCondition("sigilcharging", false, SigilCharging);
}
{
    const IsBossFight = function(positionalParams, namedParams, state, atTime) {
        let bossEngaged = state.inCombat && OvaleBossMod.IsBossEngaged(state);
        return TestBoolean(bossEngaged, "yes");
    }
    OvaleCondition.RegisterCondition("isbossfight", false, IsBossFight);
}
{
    const Race = function(positionalParams, namedParams, state, atTime) {
        let isRace = false;
        let target = namedParams.target || "player";
        let [_, targetRaceId] = API_UnitRace(target);
        for (const [_, v] of _ipairs(positionalParams)) {
            isRace = isRace || (v == raceId);
        }
        return TestBoolean(isRace, "yes");
    }
    OvaleCondition.RegisterCondition("race", false, Race);
}
{
    const UnitInRaid = function(positionalParams, namedParams, state, atTime) {
        let target = namedParams.target || "player";
        let raidIndex = API_UnitInRaid(target);
        return TestBoolean(raidIndex != nul, "yes");
    }
    OvaleCondition.RegisterCondition("unitinraid", false, UnitInRaid);
}
{
    const SoulFragments = function(positionalParams, namedParams, state, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = state.SoulFragments(atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("soulfragments", false, SoulFragments);
}
