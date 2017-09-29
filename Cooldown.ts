import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleData } from "./Data";
import { OvaleFuture } from "./Future";
import { OvaleGUID } from "./GUID";
import { OvalePaperDoll } from "./PaperDoll";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleStance } from "./Stance";
import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
let OvaleCooldownBase = Ovale.NewModule("OvaleCooldown", "AceEvent-3.0");
export let OvaleCooldown: OvaleCooldownClass;
let _next = next;
let _pairs = pairs;
let API_GetSpellCharges = GetSpellCharges;
let API_GetSpellCooldown = GetSpellCooldown;
let API_GetTime = GetTime;
let GLOBAL_COOLDOWN = 61304;
let COOLDOWN_THRESHOLD = 0.10;
let strsub = string.sub;
let BASE_GCD = {
    ["DEATHKNIGHT"]: {
        1: 1.5,
        2: "melee"
    },
    ["DEMONHUNTER"]: {
        1: 1.5,
        2: "melee"
    },
    ["DRUID"]: {
        1: 1.5,
        2: "spell"
    },
    ["HUNTER"]: {
        1: 1.5,
        2: "ranged"
    },
    ["MAGE"]: {
        1: 1.5,
        2: "spell"
    },
    ["MONK"]: {
        1: 1.0,
        2: false
    },
    ["PALADIN"]: {
        1: 1.5,
        2: "spell"
    },
    ["PRIEST"]: {
        1: 1.5,
        2: "spell"
    },
    ["ROGUE"]: {
        1: 1.0,
        2: false
    },
    ["SHAMAN"]: {
        1: 1.5,
        2: "spell"
    },
    ["WARLOCK"]: {
        1: 1.5,
        2: "spell"
    },
    ["WARRIOR"]: {
        1: 1.5,
        2: "melee"
    }
}

class OvaleCooldownClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleCooldownBase)) {

    serial = 0;
    sharedCooldown = {}
    gcd = {
        serial: 0,
        start: 0,
        duration: 0
    }

