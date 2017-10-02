import { OvaleDebug } from "./Debug";
import { OvalePool } from "./Pool";
import { OvaleProfiler } from "./Profiler";
import { OvaleTimeSpan, UNIVERSE, newTimeSpanFromArray, EMPTY_SET, newTimeSpan, releaseTimeSpans } from "./TimeSpan";
import { OvaleAST } from "./AST";
import { OvaleActionBar } from "./ActionBar";
import { OvaleCompile } from "./Compile";
import { OvaleCondition } from "./Condition";
import { OvaleCooldown } from "./Cooldown";
import { OvaleData } from "./Data";
import { OvaleEquipment } from "./Equipment";
import { OvaleGUID } from "./Guid";
import { OvaleFuture } from "./Future";
import { OvalePower } from "./Power";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleStance } from "./Stance";
import { Ovale } from "./Ovale";
let OvaleBestActionBase = Ovale.NewModule("OvaleBestAction", "AceEvent-3.0");
let abs = math.abs;
let _assert = assert;
let floor = math.floor;
let _ipairs = ipairs;
let _loadstring = loadstring;
let _pairs = pairs;
let _tonumber = tonumber;
let _type = type;
let _wipe = wipe;
let INFINITY = math.huge;
let API_GetTime = GetTime;
let API_GetActionCooldown = GetActionCooldown;
let API_GetActionTexture = GetActionTexture;
let API_GetItemIcon = GetItemIcon;
let API_GetItemCooldown = GetItemCooldown;
let API_GetItemSpell = GetItemSpell;
let API_GetSpellTexture = GetSpellTexture;
let API_IsActionInRange = IsActionInRange;
let API_IsCurrentAction = IsCurrentAction;
let API_IsItemInRange = IsItemInRange;
let API_IsUsableAction = IsUsableAction;
let API_IsUsableItem = IsUsableItem;
let COMPUTE_VISITOR = {
    ["action"]: "ComputeAction",
    ["arithmetic"]: "ComputeArithmetic",
    ["compare"]: "ComputeCompare",
    ["custom_function"]: "ComputeCustomFunction",
    ["function"]: "ComputeFunction",
    ["group"]: "ComputeGroup",
    ["if"]: "ComputeIf",
    ["logical"]: "ComputeLogical",
    ["lua"]: "ComputeLua",
    ["state"]: "ComputeState",
    ["unless"]: "ComputeIf",
    ["value"]: "ComputeValue"
}
let self_serial = 0;
let self_timeSpan: LuaObj<OvaleTimeSpan> = {
}
let self_valuePool = new OvalePool("OvaleBestAction_valuePool");
let self_value = {
}

export let OvaleBestAction:OvaleBestActionClass = undefined;

