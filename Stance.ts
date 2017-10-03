import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleData, dataState } from "./Data";
import { OvaleState, StateModule } from "./State";

let OvaleStanceBase = Ovale.NewModule("OvaleStance", "AceEvent-3.0");
export let OvaleStance: OvaleStanceClass;
let _ipairs = ipairs;
let _pairs = pairs;
let substr = string.sub;
let tconcat = table.concat;
let tinsert = table.insert;
let _tonumber = tonumber;
let tsort = table.sort;
let _type = type;
let _wipe = wipe;
let API_GetNumShapeshiftForms = GetNumShapeshiftForms;
let API_GetShapeshiftForm = GetShapeshiftForm;
let API_GetShapeshiftFormInfo = GetShapeshiftFormInfo;
let API_GetSpellInfo = GetSpellInfo;

const [druidCatForm] = API_GetSpellInfo(768);
const [druidTravelForm] = API_GetSpellInfo(783);
const [druidAquaticForm] = API_GetSpellInfo(1066);
const [druidBearForm] = API_GetSpellInfo(5487);
const [druidMoonkinForm] =API_GetSpellInfo(24858);
const [druid_flight_form] = API_GetSpellInfo(33943);
const [druid_swift_flight_form] = API_GetSpellInfo(40120);
const [rogue_stealth] = API_GetSpellInfo(1784);

let SPELL_NAME_TO_STANCE = {
    [druidCatForm]: "druid_cat_form",
    [druidTravelForm]: "druid_travel_form",
    [druidAquaticForm]: "druid_aquatic_form",
    [druidBearForm]: "druid_bear_form",
    [druidMoonkinForm]: "druid_moonkin_form",
    [druid_flight_form]: "druid_flight_form",
    [druid_swift_flight_form]: "druid_swift_flight_form",
    [rogue_stealth]: "rogue_stealth"
}
let STANCE_NAME = {
}
{
    for (const [_, name] of _pairs(SPELL_NAME_TO_STANCE)) {
        STANCE_NAME[name] = true;
    }
}
{
    let debugOptions = {
        stance: {
            name: L["Stances"],
            type: "group",
            args: {
                stance: {
                    name: L["Stances"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: function (info) {
                        return OvaleStance.DebugStances();
                    }
                }
            }
        }
    }
    for (const [k, v] of _pairs(debugOptions)) {
        OvaleDebug.options.args[k] = v;
    }
}
let array = {
}

class OvaleStanceClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleStanceBase)) {
    ready = false;
    stanceList = {
    }
    stanceId = {
    }
    stance = undefined;
    STANCE_NAME = STANCE_NAME;

    
    OnInitialize() {
    }
    OnEnable() {
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances");
        this.RegisterEvent("UPDATE_SHAPESHIFT_FORM");
        this.RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
        this.RegisterMessage("Ovale_SpellsChanged", "UpdateStances");
        this.RegisterMessage("Ovale_TalentsChanged", "UpdateStances");
        OvaleData.RegisterRequirement("stance", "RequireStanceHandler", this);
    }
    OnDisable() {
        OvaleData.UnregisterRequirement("stance");
        this.UnregisterEvent("PLAYER_ALIVE");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        this.UnregisterEvent("UPDATE_SHAPESHIFT_FORMS");
        this.UnregisterMessage("Ovale_SpellsChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    PLAYER_TALENT_UPDATE(event) {
        this.stance = undefined;
        this.UpdateStances();
    }
    UPDATE_SHAPESHIFT_FORM(event) {
        this.ShapeshiftEventHandler();
    }
    UPDATE_SHAPESHIFT_FORMS(event) {
        this.ShapeshiftEventHandler();
    }
    CreateStanceList() {
        this.StartProfiling("OvaleStance_CreateStanceList");
        _wipe(this.stanceList);
        _wipe(this.stanceId);
        let _, name, stanceName;
        for (let i = 1; i <= API_GetNumShapeshiftForms(); i += 1) {
            [_, name] = API_GetShapeshiftFormInfo(i);
            stanceName = SPELL_NAME_TO_STANCE[name];
            if (stanceName) {
                this.stanceList[i] = stanceName;
                this.stanceId[stanceName] = i;
            }
        }
        this.StopProfiling("OvaleStance_CreateStanceList");
    }
    DebugStances() {
        _wipe(array);
        for (const [k, v] of _pairs(this.stanceList)) {
            if (this.stance == k) {
                tinsert(array, `${v} (active)`);
            } else {
                tinsert(array, v);
            }
        }
        tsort(array);
        return tconcat(array, "\n");
    }

    GetStance(stanceId) {
        stanceId = stanceId || this.stance;
        return this.stanceList[stanceId];
    }
    IsStance(name) {
        if (name && this.stance) {
            if (_type(name) == "number") {
                return name == this.stance;
            } else {
                return name == OvaleStance.GetStance(this.stance);
            }
        }
        return false;
    }
    IsStanceSpell(spellId) {
        let [name] = API_GetSpellInfo(spellId);
        return !!(name && SPELL_NAME_TO_STANCE[name]);
    }
    ShapeshiftEventHandler() {
        this.StartProfiling("OvaleStance_ShapeshiftEventHandler");
        let oldStance = this.stance;
        let newStance = API_GetShapeshiftForm();
        if (oldStance != newStance) {
            this.stance = newStance;
            Ovale.refreshNeeded[Ovale.playerGUID] = true;
            this.SendMessage("Ovale_StanceChanged", this.GetStance(newStance), this.GetStance(oldStance));
        }
        this.StopProfiling("OvaleStance_ShapeshiftEventHandler");
    }
    UpdateStances() {
        this.CreateStanceList();
        this.ShapeshiftEventHandler();
        this.ready = true;
    }
    RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let stance = tokens;
        if (index) {
            stance = tokens[index];
            index = index + 1;
        }
        if (stance) {
            let isBang = false;
            if (substr(stance, 1, 1) == "!") {
                isBang = true;
                stance = substr(stance, 2);
            }
            stance = _tonumber(stance) || stance;
            let isStance = this.IsStance(stance);
            if (!isBang && isStance || isBang && !isStance) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                this.Log("    Require NOT stance '%s': %s", stance, result);
            } else {
                this.Log("    Require stance '%s': %s", stance, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement);
        }
        return [verified, requirement, index];
    }
}

class StanceState implements StateModule {
    stance = undefined;
    InitializeState() {
        this.stance = undefined;
    }
    CleanState(): void {
    }
    ResetState() {
        OvaleStance.StartProfiling("OvaleStance_ResetState");
        this.stance = OvaleStance.stance || 0;
        OvaleStance.StopProfiling("OvaleStance_ResetState");
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        OvaleStance.StartProfiling("OvaleStance_ApplySpellAfterCast");
        let stance = dataState.GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID);
        if (stance) {
            if (_type(stance) == "string") {
                stance = OvaleStance.stanceId[stance];
            }
            this.stance = stance;
        }
        OvaleStance.StopProfiling("OvaleStance_ApplySpellAfterCast");
    }
    IsStance(name) {
        return OvaleStance.IsStance(name);
    } 
    RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return OvaleStance.RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }
}

export const stanceState = new StanceState();
OvaleState.RegisterState(stanceState);

OvaleStance = new OvaleStanceClass();