    OnInitialize() {
    }
    OnEnable() {
        this.RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "Update");
        this.RegisterEvent("BAG_UPDATE_COOLDOWN", "Update");
        this.RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "Update");
        this.RegisterEvent("SPELL_UPDATE_CHARGES", "Update");
        this.RegisterEvent("SPELL_UPDATE_USABLE", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.RegisterEvent("UNIT_SPELLCAST_START", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "Update");
        this.RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "Update");
        OvaleFuture.RegisterSpellcastInfo(this);
        OvaleState.RegisterState(this, this.statePrototype);
        OvaleData.RegisterRequirement("oncooldown", "RequireCooldownHandler", this);
    }
    OnDisable() {
        OvaleState.UnregisterState(this);
        OvaleFuture.UnregisterSpellcastInfo(this);
        OvaleData.UnregisterRequirement("oncooldown");
        this.UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
        this.UnregisterEvent("BAG_UPDATE_COOLDOWN");
        this.UnregisterEvent("PET_BAR_UPDATE_COOLDOWN");
        this.UnregisterEvent("SPELL_UPDATE_CHARGES");
        this.UnregisterEvent("SPELL_UPDATE_USABLE");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
        this.UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.UnregisterEvent("UNIT_SPELLCAST_START");
        this.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        this.UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN");
    }
    UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId) {
        if (unit == "player" || unit == "pet") {
            this.Update(event, unit);
            this.Debug("Resetting global cooldown.");
            let cd = this.gcd;
            cd.start = 0;
            cd.duration = 0;
        }
    }
    Update(event, unit) {
        if (!unit || unit == "player" || unit == "pet") {
            this.serial = this.serial + 1;
            Ovale.refreshNeeded[Ovale.playerGUID] = true;
            this.Debug(event, this.serial);
        }
    }
    ResetSharedCooldowns() {
        for (const [name, spellTable] of _pairs(this.sharedCooldown)) {
            for (const [spellId] of _pairs(spellTable)) {
                spellTable[spellId] = undefined;
            }
        }
    }
    IsSharedCooldown(name) {
        let spellTable = this.sharedCooldown[name];
        return (spellTable && _next(spellTable) != undefined);
    }
    AddSharedCooldown(name, spellId) {
        this.sharedCooldown[name] = this.sharedCooldown[name] || {
        }
        this.sharedCooldown[name][spellId] = true;
    }
    GetGlobalCooldown(now?) {
        let cd = this.gcd;
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            now = now || API_GetTime();
            if (now >= cd.start + cd.duration) {
                [cd.start, cd.duration] = API_GetSpellCooldown(GLOBAL_COOLDOWN);
            }
        }
        return [cd.start, cd.duration];
    }
    GetSpellCooldown(spellId) {
        let [cdStart, cdDuration, cdEnable] = [0, 0, 1];
        if (this.sharedCooldown[spellId]) {
            for (const [id] of _pairs(this.sharedCooldown[spellId])) {
                let [start, duration, enable] = this.GetSpellCooldown(id);
                if (start) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                    break;
                }
            }
        } else {
            let start, duration, enable;
            let [index, bookType] = OvaleSpellBook.GetSpellBookIndex(spellId);
            if (index && bookType) {
                [start, duration, enable] = API_GetSpellCooldown(index, bookType);
            } else {
                [start, duration, enable] = API_GetSpellCooldown(spellId);
            }
            if (start && start > 0) {
                let [gcdStart, gcdDuration] = this.GetGlobalCooldown();
                if (start + duration > gcdStart + gcdDuration) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                } else {
                    cdStart = start + duration;
                    cdDuration = 0;
                    cdEnable = enable;
                }
            } else {
                [cdStart, cdDuration, cdEnable] = [start || 0, duration, enable];
            }
        }
        return [cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable];
    }
    GetBaseGCD() {
        let gcd, haste;
        let baseGCD = BASE_GCD[Ovale.playerClass];
        if (baseGCD) {
            [gcd, haste] = [baseGCD[1], baseGCD[2]];
        } else {
            [gcd, haste] = [1.5, "spell"];
        }
        return [gcd, haste];
    }
    CopySpellcastInfo(spellcast, dest) {
        if (spellcast.offgcd) {
            dest.offgcd = spellcast.offgcd;
        }
    }
    SaveSpellcastInfo(spellcast, atTime, state) {
        let spellId = spellcast.spellId;
        if (spellId) {
            let dataModule = state || OvaleData;
            let gcd = dataModule.GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target);
            if (gcd && gcd == 0) {
                spellcast.offgcd = true;
            }
        }
    }
    RequireCooldownHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let cdSpellId = tokens;
        let verified = false;
        if (index) {
            cdSpellId = tokens[index];
            index = index + 1;
        }
        if (cdSpellId) {
            let isBang = false;
            if (strsub(cdSpellId, 1, 1) == "!") {
                isBang = true;
                cdSpellId = strsub(cdSpellId, 2);
            }
            let cd = this.GetCD(cdSpellId);
            verified = !isBang && cd.duration > 0 || isBang && cd.duration <= 0;
            let result = verified && "passed" || "FAILED";
            this.Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang && "OFF" || !isBang && "ON", atTime, result, cd.duration);
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement);
        }
        return [verified, requirement, index];
    }

    InitializeState(state) {
        state.cd = {
        }
    }
    ResetState(state) {
        for (const [spellId, cd] of _pairs(state.cd)) {
            cd.serial = undefined;
        }
    }
    CleanState(state) {
        for (const [spellId, cd] of _pairs(state.cd)) {
            for (const [k] of _pairs(cd)) {
                cd[k] = undefined;
            }
            state.cd[spellId] = undefined;
        }
    }
    ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleCooldown_ApplySpellStartCast");
        if (isChanneled) {
            state.ApplyCooldown(spellId, targetGUID, startCast);
        }
        this.StopProfiling("OvaleCooldown_ApplySpellStartCast");
    }
    ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleCooldown_ApplySpellAfterCast");
        if (!isChanneled) {
            state.ApplyCooldown(spellId, targetGUID, endCast);
        }
        this.StopProfiling("OvaleCooldown_ApplySpellAfterCast");
    }
}

OvaleCooldown.statePrototype = {
}
let statePrototype = OvaleCooldown.statePrototype;
statePrototype.cd = undefined;

