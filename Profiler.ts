import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleProfilerBase = Ovale.NewModule("OvaleProfiler");
import AceConfig from "AceConfig-3.0";
import AceConfigDialog from "AceConfigDialog-3.0";
import { L } from "./Localization";
import LibTextDump from "LibTextDump-1.0";
import { options } from "./Options";
let _debugprofilestop = debugprofilestop;
let format = string.format;
let _ipairs = ipairs;
let _next = next;
let _pairs = pairs;
let tconcat = table.concat;
let tinsert = table.insert;
let tsort = table.sort;
let _wipe = wipe;
let API_GetTime = GetTime;

export class Profiler {
    constructor(private module: AceModule){

    }
    self_timestamp = _debugprofilestop();
    self_timeSpent = {}
    self_timesInvoked = {}
    self_stack = {}
    self_stackSize = 0;
    enabled = false;

    StartProfiling(tag) {
        if (!this.enabled) return;
        let newTimestamp = _debugprofilestop();
        if (this.self_stackSize > 0) {
            let delta = newTimestamp - this.self_timestamp;
            let previous = this.self_stack[this.self_stackSize];
            let timeSpent = this.self_timeSpent[previous] || 0;
            timeSpent = timeSpent + delta;
            this.self_timeSpent[previous] = timeSpent;
        }
        this.self_timestamp = newTimestamp;
        this.self_stackSize = this.self_stackSize + 1;
        this.self_stack[this.self_stackSize] = tag;
        {
            let timesInvoked = this.self_timesInvoked[tag] || 0;
            timesInvoked = timesInvoked + 1;
            this.self_timesInvoked[tag] = timesInvoked;
        }
    }

    StopProfiling(tag) {
        if (!this.enabled) return;
        if (this.self_stackSize > 0) {
            let currentTag = this.self_stack[this.self_stackSize];
            if (currentTag == tag) {
                let newTimestamp = _debugprofilestop();
                let delta = newTimestamp - this.self_timestamp;
                let timeSpent = this.self_timeSpent[currentTag] || 0;
                timeSpent = timeSpent + delta;
                this.self_timeSpent[currentTag] = timeSpent;
                this.self_timestamp = newTimestamp;
                this.self_stackSize = this.self_stackSize - 1;
            }
        }
    }
    
    ResetProfiling() {
        for (const [tag] of _pairs(this.self_timeSpent)) {
            this.self_timeSpent[tag] = undefined;
        }
        for (const [tag] of _pairs(this.self_timesInvoked)) {
            this.self_timesInvoked[tag] = undefined;
        }
    }
}

class OvaleProfiler extends OvaleProfilerBase {
    self_profilingOutput = undefined;
    profiles: LuaObj<Profiler> = {};

    actions = {
        profiling: {
            name: L["Profiling"],
            type: "execute",
            func: function () {
                let appName = this.GetName();
                AceConfigDialog.SetDefaultSize(appName, 800, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }

    constructor() {
        super();
        for (const [k, v] of _pairs(this.actions)) {
            options.options.args.actions.args[k] = v;
        }
        options.defaultDB.global = options.defaultDB.global || {}
        options.defaultDB.global.profiler = {}
        options.RegisterOptions(OvaleProfiler);
    }

    options = {
        name: OVALE + " " + L["Profiling"],
        type: "group",
        args: {
            profiling: {
                name: L["Profiling"],
                type: "group",
                args: {
                    modules: {
                        name: L["Modules"],
                        type: "group",
                        inline: true,
                        order: 10,
                        args: {
                        },
                        get: (info) => {
                            let name = info[lualength(info)];
                            const value = Ovale.db.global.profiler[name];
                            return (value != undefined);
                        },
                        set: (info, value) => {
                            value = value || undefined;
                            let name = info[lualength(info)];
                            Ovale.db.global.profiler[name] = value;
                            if (value) {
                                this.EnableProfiling(name);
                            } else {
                                this.DisableProfiling(name);
                            }
                        }
                    },
                    reset: {
                        name: L["Reset"],
                        desc: L["Reset the profiling statistics."],
                        type: "execute",
                        order: 20,
                        func: function () {
                            this.ResetProfiling();
                        }
                    },
                    show: {
                        name: L["Show"],
                        desc: L["Show the profiling statistics."],
                        type: "execute",
                        order: 30,
                        func: () => {
                            this.self_profilingOutput.Clear();
                            let s = this.GetProfilingInfo();
                            if (s) {
                                this.self_profilingOutput.AddLine(s);
                                this.self_profilingOutput.Display();
                            }
                        }
                    }
                }
            }
        }
    }

    DoNothing = function() {}

    
    OnInitialize() {
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Profiling"], OVALE);
    }
    
    OnEnable() {
        if (!this.self_profilingOutput) {
            this.self_profilingOutput = LibTextDump.New(OVALE + " - " + L["Profiling"], 750, 500);
        }
    }
    OnDisable() {
        this.self_profilingOutput.Clear();
    }
    RegisterProfiling(module: AceModule, name?: string) {
        name = name || module.GetName();
        this.options.args.profiling.args.modules.args[name] = {
            name: name,
            desc: format(L["Enable profiling for the %s module."], name),
            type: "toggle"
        }
        return new Profiler(module);
    }

    array = {}

    GetProfilingInfo() {
        // if (_next(this.self_timeSpent)) {
        //     let width = 1;
        //     {
        //         let tenPower = 10;
        //         for (const [_, timesInvoked] of _pairs(this.self_timesInvoked)) {
        //             while (timesInvoked > tenPower) {
        //                 width = width + 1;
        //                 tenPower = tenPower * 10;
        //             }
        //         }
        //     }
        //     _wipe(this.array);
        //     let formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width);
        //     for (const [tag, timeSpent] of _pairs(this.self_timeSpent)) {
        //         let timesInvoked = this.self_timesInvoked[tag];
        //         tinsert(this.array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag));
        //     }
        //     if (_next(this.array)) {
        //         tsort(this.array);
        //         let now = API_GetTime();
        //         tinsert(this.array, 1, format("Profiling statistics at %f:", now));
        //         return tconcat(this.array, "\n");
        //     }
        // }
    }

    DebuggingInfo() {
        // Ovale.Print("Profiler stack size = %d", this.self_stackSize);
        // let index = this.self_stackSize;
        // while (index > 0 && this.self_stackSize - index < 10) {
        //     let tag = this.self_stack[index];
        //     Ovale.Print("    [%d] %s", index, tag);
        //     index = index - 1;
        // }
    }

    
    EnableProfiling(name: string) {
        this.profiles[name].enabled = true;
    }
    DisableProfiling(name: string) {
        this.profiles[name].enabled = false;
    }
}

export const profiler = new OvaleProfiler();