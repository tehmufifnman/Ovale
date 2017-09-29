import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleStateBase = Ovale.NewModule("OvaleState");
export let OvaleState: OvaleStateClass;
import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleQueue } from "./Queue";
import { Constructor } from "./Ovale";
let _pairs = pairs;
let self_statePrototype:LuaObj<OvaleStatePrototype> = {
}
let self_stateAddons = new OvaleQueue<StateModule>("OvaleState_stateAddons");

export interface StateModule extends AceModule {
    CleanState(state: OvaleStatePrototype):void;
    InitializeState(state: OvaleStatePrototype):void;
    ResetState(state: OvaleStatePrototype):void;
}

class OvaleStateClass extends OvaleDebug.RegisterDebugging(OvaleStateBase) {
    state:OvaleStatePrototype = new OvaleStatePrototype();

    OnEnable() {}
    OnDisable() {}
    RegisterState(stateAddon: StateModule, statePrototype: ((base:Constructor<OvaleStatePrototype>) => OvaleStatePrototype)) {
        self_stateAddons.Insert(stateAddon);
        const name = stateAddon.GetName();
        self_statePrototype[name] = statePrototype;
        for (const [k, v] of _pairs(statePrototype)) {
            this.state[k] = v;
        }
    }
    UnregisterState(stateAddon: StateModule) {
        const name = stateAddon.GetName();
        let stateModules = new OvaleQueue<StateModule>("OvaleState_stateModules");
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
        let statePrototype = self_statePrototype[name];
        if (statePrototype) {
            for (const [k] of _pairs(statePrototype)) {
                this.state[k] = undefined;
            }
        }
        self_statePrototype[name] = undefined;
    }
    InvokeInitializeState(state: OvaleStatePrototype) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.InitializeState) iterator.value.InitializeState(state);
        }
    }
    InvokeResetState(state: OvaleStatePrototype) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ResetState) iterator.value.ResetState(state);
        }
    }

    InitializeState(state: OvaleStatePrototype) {
        state.futureVariable = {
        }
        state.futureLastEnable = {
        }
        state.variable = {
        }
        state.lastEnable = {
        }
    }
    ResetState(state: OvaleStatePrototype) {
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

export class OvaleStatePrototype {
    isState = true;
    isInitialized = undefined;
    futureVariable = undefined;
    futureLastEnable = undefined;
    variable = undefined;
    lastEnable = undefined;
    inCombat: boolean;

    Initialize() {
        if (!this.isInitialized) {
            OvaleState.InvokeInitializeState(this);
            this.isInitialized = true;
        }
    }

    Reset () {
        OvaleState.InvokeResetState(this);
    }
    GetState(state, name) {
        return state.futureVariable[name] || state.variable[name] || 0;
    }
    GetStateDuration(state, name) {
        let lastEnable = state.futureLastEnable[name] || state.lastEnable[name] || state.currentTime;
        return state.currentTime - lastEnable;
    }
    PutState (state, name, value, isFuture) {
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

    Log(...parameters) {
        OvaleState.Log(...parameters);
    }
}