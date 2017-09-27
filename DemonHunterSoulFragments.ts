import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleDemonHunterSoulFragments = Ovale.NewModule("OvaleDemonHunterSoulFragments", "AceEvent-3.0");
Ovale.OvaleDemonHunterSoulFragments = OvaleDemonHunterSoulFragments;
let OvaleDebug = undefined;
let OvaleState = undefined;
let _ipairs = ipairs;
let tinsert = table.insert;
let tremove = table.remove;
let API_GetTime = GetTime;
let API_GetSpellCount = GetSpellCount;
class OvaleDemonHunterSoulFragments {
    OnInitialize() {
        OvaleDebug = Ovale.OvaleDebug;
        OvaleState = Ovale.OvaleState;
        OvaleDebug.RegisterDebugging(OvaleDemonHunterSoulFragments);
        this.SetCurrentSoulFragments(0);
    }
    OnEnable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.RegisterEvent("PLAYER_REGEN_ENABLED");
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            this.RegisterEvent("PLAYER_REGEN_DISABLED");
            OvaleState.RegisterState(this, this.statePrototype);
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            OvaleState.UnregisterState(this);
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            this.UnregisterEvent("PLAYER_REGEN_ENABLED");
            this.UnregisterEvent("PLAYER_REGEN_DISABLED");
        }
    }
}
let SOUL_FRAGMENTS_BUFF_ID = 228477;
let SOUL_FRAGMENTS_SPELL_HEAL_ID = 203794;
let SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID = 204255;
let SOUL_FRAGMENT_FINISHERS = {
    [228477]: true,
    [247454]: true,
    [227225]: true
}
class OvaleDemonHunterSoulFragments {
    PLAYER_REGEN_ENABLED() {
        this.SetCurrentSoulFragments();
    }
    PLAYER_REGEN_DISABLED() {
        this.soul_fragments = {
        }
        this.last_checked = undefined;
        this.SetCurrentSoulFragments();
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, _, subtype, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName) {
        import { me } from "./playerGUID";
        if (sourceGUID == me) {
            let current_sould_fragment_count = this.last_soul_fragment_count;
            if (subtype == "SPELL_HEAL" && spellID == SOUL_FRAGMENTS_SPELL_HEAL_ID) {
                this.SetCurrentSoulFragments(this.last_soul_fragment_count.fragments - 1);
            }
            if (subtype == "SPELL_CAST_SUCCESS" && spellID == SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID) {
                this.SetCurrentSoulFragments(this.last_soul_fragment_count.fragments + 1);
            }
            if (subtype == "SPELL_CAST_SUCCESS" && SOUL_FRAGMENT_FINISHERS[spellID]) {
                this.SetCurrentSoulFragments(0);
            }
            let now = API_GetTime();
            if (this.last_checked == undefined || now - this.last_checked >= 1.5) {
                this.SetCurrentSoulFragments();
            }
        }
    }
    SetCurrentSoulFragments(count) {
        let now = API_GetTime();
        this.last_checked = now;
        this.soul_fragments = this.soul_fragments || {
        }
        if (type(count) != "number") {
            count = API_GetSpellCount(SOUL_FRAGMENTS_BUFF_ID) || 0;
        }
        if (count < 0) {
            count = 0;
        }
        if (this.last_soul_fragment_count == undefined || this.last_soul_fragment_count.fragments != count) {
            let entry = {
                ["timestamp"]: now,
                ["fragments"]: count
            }
            this.Debug("Setting current soul fragment count to '%d' (at: %s)", entry.fragments, entry.timestamp);
            this.last_soul_fragment_count = entry;
            tinsert(this.soul_fragments, entry);
        }
    }
    DebugSoulFragments() {
        print("Fragments:" + this.last_soul_fragment_count["fragments"]);
        print("Time:" + this.last_soul_fragment_count["timestamp"]);
    }
}
OvaleDemonHunterSoulFragments.statePrototype = {
}
let statePrototype = OvaleDemonHunterSoulFragments.statePrototype;
statePrototype.SoulFragments = function (state, atTime) {
    for (const [k, v] of spairs(OvaleDemonHunterSoulFragments.soul_fragments, function (t, a, b) {
        return t[a]["timestamp"] > t[b]["timestamp"];
    })) {
        if ((atTime >= v["timestamp"])) {
            return v["fragments"];
        }
    }
    return (OvaleDemonHunterSoulFragments.last_soul_fragment_count != undefined && OvaleDemonHunterSoulFragments.last_soul_fragment_count.fragments) || 0;
}
function spairs(t, order) {
    let keys = {
    }
    for (const [k] of pairs(t)) {
        keys[lualength(keys) + 1] = k;
    }
    if (order) {
        table.sort(keys, function (a, b) {
            return order(t, a, b);
        });
    } else {
        table.sort(keys);
    }
    let i = 0;
    return function () {
        i = i + 1;
        if (keys[i]) {
            return [keys[i], t[keys[i]]];
        }
    };
}
