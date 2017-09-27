local OVALE, Ovale = ...
require(OVALE, Ovale, "State", { "./L", "./OvaleDebug", "./OvaleQueue" }, function(__exports, __L, __OvaleDebug, __OvaleQueue)
local OvaleState = Ovale:NewModule("OvaleState")
Ovale.OvaleState = OvaleState
local _pairs = pairs
local self_statePrototype = {}
local self_stateAddons = __OvaleQueue.OvaleQueue:NewQueue("OvaleState_stateAddons")
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleState)
OvaleState.state = {}
local OvaleState = __class()
function OvaleState:OnEnable()
    self:RegisterState(self, self.statePrototype)
end
function OvaleState:OnDisable()
    self:UnregisterState(self)
end
function OvaleState:RegisterState(stateAddon, statePrototype)
    self_stateAddons:Insert(stateAddon)
    self_statePrototype[stateAddon] = statePrototype
    for k, v in _pairs(statePrototype) do
        self.state[k] = v
    end
end
function OvaleState:UnregisterState(stateAddon)
    local stateModules = __OvaleQueue.OvaleQueue:NewQueue("OvaleState_stateModules")
    while self_stateAddons:Size() > 0do
        local addon = self_stateAddons:Remove()
        if stateAddon ~= addon then
            stateModules:Insert(addon)
        end
end
    self_stateAddons = stateModules
    if stateAddon.CleanState then
        stateAddon:CleanState(self.state)
    end
    local statePrototype = self_statePrototype[stateAddon]
    if statePrototype then
        for k in _pairs(statePrototype) do
            self.state[k] = nil
        end
    end
    self_statePrototype[stateAddon] = nil
end
function OvaleState:InvokeMethod(methodName, ...)
    for _, addon in self_stateAddons:Iterator() do
        if addon[methodName] then
            addon[methodName](addon, ...)
        end
    end
end
OvaleState.statePrototype = {}
local statePrototype = OvaleState.statePrototype
statePrototype.isState = true
statePrototype.isInitialized = nil
statePrototype.futureVariable = nil
statePrototype.futureLastEnable = nil
statePrototype.variable = nil
statePrototype.lastEnable = nil
local OvaleState = __class()
function OvaleState:InitializeState(state)
    state.futureVariable = {}
    state.futureLastEnable = {}
    state.variable = {}
    state.lastEnable = {}
end
function OvaleState:ResetState(state)
    for k in _pairs(state.futureVariable) do
        state.futureVariable[k] = nil
        state.futureLastEnable[k] = nil
    end
    if  not state.inCombat then
        for k in _pairs(state.variable) do
            state:Log("Resetting state variable '%s'.", k)
            state.variable[k] = nil
            state.lastEnable[k] = nil
        end
    end
end
function OvaleState:CleanState(state)
    for k in _pairs(state.futureVariable) do
        state.futureVariable[k] = nil
    end
    for k in _pairs(state.futureLastEnable) do
        state.futureLastEnable[k] = nil
    end
    for k in _pairs(state.variable) do
        state.variable[k] = nil
    end
    for k in _pairs(state.lastEnable) do
        state.lastEnable[k] = nil
    end
end
statePrototype.Initialize = function(state)
    if  not state.isInitialized then
        OvaleState:InvokeMethod("InitializeState", state)
        state.isInitialized = true
    end
end
statePrototype.Reset = function(state)
    OvaleState:InvokeMethod("ResetState", state)
end
statePrototype.GetState = function(state, name)
    return state.futureVariable[name] or state.variable[name] or 0
end
statePrototype.GetStateDuration = function(state, name)
    local lastEnable = state.futureLastEnable[name] or state.lastEnable[name] or state.currentTime
    return state.currentTime - lastEnable
end
statePrototype.PutState = function(state, name, value, isFuture)
    if isFuture then
        local oldValue = state:GetState(name)
        if value ~= oldValue then
            state:Log("Setting future state: %s from %s to %s.", name, oldValue, value)
            state.futureVariable[name] = value
            state.futureLastEnable[name] = state.currentTime
        end
    else
        local oldValue = state.variable[name] or 0
        if value ~= oldValue then
            OvaleState:DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value)
            state:Log("Advancing combat state: %s from %s to %s.", name, oldValue, value)
            state.variable[name] = value
            state.lastEnable[name] = state.currentTime
        end
    end
end
statePrototype.Log = function(state, ...)
    return __OvaleDebug.OvaleDebug:Log(...)
end
statePrototype.GetMethod = Ovale.GetMethod
end))
