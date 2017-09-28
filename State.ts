import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleStateBase = Ovale.NewModule("OvaleState");
export let OvaleState: OvaleStateClass;
import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleQueue } from "./Queue";
let _pairs = pairs;
let self_statePrototype = {
}
let self_stateAddons = OvaleQueue.NewQueue("OvaleState_stateAddons");
class OvaleStateClass extends OvaleStateBase {
    debug = OvaleDebug.RegisterDebugging(this);
    state = { }
    OnEnable() {
        this.RegisterState(this, this.statePrototype);
    }
    OnDisable() {
        this.UnregisterState(this);
    }
    RegisterState(stateAddon, statePrototype) {
        self_stateAddons.Insert(stateAddon);
        self_statePrototype[stateAddon] = statePrototype;
        for (const [k, v] of _pairs(statePrototype)) {
            this.state[k] = v;
        }
    }
    UnregisterState(stateAddon) {
        let stateModules = OvaleQueue.NewQueue("OvaleState_stateModules");
        while (self_stateAddons.Size() > 0) {
            let addon = self_stateAddons.Remove();
            if (stateAddon != addon) {
                stateModules.Insert(addon);
            }
        }
        self_stateAddons = stateModules;
        if (stateAddon.CleanState) {
            stateAddon.CleanState(this.state);
        }
        let statePrototype = self_statePrototype[stateAddon];
        if (statePrototype) {
            for (const [k] of _pairs(statePrototype)) {
                this.state[k] = undefined;
            }
        }
        self_statePrototype[stateAddon] = undefined;
    }
    InvokeMethod(methodName, ...__args) {
        for (const [_, addon] of self_stateAddons.Iterator()) {
            if (addon[methodName]) {
                addon[methodName](addon, ...__args);
            }
        }
    }

    InitializeState(state) {
        state.futureVariable = {
        }
        state.futureLastEnable = {
        }
        state.variable = {
        }
        state.lastEnable = {
        }
    }
    ResetState(state) {
        for (const [k] of _pairs(state.futureVariable)) {
            state.futureVariable[k] = undefined;
            state.futureLastEnable[k] = undefined;
        }
        if (!state.inCombat) {
            for (const [k] of _pairs(state.variable)) {
                state.Log("Resetting state variable '%s'.", k);
                state.variable[k] = undefined;
                state.lastEnable[k] = undefined;
            }
        }
    }
    CleanState(state) {
        for (const [k] of _pairs(state.futureVariable)) {
            state.futureVariable[k] = undefined;
        }
        for (const [k] of _pairs(state.futureLastEnable)) {
            state.futureLastEnable[k] = undefined;
        }
        for (const [k] of _pairs(state.variable)) {
            state.variable[k] = undefined;
        }
        for (const [k] of _pairs(state.lastEnable)) {
            state.lastEnable[k] = undefined;
        }
    }
}

OvaleState.statePrototype = {
}
let statePrototype = OvaleState.statePrototype;
statePrototype.isState = true;
statePrototype.isInitialized = undefined;
statePrototype.futureVariable = undefined;
statePrototype.futureLastEnable = undefined;
statePrototype.variable = undefined;
statePrototype.lastEnable = undefined;

statePrototype.Initialize = function (state) {
    if (!state.isInitialized) {
        OvaleState.InvokeMethod("InitializeState", state);
        state.isInitialized = true;
    }
}
statePrototype.Reset = function (state) {
    OvaleState.InvokeMethod("ResetState", state);
}
statePrototype.GetState = function (state, name) {
    return state.futureVariable[name] || state.variable[name] || 0;
}
statePrototype.GetStateDuration = function (state, name) {
    let lastEnable = state.futureLastEnable[name] || state.lastEnable[name] || state.currentTime;
    return state.currentTime - lastEnable;
}
statePrototype.PutState = function (state, name, value, isFuture) {
    if (isFuture) {
        let oldValue = state.GetState(name);
        if (value != oldValue) {
            state.Log("Setting future state: %s from %s to %s.", name, oldValue, value);
            state.futureVariable[name] = value;
            state.futureLastEnable[name] = state.currentTime;
        }
    } else {
        let oldValue = state.variable[name] || 0;
        if (value != oldValue) {
            OvaleState.DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value);
            state.Log("Advancing combat state: %s from %s to %s.", name, oldValue, value);
            state.variable[name] = value;
            state.lastEnable[name] = state.currentTime;
        }
    }
}
statePrototype.Log = function (state, ...__args) {
    return OvaleDebug.Log(...__args);
}
statePrototype.GetMethod = Ovale.GetMethod;