const SetValue = function(node, value?, origin?, rate?) {
    let result = self_value[node];
    if (!result) {
        result = self_valuePool.Get();
        self_value[node] = result;
    }
    result.type = "value";
    result.value = value || 0;
    result.origin = origin || 0;
    result.rate = rate || 0;
    return result;
}
const AsValue = function(atTime: number, timeSpan: OvaleTimeSpan, node?):[number, number, number, OvaleTimeSpan] {
    let value: number, origin: number, rate: number;
    if (node && node.type == "value") {
        [value, origin, rate] = [node.value, node.origin, node.rate];
    } else if (timeSpan && timeSpan.HasTime(atTime)) {
        [value, origin, rate, timeSpan] = [1, 0, 0, UNIVERSE];
    } else {
        [value, origin, rate, timeSpan] = [0, 0, 0, UNIVERSE];
    }
    return [value, origin, rate, timeSpan];
}
const GetTimeSpan = function(node, defaultTimeSpan?: OvaleTimeSpan) {
    let timeSpan = self_timeSpan[node];
    if (timeSpan) {
        if (defaultTimeSpan) {
            timeSpan.copyFromArray(defaultTimeSpan);
        }
    } else {
        self_timeSpan[node] = newTimeSpanFromArray(defaultTimeSpan);
        timeSpan = self_timeSpan[node];
    }
    return timeSpan;
}
const GetActionItemInfo = function(element, state, atTime, target) {
    OvaleBestAction.StartProfiling("OvaleBestAction_GetActionItemInfo");
    let actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId;
    let itemId = element.positionalParams[1];
    if (_type(itemId) != "number") {
        itemId = OvaleEquipment.GetEquippedItem(itemId);
    }
    if (!itemId) {
        state.Log("Unknown item '%s'.", element.positionalParams[1]);
    } else {
        state.Log("Item ID '%s'", itemId);
        let action = OvaleActionBar.GetForItem(itemId);
        let spellName = API_GetItemSpell(itemId);
        if (element.namedParams.texture) {
            actionTexture = "Interface\\Icons\\" + element.namedParams.texture;
        }
        actionTexture = actionTexture || API_GetItemIcon(itemId);
        actionInRange = API_IsItemInRange(itemId, target);
        [actionCooldownStart, actionCooldownDuration, actionEnable] = API_GetItemCooldown(itemId);
        actionUsable = spellName && API_IsUsableItem(itemId) && state.IsUsableItem(itemId);
        if (action) {
            actionShortcut = OvaleActionBar.GetBinding(action);
            actionIsCurrent = API_IsCurrentAction(action);
        }
        actionType = "item";
        actionId = itemId;
    }
    OvaleBestAction.StopProfiling("OvaleBestAction_GetActionItemInfo");
    return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target];
}
const GetActionMacroInfo = function(element, state, atTime, target) {
    OvaleBestAction.StartProfiling("OvaleBestAction_GetActionMacroInfo");
    let actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId;
    let macro = element.positionalParams[1];
    let action = OvaleActionBar.GetForMacro(macro);
    if (!action) {
        state.Log("Unknown macro '%s'.", macro);
    } else {
        if (element.namedParams.texture) {
            actionTexture = "Interface\\Icons\\" + element.namedParams.texture;
        }
        actionTexture = actionTexture || API_GetActionTexture(action);
        actionInRange = API_IsActionInRange(action, target);
        [actionCooldownStart, actionCooldownDuration, actionEnable] = API_GetActionCooldown(action);
        actionUsable = API_IsUsableAction(action);
        actionShortcut = OvaleActionBar.GetBinding(action);
        actionIsCurrent = API_IsCurrentAction(action);
        actionType = "macro";
        actionId = macro;
    }
    OvaleBestAction.StopProfiling("OvaleBestAction_GetActionMacroInfo");
    return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target];
}
const GetActionSpellInfo = function(element, state, atTime, target) {
    OvaleBestAction.StartProfiling("OvaleBestAction_GetActionSpellInfo");
    let actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionResourceExtend, actionCharges;
    let targetGUID = OvaleGUID.UnitGUID(target);
    let spellId = element.positionalParams[1];
    let si = OvaleData.spellInfo[spellId];
    let replacedSpellId = undefined;
    if (si && si.replace) {
        let replacement = state.GetSpellInfoProperty(spellId, atTime, "replace", targetGUID);
        if (replacement) {
            replacedSpellId = spellId;
            spellId = replacement;
            si = OvaleData.spellInfo[spellId];
            state.Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId);
        }
    }
    let action = OvaleActionBar.GetForSpell(spellId);
    if (!action && replacedSpellId) {
        state.Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId);
        action = OvaleActionBar.GetForSpell(replacedSpellId);
    }
    let isKnownSpell = OvaleSpellBook.IsKnownSpell(spellId);
    if (!isKnownSpell && replacedSpellId) {
        state.Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId);
        isKnownSpell = OvaleSpellBook.IsKnownSpell(replacedSpellId);
    }
    if (!isKnownSpell && !action) {
        state.Log("Unknown spell ID '%s'.", spellId);
    } else {
        let [isUsable, noMana] = state.IsUsableSpell(spellId, atTime, targetGUID);
        if (isUsable || noMana) {
            if (element.namedParams.texture) {
                actionTexture = "Interface\\Icons\\" + element.namedParams.texture;
            }
            actionTexture = actionTexture || API_GetSpellTexture(spellId);
            actionInRange = OvaleSpellBook.IsSpellInRange(spellId, target);
            [actionCooldownStart, actionCooldownDuration, actionEnable] = state.GetSpellCooldown(spellId);
            actionCharges = state.GetSpellCharges(spellId);
            actionResourceExtend = 0;
            actionUsable = isUsable;
            if (action) {
                actionShortcut = OvaleActionBar.GetBinding(action);
                actionIsCurrent = API_IsCurrentAction(action);
            }
            actionType = "spell";
            actionId = spellId;
            if (si) {
                if (si.texture) {
                    actionTexture = "Interface\\Icons\\" + si.texture;
                }
                if (actionCooldownStart && actionCooldownDuration) {
                    let extraPower = element.namedParams.extra_amount || 0;
                    let seconds = state.GetTimeToSpell(spellId, atTime, targetGUID, extraPower);
                    if (seconds > 0 && seconds > actionCooldownDuration) {
                        if (actionCooldownDuration > 0) {
                            actionResourceExtend = seconds - actionCooldownDuration;
                        } else {
                            actionResourceExtend = seconds;
                        }
                        state.Log("Spell ID '%s' requires an extra %fs for primary resource.", spellId, actionResourceExtend);
                    }
                }
            }
        }
    }
    OvaleBestAction.StopProfiling("OvaleBestAction_GetActionSpellInfo");
    return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, actionResourceExtend, actionCharges];
}
const GetActionTextureInfo = function(element, state, atTime, target) {
    OvaleBestAction.StartProfiling("OvaleBestAction_GetActionTextureInfo");
    let actionTexture;
    {
        let texture = element.positionalParams[1];
        let spellId = _tonumber(texture);
        if (spellId) {
            actionTexture = API_GetSpellTexture(spellId);
        } else {
            actionTexture = "Interface\\Icons\\" + texture;
        }
    }
    let actionInRange = undefined;
    let actionCooldownStart = 0;
    let actionCooldownDuration = 0;
    let actionEnable = 1;
    let actionUsable = true;
    let actionShortcut = undefined;
    let actionIsCurrent = undefined;
    let actionType = "texture";
    let actionId = actionTexture;
    OvaleBestAction.StopProfiling("OvaleBestAction_GetActionTextureInfo");
    return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target];
}
class OvaleBestActionClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleBestActionBase)) {
    
