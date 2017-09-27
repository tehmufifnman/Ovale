import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleProfiler = Ovale.NewModule("OvaleProfiler");
Ovale.OvaleProfiler = OvaleProfiler;
let AceConfig = LibStub("AceConfig-3.0");
let AceConfigDialog = LibStub("AceConfigDialog-3.0");
import { L } from "./L";
let LibTextDump = LibStub("LibTextDump-1.0");
import { OvaleOptions } from "./OvaleOptions";
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
let self_timestamp = _debugprofilestop();
let self_stack = {
}
let self_stackSize = 0;
let self_timeSpent = {
}
let self_timesInvoked = {
}
let self_profilingOutput = undefined;
{
    let actions = {
        profiling: {
            name: L["Profiling"],
            type: "execute",
            func: function () {
                let appName = OvaleProfiler.GetName();
                AceConfigDialog.SetDefaultSize(appName, 800, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }
    for (const [k, v] of _pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global || {
    }
    OvaleOptions.defaultDB.global.profiler = {
    }
    OvaleOptions.RegisterOptions(OvaleProfiler);
}
OvaleProfiler.options = {
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
                    get: function (info) {
                        let name = info[lualength(info)];
                        import { value } from "./db";
                        return (value != undefined);
                    },
                    set: function (info, value) {
                        value = value || undefined;
                        let name = info[lualength(info)];
                        Ovale.db.global.profiler[name] = value;
                        if (value) {
                            OvaleProfiler.EnableProfiling(name);
                        } else {
                            OvaleProfiler.DisableProfiling(name);
                        }
                    }
                },
                reset: {
                    name: L["Reset"],
                    desc: L["Reset the profiling statistics."],
                    type: "execute",
                    order: 20,
                    func: function () {
                        OvaleProfiler.ResetProfiling();
                    }
                },
                show: {
                    name: L["Show"],
                    desc: L["Show the profiling statistics."],
                    type: "execute",
                    order: 30,
                    func: function () {
                        self_profilingOutput.Clear();
                        let s = OvaleProfiler.GetProfilingInfo();
                        if (s) {
                            self_profilingOutput.AddLine(s);
                            self_profilingOutput.Display();
                        }
                    }
                }
            }
        }
    }
}
const DoNothing = function() {
}
const StartProfiling = function(_, tag) {
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
const StopProfiling = function(_, tag) {
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
class OvaleProfiler {
    OnInitialize() {
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Profiling"], OVALE);
    }
    OnEnable() {
        if (!self_profilingOutput) {
            self_profilingOutput = LibTextDump.New(OVALE + " - " + L["Profiling"], 750, 500);
        }
    }
    OnDisable() {
        self_profilingOutput.Clear();
    }
    RegisterProfiling(addon, name) {
        name = name || addon.GetName();
        this.options.args.profiling.args.modules.args[name] = {
            name: name,
            desc: format(L["Enable profiling for the %s module."], name),
            type: "toggle"
        }
        this.DisableProfiling(name);
    }
    EnableProfiling(name) {
        let addon = Ovale[name];
        if (addon) {
            addon.StartProfiling = StartProfiling;
            addon.StopProfiling = StopProfiling;
        }
    }
    DisableProfiling(name) {
        let addon = Ovale[name];
        if (addon) {
            addon.StartProfiling = DoNothing;
            addon.StopProfiling = DoNothing;
        }
    }
    ResetProfiling() {
        for (const [tag] of _pairs(self_timeSpent)) {
            self_timeSpent[tag] = undefined;
        }
        for (const [tag] of _pairs(self_timesInvoked)) {
            self_timesInvoked[tag] = undefined;
        }
    }
}
{
    let array = {
    }
class OvaleProfiler {
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
                _wipe(array);
                let formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width);
                for (const [tag, timeSpent] of _pairs(self_timeSpent)) {
                    let timesInvoked = self_timesInvoked[tag];
                    tinsert(array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag));
                }
                if (_next(array)) {
                    tsort(array);
                    let now = API_GetTime();
                    tinsert(array, 1, format("Profiling statistics at %f:", now));
                    return tconcat(array, "\n");
                }
            }
        }
}
}
class OvaleProfiler {
    DebuggingInfo() {
        Ovale.Print("Profiler stack size = %d", self_stackSize);
        let index = self_stackSize;
        while (index > 0 && self_stackSize - index < 10) {
            let tag = self_stack[index];
            Ovale.Print("    [%d] %s", index, tag);
            index = index - 1;
        }
    }
}
