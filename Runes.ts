import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleRunes = Ovale.NewModule("OvaleRunes", "AceEvent-3.0");
Ovale.OvaleRunes = OvaleRunes;
import { OvaleDebug } from "./OvaleDebug";
import { OvaleProfiler } from "./OvaleProfiler";
let OvaleData = undefined;
let OvaleEquipment = undefined;
let OvalePower = undefined;
let OvaleSpellBook = undefined;
let OvaleStance = undefined;
let OvaleState = undefined;
let _ipairs = ipairs;
let _pairs = pairs;
let _type = type;
let _wipe = wipe;
let API_GetRuneCooldown = GetRuneCooldown;
let API_GetSpellInfo = GetSpellInfo;
let API_GetTime = GetTime;
let INFINITY = math.huge;
let _sort = sort;
OvaleDebug.RegisterDebugging(OvaleRunes);
OvaleProfiler.RegisterProfiling(OvaleRunes);
let EMPOWER_RUNE_WEAPON = 47568;
let RUNE_SLOTS = 6;
OvaleRunes.rune = {
}
const IsActiveRune = function(rune, atTime) {
    return (rune.startCooldown == 0 || rune.endCooldown <= atTime);
}
class OvaleRunes {
    OnInitialize() {
        OvaleData = Ovale.OvaleData;
        OvaleEquipment = Ovale.OvaleEquipment;
        OvalePower = Ovale.OvalePower;
        OvaleSpellBook = Ovale.OvaleSpellBook;
        OvaleStance = Ovale.OvaleStance;
        OvaleState = Ovale.OvaleState;
    }
    OnEnable() {
        if (Ovale.playerClass == "DEATHKNIGHT") {
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                this.rune[slot] = {
                    slot: slot,
                    IsActiveRune: IsActiveRune
                }
            }
            this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllRunes");
            this.RegisterEvent("RUNE_POWER_UPDATE");
            this.RegisterEvent("RUNE_TYPE_UPDATE");
            this.RegisterEvent("UNIT_RANGEDDAMAGE");
            this.RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE");
            OvaleState.RegisterState(this, this.statePrototype);
            this.UpdateAllRunes();
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEATHKNIGHT") {
            this.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.UnregisterEvent("RUNE_POWER_UPDATE");
            this.UnregisterEvent("RUNE_TYPE_UPDATE");
            this.UnregisterEvent("UNIT_RANGEDDAMAGE");
            this.UnregisterEvent("UNIT_SPELL_HASTE");
            OvaleState.UnregisterState(this);
            this.rune = {
            }
        }
    }
    RUNE_POWER_UPDATE(event, slot, usable) {
        this.Debug(event, slot, usable);
        this.UpdateRune(slot);
    }
    RUNE_TYPE_UPDATE(event, slot) {
        this.Debug(event, slot);
        this.UpdateRune(slot);
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.Debug(event);
            this.UpdateAllRunes();
        }
    }
    UpdateRune(slot) {
        this.StartProfiling("OvaleRunes_UpdateRune");
        let rune = this.rune[slot];
        let [start, duration, runeReady] = API_GetRuneCooldown(slot);
        if (start && duration) {
            if (start > 0) {
                rune.startCooldown = start;
                rune.endCooldown = start + duration;
            } else {
                rune.startCooldown = 0;
                rune.endCooldown = 0;
            }
            Ovale.refreshNeeded[Ovale.playerGUID] = true;
        } else {
            this.Debug("Warning: rune information for slot %d not available.", slot);
        }
        this.StopProfiling("OvaleRunes_UpdateRune");
    }
    UpdateAllRunes(event) {
        this.Debug(event);
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            this.UpdateRune(slot);
        }
    }
    DebugRunes() {
        let now = API_GetTime();
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = this.rune[slot];
            if (rune.IsActiveRune(now)) {
                this.Print("rune[%d] is active.", slot);
            } else {
                this.Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now);
            }
        }
    }
}
OvaleRunes.statePrototype = {
}
let statePrototype = OvaleRunes.statePrototype;
statePrototype.rune = undefined;
class OvaleRunes {
    InitializeState(state) {
        state.rune = {
        }
        for (const [slot] of _ipairs(this.rune)) {
            state.rune[slot] = {
            }
        }
    }
    ResetState(state) {
        this.StartProfiling("OvaleRunes_ResetState");
        for (const [slot, rune] of _ipairs(this.rune)) {
            let stateRune = state.rune[slot];
            for (const [k, v] of _pairs(rune)) {
                stateRune[k] = v;
            }
        }
        this.StopProfiling("OvaleRunes_ResetState");
    }
    CleanState(state) {
        for (const [slot, rune] of _ipairs(state.rune)) {
            for (const [k] of _pairs(rune)) {
                rune[k] = undefined;
            }
            state.rune[slot] = undefined;
        }
    }
    ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleRunes_ApplySpellStartCast");
        if (isChanneled) {
            state.ApplyRuneCost(spellId, startCast, spellcast);
        }
        this.StopProfiling("OvaleRunes_ApplySpellStartCast");
    }
    ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleRunes_ApplySpellAfterCast");
        if (!isChanneled) {
            state.ApplyRuneCost(spellId, endCast, spellcast);
            if (spellId == EMPOWER_RUNE_WEAPON) {
                for (const [slot] of _ipairs(state.rune)) {
                    state.ReactivateRune(slot, endCast);
                }
            }
        }
        this.StopProfiling("OvaleRunes_ApplySpellAfterCast");
    }
}
statePrototype.DebugRunes = function (state) {
    OvaleRunes.Print("Current rune state:");
    let now = state.currentTime;
    for (const [slot, rune] of _ipairs(state.rune)) {
        if (rune.IsActiveRune(now)) {
            OvaleRunes.Print("    rune[%d] is active.", slot);
        } else {
            OvaleRunes.Print("    rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now);
        }
    }
}
statePrototype.ApplyRuneCost = function (state, spellId, atTime, spellcast) {
    let si = OvaleData.spellInfo[spellId];
    if (si) {
        let count = si.runes || 0;
        while (count > 0) {
            state.ConsumeRune(spellId, atTime, spellcast);
            count = count - 1;
        }
    }
}
statePrototype.ReactivateRune = function (state, slot, atTime) {
    let rune = state.rune[slot];
    if (atTime < state.currentTime) {
        atTime = state.currentTime;
    }
    if (rune.startCooldown > atTime) {
        rune.startCooldown = atTime;
    }
    rune.endCooldown = atTime;
}
statePrototype.ConsumeRune = function (state, spellId, atTime, snapshot) {
    OvaleRunes.StartProfiling("OvaleRunes_state_ConsumeRune");
    let consumedRune;
    for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
        let rune = state.rune[slot];
        if (rune.IsActiveRune(atTime)) {
            consumedRune = rune;
            break;
        }
    }
    if (consumedRune) {
        let start = atTime;
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = state.rune[slot];
            if (rune.endCooldown > start) {
                start = rune.endCooldown;
            }
        }
        let duration = 10 / state.GetSpellHasteMultiplier(snapshot);
        consumedRune.startCooldown = start;
        consumedRune.endCooldown = start + duration;
        let runicpower = state.runicpower;
        runicpower = runicpower + 10;
        let maxi = OvalePower.maxPower.runicpower;
        state.runicpower = (runicpower < maxi) && runicpower || maxi;
    } else {
        state.Log("No %s rune available at %f to consume for spell %d!", RUNE_NAME[runeType], atTime, spellId);
    }
    OvaleRunes.StopProfiling("OvaleRunes_state_ConsumeRune");
}
statePrototype.RuneCount = function (state, atTime) {
    OvaleRunes.StartProfiling("OvaleRunes_state_RuneCount");
    atTime = atTime || state.currentTime;
    let count = 0;
    let [startCooldown, endCooldown] = [INFINITY, INFINITY];
    for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
        let rune = state.rune[slot];
        if (rune.IsActiveRune(atTime)) {
            count = count + 1;
        } else if (rune.endCooldown < endCooldown) {
            [startCooldown, endCooldown] = [rune.startCooldown, rune.endCooldown];
        }
    }
    OvaleRunes.StopProfiling("OvaleRunes_state_RuneCount");
    return [count, startCooldown, endCooldown];
}
statePrototype.GetRunesCooldown = undefined;
{
    let count = {
    }
    let usedRune = {
    }
    statePrototype.GetRunesCooldown = function (state, atTime, runes) {
        if (runes <= 0) {
            return 0;
        }
        if (runes > RUNE_SLOTS) {
            state.Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS);
            return 0;
        }
        OvaleRunes.StartProfiling("OvaleRunes_state_GetRunesCooldown");
        atTime = atTime || state.currentTime;
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = state.rune[slot];
            usedRune[slot] = rune.endCooldown - atTime;
        }
        _sort(usedRune);
        OvaleRunes.StopProfiling("OvaleRunes_state_GetRunesCooldown");
        return usedRune[runes];
    }
}
