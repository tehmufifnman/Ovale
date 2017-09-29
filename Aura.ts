import __addon from "addon";
let [OVALE, AddOn] = __addon;
let OvaleAuraBase = AddOn.NewModule("OvaleAura", "AceEvent-3.0");
import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvalePool, OvalePoolNoClean } from "./Pool";
import { OvaleProfiler } from "./Profiler";
import { OvaleData } from "./Data";
import { OvaleFuture } from "./Future";
import { OvaleGUID } from "./GUID";
import { OvalePaperDoll } from "./PaperDoll";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
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
let UNKNOWN_GUID = 0;

}
let DEBUFF_TYPE = {
    Curse: true,
    Disease: true,
    Enrage: true,
    Magic: true,
    Poison: true
}
let SPELLINFO_DEBUFF_TYPE: LuaObj<string> = {}
{
    for (const [debuffType] of _pairs(DEBUFF_TYPE)) {
        let siDebuffType = strlower(debuffType);
        SPELLINFO_DEBUFF_TYPE[siDebuffType] = debuffType;
    }
}
let CLEU_AURA_EVENTS = {
    SPELL_AURA_APPLIED: true,
    SPELL_AURA_REMOVED: true,
    SPELL_AURA_APPLIED_DOSE: true,
    SPELL_AURA_REMOVED_DOSE: true,
    SPELL_AURA_REFRESH: true,
    SPELL_AURA_BROKEN: true,
    SPELL_AURA_BROKEN_SPELL: true
}
let CLEU_TICK_EVENTS = {
    SPELL_PERIODIC_DAMAGE: true,
    SPELL_PERIODIC_HEAL: true,
    SPELL_PERIODIC_ENERGIZE: true,
    SPELL_PERIODIC_DRAIN: true,
    SPELL_PERIODIC_LEECH: true
}
let CLEU_SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW);

class OvaleAuraClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleAuraBase)) {
    self_playerGUID = undefined;
    self_petGUID:LuaObj<string> = {};
    self_pool = new OvalePoolNoClean<any>("OvaleAura_pool");

    output: LuaArray<string> = {}
    debugOptions = {
        playerAura: {
            name: L["Auras (player)"],
            type: "group",
            args: {
                buff: {
                    name: L["Auras on the player"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info) => {
                        _wipe(this.output);
                        let helpful = OvaleState.state.DebugUnitAuras("player", "HELPFUL");
                        if (helpful) {
                            this.output[lualength(this.output) + 1] = "== BUFFS ==";
                            this.output[lualength(this.output) + 1] = helpful;
                        }
                        let harmful = OvaleState.state.DebugUnitAuras("player", "HARMFUL");
                        if (harmful) {
                            this.output[lualength(this.output) + 1] = "== DEBUFFS ==";
                            this.output[lualength(this.output) + 1] = harmful;
                        }
                        return tconcat(this.output, "\n");
                    }
                }
            }
        },
        targetAura: {
            name: L["Auras (target)"],
            type: "group",
            args: {
                targetbuff: {
                    name: L["Auras on the target"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info) => {
                        _wipe(this.output);
                        let helpful = OvaleState.state.DebugUnitAuras("target", "HELPFUL");
                        if (helpful) {
                            this.output[lualength(this.output) + 1] = "== BUFFS ==";
                            this.output[lualength(this.output) + 1] = helpful;
                        }
                        let harmful = OvaleState.state.DebugUnitAuras("target", "HARMFUL");
                        if (harmful) {
                            this.output[lualength(this.output) + 1] = "== DEBUFFS ==";
                            this.output[lualength(this.output) + 1] = harmful;
                        }
                        return tconcat(this.output, "\n");
                    }
                }
            }
        }
    }

    constructor() {
        super();
        for (const [k, v] of _pairs(thisOptions)) {
            OvaleDebug.options.args[k] = v;
        }   
    }

    aura: LuaObj<LuaObj<LuaObj<Aura>>> = {}
    serial = {}
    bypassState = {}

    PutAura(auraDB, guid, auraId, casterGUID, aura) {
        if (!auraDB[guid]) {
            auraDB[guid] = this.self_pool.Get();
        }
        if (!auraDB[guid][auraId]) {
            auraDB[guid][auraId] = this.self_pool.Get();
        }
        if (auraDB[guid][auraId][casterGUID]) {
            this.self_pool.Release(auraDB[guid][auraId][casterGUID]);
        }
        auraDB[guid][auraId][casterGUID] = aura;
        aura.guid = guid;
        aura.spellId = auraId;
        aura.source = casterGUID;
    }