    OnInitialize() {
    }
    OnEnable() {
        this.RegisterMessage("Ovale_ScriptChanged");
    }
    OnDisable() {
        this.UnregisterMessage("Ovale_ScriptChanged");
    }
    Ovale_ScriptChanged() {
        for (const [node, timeSpan] of _pairs(self_timeSpan)) {
            timeSpan.Release();
            self_timeSpan[node] = undefined;
        }
        for (const [node, value] of _pairs(self_value)) {
            self_valuePool.Release(value);
            self_value[node] = undefined;
        }
    }
    StartNewAction(state) {
        state.Reset();
        OvaleFuture.ApplyInFlightSpells(state);
        self_serial = self_serial + 1;
    }
    GetActionInfo(element, state, atTime) {
        if (element && element.type == "action") {
            if (element.serial && element.serial >= self_serial) {
                state.Log("[%d]    using cached result (age = %d)", element.nodeId, element.serial);
                return [element.actionTexture, element.actionInRange, element.actionCooldownStart, element.actionCooldownDuration, element.actionUsable, element.actionShortcut, element.actionIsCurrent, element.actionEnable, element.actionType, element.actionId, element.actionTarget, element.actionResourceExtend, element.actionCharges];
            } else {
                let target = element.namedParams.target || state.defaultTarget;
                if (element.lowername == "item") {
                    return GetActionItemInfo(element, state, atTime, target);
                } else if (element.lowername == "macro") {
                    return GetActionMacroInfo(element, state, atTime, target);
                } else if (element.lowername == "spell") {
                    return GetActionSpellInfo(element, state, atTime, target);
                } else if (element.lowername == "texture") {
                    return GetActionTextureInfo(element, state, atTime, target);
                }
            }
        }
        return undefined;
    }
    GetAction(node, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_GetAction");
        let groupNode = node.child[1];
        let [timeSpan, element] = this.Compute(groupNode, state, atTime);
        if (element && element.type == "state") {
            let [variable, value] = [element.positionalParams[1], element.positionalParams[2]];
            let isFuture = !timeSpan.HasTime(atTime);
            state.PutState(variable, value, isFuture);
        }
        this.StopProfiling("OvaleBestAction_GetAction");
        return [timeSpan, element];
    }
    PostOrderCompute(element, state, atTime): [OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan: OvaleTimeSpan, result;
        let postOrder = element.postOrder;
        if (postOrder && !(element.serial && element.serial >= self_serial)) {
            let index = 1;
            let N = lualength(postOrder);
            while (index < N) {
                let [childNode, parentNode] = [postOrder[index], postOrder[index + 1]];
                index = index + 2;
                [timeSpan, result] = this.PostOrderCompute(childNode, state, atTime);
                if (parentNode) {
                    let shortCircuit = false;
                    if (parentNode.child && parentNode.child[1] == childNode) {
                        if (parentNode.type == "if" && timeSpan.Measure() == 0) {
                            state.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        } else if (parentNode.type == "unless" && timeSpan.IsUniverse()) {
                            state.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        } else if (parentNode.type == "logical" && parentNode.operator == "and" && timeSpan.Measure() == 0) {
                            state.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        } else if (parentNode.type == "logical" && parentNode.operator == "or" && timeSpan.IsUniverse()) {
                            state.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        }
                    }
                    if (shortCircuit) {
                        while (parentNode != postOrder[index] && index <= N) {
                            index = index + 2;
                        }
                        if (index > N) {
                            this.Error("Ran off end of postOrder node list for node %d.", element.nodeId);
                        }
                    }
                }
            }
        }
        [timeSpan, result] = this.RecursiveCompute(element, state, atTime);
        this.StartProfiling("OvaleBestAction_Compute");
        return [timeSpan, result];
    }
    RecursiveCompute(element, state, atTime): [OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan, result;
        if (element) {
            if (element.serial && element.serial >= self_serial) {
                timeSpan = element.timeSpan;
                result = element.result;
            } else {
                if (element.asString) {
                    state.Log("[%d] >>> Computing '%s' at time=%f: %s", element.nodeId, element.type, atTime, element.asString);
                } else {
                    state.Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.type, atTime);
                }
                let visitor = COMPUTE_VISITOR[element.type];
                if (visitor && this[visitor]) {
                    [timeSpan, result] = this[visitor](this, element, state, atTime);
                    element.serial = self_serial;
                    element.timeSpan = timeSpan;
                    element.result = result;
                } else {
                    state.Log("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type);
                }
                if (result && result.type == "value") {
                    state.Log("[%d] <<< '%s' returns %s with value = %s, %s, %s", element.nodeId, element.type, timeSpan, result.value, result.origin, result.rate);
                } else if (result && result.nodeId) {
                    state.Log("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, timeSpan);
                } else {
                    state.Log("[%d] <<< '%s' returns %s", element.nodeId, element.type, timeSpan);
                }
            }
        }
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, result];
    }
    ComputeBool(element, state, atTime) {
        let [timeSpan, newElement] = this.Compute(element, state, atTime);
        if (newElement && newElement.type == "value" && newElement.value == 0 && newElement.rate == 0) {
            return EMPTY_SET;
        } else {
            return timeSpan;
        }
    }
    ComputeAction(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_ComputeAction");
        let nodeId = element.nodeId;
        let timeSpan = GetTimeSpan(element);
        let result;
        state.Log("[%d]    evaluating action: %s(%s)", nodeId, element.name, element.paramsAsString);
        let [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend, actionCharges] = this.GetActionInfo(element, state, atTime);
        element.actionTexture = actionTexture;
        element.actionInRange = actionInRange;
        element.actionCooldownStart = actionCooldownStart;
        element.actionCooldownDuration = actionCooldownDuration;
        element.actionUsable = actionUsable;
        element.actionShortcut = actionShortcut;
        element.actionIsCurrent = actionIsCurrent;
        element.actionEnable = actionEnable;
        element.actionType = actionType;
        element.actionId = actionId;
        element.actionTarget = actionTarget;
        element.actionResourceExtend = actionResourceExtend;
        element.actionCharges = actionCharges;
        let action = element.positionalParams[1];
        if (!actionTexture) {
            state.Log("[%d]    Action %s not found.", nodeId, action);
            _wipe(timeSpan);
        } else if (!(actionEnable && actionEnable > 0)) {
            state.Log("[%d]    Action %s not enabled.", nodeId, action);
            _wipe(timeSpan);
        } else if (element.namedParams.usable == 1 && !actionUsable) {
            state.Log("[%d]    Action %s not usable.", nodeId, action);
            _wipe(timeSpan);
        } else {
            let spellInfo;
            if (actionType == "spell") {
                let spellId = actionId;
                spellInfo = spellId && OvaleData.spellInfo[spellId];
                if (spellInfo && spellInfo.casttime) {
                    element.castTime = spellInfo.casttime;
                } else {
                    element.castTime = OvaleSpellBook.GetCastTime(spellId);
                }
            } else {
                element.castTime = 0;
            }
            let start: number;
            if (actionCooldownStart && actionCooldownStart > 0 && (actionCharges == undefined || actionCharges == 0)) {
                state.Log("[%d]    Action %s (actionCharges=%s)", nodeId, action, actionCharges || "(nil)");
                if (actionCooldownDuration && actionCooldownDuration > 0) {
                    state.Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, actionCooldownStart, actionCooldownDuration);
                    start = actionCooldownStart + actionCooldownDuration;
                } else {
                    state.Log("[%d]    Action %s is waiting on the GCD (start=%f).", nodeId, action, actionCooldownStart);
                    start = actionCooldownStart;
                }
            } else {
                if (actionCharges == undefined) {
                    state.Log("[%d]    Action %s is off cooldown.", nodeId, action);
                } else {
                    state.Log("[%d]    Action %s still has %f charges.", nodeId, action, actionCharges);
                }
                start = state.currentTime;
            }
            if (actionResourceExtend && actionResourceExtend > 0) {
                if (element.namedParams.pool_resource && element.namedParams.pool_resource == 1) {
                    state.Log("[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.", nodeId, action);
                } else {
                    state.Log("[%d]    Action %s is waiting on resources (start=%f, extend=%f).", nodeId, action, start, actionResourceExtend);
                    start = start + actionResourceExtend;
                }
            }
            state.Log("[%d]    start=%f atTime=%f", nodeId, start, atTime);
            let offgcd = element.namedParams.offgcd || (spellInfo && spellInfo.offgcd) || 0;
            element.offgcd = (offgcd == 1) && true || undefined;
            if (element.offgcd) {
                state.Log("[%d]    Action %s is off the global cooldown.", nodeId, action);
            } else if (start < atTime) {
                state.Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action);
                let newStart = atTime;
                if (state.IsChanneling(atTime)) {
                    let spellId = state.currentSpellId;
                    let si = spellId && OvaleData.spellInfo[spellId];
                    if (si) {
                        let channel = si.channel || si.canStopChannelling;
                        if (channel) {
                            let hasteMultiplier = state.GetHasteMultiplier(si.haste);
                            let numTicks = floor(channel * hasteMultiplier + 0.5);
                            let tick = (state.endCast - state.startCast) / numTicks;
                            let tickTime = state.startCast;
                            for (let i = 1; i <= numTicks; i += 1) {
                                tickTime = tickTime + tick;
                                if (newStart <= tickTime) {
                                    break;
                                }
                            }
                            newStart = tickTime;
                            state.Log("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spellId, newStart, numTicks, tick, tickTime);
                        }
                    }
                }
                if (start < newStart) {
                    start = newStart;
                }
            }
            state.Log("[%d]    Action %s can start at %f.", nodeId, action, start);
            timeSpan.Copy(start, INFINITY);
            result = element;
        }
        this.StopProfiling("OvaleBestAction_ComputeAction");
        return [timeSpan, result];
    }
    ComputeArithmetic(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan = GetTimeSpan(element);
        let result;
        const [rawTimeSpanA] = this.Compute(element.child[1], state, atTime);
        let [a, b, c, timeSpanA] = AsValue(atTime, rawTimeSpanA);
        const [rawTimeSpanB] = this.Compute(element.child[2], state, atTime);
        let [x, y, z, timeSpanB] = AsValue(atTime, rawTimeSpanB);
        timeSpanA.Intersect(timeSpanB, timeSpan);
        if (timeSpan.Measure() == 0) {
            state.Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan);
            result = SetValue(element, 0);
        } else {
            let operator = element.operator;
            let t = atTime;
            state.Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z);
            let l, m, n;
            let A = a + (t - b) * c;
            let B = x + (t - y) * z;
            if (operator == "+") {
                l = A + B;
                m = t;
                n = c + z;
            } else if (operator == "-") {
                l = A - B;
                m = t;
                n = c - z;
            } else if (operator == "*") {
                l = A * B;
                m = t;
                n = A * z + B * c;
            } else if (operator == "/") {
                l = A / B;
                m = t;
                let numerator = B * c - A * z;
                if (numerator != INFINITY) {
                    n = numerator / (B ^ 2);
                } else {
                    n = numerator;
                }
                let bound;
                if (z == 0) {
                    bound = INFINITY;
                } else {
                    bound = abs(B / z);
                }
                let scratch = timeSpan.IntersectInterval(t - bound, t + bound);
                timeSpan.copyFromArray(scratch);
                scratch.Release();
            } else if (operator == "%") {
                if (c == 0 && z == 0) {
                    l = A % B;
                    m = t;
                    n = 0;
                } else {
                    this.Error("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId);
                    l = 0;
                    m = 0;
                    n = 0;
                }
            }
            state.Log("[%d]    arithmetic '%s' returns %s+(t-%s)*%s", element.nodeId, operator, l, m, n);
            result = SetValue(element, l, m, n);
        }
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, result];
    }
    ComputeCompare(element, state, atTime) {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan = GetTimeSpan(element);
        const [rawTimeSpanA] = this.Compute(element.child[1], state, atTime);
        let [a, b, c, timeSpanA] = AsValue(atTime, rawTimeSpanA);
        const [rawTimeSpanB] = this.Compute(element.child[2], state, atTime);
        let [x, y, z, timeSpanB] = AsValue(atTime, rawTimeSpanB);
        timeSpanA.Intersect(timeSpanB, timeSpan);
        if (timeSpan.Measure() == 0) {
            state.Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan);
        } else {
            let operator = element.operator;
            state.Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z);
            let A = a - b * c;
            let B = x - y * z;
            if (c == z) {
                if (!((operator == "==" && A == B) || (operator == "!=" && A != B) || (operator == "<" && A < B) || (operator == "<=" && A <= B) || (operator == ">" && A > B) || (operator == ">=" && A >= B))) {
                    _wipe(timeSpan);
                }
            } else {
                let diff = B - A;
                let t;
                if (diff == INFINITY) {
                    t = INFINITY;
                } else {
                    t = diff / (c - z);
                }
                t = (t > 0) && t || 0;
                state.Log("[%d]    intersection at t = %s", element.nodeId, t);
                let scratch:OvaleTimeSpan;
                if ((c > z && operator == "<") || (c > z && operator == "<=") || (c < z && operator == ">") || (c < z && operator == ">=")) {
                    scratch = timeSpan.IntersectInterval(0, t);
                } else if ((c < z && operator == "<") || (c < z && operator == "<=") || (c > z && operator == ">") || (c > z && operator == ">=")) {
                    scratch = timeSpan.IntersectInterval(t, INFINITY);
                }
                if (scratch) {
                    timeSpan.copyFromArray(scratch);
                    scratch.Release();
                } else {
                    _wipe(timeSpan);
                }
            }
            state.Log("[%d]    compare '%s' returns %s", element.nodeId, operator, timeSpan);
        }
        this.StopProfiling("OvaleBestAction_Compute");
        return timeSpan;
    }
    ComputeCustomFunction(element, state, atTime): [OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan = GetTimeSpan(element);
        let result: OvaleTimeSpan;
        let node = OvaleCompile.GetFunctionNode(element.name);
        if (node) {
            let [timeSpanA, elementA] = this.Compute(node.child[1], state, atTime);
            timeSpan.copyFromArray(timeSpanA);
            result = elementA;
        } else {
            _wipe(timeSpan);
        }
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, result];
    }
    ComputeFunction(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_ComputeFunction");
        let timeSpan = GetTimeSpan(element);
        let result;
        let [start, ending, value, origin, rate] = OvaleCondition.EvaluateCondition(element.func, element.positionalParams, element.namedParams, state, atTime);
        if (start && ending) {
            timeSpan.Copy(start, ending);
        } else {
            _wipe(timeSpan);
        }
        if (value) {
            result = SetValue(element, value, origin, rate);
        }
        state.Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate);
        this.StopProfiling("OvaleBestAction_ComputeFunction");
        return [timeSpan, result];
    }
    ComputeGroup(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let bestTimeSpan, bestElement, bestCastTime;
        let best = newTimeSpan();
        let current = newTimeSpan();
        for (const [_, node] of _ipairs<{nodeId:number}>(element.child)) {
            let [currentTimeSpan, currentElement] = this.Compute(node, state, atTime);
            currentTimeSpan.IntersectInterval(atTime, INFINITY, current);
            if (current.Measure() > 0) {
                let nodeString = (currentElement && currentElement.nodeId) && " [" + currentElement.nodeId + "]" || "";
                state.Log("[%d]    group checking [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString);
                let currentCastTime;
                if (currentElement) {
                    currentCastTime = currentElement.castTime;
                }
                let gcd = state.GetGCD();
                if (!currentCastTime || currentCastTime < gcd) {
                    currentCastTime = gcd;
                }
                let currentIsBetter = false;
                if (best.Measure() == 0) {
                    state.Log("[%d]    group first best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString);
                    currentIsBetter = true;
                } else {
                    let threshold = (bestElement && bestElement.namedParams) && bestElement.namedParams.wait || 0;
                    if (best[1] - current[1] > threshold) {
                        state.Log("[%d]    group new best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString);
                        currentIsBetter = true;
                    }
                }
                if (currentIsBetter) {
                    best.copyFromArray(current);
                    bestTimeSpan = currentTimeSpan;
                    bestElement = currentElement;
                    bestCastTime = currentCastTime;
                }
            }
        }
        releaseTimeSpans(best, current);
        let timeSpan = GetTimeSpan(element, bestTimeSpan);
        if (!bestTimeSpan) {
            _wipe(timeSpan);
        }
        if (bestElement) {
            let id = bestElement.value;
            if (bestElement.positionalParams) {
                id = bestElement.positionalParams[1];
            }
            state.Log("[%d]    group best action %s remains %s", element.nodeId, id, timeSpan);
        } else {
            state.Log("[%d]    group no best action returns %s", element.nodeId, timeSpan);
        }
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, bestElement];
    }
    ComputeIf(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan = GetTimeSpan(element);
        let result;
        let timeSpanA = this.ComputeBool(element.child[1], state, atTime);
        let conditionTimeSpan = timeSpanA;
        if (element.type == "unless") {
            conditionTimeSpan = timeSpanA.Complement();
        }
        if (conditionTimeSpan.Measure() == 0) {
            timeSpan.copyFromArray(conditionTimeSpan);
            state.Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan);
        } else {
            let [timeSpanB, elementB] = this.Compute(element.child[2], state, atTime);
            conditionTimeSpan.Intersect(timeSpanB, timeSpan);
            state.Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, timeSpanB);
            result = elementB;
        }
        if (element.type == "unless") {
            conditionTimeSpan.Release();
        }
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, result];
    }
    ComputeLogical(element, state, atTime) {
        this.StartProfiling("OvaleBestAction_Compute");
        let timeSpan = GetTimeSpan(element);
        let timeSpanA = this.ComputeBool(element.child[1], state, atTime);
        if (element.operator == "and") {
            if (timeSpanA.Measure() == 0) {
                timeSpan.copyFromArray(timeSpanA);
                state.Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator);
            } else {
                let timeSpanB = this.ComputeBool(element.child[2], state, atTime);
                timeSpanA.Intersect(timeSpanB, timeSpan);
            }
        } else if (element.operator == "not") {
            timeSpanA.Complement(timeSpan);
        } else if (element.operator == "or") {
            if (timeSpanA.IsUniverse()) {
                timeSpan.copyFromArray(timeSpanA);
                state.Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator);
            } else {
                let timeSpanB = this.ComputeBool(element.child[2], state, atTime);
                timeSpanA.Union(timeSpanB, timeSpan);
            }
        } else if (element.operator == "xor") {
            let timeSpanB = this.ComputeBool(element.child[2], state, atTime);
            let left = timeSpanA.Union(timeSpanB);
            let scratch = timeSpanA.Intersect(timeSpanB);
            let right = scratch.Complement();
            left.Intersect(right, timeSpan);
            releaseTimeSpans(left, scratch, right);
        } else {
            _wipe(timeSpan);
        }
        state.Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, timeSpan);
        this.StopProfiling("OvaleBestAction_Compute");
        return timeSpan;
    }
    ComputeLua(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_ComputeLua");
        let value = _loadstring(element.lua)();
        state.Log("[%d]    lua returns %s", element.nodeId, value);
        let result;
        if (value) {
            result = SetValue(element, value);
        }
        let timeSpan = GetTimeSpan(element, UNIVERSE);
        this.StopProfiling("OvaleBestAction_ComputeLua");
        return [timeSpan, result];
    }
    ComputeState(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        let result = element;
        _assert(element.func == "setstate");
        state.Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2]);
        let timeSpan = GetTimeSpan(element, UNIVERSE);
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, result];
    }
    ComputeValue(element, state, atTime):[OvaleTimeSpan, any] {
        this.StartProfiling("OvaleBestAction_Compute");
        state.Log("[%d]    value is %s", element.nodeId, element.value);
        let timeSpan = GetTimeSpan(element, UNIVERSE);
        this.StopProfiling("OvaleBestAction_Compute");
        return [timeSpan, element];
    }

    Compute = this.PostOrderCompute;
}

OvaleBestAction = new OvaleBestActionClass();