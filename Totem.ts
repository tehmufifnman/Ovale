import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleTotem = Ovale.NewModule("OvaleTotem", "AceEvent-3.0");
Ovale.OvaleTotem = OvaleTotem;
import { OvaleProfiler } from "./OvaleProfiler";
let OvaleData = undefined;
let OvaleSpellBook = undefined;
let OvaleState = undefined;
let _ipairs = ipairs;
let _pairs = pairs;
let API_GetTotemInfo = GetTotemInfo;
let _AIR_TOTEM_SLOT = AIR_TOTEM_SLOT;
let _EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT;
let _FIRE_TOTEM_SLOT = FIRE_TOTEM_SLOT;
let INFINITY = math.huge;
let _MAX_TOTEMS = MAX_TOTEMS;
let _WATER_TOTEM_SLOT = WATER_TOTEM_SLOT;
OvaleProfiler.RegisterProfiling(OvaleTotem);
let self_serial = 0;
let TOTEM_CLASS = {
    DRUID: true,
    MAGE: true,
    MONK: true,
    SHAMAN: true
}
let TOTEM_SLOT = {
    air: _AIR_TOTEM_SLOT,
    earth: _EARTH_TOTEM_SLOT,
    fire: _FIRE_TOTEM_SLOT,
    water: _WATER_TOTEM_SLOT,
    spirit_wolf: 1
}
let TOTEMIC_RECALL = 36936;
OvaleTotem.totem = {
}
class OvaleTotem {
    OnInitialize() {
        OvaleData = Ovale.OvaleData;
        OvaleSpellBook = Ovale.OvaleSpellBook;
        OvaleState = Ovale.OvaleState;
    }
    OnEnable() {
        if (TOTEM_CLASS[Ovale.playerClass]) {
            this.RegisterEvent("PLAYER_ENTERING_WORLD", "Update");
            this.RegisterEvent("PLAYER_TALENT_UPDATE", "Update");
            this.RegisterEvent("PLAYER_TOTEM_UPDATE", "Update");
            this.RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update");
            OvaleState.RegisterState(this, this.statePrototype);
        }
    }
    OnDisable() {
        if (TOTEM_CLASS[Ovale.playerClass]) {
            OvaleState.UnregisterState(this);
            this.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.UnregisterEvent("PLAYER_TALENT_UPDATE");
            this.UnregisterEvent("PLAYER_TOTEM_UPDATE");
            this.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        }
    }
    Update() {
        self_serial = self_serial + 1;
        Ovale.refreshNeeded[Ovale.playerGUID] = true;
    }
}
OvaleTotem.statePrototype = {
}
let statePrototype = OvaleTotem.statePrototype;
statePrototype.totem = undefined;
class OvaleTotem {
    InitializeState(state) {
        state.totem = {
        }
        for (let slot = 1; slot <= _MAX_TOTEMS; slot += 1) {
            state.totem[slot] = {
            }
        }
    }
    CleanState(state) {
        for (const [slot, totem] of _pairs(state.totem)) {
            for (const [k] of _pairs(totem)) {
                totem[k] = undefined;
            }
            state.totem[slot] = undefined;
        }
    }
    ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        this.StartProfiling("OvaleTotem_ApplySpellAfterCast");
        if (Ovale.playerClass == "SHAMAN" && spellId == TOTEMIC_RECALL) {
            for (const [slot] of _ipairs(state.totem)) {
                state.DestroyTotem(slot, endCast);
            }
        } else {
            let atTime = endCast;
            let slot = state.GetTotemSlot(spellId, atTime);
            if (slot) {
                state.SummonTotem(spellId, slot, atTime);
            }
        }
        this.StopProfiling("OvaleTotem_ApplySpellAfterCast");
    }
}
statePrototype.IsActiveTotem = function (state, totem, atTime) {
    atTime = atTime || state.currentTime;
    let boolean = false;
    if (totem && (totem.serial == self_serial) && totem.start && totem.duration && totem.start < atTime && atTime < totem.start + totem.duration) {
        boolean = true;
    }
    return boolean;
}
statePrototype.GetTotem = function (state, slot) {
    OvaleTotem.StartProfiling("OvaleTotem_state_GetTotem");
    slot = TOTEM_SLOT[slot] || slot;
    let totem = state.totem[slot];
    if (totem && (!totem.serial || totem.serial < self_serial)) {
        let [haveTotem, name, startTime, duration, icon] = API_GetTotemInfo(slot);
        if (haveTotem) {
            totem.name = name;
            totem.start = startTime;
            totem.duration = duration;
            totem.icon = icon;
        } else {
            totem.name = "";
            totem.start = 0;
            totem.duration = 0;
            totem.icon = "";
        }
        totem.serial = self_serial;
    }
    OvaleTotem.StopProfiling("OvaleTotem_state_GetTotem");
    return totem;
}
statePrototype.GetTotemInfo = function (state, slot) {
    let [haveTotem, name, startTime, duration, icon];
    slot = TOTEM_SLOT[slot] || slot;
    let totem = state.GetTotem(slot);
    if (totem) {
        haveTotem = state.IsActiveTotem(totem);
        name = totem.name;
        startTime = totem.start;
        duration = totem.duration;
        icon = totem.icon;
    }
    return [haveTotem, name, startTime, duration, icon];
}
statePrototype.GetTotemCount = function (state, spellId, atTime) {
    atTime = atTime || state.currentTime;
    let [start, ending];
    let count = 0;
    let si = OvaleData.spellInfo[spellId];
    if (si && si.totem) {
        let buffPresent = true;
        if (si.buff_totem) {
            let aura = state.GetAura("player", si.buff_totem);
            buffPresent = state.IsActiveAura(aura, atTime);
        }
        if (buffPresent) {
            let texture = OvaleSpellBook.GetSpellTexture(spellId);
            let maxTotems = si.max_totems || 1;
            for (const [slot] of _ipairs(state.totem)) {
                let totem = state.GetTotem(slot);
                if (state.IsActiveTotem(totem, atTime) && totem.icon == texture) {
                    count = count + 1;
                    if (!start || start > totem.start) {
                        start = totem.start;
                    }
                    if (!ending || ending < totem.start + totem.duration) {
                        ending = totem.start + totem.duration;
                    }
                }
                if (count >= maxTotems) {
                    break;
                }
            }
        }
    }
    return [count, start, ending];
}
statePrototype.GetTotemSlot = function (state, spellId, atTime) {
    OvaleTotem.StartProfiling("OvaleTotem_state_GetTotemSlot");
    atTime = atTime || state.currentTime;
    let totemSlot;
    let si = OvaleData.spellInfo[spellId];
    if (si && si.totem) {
        totemSlot = TOTEM_SLOT[si.totem];
        if (!totemSlot) {
            let availableSlot;
            for (const [slot] of _ipairs(state.totem)) {
                let totem = state.GetTotem(slot);
                if (!state.IsActiveTotem(totem, atTime)) {
                    availableSlot = slot;
                    break;
                }
            }
            let texture = OvaleSpellBook.GetSpellTexture(spellId);
            let maxTotems = si.max_totems || 1;
            let count = 0;
            let start = INFINITY;
            for (const [slot] of _ipairs(state.totem)) {
                let totem = state.GetTotem(slot);
                if (state.IsActiveTotem(totem, atTime) && totem.icon == texture) {
                    count = count + 1;
                    if (start > totem.start) {
                        start = totem.start;
                        totemSlot = slot;
                    }
                }
            }
            if (count < maxTotems) {
                totemSlot = availableSlot;
            }
        }
        totemSlot = totemSlot || 1;
    }
    OvaleTotem.StopProfiling("OvaleTotem_state_GetTotemSlot");
    return totemSlot;
}
statePrototype.SummonTotem = function (state, spellId, slot, atTime) {
    OvaleTotem.StartProfiling("OvaleTotem_state_SummonTotem");
    atTime = atTime || state.currentTime;
    slot = TOTEM_SLOT[slot] || slot;
    state.Log("Spell %d summons totem into slot %d.", spellId, slot);
    let [name, _, icon] = OvaleSpellBook.GetSpellInfo(spellId);
    let duration = state.GetSpellInfoProperty(spellId, atTime, "duration");
    let totem = state.totem[slot];
    totem.name = name;
    totem.start = atTime;
    totem.duration = duration || 15;
    totem.icon = icon;
    OvaleTotem.StopProfiling("OvaleTotem_state_SummonTotem");
}
statePrototype.DestroyTotem = function (state, slot, atTime) {
    OvaleTotem.StartProfiling("OvaleTotem_state_DestroyTotem");
    atTime = atTime || state.currentTime;
    slot = TOTEM_SLOT[slot] || slot;
    state.Log("Destroying totem in slot %d.", slot);
    let totem = state.totem[slot];
    let duration = atTime - totem.start;
    if (duration < 0) {
        duration = 0;
    }
    totem.duration = duration;
    OvaleTotem.StopProfiling("OvaleTotem_state_DestroyTotem");
}