    GetAuraFromDb(auraDB: LuaObj<LuaObj<LuaObj<Aura>>>, unitGuid: string, auraId: number, casterGUID: string) {
        if (auraDB[unitGuid] && auraDB[unitGuid][auraId] && auraDB[unitGuid][auraId][casterGUID]) {
            if (auraId == 215570) {
                let spellcast = OvaleFuture.LastInFlightSpell();
                if (spellcast && spellcast.spellId && spellcast.spellId == 190411 && spellcast.start) {
                    let aura = auraDB[unitGuid][auraId][casterGUID];
                    if (aura.start && aura.start < spellcast.start) {
                        aura.ending = spellcast.start;
                    }
                }
            }
            return auraDB[unitGuid][auraId][casterGUID];
        }
    }
    GetAuraAnyCaster(auraDB, guid, auraId) {
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
    GetDebuffType(auraDB, guid, debuffType, filter, casterGUID) {
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
    GetDebuffTypeAnyCaster(auraDB, guid, debuffType, filter) {
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
    GetAuraOnGUID(auraDB, guid, auraId, filter, mine) {
        let auraFound;
        if (DEBUFF_TYPE[auraId]) {
            if (mine) {
                auraFound = this.GetDebuffType(auraDB, guid, auraId, filter, this.self_playerGUID);
                if (!auraFound) {
                    for (const [petGUID] of _pairs(this.self_petGUID)) {
                        let aura = this.GetDebuffType(auraDB, guid, auraId, filter, petGUID);
                        if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                            auraFound = aura;
                        }
                    }
                }
            } else {
                auraFound = this.GetDebuffTypeAnyCaster(auraDB, guid, auraId, filter);
            }
        } else {
            if (mine) {
                auraFound = this.GetAura(auraDB, guid, auraId, this.self_playerGUID);
                if (!auraFound) {
                    for (const [petGUID] of _pairs(this.self_petGUID)) {
                        let aura = this.GetAura(auraDB, guid, auraId, petGUID);
                        if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                            auraFound = aura;
                        }
                    }
                }
            } else {
                auraFound = this.GetAuraAnyCaster(auraDB, guid, auraId);
            }
        }
        return auraFound;
    }
    RemoveAurasOnGUID(auraDB, guid: string) {
        if (auraDB[guid]) {
            let auraTable = auraDB[guid];
            for (const [auraId, whoseTable] of _pairs(auraTable)) {
                for (const [casterGUID, aura] of _pairs(whoseTable)) {
                    this.self_pool.Release(aura);
                    whoseTable[casterGUID] = undefined;
                }
                this.self_pool.Release(whoseTable);
                auraTable[auraId] = undefined;
            }
            this.self_pool.Release(auraTable);
            auraDB[guid] = undefined;
        }
    }
    IsWithinAuraLag(time1, time2, factor?) {
        factor = factor || 1;
        const auraLag = Ovale.db.profile.apparence.auraLag;
        let tolerance = factor * auraLag / 1000;
        return (time1 - time2 < tolerance) && (time2 - time1 < tolerance);
    }

    OnInitialize() {
    }

    OnEnable() {
        this.self_playerGUID = Ovale.playerGUID;
        this.self_petGUID = OvaleGUID.petGUID;
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_ENTERING_WORLD");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("UNIT_AURA");
        this.RegisterMessage("Ovale_GroupChanged", this.ScanAllUnitAuras);
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
            this.RemoveAurasOnGUID(this.aura, guid);
        }
        this.self_pool.Drain();
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        let mine = (sourceGUID == this.self_playerGUID || OvaleGUID.IsPlayerPet(sourceGUID));
        if (mine && cleuEvent == "SPELL_MISSED") {
            let [spellId, spellName, spellSchool] = [arg12, arg13, arg14];
            let si = OvaleData.spellInfo[spellId];
            let bypassState = this.bypassState;
            if (si && si.aura && si.aura.player) {
                for (const [filter, auraTable] of _pairs(si.aura.player)) {
                    for (const [auraId] of _pairs(auraTable)) {
                        if (!bypassState[auraId]) {
                            bypassState[auraId] = {
                            }
                        }
                        bypassState[auraId][this.self_playerGUID] = true;
                    }
                }
            }
            if (si && si.aura && si.aura.target) {
                for (const [filter, auraTable] of _pairs(si.aura.target)) {
                    for (const [auraId] of _pairs(auraTable)) {
                        if (!bypassState[auraId]) {
                            bypassState[auraId] = {
                            }
                        }
                        bypassState[auraId][destGUID] = true;
                    }
                }
            }
            if (si && si.aura && si.aura.pet) {
                for (const [filter, auraTable] of _pairs(si.aura.pet)) {
                    for (const [auraId, index] of _pairs(auraTable)) {
                        for (const [petGUID] of _pairs(this.self_petGUID)) {
                            if (!bypassState[petGUID]) {
                                bypassState[auraId] = {
                                }
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
                    let aura = this.GetAuraOnGUID(this.aura, destGUID, spellId, filter, true);
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
                let aura = this.GetAura(this.aura, destGUID, spellId, this.self_playerGUID);
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
        this.self_pool.Drain();
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
        for (const [unitGuid] of _pairs(this.aura)) {
            let unitId = OvaleGUID.GUIDUnit(unitGuid);
            if (!unitId) {
                this.Debug("Removing auras from GUID %s", OvaleGUID);
                this.RemoveAurasOnGUID(this.aura, unitGuid);
                this.serial[OvaleGUID] = undefined;
            }
        }
    }
    IsActiveAura(aura, atTime) {
        let boolean = false;
        if (aura) {
            atTime = atTime || API_GetTime();
            if (aura.serial == this.serial[aura.guid] && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                boolean = true;
            } else if (aura.consumed && this.IsWithinAuraLag(aura.ending, atTime)) {
                boolean = true;
            }
        }
        return boolean;
    }
    GainedAuraOnGUID(unitGuid: string, atTime, auraId, casterGUID, filter, visible, icon, count, debuffType, duration, expirationTime, isStealable, name, value1?, value2?, value3?) {
        this.profiler.StartProfiling("OvaleAura_GainedAuraOnGUID");
        casterGUID = casterGUID || UNKNOWN_GUID;
        count = (count && count > 0) && count || 1;
        duration = (duration && duration > 0) && duration || INFINITY;
        expirationTime = (expirationTime && expirationTime > 0) && expirationTime || INFINITY;
        let aura = this.GetAura(this.aura, unitGuid, auraId, casterGUID);
        let auraIsActive;
        if (aura) {
            auraIsActive = (aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending);
        } else {
            aura = this.self_pool.Get();
            this.PutAura(this.aura, unitGuid, auraId, casterGUID, aura);
            auraIsActive = false;
        }
        let auraIsUnchanged = (aura.source == casterGUID && aura.duration == duration && aura.ending == expirationTime && aura.stacks == count && aura.value1 == value1 && aura.value2 == value2 && aura.value3 == value3);
        aura.serial = this.serial[unitGuid];
        if (!auraIsActive || !auraIsUnchanged) {
            this.Debug("    Adding %s %s (%s) to %s at %f, aura.serial=%d", filter, name, auraId, unitGuid, atTime, aura.serial);
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
            let mine = (casterGUID == this.self_playerGUID || OvaleGUID.IsPlayerPet(casterGUID));
            if (mine) {
                let spellcast = OvaleFuture.LastInFlightSpell();
                if (spellcast && spellcast.stop && !this.IsWithinAuraLag(spellcast.stop, atTime)) {
                    spellcast = OvaleFuture.lastSpellcast;
                    if (spellcast && spellcast.stop && !this.IsWithinAuraLag(spellcast.stop, atTime)) {
                        spellcast = undefined;
                    }
                }
                if (spellcast && spellcast.target == unitGuid) {
                    let spellId = spellcast.spellId;
                    let spellName = OvaleSpellBook.GetSpellName(spellId) || "Unknown spell";
                    let keepSnapshot = false;
                    let si = OvaleData.spellInfo[spellId];
                    if (si && si.aura) {
                        let auraTable = OvaleGUID.IsPlayerPet(unitGuid) && si.aura.pet || si.aura.target;
                        if (auraTable && auraTable[filter]) {
                            let spellData = auraTable[filter][auraId];
                            if (spellData == "refresh_keep_snapshot") {
                                keepSnapshot = true;
                            } else if (_type(spellData) == "table" && spellData[1] == "refresh_keep_snapshot") {
                                keepSnapshot = OvaleData.CheckRequirements(spellId, atTime, spellData, 2, unitGuid);
                            }
                        }
                    }
                    if (keepSnapshot) {
                        this.Debug("    Keeping snapshot stats for %s %s (%d) on %s refreshed by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, unitGuid, spellName, spellId, aura.snapshotTime, atTime, aura.serial);
                    } else {
                        this.Debug("    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, unitGuid, spellName, spellId, spellcast.snapshotTime, atTime, aura.serial);
                        OvaleFuture.CopySpellcastInfo(spellcast, aura);
                    }
                }
                let si = OvaleData.spellInfo[auraId];
                if (si) {
                    if (si.tick) {
                        this.Debug("    %s (%s) is a periodic aura.", name, auraId);
                        if (!auraIsActive) {
                            aura.baseTick = si.tick;
                            if (spellcast && spellcast.target == unitGuid) {
                                aura.tick = OvaleData.GetTickLength(auraId, spellcast);
                            } else {
                                aura.tick = OvaleData.GetTickLength(auraId);
                            }
                        }
                    }
                    if (si.buff_cd && unitGuid == this.self_playerGUID) {
                        this.Debug("    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd);
                        if (!auraIsActive) {
                            aura.cooldownEnding = aura.gain + si.buff_cd;
                        }
                    }
                }
            }
            if (!auraIsActive) {
                this.SendMessage("Ovale_AuraAdded", atTime, unitGuid, auraId, aura.source);
            } else if (!auraIsUnchanged) {
                this.SendMessage("Ovale_AuraChanged", atTime, unitGuid, auraId, aura.source);
            }
            Ovale.refreshNeeded[unitGuid] = true;
        }
        this.profiler.StopProfiling("OvaleAura_GainedAuraOnGUID");
    }
    LostAuraOnGUID(unitGuid: string, atTime, auraId, casterGUID) {
        this.profiler.StartProfiling("OvaleAura_LostAuraOnGUID");
        let aura = this.GetAura(this.aura, unitGuid, auraId, casterGUID);
        if (aura) {
            let filter = aura.filter;
            this.Debug("    Expiring %s %s (%d) from %s at %f.", filter, aura.name, auraId, unitGuid, atTime);
            if (aura.ending > atTime) {
                aura.ending = atTime;
            }
            let mine = (casterGUID == this.self_playerGUID || OvaleGUID.IsPlayerPet(casterGUID));
            if (mine) {
                aura.baseTick = undefined;
                aura.lastTickTime = undefined;
                aura.tick = undefined;
                if (aura.start + aura.duration > aura.ending) {
                    let spellcast;
                    if (unitGuid == this.self_playerGUID) {
                        spellcast = OvaleFuture.LastSpellSent();
                    } else {
                        spellcast = OvaleFuture.lastSpellcast;
                    }
                    if (spellcast) {
                        if ((spellcast.success && spellcast.stop && this.IsWithinAuraLag(spellcast.stop, aura.ending)) || (spellcast.queued && this.IsWithinAuraLag(spellcast.queued, aura.ending))) {
                            aura.consumed = true;
                            let spellName = OvaleSpellBook.GetSpellName(spellcast.spellId) || "Unknown spell";
                            this.Debug("    Consuming %s %s (%d) on %s with queued %s (%d) at %f.", filter, aura.name, auraId, unitGuid, spellName, spellcast.spellId, spellcast.queued);
                        }
                    }
                }
            }
            aura.lastUpdated = atTime;
            this.SendMessage("Ovale_AuraRemoved", atTime, unitGuid, auraId, aura.source);
            Ovale.refreshNeeded[unitGuid] = true;
        }
        this.profiler.StopProfiling("OvaleAura_LostAuraOnGUID");
    }
    ScanAuras(unitId, unitGuid?: string) {
        this.profiler.StartProfiling("OvaleAura_ScanAuras");
        unitGuid = unitGuid || OvaleGUID.UnitGUID(unitId);
        if (unitGuid) {
            this.DebugTimestamp("Scanning auras on %s (%s)", unitGuid, unitId);
            let serial = this.serial[unitGuid] || 0;
            serial = serial + 1;
            this.Debug("    Advancing age of auras for %s (%s) to %d.", unitGuid, unitId, serial);
            this.serial[unitGuid] = serial;
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
                    this.GainedAuraOnGUID(unitGuid, now, spellId, casterGUID, filter, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3);
                    i = i + 1;
                }
            }
            if (this.aura[unitGuid]) {
                let auraTable = this.aura[unitGuid];
                for (const [auraId, whoseTable] of _pairs(auraTable)) {
                    for (const [casterGUID, aura] of _pairs(whoseTable)) {
                        if (aura.serial == serial - 1) {
                            if (aura.visible) {
                                this.LostAuraOnGUID(unitGuid, now, auraId, casterGUID);
                            } else {
                                aura.serial = serial;
                                this.Debug("    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d", aura.name, aura.spellId, aura.start, aura.ending, aura.serial);
                            }
                        }
                    }
                }
            }
            this.Debug("End scanning of auras on %s (%s).", unitGuid, unitId);
        }
        this.profiler.StopProfiling("OvaleAura_ScanAuras");
    }
    GetAuraByGUID(unitGuid: string, auraId, filter, mine) {
        if (!this.serial[unitGuid]) {
            let unitId = OvaleGUID.GUIDUnit(unitGuid);
            this.ScanAuras(unitId, unitGuid);
        }
        let auraFound;
        if (OvaleData.buffSpellList[auraId]) {
            for (const [id] of _pairs(OvaleData.buffSpellList[auraId])) {
                let aura = this.GetAuraOnGUID(this.aura, unitGuid, id, filter, mine);
                if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                    auraFound = aura;
                }
            }
        } else {
            auraFound = this.GetAuraOnGUID(this.aura, unitGuid, auraId, filter, mine);
        }
        return auraFound;
    }
    GetAura(unitId, auraId, filter, mine) {
        let unitGuid = OvaleGUID.UnitGUID(unitId);
        return this.GetAuraByGUID(unitGuid, auraId, filter, mine);
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
            buffName = _tonumber(buffName) || buffName;
            let [guid, unitId, filter, mine];
            if (strsub(requirement, 1, 7) == "target_") {
                if (targetGUID) {
                    guid = targetGUID;
                    unitId = guid.GUIDUnit(guid);
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
            guid = guid || guid.UnitGUID(unitId);
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
    RequireStealthHandler(spellId, atTime, requirement, tokens, index: number, targetGUID) {
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

interface Aura {
    serial: number;
    stacks: number;
    start: number;
    ending: number;
    debuffType: string;
    filter: string;
    state: any;
    name: string;
    gain: number;
}

class OvaleAuraState {
    aura: LuaObj<LuaObj<LuaObj<Aura>>> = {};
    serial = 0;
    currentTime: number;
    
    constructor(private ovaleAura: OvaleAuraClass){}

    ResetState() {
        this.ovaleAura.profiler.StartProfiling("OvaleAura_ResetState");
        this.serial = this.serial + 1;
        if (_next(this.aura)) {
            this.ovaleAura.debug.Log("Resetting aura state:");
        }
        for (const [guid, auraTable] of _pairs(this.aura)) {
            for (const [auraId, whoseTable] of _pairs(auraTable)) {
                for (const [casterGUID, aura] of _pairs(whoseTable)) {
                    this.ovaleAura.self_pool.Release(aura);
                    whoseTable[casterGUID] = undefined;
                    this.ovaleAura.debug.Log("    Aura %d on %s removed.", auraId, guid);
                }
                if (!_next(whoseTable)) {
                    this.ovaleAura.self_pool.Release(whoseTable);
                    auraTable[auraId] = undefined;
                }
            }
            if (!_next(auraTable)) {
                this.ovaleAura.self_pool.Release(auraTable);
                this.aura[guid] = undefined;
            }
        }
        this.ovaleAura.profiler.StopProfiling("OvaleAura_ResetState");
    }
    CleanState() {
        for (const [guid] of _pairs(this.aura)) {
            this.ovaleAura.RemoveAurasOnGUID(this.aura, guid);
        }
    }
    ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.ovaleAura.profiler.StartProfiling("OvaleAura_ApplySpellStartCast");
        if (isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    state.ApplySpellAuras(spellId, this.ovaleAura.self_playerGUID, startCast, si.aura.player, spellcast);
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
        this.ovaleAura.profiler.StopProfiling("OvaleAura_ApplySpellStartCast");
    }
    ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.ovaleAura.profiler.StartProfiling("OvaleAura_ApplySpellAfterCast");
        if (!isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    state.ApplySpellAuras(spellId, this.ovaleAura.self_playerGUID, endCast, si.aura.player, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = OvaleGUID.UnitGUID("pet");
                    if (petGUID) {
                        state.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        this.ovaleAura.profiler.StopProfiling("OvaleAura_ApplySpellAfterCast");
    }
    ApplySpellOnHit(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.ovaleAura.profiler.StartProfiling("OvaleAura_ApplySpellAfterHit");
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
        this.ovaleAura.profiler.StopProfiling("OvaleAura_ApplySpellAfterHit");
    }

    GetStateAura(unitGuid, auraId, casterGUID) {
        let aura = this.ovaleAura.GetAura(this.aura, unitGuid, auraId, casterGUID);
        if (!aura || aura.serial < this.serial) {
            aura =  this.ovaleAura.GetAura(this.ovaleAura.aura, unitGuid, auraId, casterGUID);
        }
        return aura;
    }
    
    GetStateAuraAnyCaster(unitGuid, auraId) {
        let auraFound;
        if (this.ovaleAura.aura[unitGuid] && this.ovaleAura.aura[unitGuid][auraId]) {
            for (const [casterGUID] of _pairs(this.ovaleAura.aura[unitGuid][auraId])) {
                let aura = this.GetStateAura(unitGuid, auraId, casterGUID);
                if (aura && !aura.state && this.ovaleAura.IsActiveAura(aura, this.currentTime)) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
        if (this.aura[unitGuid] && this.aura[unitGuid][auraId]) {
            for (const [casterGUID, aura] of _pairs(this.aura[unitGuid][auraId])) {
                if (aura.stacks > 0) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
        return auraFound;
    }
    GetStateDebuffType(unitGuid, debuffType, filter, casterGUID) {
        let auraFound;
        if (this.ovaleAura.aura[unitGuid]) {
            for (const [auraId] of _pairs(this.ovaleAura.aura[unitGuid])) {
                let aura = this.GetStateAura(unitGuid, auraId, casterGUID);
                if (aura && !aura.state && this.ovaleAura.IsActiveAura(aura, this.currentTime)) {
                    if (aura.debuffType == debuffType && aura.filter == filter) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
        if (this.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.aura[unitGuid])) {
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
    GetStateDebuffTypeAnyCaster(unitGuid, debuffType, filter) {
        let auraFound;
        if (this.ovaleAura.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.ovaleAura.aura[unitGuid])) {
                for (const [casterGUID] of _pairs(whoseTable)) {
                    let aura = this.GetStateAura(unitGuid, auraId, casterGUID);
                    if (aura && !aura.state && this.ovaleAura.IsActiveAura(aura, this.currentTime)) {
                        if (aura.debuffType == debuffType && aura.filter == filter) {
                            if (!auraFound || auraFound.ending < aura.ending) {
                                auraFound = aura;
                            }
                        }
                    }
                }
            }
        }
        if (this.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.aura[unitGuid])) {
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
    GetStateAuraOnGUID(unitGuid, auraId: string, filter, mine) {
        let auraFound;
        if (DEBUFF_TYPE[auraId]) {
            if (mine) {
                auraFound = this.GetStateDebuffType(unitGuid, auraId, filter, this.ovaleAura.self_playerGUID);
                if (!auraFound) {
                    for (const [petGUID] of _pairs(this.ovaleAura.self_petGUID)) {
                        let aura = this.GetStateDebuffType(unitGuid, auraId, filter, petGUID);
                        if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                            auraFound = aura;
                        }
                    }
                }
            } else {
                auraFound = this.GetStateDebuffTypeAnyCaster(unitGuid, auraId, filter);
            }
        } else {
            if (mine) {
                let aura = this.GetStateAura(unitGuid, auraId, this.ovaleAura.self_playerGUID);
                if (aura && aura.stacks > 0) {
                    auraFound = aura;
                } else {
                    for (const [petGUID] of _pairs(this.ovaleAura.self_petGUID)) {
                        aura = this.GetStateAura(unitGuid, auraId, petGUID);
                        if (aura && aura.stacks > 0) {
                            auraFound = aura;
                            break;
                        }
                    }
                }
            } else {
                auraFound = this.GetStateAuraAnyCaster(unitGuid, auraId);
            }
        }
        return auraFound;
    }

    array = {}

    DebugUnitAuras(unitId, filter) {
        _wipe(this.array);
        let unitGuid = OvaleGUID.UnitGUID(unitId);
        if (this.ovaleAura.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.ovaleAura.aura[unitGuid])) {
                for (const [casterGUID] of _pairs(whoseTable)) {
                    let aura = this.GetStateAura(unitGuid, auraId, casterGUID);
                    if (this.IsActiveAura(aura) && aura.filter == filter && !aura.state) {
                        let name = aura.name || "Unknown spell";
                        tinsert(this.array, name + ": " + auraId);
                    }
                }
            }
        }
        if (this.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.aura[unitGuid])) {
                for (const [casterGUID, aura] of _pairs(whoseTable)) {
                    if (this.IsActiveAura(aura) && aura.filter == filter) {
                        let name = aura.name || "Unknown spell";
                        tinsert(this.array, name + ": " + auraId);
                    }
                }
            }
        }
        if (_next(this.array)) {
            tsort(this.array);
            return tconcat(this.array, "\n");
        }
    }

    IsActiveAura(aura, atTime?) {
        atTime = atTime || this.currentTime;
        let boolean = false;
        if (aura) {
            if (aura.state) {
                if (aura.serial == this.serial && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                    boolean = true;
                } else if (aura.consumed && this.ovaleAura.IsWithinAuraLag(aura.ending, atTime)) {
                    boolean = true;
                }
            } else {
                boolean = this.ovaleAura.IsActiveAura(aura, atTime);
            }
        }
        return boolean;
    }
    
    CanApplySpellAura(spellData) {
        if (spellData["if_target_debuff"]) {
        } else if (spellData["if_buff"]) {
        }
    }

    ApplySpellAuras(spellId, unitGuid, atTime, auraList, spellcast) {
        this.ovaleAura.profiler.StartProfiling("OvaleAura_state_ApplySpellAuras");
        for (const [filter, filterInfo] of _pairs(auraList)) {
            for (const [auraId, spellData] of _pairs(filterInfo)) {
                let duration = OvaleData.GetBaseDuration(auraId, spellcast);
                let stacks = 1;
                let count = undefined;
                let extend = 0;
                let toggle = undefined;
                let refresh = false;
                let keepSnapshot = false;
                let [verified, value, auraData] = OvaleData.CheckSpellAuraData(auraId, spellData, atTime, unitGuid);
                if (value == "refresh") {
                    refresh = true;
                } else if (value == "refresh_keep_snapshot") {
                    refresh = true;
                    keepSnapshot = true;
                } else if (value == "toggle") {
                    toggle = true;
                } else if (value == "count") {
                    count = auraData;
                } else if (value == "extend") {
                    extend = auraData;
                } else if (_tonumber(value)) {
                    stacks = _tonumber(value);
                } else {
                    this.ovaleAura.debug.Log("Unknown stack %s", stacks);
                }
                if (verified) {
                    let si = OvaleData.spellInfo[auraId];
                    let auraFound = this.GetAuraByGUID(unitGuid, auraId, filter, true);
                    if (this.IsActiveAura(auraFound, atTime)) {
                        let aura;
                        if (auraFound.state) {
                            aura = auraFound;
                        } else {
                            aura = this.AddAuraToGUID(unitGuid, auraId, auraFound.source, filter, undefined, 0, INFINITY);
                            for (const [k, v] of _pairs(auraFound)) {
                                aura[k] = v;
                            }
                            aura.serial = this.serial;
                            this.ovaleAura.debug.Log("Aura %d is copied into simulator.", auraId);
                        }
                        if (toggle) {
                            this.ovaleAura.debug.Log("Aura %d is toggled off by spell %d.", auraId, spellId);
                            stacks = 0;
                        }
                        if (count && count > 0) {
                            stacks = count - aura.stacks;
                        }
                        if (refresh || extend > 0 || stacks > 0) {
                            if (refresh) {
                                this.ovaleAura.debug.Log("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks);
                            } else if (extend > 0) {
                                this.ovaleAura.debug.Log("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks);
                            } else {
                                let maxStacks = 1;
                                if (si && (si.max_stacks || si.maxstacks)) {
                                    maxStacks = si.max_stacks || si.maxstacks;
                                }
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks > maxStacks) {
                                    aura.stacks = maxStacks;
                                }
                                this.ovaleAura.debug.Log("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId);
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
                            this.ovaleAura.debug.Log("Aura %d with duration %s now ending at %s", auraId, aura.duration, aura.ending);
                            if (keepSnapshot) {
                                this.ovaleAura.debug.Log("Aura %d keeping previous snapshot.", auraId);
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
                                this.ovaleAura.debug.Log("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId);
                            }
                            if (aura.stacks == 0) {
                                this.ovaleAura.debug.Log("Aura %d is completely removed.", auraId);
                                aura.ending = atTime;
                                aura.consumed = true;
                            }
                        }
                    } else {
                        if (toggle) {
                            this.ovaleAura.debug.Log("Aura %d is toggled on by spell %d.", auraId, spellId);
                            stacks = 1;
                        }
                        if (!refresh && stacks > 0) {
                            this.ovaleAura.debug.Log("New aura %d at %f on %s", auraId, atTime, unitGuid);
                            let debuffType;
                            if (si) {
                                for (const [k, v] of _pairs(SPELLINFO_DEBUFF_TYPE)) {
                                    if (si[k] == 1) {
                                        debuffType = v;
                                        break;
                                    }
                                }
                            }
                            let aura = this.AddAuraToGUID(unitGuid, auraId, this.ovaleAura.self_playerGUID, filter, debuffType, 0, INFINITY);
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
                    this.ovaleAura.debug.Log("Aura %d (%s) is not applied.", auraId, spellData);
                }
            }
        }
        this.ovaleAura.profiler.StopProfiling("OvaleAura_state_ApplySpellAuras");
    }

    GetAuraByGUID(unitGuid, auraId, filter, mine) {
        let auraFound;
        if (OvaleData.buffSpellList[auraId]) {
            for (const [id] of _pairs(OvaleData.buffSpellList[auraId])) {
                let aura = this.GetStateAuraOnGUID(unitGuid, id, filter, mine);
                if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                    this.ovaleAura.debug.Log("Aura %s matching '%s' found on %s with (%s, %s)", id, auraId, unitGuid, aura.start, aura.ending);
                    auraFound = aura;
                } else {
                }
            }
            if (!auraFound) {
                this.ovaleAura.debug.Log("Aura matching '%s' is missing on %s.", auraId, unitGuid);
            }
        } else {
            auraFound = this.GetStateAuraOnGUID(unitGuid, auraId, filter, mine);
            if (auraFound) {
                this.ovaleAura.debug.Log("Aura %s found on %s with (%s, %s)", auraId, unitGuid, auraFound.start, auraFound.ending);
            } else {
                this.ovaleAura.debug.Log("Aura %s is missing on %s.", auraId, unitGuid);
            }
        }
        return auraFound;
    }

    GetAura(unitId, auraId, filter, mine) {
        let unitGuid = OvaleGUID.UnitGUID(unitId);
        let stateAura = this.GetAuraByGUID(unitGuid, auraId, filter, mine);
        let aura = this.ovaleAura.GetAuraByGUID(unitGuid, auraId, filter, mine);
        let bypassState = this.ovaleAura.bypassState;
        if (!bypassState[auraId]) {
            bypassState[auraId] = {
            }
        }
        if (bypassState[auraId][unitGuid]) {
            if (aura && aura.start && aura.ending && stateAura && stateAura.start && stateAura.ending && aura.start == stateAura.start && aura.ending == stateAura.ending) {
                bypassState[auraId][unitGuid] = false;
                return stateAura;
            } else {
                return aura;
            }
        }
        return this.GetAuraByGUID(unitGuid, auraId, filter, mine);
    }

    AddAuraToGUID(unitGuid, auraId, casterGUID, filter, debuffType, start, ending, snapshot?) {
        let aura = this.ovaleAura.self_pool.Get();
        aura.state = true;
        aura.serial = this.serial;
        aura.lastUpdated = this.currentTime;
        aura.filter = filter;
        aura.start = start || 0;
        aura.ending = ending || INFINITY;
        aura.duration = aura.ending - aura.start;
        aura.gain = aura.start;
        aura.stacks = 1;
        aura.debuffType = debuffType;
        aura.enrage = (debuffType == "Enrage") || undefined;
        this.UpdateSnapshot(aura, snapshot);
        this.PutAura(this.aura, unitGuid, auraId, casterGUID, aura);
        return aura;
    }

    RemoveAuraOnGUID(unitGuid, auraId, filter, mine, atTime) {
        let auraFound = this.GetAuraByGUID(unitGuid, auraId, filter, mine);
        if (this.IsActiveAura(auraFound, atTime)) {
            let aura;
            if (auraFound.state) {
                aura = auraFound;
            } else {
                aura = this.AddAuraToGUID(unitGuid, auraId, auraFound.source, filter, undefined, 0, INFINITY);
                for (const [k, v] of _pairs(auraFound)) {
                    aura[k] = v;
                }
                aura.serial = this.serial;
            }
            aura.stacks = 0;
            aura.ending = atTime;
            aura.lastUpdated = atTime;
        }
    }
    
    GetAuraWithProperty(unitId, propertyName, filter, atTime) {
        atTime = atTime || this.currentTime;
        let count = 0;
        let unitGuid = OvaleGUID.UnitGUID(unitId);
        let [start, ending] = [INFINITY, 0];
        if (this.ovaleAura.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.ovaleAura.aura[unitGuid])) {
                for (const [casterGUID] of _pairs(whoseTable)) {
                    let aura = this.GetStateAura(unitGuid, auraId, this.ovaleAura.self_playerGUID);
                    if (this.IsActiveAura(aura, atTime) && !aura.state) {
                        if (aura[propertyName] && aura.filter == filter) {
                            count = count + 1;
                            start = (aura.gain < start) && aura.gain || start;
                            ending = (aura.ending > ending) && aura.ending || ending;
                        }
                    }
                }
            }
        }
        if (this.aura[unitGuid]) {
            for (const [auraId, whoseTable] of _pairs(this.aura[unitGuid])) {
                for (const [casterGUID, aura] of _pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime)) {
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
            this.ovaleAura.debug.Log("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending);
        } else {
            this.ovaleAura.debug.Log("Aura with '%s' property is missing on %s.", propertyName, unitId);
            start = undefined;
            ending = undefined;
        }
        return [start, ending];
    }

    count: number;
    stacks: number;
    startChangeCount: number;
    endingChangeCount: number;
    startFirst: number;
    endingLast: number;

    CountMatchingActiveAura(aura) {
        this.ovaleAura.debug.Log("Counting aura %s found on %s with (%s, %s)", aura.spellId, aura.guid, aura.start, aura.ending);
        this.count = this.count + 1;
        this.stacks = this.stacks + aura.stacks;
        if (aura.ending < this.endingChangeCount) {
            [this.startChangeCount, this.endingChangeCount] = [aura.gain, aura.ending];
        }
        if (aura.gain < this.startFirst) {
            this.startFirst = aura.gain;
        }
        if (aura.ending > this.endingLast) {
            this.endingLast = aura.ending;
        }
    }

    AuraCount(auraId, filter, mine, minStacks, atTime, excludeUnitId) {
        this.ovaleAura.profiler.StartProfiling("OvaleAura_state_AuraCount");
        minStacks = minStacks || 1;
        this.count = 0;
        this.stacks = 0;
        [this.startChangeCount, this.endingChangeCount] = [INFINITY, INFINITY];
        [this.startFirst, this.endingLast] = [INFINITY, 0];
        let excludeGUID = excludeUnitId && OvaleGUID.UnitGUID(excludeUnitId) || undefined;
        for (const [unitGuid, auraTable] of _pairs(this.ovaleAura.aura)) {
            if (unitGuid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = this.GetStateAura(unitGuid, auraId, this.ovaleAura.self_playerGUID);
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                        this.CountMatchingActiveAura(aura);
                    }
                    for (const [petGUID] of _pairs(this.ovaleAura.self_petGUID)) {
                        aura = this.GetStateAura(unitGuid, auraId, petGUID);
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [casterGUID] of _pairs(auraTable[auraId])) {
                        let aura = this.GetStateAura(unitGuid, auraId, casterGUID);
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        for (const [guid, auraTable] of _pairs(this.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = auraTable[auraId][this.ovaleAura.self_playerGUID];
                    if (aura) {
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                    for (const [petGUID] of _pairs(this.ovaleAura.self_petGUID)) {
                        aura = auraTable[auraId][petGUID];
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [casterGUID, aura] of _pairs(auraTable[auraId])) {
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        this.ovaleAura.debug.Log("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, this.count, this.stacks, this.startChangeCount, this.endingChangeCount, this.startFirst, this.endingLast);
        this.ovaleAura.profiler.StopProfiling("OvaleAura_state_AuraCount");
        return [this.count, this.stacks, this.startChangeCount, this.endingChangeCount, this.startFirst, this.endingLast];
    }

    RequireBuffHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return this.ovaleAura.RequireBuffHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    } 

    RequireStealthHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return this.ovaleAura.RequireStealthHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }
}

export const OvaleAura = new OvaleAuraClass();