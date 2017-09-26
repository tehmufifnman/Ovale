import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleAura = Ovale.NewModule("OvaleAura", "AceEvent-3.0");
Ovale.OvaleAura = OvaleAura;
import { L } from "./L";
import { OvaleDebug } from "./OvaleDebug";
import { OvalePool } from "./OvalePool";
import { OvaleProfiler } from "./OvaleProfiler";
let OvaleData = undefined;
let OvaleFuture = undefined;
let OvaleGUID = undefined;
let OvalePaperDoll = undefined;
let OvaleSpellBook = undefined;
let OvaleState = undefined;
let bit_band = bit.band;
let bit_bor = bit.bor;
let floor = math.floor;
let _ipairs = ipairs;
let _next = next;
let _pairs = pairs;
let strfind = string.find;
let strlower = string.lower;
let strsub = string.sub;
let tconcat = table.concat;
let tinsert = table.insert;
let _tonumber = tonumber;
let tsort = table.sort;
let _type = type;
let _wipe = wipe;
let API_GetTime = GetTime;
let API_UnitAura = UnitAura;
let INFINITY = math.huge;
let _SCHOOL_MASK_ARCANE = SCHOOL_MASK_ARCANE;
let _SCHOOL_MASK_FIRE = SCHOOL_MASK_FIRE;
let _SCHOOL_MASK_FROST = SCHOOL_MASK_FROST;
let _SCHOOL_MASK_HOLY = SCHOOL_MASK_HOLY;
let _SCHOOL_MASK_NATURE = SCHOOL_MASK_NATURE;
let _SCHOOL_MASK_SHADOW = SCHOOL_MASK_SHADOW;
OvaleDebug.RegisterDebugging(OvaleAura);
OvaleProfiler.RegisterProfiling(OvaleAura);
let self_playerGUID = undefined;
let self_petGUID = undefined;
let self_pool = OvalePool("OvaleAura_pool");
let UNKNOWN_GUID = 0;
{
    let output = {  }
    let debugOptions = { playerAura: { name: L["Auras (player)"], type: "group", args: { buff: { name: L["Auras on the player"], type: "input", multiline: 25, width: "full", get: function (info) {
        _wipe(output);
        let helpful = OvaleState.state.DebugUnitAuras("player", "HELPFUL");
        if (helpful) {
            output[lualength(output) + 1] = "== BUFFS ==";
            output[lualength(output) + 1] = helpful;
        }
        let harmful = OvaleState.state.DebugUnitAuras("player", "HARMFUL");
        if (harmful) {
            output[lualength(output) + 1] = "== DEBUFFS ==";
            output[lualength(output) + 1] = harmful;
        }
        return tconcat(output, "\n");
    } } } }, targetAura: { name: L["Auras (target)"], type: "group", args: { targetbuff: { name: L["Auras on the target"], type: "execute", type: "input", multiline: 25, width: "full", get: function (info) {
        _wipe(output);
        let helpful = OvaleState.state.DebugUnitAuras("target", "HELPFUL");
        if (helpful) {
            output[lualength(output) + 1] = "== BUFFS ==";
            output[lualength(output) + 1] = helpful;
        }
        let harmful = OvaleState.state.DebugUnitAuras("target", "HARMFUL");
        if (harmful) {
            output[lualength(output) + 1] = "== DEBUFFS ==";
            output[lualength(output) + 1] = harmful;
        }
        return tconcat(output, "\n");
    } } } } }
    for (const [k, v] of _pairs(debugOptions)) {
        OvaleDebug.options.args[k] = v;
    }
}
let DEBUFF_TYPE = { Curse: true, Disease: true, Enrage: true, Magic: true, Poison: true }
let SPELLINFO_DEBUFF_TYPE = {  }
{
    for (const [debuffType] of _pairs(DEBUFF_TYPE)) {
        let siDebuffType = strlower(debuffType);
        SPELLINFO_DEBUFF_TYPE[siDebuffType] = debuffType;
    }
}
let CLEU_AURA_EVENTS = { SPELL_AURA_APPLIED: true, SPELL_AURA_REMOVED: true, SPELL_AURA_APPLIED_DOSE: true, SPELL_AURA_REMOVED_DOSE: true, SPELL_AURA_REFRESH: true, SPELL_AURA_BROKEN: true, SPELL_AURA_BROKEN_SPELL: true }
let CLEU_TICK_EVENTS = { SPELL_PERIODIC_DAMAGE: true, SPELL_PERIODIC_HEAL: true, SPELL_PERIODIC_ENERGIZE: true, SPELL_PERIODIC_DRAIN: true, SPELL_PERIODIC_LEECH: true }
let CLEU_SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW);
OvaleAura.aura = {  }
OvaleAura.serial = {  }
OvaleAura.bypassState = {  }
const PutAura = function(auraDB, guid, auraId, casterGUID, aura) {
    if (!auraDB[guid]) {
        auraDB[guid] = self_pool.Get();
    }
    if (!auraDB[guid][auraId]) {
        auraDB[guid][auraId] = self_pool.Get();
    }
    if (auraDB[guid][auraId][casterGUID]) {
        self_pool.Release(auraDB[guid][auraId][casterGUID]);
    }
    auraDB[guid][auraId][casterGUID] = aura;
    aura.guid = guid;
    aura.spellId = auraId;
    aura.source = casterGUID;
}
const GetAura = function(auraDB, guid, auraId, casterGUID) {
    if (auraDB[guid] && auraDB[guid][auraId] && auraDB[guid][auraId][casterGUID]) {
        if (auraId == 215570) {
            let spellcast = OvaleFuture.LastInFlightSpell();
            if (spellcast && spellcast.spellId && spellcast.spellId == 190411 && spellcast.start) {
                let aura = auraDB[guid][auraId][casterGUID];
                if (aura.start && aura.start < spellcast.start) {
                    aura.ending = spellcast.start;
                }
            }
        }
        return auraDB[guid][auraId][casterGUID];
    }
}
const GetAuraAnyCaster = function(auraDB, guid, auraId) {
    let auraFound;
    if (auraDB[guid] && auraDB[guid][auraId]) {
        for (const [casterGUID, aura] of _pairs(auraDB[guid][auraId])) {
            if (!auraFound || auraFound.ending < aura.ending) {
                auraFound = aura;
            }
        }
    }
    return auraFound;
}
const GetDebuffType = function(auraDB, guid, debuffType, filter, casterGUID) {
    let auraFound;
    if (auraDB[guid]) {
        for (const [auraId, whoseTable] of _pairs(auraDB[guid])) {
            let aura = whoseTable[casterGUID];
            if (aura && aura.debuffType == debuffType && aura.filter == filter) {
                if (!auraFound || auraFound.ending < aura.ending) {
                    auraFound = aura;
                }
            }
        }
    }
    return auraFound;
}
const GetDebuffTypeAnyCaster = function(auraDB, guid, debuffType, filter) {
    let auraFound;
    if (auraDB[guid]) {
        for (const [auraId, whoseTable] of _pairs(auraDB[guid])) {
            for (const [casterGUID, aura] of _pairs(whoseTable)) {
                if (aura && aura.debuffType == debuffType && aura.filter == filter) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
    }
    return auraFound;
}
const GetAuraOnGUID = function(auraDB, guid, auraId, filter, mine) {
    let auraFound;
    if (DEBUFF_TYPE[auraId]) {
        if (mine) {
            auraFound = GetDebuffType(auraDB, guid, auraId, filter, self_playerGUID);
            if (!auraFound) {
                for (const [petGUID] of _pairs(self_petGUID)) {
                    let aura = GetDebuffType(auraDB, guid, auraId, filter, petGUID);
                    if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = GetDebuffTypeAnyCaster(auraDB, guid, auraId, filter);
        }
    } else {
        if (mine) {
            auraFound = GetAura(auraDB, guid, auraId, self_playerGUID);
            if (!auraFound) {
                for (const [petGUID] of _pairs(self_petGUID)) {
                    let aura = GetAura(auraDB, guid, auraId, petGUID);
                    if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = GetAuraAnyCaster(auraDB, guid, auraId);
        }
    }
    return auraFound;
}
const RemoveAurasOnGUID = function(auraDB, guid) {
    if (auraDB[guid]) {
        let auraTable = auraDB[guid];
        for (const [auraId, whoseTable] of _pairs(auraTable)) {
            for (const [casterGUID, aura] of _pairs(whoseTable)) {
                self_pool.Release(aura);
                whoseTable[casterGUID] = undefined;
            }
            self_pool.Release(whoseTable);
            auraTable[auraId] = undefined;
        }
        self_pool.Release(auraTable);
        auraDB[guid] = undefined;
    }
}
const IsWithinAuraLag = function(time1, time2, factor) {
    factor = factor || 1;
    import { auraLag } from "./db";
    let tolerance = factor * auraLag / 1000;
    return (time1 - time2 < tolerance) && (time2 - time1 < tolerance);
}
class OvaleAura {
    OnInitialize() {
        OvaleData = Ovale.OvaleData;
        OvaleFuture = Ovale.OvaleFuture;
        OvaleGUID = Ovale.OvaleGUID;
        OvalePaperDoll = Ovale.OvalePaperDoll;
        OvaleSpellBook = Ovale.OvaleSpellBook;
        OvaleState = Ovale.OvaleState;
    }
    OnEnable() {
        self_playerGUID = Ovale.playerGUID;
        self_petGUID = OvaleGUID.petGUID;
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_ENTERING_WORLD");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("UNIT_AURA");
        this.RegisterMessage("Ovale_GroupChanged", "ScanAllUnitAuras");
        this.RegisterMessage("Ovale_UnitChanged");
        OvaleData.RegisterRequirement("buff", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("buff_any", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("debuff", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("debuff_any", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("pet_buff", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("pet_debuff", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("stealth", "RequireStealthHandler", this);
        OvaleData.RegisterRequirement("stealthed", "RequireStealthHandler", this);
        OvaleData.RegisterRequirement("target_buff", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("target_buff_any", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("target_debuff", "RequireBuffHandler", this);
        OvaleData.RegisterRequirement("target_debuff_any", "RequireBuffHandler", this);
        OvaleState.RegisterState(this, this.statePrototype);
    }
    OnDisable() {
        OvaleState.UnregisterState(this);
        OvaleData.UnregisterRequirement("buff");
        OvaleData.UnregisterRequirement("buff_any");
        OvaleData.UnregisterRequirement("debuff");
        OvaleData.UnregisterRequirement("debuff_any");
        OvaleData.UnregisterRequirement("pet_buff");
        OvaleData.UnregisterRequirement("pet_debuff");
        OvaleData.UnregisterRequirement("stealth");
        OvaleData.UnregisterRequirement("stealthed");
        OvaleData.UnregisterRequirement("target_buff");
        OvaleData.UnregisterRequirement("target_buff_any");
        OvaleData.UnregisterRequirement("target_debuff");
        OvaleData.UnregisterRequirement("target_debuff_any");
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.UnregisterEvent("PLAYER_UNGHOST");
        this.UnregisterEvent("UNIT_AURA");
        this.UnregisterMessage("Ovale_GroupChanged");
        this.UnregisterMessage("Ovale_UnitChanged");
        for (const [guid] of _pairs(this.aura)) {
            RemoveAurasOnGUID(this.aura, guid);
        }
        self_pool.Drain();
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        let mine = (sourceGUID == self_playerGUID || OvaleGUID.IsPlayerPet(sourceGUID));
        if (mine && cleuEvent == "SPELL_MISSED") {
            let [spellId, spellName, spellSchool] = [arg12, arg13, arg14];
            let si = OvaleData.spellInfo[spellId];
            let bypassState = OvaleAura.bypassState;
            if (si && si.aura && si.aura.player) {
                for (const [filter, auraTable] of _pairs(si.aura.player)) {
                    for (const [auraId] of _pairs(auraTable)) {
                        if (!bypassState[auraId]) {
                            bypassState[auraId] = {  }
                        }
                        bypassState[auraId][self_playerGUID] = true;
                    }
                }
            }
            if (si && si.aura && si.aura.target) {
                for (const [filter, auraTable] of _pairs(si.aura.target)) {
                    for (const [auraId] of _pairs(auraTable)) {
                        if (!bypassState[auraId]) {
                            bypassState[auraId] = {  }
                        }
                        bypassState[auraId][destGUID] = true;
                    }
                }
            }
            if (si && si.aura && si.aura.pet) {
                for (const [filter, auraTable] of _pairs(si.aura.pet)) {
                    for (const [auraId, index] of _pairs(auraTable)) {
                        for (const [petGUID] of _pairs(self_petGUID)) {
                            if (!bypassState[petGUID]) {
                                bypassState[auraId] = {  }
                            }
                            bypassState[auraId][petGUID] = true;
                        }
                    }
                }
            }
        }
        if (CLEU_AURA_EVENTS[cleuEvent]) {
            let unitId = OvaleGUID.GUIDUnit(destGUID);
            if (unitId) {
                if (!OvaleGUID.UNIT_AURA_UNIT[unitId]) {
                    this.DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId);
                    this.ScanAuras(unitId, destGUID);
                }
            } else if (mine) {
                let [spellId, spellName, spellSchool] = [arg12, arg13, arg14];
                this.DebugTimestamp("%s: %s (%d) on %s", cleuEvent, spellName, spellId, destGUID);
                let now = API_GetTime();
                if (cleuEvent == "SPELL_AURA_REMOVED" || cleuEvent == "SPELL_AURA_BROKEN" || cleuEvent == "SPELL_AURA_BROKEN_SPELL") {
                    this.LostAuraOnGUID(destGUID, now, spellId, sourceGUID);
                } else {
                    let [auraType, amount] = [arg15, arg16];
                    let filter = (auraType == "BUFF") && "HELPFUL" || "HARMFUL";
                    let si = OvaleData.spellInfo[spellId];
                    let aura = GetAuraOnGUID(this.aura, destGUID, spellId, filter, true);
                    let duration;
                    if (aura) {
                        duration = aura.duration;
                    } else if (si && si.duration) {
                        duration = OvaleData.GetSpellInfoProperty(spellId, now, "duration", destGUID);
                        if (si.addduration) {
                            duration = duration + si.addduration;
                        }
                    } else {
                        duration = 15;
                    }
                    let expirationTime = now + duration;
                    let count;
                    if (cleuEvent == "SPELL_AURA_APPLIED") {
                        count = 1;
                    } else if (cleuEvent == "SPELL_AURA_APPLIED_DOSE" || cleuEvent == "SPELL_AURA_REMOVED_DOSE") {
                        count = amount;
                    } else if (cleuEvent == "SPELL_AURA_REFRESH") {
                        count = aura && aura.stacks || 1;
                    }
                    this.GainedAuraOnGUID(destGUID, now, spellId, sourceGUID, filter, true, undefined, count, undefined, duration, expirationTime, undefined, spellName);
                }
            }
        } else if (mine && CLEU_TICK_EVENTS[cleuEvent]) {
            let [spellId, spellName, spellSchool] = [arg12, arg13, arg14];
            let multistrike;
            if (strsub(cleuEvent, -7) == "_DAMAGE") {
                multistrike = arg25;
            } else if (strsub(cleuEvent, -5) == "_HEAL") {
                multistrike = arg19;
            }
            if (!multistrike) {
                this.DebugTimestamp("%s: %s", cleuEvent, destGUID);
                let aura = GetAura(this.aura, destGUID, spellId, self_playerGUID);
                let now = API_GetTime();
                if (this.IsActiveAura(aura, now)) {
                    let name = aura.name || "Unknown spell";
                    let [baseTick, lastTickTime] = [aura.baseTick, aura.lastTickTime];
                    let tick = baseTick;
                    if (lastTickTime) {
                        tick = timestamp - lastTickTime;
                    } else if (!baseTick) {
                        this.Debug("    First tick seen of unknown periodic aura %s (%d) on %s.", name, spellId, destGUID);
                        let si = OvaleData.spellInfo[spellId];
                        baseTick = (si && si.tick) && si.tick || 3;
                        tick = OvaleData.GetTickLength(spellId);
                    }
                    aura.baseTick = baseTick;
                    aura.lastTickTime = timestamp;
                    aura.tick = tick;
                    this.Debug("    Updating %s (%s) on %s, tick=%s, lastTickTime=%s", name, spellId, destGUID, tick, lastTickTime);
                    Ovale.refreshNeeded[destGUID] = true;
                }
            }
        }
    }
    PLAYER_ENTERING_WORLD(event) {
        this.ScanAllUnitAuras();
    }
    PLAYER_REGEN_ENABLED(event) {
        this.RemoveAurasOnInactiveUnits();
        self_pool.Drain();
    }
    UNIT_AURA(event, unitId) {
        this.Debug("%s: %s", event, unitId);
        this.ScanAuras(unitId);
    }
    Ovale_UnitChanged(event, unitId, guid) {
        if ((unitId == "pet" || unitId == "target") && guid) {
            this.Debug(event, unitId, guid);
            this.ScanAuras(unitId, guid);
        }
    }
    ScanAllUnitAuras() {
        for (const [unitId] of _pairs(OvaleGUID.UNIT_AURA_UNIT)) {
            this.ScanAuras(unitId);
        }
    }
    RemoveAurasOnInactiveUnits() {
        for (const [guid] of _pairs(this.aura)) {
            let unitId = OvaleGUID.GUIDUnit(guid);
            if (!unitId) {
                this.Debug("Removing auras from GUID %s", guid);
                RemoveAurasOnGUID(this.aura, guid);
                this.serial[guid] = undefined;
            }
        }
    }
    IsActiveAura(aura, atTime) {
        let boolean = false;
        if (aura) {
            atTime = atTime || API_GetTime();
            if (aura.serial == this.serial[aura.guid] && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                boolean = true;
            } else if (aura.consumed && IsWithinAuraLag(aura.ending, atTime)) {
                boolean = true;
            }
        }
        return boolean;
    }
    GainedAuraOnGUID(guid, atTime, auraId, casterGUID, filter, visible, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3) {
        this.StartProfiling("OvaleAura_GainedAuraOnGUID");
        casterGUID = casterGUID || UNKNOWN_GUID;
        count = (count && count > 0) && count || 1;
        duration = (duration && duration > 0) && duration || INFINITY;
        expirationTime = (expirationTime && expirationTime > 0) && expirationTime || INFINITY;
        let aura = GetAura(this.aura, guid, auraId, casterGUID);
        let auraIsActive;
        if (aura) {
            auraIsActive = (aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending);
        } else {
            aura = self_pool.Get();
            PutAura(this.aura, guid, auraId, casterGUID, aura);
            auraIsActive = false;
        }
        let auraIsUnchanged = (aura.source == casterGUID && aura.duration == duration && aura.ending == expirationTime && aura.stacks == count && aura.value1 == value1 && aura.value2 == value2 && aura.value3 == value3);
        aura.serial = this.serial[guid];
        if (!auraIsActive || !auraIsUnchanged) {
            this.Debug("    Adding %s %s (%s) to %s at %f, aura.serial=%d", filter, name, auraId, guid, atTime, aura.serial);
            aura.name = name;
            aura.duration = duration;
            aura.ending = expirationTime;
            if (duration < INFINITY && expirationTime < INFINITY) {
                aura.start = expirationTime - duration;
            } else {
                aura.start = atTime;
            }
            aura.gain = atTime;
            aura.lastUpdated = atTime;
            let direction = aura.direction || 1;
            if (aura.stacks) {
                if (aura.stacks < count) {
                    direction = 1;
                } else if (aura.stacks > count) {
                    direction = -1;
                }
            }
            aura.direction = direction;
            aura.stacks = count;
            aura.consumed = undefined;
            aura.filter = filter;
            aura.visible = visible;
            aura.icon = icon;
            aura.debuffType = debuffType;
            aura.enrage = (debuffType == "Enrage") || undefined;
            aura.stealable = isStealable;
            [aura.value1, aura.value2, aura.value3] = [value1, value2, value3];
            let mine = (casterGUID == self_playerGUID || OvaleGUID.IsPlayerPet(casterGUID));
            if (mine) {
                let spellcast = OvaleFuture.LastInFlightSpell();
                if (spellcast && spellcast.stop && !IsWithinAuraLag(spellcast.stop, atTime)) {
                    spellcast = OvaleFuture.lastSpellcast;
                    if (spellcast && spellcast.stop && !IsWithinAuraLag(spellcast.stop, atTime)) {
                        spellcast = undefined;
                    }
                }
                if (spellcast && spellcast.target == guid) {
                    let spellId = spellcast.spellId;
                    let spellName = OvaleSpellBook.GetSpellName(spellId) || "Unknown spell";
                    let keepSnapshot = false;
                    let si = OvaleData.spellInfo[spellId];
                    if (si && si.aura) {
                        let auraTable = OvaleGUID.IsPlayerPet(guid) && si.aura.pet || si.aura.target;
                        if (auraTable && auraTable[filter]) {
                            let spellData = auraTable[filter][auraId];
                            if (spellData == "refresh_keep_snapshot") {
                                keepSnapshot = true;
                            } else if (_type(spellData) == "table" && spellData[1] == "refresh_keep_snapshot") {
                                keepSnapshot = OvaleData.CheckRequirements(spellId, atTime, spellData, 2, guid);
                            }
                        }
                    }
                    if (keepSnapshot) {
                        this.Debug("    Keeping snapshot stats for %s %s (%d) on %s refreshed by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, aura.snapshotTime, atTime, aura.serial);
                    } else {
                        this.Debug("    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, spellcast.snapshotTime, atTime, aura.serial);
                        OvaleFuture.CopySpellcastInfo(spellcast, aura);
                    }
                }
                let si = OvaleData.spellInfo[auraId];
                if (si) {
                    if (si.tick) {
                        this.Debug("    %s (%s) is a periodic aura.", name, auraId);
                        if (!auraIsActive) {
                            aura.baseTick = si.tick;
                            if (spellcast && spellcast.target == guid) {
                                aura.tick = OvaleData.GetTickLength(auraId, spellcast);
                            } else {
                                aura.tick = OvaleData.GetTickLength(auraId);
                            }
                        }
                    }
                    if (si.buff_cd && guid == self_playerGUID) {
                        this.Debug("    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd);
                        if (!auraIsActive) {
                            aura.cooldownEnding = aura.gain + si.buff_cd;
                        }
                    }
                }
            }
            if (!auraIsActive) {
                this.SendMessage("Ovale_AuraAdded", atTime, guid, auraId, aura.source);
            } else if (!auraIsUnchanged) {
                this.SendMessage("Ovale_AuraChanged", atTime, guid, auraId, aura.source);
            }
            Ovale.refreshNeeded[guid] = true;
        }
        this.StopProfiling("OvaleAura_GainedAuraOnGUID");
    }
    LostAuraOnGUID(guid, atTime, auraId, casterGUID) {
        this.StartProfiling("OvaleAura_LostAuraOnGUID");
        let aura = GetAura(this.aura, guid, auraId, casterGUID);
        if (aura) {
            let filter = aura.filter;
            this.Debug("    Expiring %s %s (%d) from %s at %f.", filter, aura.name, auraId, guid, atTime);
            if (aura.ending > atTime) {
                aura.ending = atTime;
            }
            let mine = (casterGUID == self_playerGUID || OvaleGUID.IsPlayerPet(casterGUID));
            if (mine) {
                aura.baseTick = undefined;
                aura.lastTickTime = undefined;
                aura.tick = undefined;
                if (aura.start + aura.duration > aura.ending) {
                    let spellcast;
                    if (guid == self_playerGUID) {
                        spellcast = OvaleFuture.LastSpellSent();
                    } else {
                        spellcast = OvaleFuture.lastSpellcast;
                    }
                    if (spellcast) {
                        if ((spellcast.success && spellcast.stop && IsWithinAuraLag(spellcast.stop, aura.ending)) || (spellcast.queued && IsWithinAuraLag(spellcast.queued, aura.ending))) {
                            aura.consumed = true;
                            let spellName = OvaleSpellBook.GetSpellName(spellcast.spellId) || "Unknown spell";
                            this.Debug("    Consuming %s %s (%d) on %s with queued %s (%d) at %f.", filter, aura.name, auraId, guid, spellName, spellcast.spellId, spellcast.queued);
                        }
                    }
                }
            }
            aura.lastUpdated = atTime;
            this.SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source);
            Ovale.refreshNeeded[guid] = true;
        }
        this.StopProfiling("OvaleAura_LostAuraOnGUID");
    }
    ScanAuras(unitId, guid) {
        this.StartProfiling("OvaleAura_ScanAuras");
        guid = guid || OvaleGUID.UnitGUID(unitId);
        if (guid) {
            this.DebugTimestamp("Scanning auras on %s (%s)", guid, unitId);
            let serial = this.serial[guid] || 0;
            serial = serial + 1;
            this.Debug("    Advancing age of auras for %s (%s) to %d.", guid, unitId, serial);
            this.serial[guid] = serial;
            let i = 1;
            let filter = "HELPFUL";
            let now = API_GetTime();
            while (true) {
                let [name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3] = API_UnitAura(unitId, i, filter);
                if (!name) {
                    if (filter == "HELPFUL") {
                        filter = "HARMFUL";
                        i = 1;
                    } else {
                        break;
                    }
                } else {
                    let casterGUID = OvaleGUID.UnitGUID(unitCaster);
                    if (debuffType == "") {
                        debuffType = "Enrage";
                    }
                    this.GainedAuraOnGUID(guid, now, spellId, casterGUID, filter, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3);
                    i = i + 1;
                }
            }
            if (this.aura[guid]) {
                let auraTable = this.aura[guid];
                for (const [auraId, whoseTable] of _pairs(auraTable)) {
                    for (const [casterGUID, aura] of _pairs(whoseTable)) {
                        if (aura.serial == serial - 1) {
                            if (aura.visible) {
                                this.LostAuraOnGUID(guid, now, auraId, casterGUID);
                            } else {
                                aura.serial = serial;
                                this.Debug("    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d", aura.name, aura.spellId, aura.start, aura.ending, aura.serial);
                            }
                        }
                    }
                }
            }
            this.Debug("End scanning of auras on %s (%s).", guid, unitId);
        }
        this.StopProfiling("OvaleAura_ScanAuras");
    }
    GetAuraByGUID(guid, auraId, filter, mine) {
        if (!this.serial[guid]) {
            let unitId = OvaleGUID.GUIDUnit(guid);
            this.ScanAuras(unitId, guid);
        }
        let auraFound;
        if (OvaleData.buffSpellList[auraId]) {
            for (const [id] of _pairs(OvaleData.buffSpellList[auraId])) {
                let aura = GetAuraOnGUID(this.aura, guid, id, filter, mine);
                if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                    auraFound = aura;
                }
            }
        } else {
            auraFound = GetAuraOnGUID(this.aura, guid, auraId, filter, mine);
        }
        return auraFound;
    }
    GetAura(unitId, auraId, filter, mine) {
        let guid = OvaleGUID.UnitGUID(unitId);
        return this.GetAuraByGUID(guid, auraId, filter, mine);
    }
    RequireBuffHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let buffName = tokens;
        let stacks = 1;
        if (index) {
            buffName = tokens[index];
            index = index + 1;
            let count = _tonumber(tokens[index]);
            if (count) {
                stacks = count;
                index = index + 1;
            }
        }
        if (buffName) {
            let isBang = false;
            if (strsub(buffName, 1, 1) == "!") {
                isBang = true;
                buffName = strsub(buffName, 2);
            }
            let buffName = _tonumber(buffName) || buffName;
            let [guid, unitId, filter, mine];
            if (strsub(requirement, 1, 7) == "target_") {
                if (targetGUID) {
                    guid = targetGUID;
                    unitId = OvaleGUID.GUIDUnit(guid);
                } else {
                    unitId = this.defaultTarget || "target";
                }
                filter = (strsub(requirement, 8, 11) == "buff") && "HELPFUL" || "HARMFUL";
                mine = !(strsub(requirement, -4) == "_any");
            } else if (strsub(requirement, 1, 4) == "pet_") {
                unitId = "pet";
                filter = (strsub(requirement, 5, 11) == "buff") && "HELPFUL" || "HARMFUL";
                mine = false;
            } else {
                unitId = "player";
                filter = (strsub(requirement, 1, 4) == "buff") && "HELPFUL" || "HARMFUL";
                mine = !(strsub(requirement, -4) == "_any");
            }
            guid = guid || OvaleGUID.UnitGUID(unitId);
            let aura = this.GetAuraByGUID(guid, buffName, filter, mine);
            let isActiveAura = this.IsActiveAura(aura, atTime) && aura.stacks >= stacks;
            if (!isBang && isActiveAura || isBang && !isActiveAura) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                this.Log("    Require aura %s with at least %d stack(s) NOT on %s at time=%f: %s", buffName, stacks, unitId, atTime, result);
            } else {
                this.Log("    Require aura %s with at least %d stack(s) on %s at time=%f: %s", buffName, stacks, unitId, atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a buff argument.", requirement);
        }
        return [verified, requirement, index];
    }
    RequireStealthHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let stealthed = tokens;
        if (index) {
            stealthed = tokens[index];
            index = index + 1;
        }
        if (stealthed) {
            stealthed = _tonumber(stealthed);
            let aura = this.GetAura("player", "stealthed_buff", "HELPFUL", true);
            let isActiveAura = this.IsActiveAura(aura, atTime);
            if (stealthed == 1 && isActiveAura || stealthed != 1 && !isActiveAura) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (stealthed == 1) {
                this.Log("    Require stealth at time=%f: %s", atTime, result);
            } else {
                this.Log("    Require NOT stealth at time=%f: %s", atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing an argument.", requirement);
        }
        return [verified, requirement, index];
    }
}
OvaleAura.statePrototype = { aura: undefined, serial: undefined }
let statePrototype = OvaleAura.statePrototype;
statePrototype.aura = undefined;
statePrototype.serial = undefined;
class OvaleAura {
    InitializeState(state) {
        state.aura = {  }
        state.serial = 0;
    }
    ResetState(state) {
        this.StartProfiling("OvaleAura_ResetState");
        state.serial = state.serial + 1;
        if (_next(state.aura)) {
            state.Log("Resetting aura state:");
        }
        for (const [guid, auraTable] of _pairs(state.aura)) {
            for (const [auraId, whoseTable] of _pairs(auraTable)) {
                for (const [casterGUID, aura] of _pairs(whoseTable)) {
                    self_pool.Release(aura);
                    whoseTable[casterGUID] = undefined;
                    state.Log("    Aura %d on %s removed.", auraId, guid);
                }
                if (!_next(whoseTable)) {
                    self_pool.Release(whoseTable);
                    auraTable[auraId] = undefined;
                }
            }
            if (!_next(auraTable)) {
                self_pool.Release(auraTable);
                state.aura[guid] = undefined;
            }
        }
        this.StopProfiling("OvaleAura_ResetState");
    }
    CleanState(state) {
        for (const [guid] of _pairs(state.aura)) {
            RemoveAurasOnGUID(state.aura, guid);
        }
    }
    ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleAura_ApplySpellStartCast");
        if (isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    state.ApplySpellAuras(spellId, self_playerGUID, startCast, si.aura.player, spellcast);
                }
                if (si.aura.target) {
                    state.ApplySpellAuras(spellId, targetGUID, startCast, si.aura.target, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = OvaleGUID.UnitGUID("pet");
                    if (petGUID) {
                        state.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        this.StopProfiling("OvaleAura_ApplySpellStartCast");
    }
    ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleAura_ApplySpellAfterCast");
        if (!isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    state.ApplySpellAuras(spellId, self_playerGUID, endCast, si.aura.player, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = OvaleGUID.UnitGUID("pet");
                    if (petGUID) {
                        state.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        this.StopProfiling("OvaleAura_ApplySpellAfterCast");
    }
    ApplySpellOnHit(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleAura_ApplySpellAfterHit");
        if (!isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura && si.aura.target) {
                let travelTime = si.travel_time || 0;
                if (travelTime > 0) {
                    let estimatedTravelTime = 1;
                    if (travelTime < estimatedTravelTime) {
                        travelTime = estimatedTravelTime;
                    }
                }
                let atTime = endCast + travelTime;
                state.ApplySpellAuras(spellId, targetGUID, atTime, si.aura.target, spellcast);
            }
        }
        this.StopProfiling("OvaleAura_ApplySpellAfterHit");
    }
}
const GetStateAura = function(state, guid, auraId, casterGUID) {
    let aura = GetAura(state.aura, guid, auraId, casterGUID);
    if (!aura || aura.serial < state.serial) {
        aura = GetAura(OvaleAura.aura, guid, auraId, casterGUID);
    }
    return aura;
}
const GetStateAuraAnyCaster = function(state, guid, auraId) {
    let auraFound;
    if (OvaleAura.aura[guid] && OvaleAura.aura[guid][auraId]) {
        for (const [casterGUID] of _pairs(OvaleAura.aura[guid][auraId])) {
            let aura = GetStateAura(state, guid, auraId, casterGUID);
            if (aura && !aura.state && OvaleAura.IsActiveAura(aura, state.currentTime)) {
                if (!auraFound || auraFound.ending < aura.ending) {
                    auraFound = aura;
                }
            }
        }
    }
    if (state.aura[guid] && state.aura[guid][auraId]) {
        for (const [casterGUID, aura] of _pairs(state.aura[guid][auraId])) {
            if (aura.stacks > 0) {
                if (!auraFound || auraFound.ending < aura.ending) {
                    auraFound = aura;
                }
            }
        }
    }
    return auraFound;
}
const GetStateDebuffType = function(state, guid, debuffType, filter, casterGUID) {
    let auraFound;
    if (OvaleAura.aura[guid]) {
        for (const [auraId] of _pairs(OvaleAura.aura[guid])) {
            let aura = GetStateAura(state, guid, auraId, casterGUID);
            if (aura && !aura.state && OvaleAura.IsActiveAura(aura, state.currentTime)) {
                if (aura.debuffType == debuffType && aura.filter == filter) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
    }
    if (state.aura[guid]) {
        for (const [auraId, whoseTable] of _pairs(state.aura[guid])) {
            let aura = whoseTable[casterGUID];
            if (aura && aura.stacks > 0) {
                if (aura.debuffType == debuffType && aura.filter == filter) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
    }
    return auraFound;
}
const GetStateDebuffTypeAnyCaster = function(state, guid, debuffType, filter) {
    let auraFound;
    if (OvaleAura.aura[guid]) {
        for (const [auraId, whoseTable] of _pairs(OvaleAura.aura[guid])) {
            for (const [casterGUID] of _pairs(whoseTable)) {
                let aura = GetStateAura(state, guid, auraId, casterGUID);
                if (aura && !aura.state && OvaleAura.IsActiveAura(aura, state.currentTime)) {
                    if (aura.debuffType == debuffType && aura.filter == filter) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
    }
    if (state.aura[guid]) {
        for (const [auraId, whoseTable] of _pairs(state.aura[guid])) {
            for (const [casterGUID, aura] of _pairs(whoseTable)) {
                if (aura && !aura.state && aura.stacks > 0) {
                    if (aura.debuffType == debuffType && aura.filter == filter) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
    }
    return auraFound;
}
const GetStateAuraOnGUID = function(state, guid, auraId, filter, mine) {
    let auraFound;
    if (DEBUFF_TYPE[auraId]) {
        if (mine) {
            auraFound = GetStateDebuffType(state, guid, auraId, filter, self_playerGUID);
            if (!auraFound) {
                for (const [petGUID] of _pairs(self_petGUID)) {
                    let aura = GetStateDebuffType(state, guid, auraId, filter, petGUID);
                    if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = GetStateDebuffTypeAnyCaster(state, guid, auraId, filter);
        }
    } else {
        if (mine) {
            let aura = GetStateAura(state, guid, auraId, self_playerGUID);
            if (aura && aura.stacks > 0) {
                auraFound = aura;
            } else {
                for (const [petGUID] of _pairs(self_petGUID)) {
                    aura = GetStateAura(state, guid, auraId, petGUID);
                    if (aura && aura.stacks > 0) {
                        auraFound = aura;
                        break;
                    }
                }
            }
        } else {
            auraFound = GetStateAuraAnyCaster(state, guid, auraId);
        }
    }
    return auraFound;
}
{
    let array = {  }
    statePrototype.DebugUnitAuras = function (state, unitId, filter) {
        _wipe(array);
        let guid = OvaleGUID.UnitGUID(unitId);
        if (OvaleAura.aura[guid]) {
            for (const [auraId, whoseTable] of _pairs(OvaleAura.aura[guid])) {
                for (const [casterGUID] of _pairs(whoseTable)) {
                    let aura = GetStateAura(state, guid, auraId, casterGUID);
                    if (state.IsActiveAura(aura) && aura.filter == filter && !aura.state) {
                        let name = aura.name || "Unknown spell";
                        tinsert(array, name + ": " + auraId);
                    }
                }
            }
        }
        if (state.aura[guid]) {
            for (const [auraId, whoseTable] of _pairs(state.aura[guid])) {
                for (const [casterGUID, aura] of _pairs(whoseTable)) {
                    if (state.IsActiveAura(aura) && aura.filter == filter) {
                        let name = aura.name || "Unknown spell";
                        tinsert(array, name + ": " + auraId);
                    }
                }
            }
        }
        if (_next(array)) {
            tsort(array);
            return tconcat(array, "\n");
        }
    }
}
statePrototype.IsActiveAura = function (state, aura, atTime) {
    atTime = atTime || state.currentTime;
    let boolean = false;
    if (aura) {
        if (aura.state) {
            if (aura.serial == state.serial && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                boolean = true;
            } else if (aura.consumed && IsWithinAuraLag(aura.ending, atTime)) {
                boolean = true;
            }
        } else {
            boolean = OvaleAura.IsActiveAura(aura, atTime);
        }
    }
    return boolean;
}
statePrototype.CanApplySpellAura = function (spellData) {
    if (spellData["if_target_debuff"]) {
    } else if (spellData["if_buff"]) {
    }
}
statePrototype.ApplySpellAuras = function (state, spellId, guid, atTime, auraList, spellcast) {
    OvaleAura.StartProfiling("OvaleAura_state_ApplySpellAuras");
    for (const [filter, filterInfo] of _pairs(auraList)) {
        for (const [auraId, spellData] of _pairs(filterInfo)) {
            let duration = OvaleData.GetBaseDuration(auraId, spellcast);
            let stacks = 1;
            let count = undefined;
            let extend = 0;
            let toggle = undefined;
            let refresh = false;
            let keepSnapshot = false;
            let [verified, value, data] = state.CheckSpellAuraData(auraId, spellData, atTime, guid);
            if (value == "refresh") {
                refresh = true;
            } else if (value == "refresh_keep_snapshot") {
                refresh = true;
                keepSnapshot = true;
            } else if (value == "toggle") {
                toggle = true;
            } else if (value == "count") {
                count = data;
            } else if (value == "extend") {
                extend = data;
            } else if (_tonumber(value)) {
                stacks = _tonumber(value);
            } else {
                state.Log("Unknown stack %s", stacks);
            }
            if (verified) {
                let si = OvaleData.spellInfo[auraId];
                let auraFound = state.GetAuraByGUID(guid, auraId, filter, true);
                if (state.IsActiveAura(auraFound, atTime)) {
                    let aura;
                    if (auraFound.state) {
                        aura = auraFound;
                    } else {
                        aura = state.AddAuraToGUID(guid, auraId, auraFound.source, filter, undefined, 0, INFINITY);
                        for (const [k, v] of _pairs(auraFound)) {
                            aura[k] = v;
                        }
                        aura.serial = state.serial;
                        state.Log("Aura %d is copied into simulator.", auraId);
                    }
                    if (toggle) {
                        state.Log("Aura %d is toggled off by spell %d.", auraId, spellId);
                        stacks = 0;
                    }
                    if (count && count > 0) {
                        stacks = count - aura.stacks;
                    }
                    if (refresh || extend > 0 || stacks > 0) {
                        if (refresh) {
                            state.Log("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks);
                        } else if (extend > 0) {
                            state.Log("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks);
                        } else {
                            let maxStacks = 1;
                            if (si && (si.max_stacks || si.maxstacks)) {
                                maxStacks = si.max_stacks || si.maxstacks;
                            }
                            aura.stacks = aura.stacks + stacks;
                            if (aura.stacks > maxStacks) {
                                aura.stacks = maxStacks;
                            }
                            state.Log("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId);
                        }
                        if (extend > 0) {
                            aura.duration = aura.duration + extend;
                            aura.ending = aura.ending + extend;
                        } else {
                            aura.start = atTime;
                            if (aura.tick && aura.tick > 0) {
                                let remainingDuration = aura.ending - atTime;
                                let extensionDuration = 0.3 * duration;
                                if (remainingDuration < extensionDuration) {
                                    aura.duration = remainingDuration + duration;
                                } else {
                                    aura.duration = extensionDuration + duration;
                                }
                            } else {
                                aura.duration = duration;
                            }
                            aura.ending = aura.start + aura.duration;
                        }
                        aura.gain = atTime;
                        state.Log("Aura %d with duration %s now ending at %s", auraId, aura.duration, aura.ending);
                        if (keepSnapshot) {
                            state.Log("Aura %d keeping previous snapshot.", auraId);
                        } else if (spellcast) {
                            OvaleFuture.CopySpellcastInfo(spellcast, aura);
                        }
                    } else if (stacks == 0 || stacks < 0) {
                        if (stacks == 0) {
                            aura.stacks = 0;
                        } else {
                            aura.stacks = aura.stacks + stacks;
                            if (aura.stacks < 0) {
                                aura.stacks = 0;
                            }
                            state.Log("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId);
                        }
                        if (aura.stacks == 0) {
                            state.Log("Aura %d is completely removed.", auraId);
                            aura.ending = atTime;
                            aura.consumed = true;
                        }
                    }
                } else {
                    if (toggle) {
                        state.Log("Aura %d is toggled on by spell %d.", auraId, spellId);
                        stacks = 1;
                    }
                    if (!refresh && stacks > 0) {
                        state.Log("New aura %d at %f on %s", auraId, atTime, guid);
                        let debuffType;
                        if (si) {
                            for (const [k, v] of _pairs(SPELLINFO_DEBUFF_TYPE)) {
                                if (si[k] == 1) {
                                    debuffType = v;
                                    break;
                                }
                            }
                        }
                        let aura = state.AddAuraToGUID(guid, auraId, self_playerGUID, filter, debuffType, 0, INFINITY);
                        aura.stacks = stacks;
                        aura.start = atTime;
                        aura.duration = duration;
                        if (si && si.tick) {
                            aura.baseTick = si.tick;
                            aura.tick = OvaleData.GetTickLength(auraId, spellcast);
                        }
                        aura.ending = aura.start + aura.duration;
                        aura.gain = aura.start;
                        if (spellcast) {
                            OvaleFuture.CopySpellcastInfo(spellcast, aura);
                        }
                    }
                }
            } else {
                state.Log("Aura %d (%s) is not applied.", auraId, spellData);
            }
        }
    }
    OvaleAura.StopProfiling("OvaleAura_state_ApplySpellAuras");
}
statePrototype.GetAuraByGUID = function (state, guid, auraId, filter, mine) {
    let auraFound;
    if (OvaleData.buffSpellList[auraId]) {
        for (const [id] of _pairs(OvaleData.buffSpellList[auraId])) {
            let aura = GetStateAuraOnGUID(state, guid, id, filter, mine);
            if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                state.Log("Aura %s matching '%s' found on %s with (%s, %s)", id, auraId, guid, aura.start, aura.ending);
                auraFound = aura;
            } else {
            }
        }
        if (!auraFound) {
            state.Log("Aura matching '%s' is missing on %s.", auraId, guid);
        }
    } else {
        auraFound = GetStateAuraOnGUID(state, guid, auraId, filter, mine);
        if (auraFound) {
            state.Log("Aura %s found on %s with (%s, %s)", auraId, guid, auraFound.start, auraFound.ending);
        } else {
            state.Log("Aura %s is missing on %s.", auraId, guid);
        }
    }
    return auraFound;
}
statePrototype.GetAura = function (state, unitId, auraId, filter, mine) {
    let guid = OvaleGUID.UnitGUID(unitId);
    let stateAura = state.GetAuraByGUID(guid, auraId, filter, mine);
    let aura = OvaleAura.GetAuraByGUID(guid, auraId, filter, mine);
    let bypassState = OvaleAura.bypassState;
    if (!bypassState[auraId]) {
        bypassState[auraId] = {  }
    }
    if (bypassState[auraId][guid]) {
        if (aura && aura.start && aura.ending && stateAura && stateAura.start && stateAura.ending && aura.start == stateAura.start && aura.ending == stateAura.ending) {
            bypassState[auraId][guid] = false;
            return stateAura;
        } else {
            return aura;
        }
    }
    return state.GetAuraByGUID(guid, auraId, filter, mine);
}
statePrototype.AddAuraToGUID = function (state, guid, auraId, casterGUID, filter, debuffType, start, ending, snapshot) {
    let aura = self_pool.Get();
    aura.state = true;
    aura.serial = state.serial;
    aura.lastUpdated = state.currentTime;
    aura.filter = filter;
    aura.start = start || 0;
    aura.ending = ending || INFINITY;
    aura.duration = aura.ending - aura.start;
    aura.gain = aura.start;
    aura.stacks = 1;
    aura.debuffType = debuffType;
    aura.enrage = (debuffType == "Enrage") || undefined;
    state.UpdateSnapshot(aura, snapshot);
    PutAura(state.aura, guid, auraId, casterGUID, aura);
    return aura;
}
statePrototype.RemoveAuraOnGUID = function (state, guid, auraId, filter, mine, atTime) {
    let auraFound = state.GetAuraByGUID(guid, auraId, filter, mine);
    if (state.IsActiveAura(auraFound, atTime)) {
        let aura;
        if (auraFound.state) {
            aura = auraFound;
        } else {
            aura = state.AddAuraToGUID(guid, auraId, auraFound.source, filter, undefined, 0, INFINITY);
            for (const [k, v] of _pairs(auraFound)) {
                aura[k] = v;
            }
            aura.serial = state.serial;
        }
        aura.stacks = 0;
        aura.ending = atTime;
        aura.lastUpdated = atTime;
    }
}
statePrototype.GetAuraWithProperty = function (state, unitId, propertyName, filter, atTime) {
    atTime = atTime || state.currentTime;
    let count = 0;
    let guid = OvaleGUID.UnitGUID(unitId);
    let [start, ending] = [INFINITY, 0];
    if (OvaleAura.aura[guid]) {
        for (const [auraId, whoseTable] of _pairs(OvaleAura.aura[guid])) {
            for (const [casterGUID] of _pairs(whoseTable)) {
                let aura = GetStateAura(state, guid, auraId, self_playerGUID);
                if (state.IsActiveAura(aura, atTime) && !aura.state) {
                    if (aura[propertyName] && aura.filter == filter) {
                        count = count + 1;
                        start = (aura.gain < start) && aura.gain || start;
                        ending = (aura.ending > ending) && aura.ending || ending;
                    }
                }
            }
        }
    }
    if (state.aura[guid]) {
        for (const [auraId, whoseTable] of _pairs(state.aura[guid])) {
            for (const [casterGUID, aura] of _pairs(whoseTable)) {
                if (state.IsActiveAura(aura, atTime)) {
                    if (aura[propertyName] && aura.filter == filter) {
                        count = count + 1;
                        start = (aura.gain < start) && aura.gain || start;
                        ending = (aura.ending > ending) && aura.ending || ending;
                    }
                }
            }
        }
    }
    if (count > 0) {
        state.Log("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending);
    } else {
        state.Log("Aura with '%s' property is missing on %s.", propertyName, unitId);
        [start, ending] = undefined;
    }
    return [start, ending];
}
{
    let count;
    let stacks;
    let [startChangeCount, endingChangeCount];
    let [startFirst, endingLast];
    const CountMatchingActiveAura = function(state, aura) {
        state.Log("Counting aura %s found on %s with (%s, %s)", aura.spellId, aura.guid, aura.start, aura.ending);
        count = count + 1;
        stacks = stacks + aura.stacks;
        if (aura.ending < endingChangeCount) {
            [startChangeCount, endingChangeCount] = [aura.gain, aura.ending];
        }
        if (aura.gain < startFirst) {
            startFirst = aura.gain;
        }
        if (aura.ending > endingLast) {
            endingLast = aura.ending;
        }
    }
    statePrototype.AuraCount = function (state, auraId, filter, mine, minStacks, atTime, excludeUnitId) {
        OvaleAura.StartProfiling("OvaleAura_state_AuraCount");
        minStacks = minStacks || 1;
        count = 0;
        stacks = 0;
        [startChangeCount, endingChangeCount] = [INFINITY, INFINITY];
        [startFirst, endingLast] = [INFINITY, 0];
        let excludeGUID = excludeUnitId && OvaleGUID.UnitGUID(excludeUnitId) || undefined;
        for (const [guid, auraTable] of _pairs(OvaleAura.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = GetStateAura(state, guid, auraId, self_playerGUID);
                    if (state.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                        CountMatchingActiveAura(state, aura);
                    }
                    for (const [petGUID] of _pairs(self_petGUID)) {
                        aura = GetStateAura(state, guid, auraId, petGUID);
                        if (state.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            CountMatchingActiveAura(state, aura);
                        }
                    }
                } else {
                    for (const [casterGUID] of _pairs(auraTable[auraId])) {
                        let aura = GetStateAura(state, guid, auraId, casterGUID);
                        if (state.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            CountMatchingActiveAura(state, aura);
                        }
                    }
                }
            }
        }
        for (const [guid, auraTable] of _pairs(state.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = auraTable[auraId][self_playerGUID];
                    if (aura) {
                        if (state.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            CountMatchingActiveAura(state, aura);
                        }
                    }
                    for (const [petGUID] of _pairs(self_petGUID)) {
                        aura = auraTable[auraId][petGUID];
                        if (state.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            CountMatchingActiveAura(state, aura);
                        }
                    }
                } else {
                    for (const [casterGUID, aura] of _pairs(auraTable[auraId])) {
                        if (state.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            CountMatchingActiveAura(state, aura);
                        }
                    }
                }
            }
        }
        state.Log("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast);
        OvaleAura.StopProfiling("OvaleAura_state_AuraCount");
        return [count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast];
    }
}
statePrototype.RequireBuffHandler = OvaleAura.RequireBuffHandler;
statePrototype.RequireStealthHandler = OvaleAura.RequireStealthHandler;
