import AceConfig from "AceConfig-3.0";
import AceConfigDialog from "AceConfigDialog-3.0";
import { L } from "./Localization";
import LibTextDump from "LibTextDump-1.0";
import { OvaleOptions } from "./Options";
import { Constructor, Ovale } from "./Ovale";

let OvaleProfilerBase = Ovale.NewModule("OvaleProfiler");

let _debugprofilestop = debugprofilestop;
let format = string.format;
let _pairs = pairs;
const _next = next;
const _wipe = wipe;
const tinsert = table.insert;
const tsort = table.sort;
const API_GetTime = GetTime;
const tconcat = table.concat;
let self_timestamp = _debugprofilestop();
let self_timeSpent = {}
let self_timesInvoked = {}
let self_stack = {}
let self_stackSize = 0;

class OvaleProfilerClass extends OvaleProfilerBase {
    self_profilingOutput: TextDump = undefined;
    profiles: LuaObj<{ enabled: boolean }> = {};

    actions = {
        profiling: {
            name: L["Profiling"],
            type: "execute",
            func: () => {
                let appName = this.GetName();
                AceConfigDialog.SetDefaultSize(appName, 800, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }

    options = {
        name: `${Ovale.GetName()} ${L["Profiling"]}`,
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
                        func: () => {
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

    
    constructor() {
        super();
        for (const [k, v] of _pairs(this.actions)) {
            OvaleOptions.options.args.actions.args[k] = v;
        }
        OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global || {}
        OvaleOptions.defaultDB.global.profiler = {}
        OvaleOptions.RegisterOptions(OvaleProfilerClass);
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Profiling"], Ovale.GetName());
    
        if (!this.self_profilingOutput) {
            this.self_profilingOutput = LibTextDump.New(`${Ovale.GetName()} - ${L["Profiling"]}`, 750, 500);
        }
    }
    OnDisable() {
        this.self_profilingOutput.Clear();
    }
    RegisterProfiling<T extends Constructor<AceModule>>(module: T, name?: string) {
        const profiler = this;
        return class extends module {
            constructor(...__args:any[]) {
                super(...__args);
                name = name || this.GetName();
                profiler.options.args.profiling.args.modules.args[name] = {
                    name: name,
                    desc: format(L["Enable profiling for the %s module."], name),
                    type: "toggle"
                }
                profiler.profiles[name] = this;       
            }

            enabled = false;
            
            StartProfiling(tag) {
                if (!this.enabled) return;
                let newTimestamp = _debugprofilestop();
                if (self_stackSize > 0) {
                    let delta = newTimestamp - self_timestamp;
                    let previous = self_stack[self_stackSize];
                    let timeSpent = self_timeSpent[previous] || 0;
                    timeSpent = timeSpent + delta;
                    self_timeSpent[previous] = timeSpent;
                }
                self_timestamp = newTimestamp;
                self_stackSize = self_stackSize + 1;
                self_stack[self_stackSize] = tag;
                {
                    let timesInvoked = self_timesInvoked[tag] || 0;
                    timesInvoked = timesInvoked + 1;
                    self_timesInvoked[tag] = timesInvoked;
                }
            }
        
            StopProfiling(tag) {
                if (!this.enabled) return;
                if (self_stackSize > 0) {
                    let currentTag = self_stack[self_stackSize];
                    if (currentTag == tag) {
                        let newTimestamp = _debugprofilestop();
                        let delta = newTimestamp - self_timestamp;
                        let timeSpent = self_timeSpent[currentTag] || 0;
                        timeSpent = timeSpent + delta;
                        self_timeSpent[currentTag] = timeSpent;
                        self_timestamp = newTimestamp;
                        self_stackSize = self_stackSize - 1;
                    }
                }
            }
        }
        
    }

    array = {}
            
    ResetProfiling() {
        for (const [tag] of _pairs(self_timeSpent)) {
            self_timeSpent[tag] = undefined;
        }
        for (const [tag] of _pairs(self_timesInvoked)) {
            self_timesInvoked[tag] = undefined;
        }
    }

    GetProfilingInfo() {
        if (_next(self_timeSpent)) {
            let width = 1;
            {
                let tenPower = 10;
                for (const [_, timesInvoked] of _pairs(self_timesInvoked)) {
                    while (timesInvoked > tenPower) {
                        width = width + 1;
                        tenPower = tenPower * 10;
                    }
                }
            }
            _wipe(this.array);
            let formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width);
            for (const [tag, timeSpent] of _pairs(self_timeSpent)) {
                let timesInvoked = self_timesInvoked[tag];
                tinsert(this.array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag));
            }
            if (_next(this.array)) {
                tsort(this.array);
                let now = API_GetTime();
                tinsert(this.array, 1, format("Profiling statistics at %f:", now));
                return tconcat(this.array, "\n");
            }
        }
    }

    DebuggingInfo() {
        Ovale.Print("Profiler stack size = %d", self_stackSize);
        let index = self_stackSize;
        while (index > 0 && self_stackSize - index < 10) {
            let tag = self_stack[index];
            Ovale.Print("    [%d] %s", index, tag);
            index = index - 1;
        }
    }
    
    EnableProfiling(name: string) {
        this.profiles[name].enabled = true;
    }
    DisableProfiling(name: string) {
        this.profiles[name].enabled = false;
    }
}

export const OvaleProfiler = new OvaleProfilerClass();