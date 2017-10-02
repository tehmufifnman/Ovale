import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
let OvaleConditionBase = Ovale.NewModule("OvaleCondition");
export let OvaleCondition: OvaleConditionClass;
let _type = type;
let _wipe = wipe;
let INFINITY = math.huge;
let self_condition = {
}
let self_spellBookCondition = {
}
{
    self_spellBookCondition["spell"] = true;
}

class OvaleConditionClass extends OvaleDebug.RegisterDebugging(OvaleConditionBase) {
    Compare = undefined;
    ParseCondition = undefined;
    ParseRuneCondition = undefined;
    TestBoolean = undefined;
    TestValue = undefined;
    COMPARATOR = {
        atLeast: true,
        atMost: true,
        equal: true,
        less: true,
        more: true
    }

    OnInitialize() {
    }
    OnEnable() {
    }
    OnDisable() {
    }
    RegisterCondition(name, isSpellBookCondition, func, arg?) {
        if (arg) {
            if (_type(func) == "string") {
                func = arg[func];
            }
            self_condition[name] = function (...__args) {
                func(arg, ...__args);
            }
        } else {
            self_condition[name] = func;
        }
        if (isSpellBookCondition) {
            self_spellBookCondition[name] = true;
        }
    }
    UnregisterCondition(name) {
        self_condition[name] = undefined;
    }
    IsCondition(name) {
        return (self_condition[name] != undefined);
    }
    IsSpellBookCondition(name) {
        return (self_spellBookCondition[name] != undefined);
    }
    EvaluateCondition(name, positionalParams, namedParams, state, atTime) {
        return self_condition[name](positionalParams, namedParams, state, atTime);
    }
}

OvaleCondition = new OvaleConditionClass();

export function ParseCondition(positionalParams, namedParams, state, defaultTarget?):[string, "HARMFUL" | "HELPFUL", boolean] {
    let target = namedParams.target || defaultTarget || "player";
    namedParams.target = namedParams.target || target;
    if (target == "target") {
        target = state.defaultTarget;
    }
    let filter: "HARMFUL" | "HELPFUL";
    if (namedParams.filter) {
        if (namedParams.filter == "debuff") {
            filter = "HARMFUL";
        } else if (namedParams.filter == "buff") {
            filter = "HELPFUL";
        }
    }
    let mine = true;
    if (namedParams.any && namedParams.any == 1) {
        mine = false;
    } else {
        if (!namedParams.any && namedParams.mine && namedParams.mine != 1) {
            mine = false;
        }
    }
    return [target, filter, mine];
}

export function TestBoolean(a, yesno) {
    if (!yesno || yesno == "yes") {
        if (a) {
            return [0, INFINITY];
        }
    } else {
        if (!a) {
            return [0, INFINITY];
        }
    }
    return undefined;
}
export function TestValue(start, ending, value, origin, rate, comparator, limit) {
    if (!value || !origin || !rate) {
        return undefined;
    }
    start = start || 0;
    ending = ending || INFINITY;
    if (!comparator) {
        if (start < ending) {
            return [start, ending, value, origin, rate];
        } else {
            return [0, INFINITY, 0, 0, 0];
        }
    } else if (!OvaleCondition.COMPARATOR[comparator]) {
        OvaleCondition.Error("unknown comparator %s", comparator);
    } else if (!limit) {
        OvaleCondition.Error("comparator %s missing limit", comparator);
    } else if (rate == 0) {
        if ((comparator == "less" && value < limit) || (comparator == "atMost" && value <= limit) || (comparator == "equal" && value == limit) || (comparator == "atLeast" && value >= limit) || (comparator == "more" && value > limit)) {
            return [start, ending];
        }
    } else if ((comparator == "less" && rate > 0) || (comparator == "atMost" && rate > 0) || (comparator == "atLeast" && rate < 0) || (comparator == "more" && rate < 0)) {
        let t = (limit - value) / rate + origin;
        ending = (ending < t) && ending || t;
        return [start, ending];
    } else if ((comparator == "less" && rate < 0) || (comparator == "atMost" && rate < 0) || (comparator == "atLeast" && rate > 0) || (comparator == "more" && rate > 0)) {
        let t = (limit - value) / rate + origin;
        start = (start > t) && start || t;
        return [start, INFINITY];
    }
    return undefined;
}

export function Compare(value, comparator, limit) {
    return OvaleCondition.TestValue(0, INFINITY, value, 0, 0, comparator, limit);
}
