import AceConfig from "AceConfig-3.0";
import AceConfigDialog from "AceConfigDialog-3.0";
import { L } from "./Localization";
import LibTextDump from "LibTextDump-1.0";
import { OvaleOptions } from "./Options";
import { Constructor, MakeString, Ovale } from "./Ovale";
let OvaleDebugBase = Ovale.NewModule("OvaleDebug", "AceTimer-3.0");
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

class OvaleDebugClass extends OvaleDebugBase {
    options = {
        name: Ovale.GetName() + " " + L["Debug"],
        type: "group",
        args: {
            toggles: {
                name: L["Options"],
                type: "group",
                order: 10,
                args: {
                },
                get: function (info) {
                    const value = Ovale.db.global.debug[info[lualength(info)]];
                    return (value != undefined);
                },
                set: function (info, value) {
                    value = value || undefined;
                    Ovale.db.global.debug[info[lualength(info)]] = value;
                }
            },
            trace: {
                name: L["Trace"],
                type: "group",
                order: 20,
                args: {
                    trace: {
                        order: 10,
                        type: "execute",
                        name: L["Trace"],
                        desc: L["Trace the next frame update."],
                        func: () => {
                            this.DoTrace(true);
                        }
                    },
                    traceLog: {
                        order: 20,
                        type: "execute",
                        name: L["Show Trace Log"],
                        func: () => {
                            this.DisplayTraceLog();
                        }
                    }
                }
            }
        }
    }

    bug = false;
    trace = false;

    constructor() {
        super();
        let actions = {
            debug: {
                name: L["Debug"],
                type: "execute",
                func: function () {
                    let appName = this.GetName();
                    AceConfigDialog.SetDefaultSize(appName, 800, 550);
                    AceConfigDialog.Open(appName);
                }
            }
        }
        for (const [k, v] of _pairs(actions)) {
            OvaleOptions.options.args.actions.args[k] = v;
        }
        OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global || {}
        OvaleOptions.defaultDB.global.debug = {}
        OvaleOptions.RegisterOptions(this);
    }
    
    OnInitialize() {
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Debug"], Ovale.GetName());
    }
    OnEnable() {
        self_traceLog = LibTextDump.New(Ovale.GetName() + " - " + L["Trace Log"], 750, 500);
    }
    DoTrace(displayLog) {
        self_traceLog.Clear();
        this.trace = true;
        this.Print("=== Trace @%f", API_GetTime());
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

    RegisterDebugging<T extends Constructor<AceModule>>(addon: T) {
        return class extends addon {
            private trace = false; 
            Debug(...__args) {
                let name = this.GetName();
                if (Ovale.db.global.debug[name]) {
                    _DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, MakeString(...__args)));
                }
            }
            DebugTimestamp(...__args) {
                let name = this.GetName();
                if (Ovale.db.global.debug[name]) {
                    let now = API_GetTime();
                    let s = format("|cffffff00%f|r %s", now, MakeString(...__args));
                    _DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
                }
            }
            Log(...__args) {
                if (this.trace) {
                    let N = self_traceLog.Lines();
                    if (N < OVALE_TRACELOG_MAXLINES - 1) {
                        self_traceLog.AddLine(MakeString(...__args));
                    } else if (N == OVALE_TRACELOG_MAXLINES - 1) {
                        self_traceLog.AddLine("WARNING: Maximum length of trace log has been reached.");
                    }
                }
            }
            Error(...__args) {
                let s = MakeString(...__args);
                this.Print("Fatal error: %s", s);
                OvaleDebug.bug = true;
            }
            Print(...__args) {
                let name = this.GetName();
                let s = MakeString(...__args);
                _DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
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

export const OvaleDebug = new OvaleDebugClass();

