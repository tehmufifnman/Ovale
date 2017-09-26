import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleDebug = Ovale.NewModule("OvaleDebug", "AceTimer-3.0");
Ovale.OvaleDebug = OvaleDebug;
let AceConfig = LibStub("AceConfig-3.0");
let AceConfigDialog = LibStub("AceConfigDialog-3.0");
import { L } from "./L";
let LibTextDump = LibStub("LibTextDump-1.0");
import { OvaleOptions } from "./OvaleOptions";
let format = string.format;
let gmatch = string.gmatch;
let gsub = string.gsub;
let _next = next;
let _pairs = pairs;
let strlen = string.len;
let _tonumber = tonumber;
let _tostring = tostring;
let _type = type;
let API_GetSpellInfo = GetSpellInfo;
let API_GetTime = GetTime;
let _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME;
let self_traced = false;
let self_traceLog = undefined;
let OVALE_TRACELOG_MAXLINES = 4096;
{
    let actions = { debug: { name: L["Debug"], type: "execute", func: function () {
        let appName = OvaleDebug.GetName();
        AceConfigDialog.SetDefaultSize(appName, 800, 550);
        AceConfigDialog.Open(appName);
    } } }
    for (const [k, v] of _pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global || {  }
    OvaleOptions.defaultDB.global.debug = {  }
    OvaleOptions.RegisterOptions(OvaleDebug);
}
OvaleDebug.options = { name: OVALE + " " + L["Debug"], type: "group", args: { toggles: { name: L["Options"], type: "group", order: 10, args: {  }, get: function (info) {
    import { value } from "./db";
    return (value != undefined);
}, set: function (info, value) {
    value = value || undefined;
    Ovale.db.global.debug[info[lualength(info)]] = value;
} }, trace: { name: L["Trace"], type: "group", order: 20, args: { trace: { order: 10, type: "execute", name: L["Trace"], desc: L["Trace the next frame update."], func: function () {
    OvaleDebug.DoTrace(true);
} }, traceLog: { order: 20, type: "execute", name: L["Show Trace Log"], func: function () {
    OvaleDebug.DisplayTraceLog();
} } } } } }
OvaleDebug.bug = false;
OvaleDebug.trace = false;
class OvaleDebug {
    OnInitialize() {
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Debug"], OVALE);
    }
    OnEnable() {
        self_traceLog = LibTextDump.New(OVALE + " - " + L["Trace Log"], 750, 500);
    }
    DoTrace(displayLog) {
        self_traceLog.Clear();
        this.trace = true;
        this.Log("=== Trace @%f", API_GetTime());
        if (displayLog) {
            this.ScheduleTimer("DisplayTraceLog", 0.5);
        }
    }
    ResetTrace() {
        this.bug = false;
        this.trace = false;
        self_traced = false;
    }
    UpdateTrace() {
        if (this.trace) {
            self_traced = true;
        }
        if (this.bug) {
            this.trace = true;
        }
        if (this.trace && self_traced) {
            self_traced = false;
            this.trace = false;
        }
    }
    RegisterDebugging(addon) {
        let name = addon.GetName();
        this.options.args.toggles.args[name] = { name: name, desc: format(L["Enable debugging messages for the %s module."], name), type: "toggle" }
        addon.Debug = this.Debug;
        addon.DebugTimestamp = this.DebugTimestamp;
    }
    Debug(...__args) {
        let name = this.GetName();
        if (Ovale.db.global.debug[name]) {
            _DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, Ovale.MakeString(...__args)));
        }
    }
    DebugTimestamp(...__args) {
        let name = this.GetName();
        if (Ovale.db.global.debug[name]) {
            let now = API_GetTime();
            let s = format("|cffffff00%f|r %s", now, Ovale.MakeString(...__args));
            _DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
        }
    }
    Log(...__args) {
        if (this.trace) {
            let N = self_traceLog.Lines();
            if (N < OVALE_TRACELOG_MAXLINES - 1) {
                self_traceLog.AddLine(Ovale.MakeString(...__args));
            } else if (N == OVALE_TRACELOG_MAXLINES - 1) {
                self_traceLog.AddLine("WARNING: Maximum length of trace log has been reached.");
            }
        }
    }
    DisplayTraceLog() {
        if (self_traceLog.Lines() == 0) {
            self_traceLog.AddLine("Trace log is empty.");
        }
        self_traceLog.Display();
    }
}
{
    let NEW_DEBUG_NAMES = { action_bar: "OvaleActionBar", aura: "OvaleAura", combo_points: "OvaleComboPoints", compile: "OvaleCompile", damage_taken: "OvaleDamageTaken", enemy: "OvaleEnemies", guid: "OvaleGUID", missing_spells: false, paper_doll: "OvalePaperDoll", power: "OvalePower", snapshot: false, spellbook: "OvaleSpellBook", state: "OvaleState", steady_focus: "OvaleSteadyFocus", unknown_spells: false }
class OvaleDebug {
        UpgradeSavedVariables() {
            import { global } from "./db";
            import { profile } from "./db";
            profile.debug = undefined;
            for (const [old, new] of _pairs(NEW_DEBUG_NAMES)) {
                if (global.debug[old] && new) {
                    global.debug[new] = global.debug[old];
                }
                global.debug[old] = undefined;
            }
            for (const [k, v] of _pairs(global.debug)) {
                if (!v) {
                    global.debug[k] = undefined;
                }
            }
        }
}
}
