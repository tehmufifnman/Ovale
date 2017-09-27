import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleSigil = Ovale.NewModule("OvaleSigil", "AceEvent-3.0");
Ovale.OvaleSigil = OvaleSigil;
import { OvaleProfiler } from "./OvaleProfiler";
let OvalePaperDoll = undefined;
let OvaleSpellBook = undefined;
let OvaleState = undefined;
let _ipairs = ipairs;
let tinsert = table.insert;
let tremove = table.remove;
let API_GetTime = GetTime;
let UPDATE_DELAY = 0.5;
let SIGIL_ACTIVATION_TIME = math.huge;
let activated_sigils = {
}
OvaleProfiler.RegisterProfiling(OvaleSigil);
class OvaleSigil {
    OnInitialize() {
        OvalePaperDoll = Ovale.OvalePaperDoll;
        OvaleSpellBook = Ovale.OvaleSpellBook;
        OvaleState = Ovale.OvaleState;
        activated_sigils["flame"] = {
        }
        activated_sigils["silence"] = {
        }
        activated_sigils["misery"] = {
        }
        activated_sigils["chains"] = {
        }
    }
    OnEnable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            OvaleState.RegisterState(this, this.statePrototype);
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            OvaleState.UnregisterState(this);
            this.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        }
    }
}
let sigil_start = {
    [204596]: {
        type: "flame"
    },
    [189110]: {
        type: "flame",
        talent: 8
    },
    [202137]: {
        type: "silence"
    },
    [207684]: {
        type: "misery"
    },
    [202138]: {
        type: "chains"
    }
}
let sigil_end = {
    [204598]: {
        type: "flame"
    },
    [204490]: {
        type: "silence"
    },
    [207685]: {
        type: "misery"
    },
    [204834]: {
        type: "chains"
    }
}
let QUICKENED_SIGILS_TALENT = 15;
class OvaleSigil {
    UNIT_SPELLCAST_SUCCEEDED(event, unitId, spellName, spellRank, guid, spellId, ...__args) {
        if ((!OvalePaperDoll.IsSpecialization("vengeance"))) {
            break;
        }
        if ((unitId == undefined || unitId != "player")) {
            break;
        }
        let id = tonumber(spellId);
        if ((sigil_start[id] != undefined)) {
            let s = sigil_start[id];
            let t = s.type;
            let tal = s.talent || undefined;
            if ((tal == undefined || OvaleSpellBook.GetTalentPoints(tal) > 0)) {
                tinsert(activated_sigils[t], API_GetTime());
            }
        }
        if ((sigil_end[id] != undefined)) {
            let s = sigil_end[id];
            let t = s.type;
            tremove(activated_sigils[t], 1);
        }
    }
}
OvaleSigil.statePrototype = {
}
let statePrototype = OvaleSigil.statePrototype;
statePrototype.IsSigilCharging = function (state, type, atTime) {
    atTime = atTime || state.currentTime;
    if ((lualength(activated_sigils[type]) == 0)) {
        return false;
    }
    let charging = false;
    for (const [_, v] of _ipairs(activated_sigils[type])) {
        let activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY;
        if ((OvaleSpellBook.GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0)) {
            activation_time = activation_time - 1;
        }
        charging = charging || atTime < v + activation_time;
    }
    return charging;
}