statePrototype.ApplyCooldown = function (state, spellId, targetGUID, atTime) {
    OvaleCooldown.StartProfiling("OvaleCooldown_state_ApplyCooldown");
    let cd = state.GetCD(spellId);
    let duration = state.GetSpellCooldownDuration(spellId, atTime, targetGUID);
    if (duration == 0) {
        cd.start = 0;
        cd.duration = 0;
        cd.enable = 1;
    } else {
        cd.start = atTime;
        cd.duration = duration;
        cd.enable = 1;
    }
    if (cd.charges && cd.charges > 0) {
        cd.chargeStart = cd.start;
        cd.charges = cd.charges - 1;
        if (cd.charges == 0) {
            cd.duration = cd.chargeDuration;
        }
    }
    state.Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges || "(nil)");
    OvaleCooldown.StopProfiling("OvaleCooldown_state_ApplyCooldown");
}
statePrototype.DebugCooldown = function (state) {
    for (const [spellId, cd] of _pairs(state.cd)) {
        if (cd.start) {
            if (cd.charges) {
                OvaleCooldown.Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration);
            } else {
                OvaleCooldown.Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration);
            }
        }
    }
}
statePrototype.GetGCD = function (state, spellId, atTime, targetGUID) {
    spellId = spellId || state.currentSpellId;
    if (!atTime) {
        if (state.endCast && state.endCast > state.currentTime) {
            atTime = state.endCast;
        } else {
            atTime = state.currentTime;
        }
    }
    targetGUID = targetGUID || OvaleGUID.UnitGUID(state.defaultTarget);
    let gcd = spellId && state.GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID);
    if (!gcd) {
        let haste;
        [gcd, haste] = OvaleCooldown.GetBaseGCD();
        if (Ovale.playerClass == "MONK" && OvalePaperDoll.IsSpecialization("mistweaver")) {
            gcd = 1.5;
            haste = "spell";
        } else if (Ovale.playerClass == "DRUID") {
            if (OvaleStance.IsStance("druid_cat_form")) {
                gcd = 1.0;
                haste = false;
            }
        }
        let gcdHaste = spellId && state.GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID);
        if (gcdHaste) {
            haste = gcdHaste;
        } else {
            let siHaste = spellId && state.GetSpellInfoProperty(spellId, atTime, "haste", targetGUID);
            if (siHaste) {
                haste = siHaste;
            }
        }
        let multiplier = state.GetHasteMultiplier(haste);
        gcd = gcd / multiplier;
        gcd = (gcd > 0.750) && gcd || 0.750;
    }
    return gcd;
}
statePrototype.GetCD = function (state, spellId) {
    OvaleCooldown.StartProfiling("OvaleCooldown_state_GetCD");
    let cdName = spellId;
    let si = OvaleData.spellInfo[spellId];
    if (si && si.sharedcd) {
        cdName = si.sharedcd;
    }
    if (!state.cd[cdName]) {
        state.cd[cdName] = {
        }
    }
    let cd = state.cd[cdName];
    if (!cd.start || !cd.serial || cd.serial < OvaleCooldown.serial) {
        let [start, duration, enable] = OvaleCooldown.GetSpellCooldown(spellId);
        if (si && si.forcecd) {
            [start, duration] = OvaleCooldown.GetSpellCooldown(si.forcecd);
        }
        cd.serial = OvaleCooldown.serial;
        cd.start = start - COOLDOWN_THRESHOLD;
        cd.duration = duration;
        cd.enable = enable;
        let [charges, maxCharges, chargeStart, chargeDuration] = API_GetSpellCharges(spellId);
        if (charges) {
            cd.charges = charges;
            cd.maxCharges = maxCharges;
            cd.chargeStart = chargeStart;
            cd.chargeDuration = chargeDuration;
        }
    }
    let now = state.currentTime;
    if (cd.start) {
        if (cd.start + cd.duration <= now) {
            cd.start = 0;
            cd.duration = 0;
        }
    }
    if (cd.charges) {
        let [charges, maxCharges, chargeStart, chargeDuration] = [cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration];
        while (chargeStart + chargeDuration <= now && charges < maxCharges) {
            chargeStart = chargeStart + chargeDuration;
            charges = charges + 1;
        }
        cd.charges = charges;
        cd.chargeStart = chargeStart;
    }
    OvaleCooldown.StopProfiling("OvaleCooldown_state_GetCD");
    return cd;
}
statePrototype.GetSpellCooldown = function (state, spellId) {
    let cd = state.GetCD(spellId);
    return [cd.start, cd.duration, cd.enable];
}
statePrototype.GetSpellCooldownDuration = function (state, spellId, atTime, targetGUID) {
    let [start, duration] = state.GetSpellCooldown(spellId);
    if (duration > 0 && start + duration > atTime) {
        state.Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start);
    } else {
        let si = OvaleData.spellInfo[spellId];
        duration = state.GetSpellInfoProperty(spellId, atTime, "cd", targetGUID);
        if (duration) {
            if (si && si.addcd) {
                duration = duration + si.addcd;
            }
            if (duration < 0) {
                duration = 0;
            }
        } else {
            duration = 0;
        }
        state.Log("Spell %d has a base cooldown of %fs.", spellId, duration);
        if (duration > 0) {
            let haste = state.GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID);
            let multiplier = state.GetHasteMultiplier(haste);
            duration = duration / multiplier;
            if (si && si.buff_cdr) {
                let aura = state.GetAura("player", si.buff_cdr);
                if (state.IsActiveAura(aura, atTime)) {
                    duration = duration * aura.value1;
                }
            }
        }
    }
    return duration;
}
statePrototype.GetSpellCharges = function (state, spellId, atTime) {
    atTime = atTime || state.currentTime;
    let cd = state.GetCD(spellId);
    let [charges, maxCharges, chargeStart, chargeDuration] = [cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration];
    if (charges) {
        while (chargeStart + chargeDuration <= atTime && charges < maxCharges) {
            chargeStart = chargeStart + chargeDuration;
            charges = charges + 1;
        }
    }
    return [charges, maxCharges, chargeStart, chargeDuration];
}
statePrototype.ResetSpellCooldown = function (state, spellId, atTime) {
    let now = state.currentTime;
    if (atTime >= now) {
        let cd = state.GetCD(spellId);
        if (cd.start + cd.duration > now) {
            cd.start = now;
            cd.duration = atTime - now;
        }
    }
}
statePrototype.RequireCooldownHandler = OvaleCooldown.RequireCooldownHandler;
OvaleCooldown = new OvaleCooldownClass();