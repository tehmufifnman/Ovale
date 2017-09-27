local OVALE, Ovale = ...
require(OVALE, Ovale, "BestAction", { "./OvaleDebug", "./OvalePool", "./OvaleProfiler", "./OvaleTimeSpan" }, function(__exports, __OvaleDebug, __OvalePool, __OvaleProfiler, __OvaleTimeSpan)
local OvaleBestAction = Ovale:NewModule("OvaleBestAction", "AceEvent-3.0")
Ovale.OvaleBestAction = OvaleBestAction
local OvaleAST = nil
local OvaleActionBar = nil
local OvaleCompile = nil
local OvaleCondition = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleEquipment = nil
local OvaleGUID = nil
local OvaleFuture = nil
local OvalePower = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local abs = math.abs
local _assert = assert
local floor = math.floor
local _ipairs = ipairs
local _loadstring = loadstring
local _pairs = pairs
local _tonumber = tonumber
local _type = type
local _wipe = wipe
local Complement = __OvaleTimeSpan.OvaleTimeSpan.Complement
local CopyTimeSpan = __OvaleTimeSpan.OvaleTimeSpan.Copy
local HasTime = __OvaleTimeSpan.OvaleTimeSpan.HasTime
local Intersect = __OvaleTimeSpan.OvaleTimeSpan.Intersect
local IntersectInterval = __OvaleTimeSpan.OvaleTimeSpan.IntersectInterval
local IsUniverse = __OvaleTimeSpan.OvaleTimeSpan.IsUniverse
local Measure = __OvaleTimeSpan.OvaleTimeSpan.Measure
local ReleaseTimeSpan = __OvaleTimeSpan.OvaleTimeSpan.Release
local Union = __OvaleTimeSpan.OvaleTimeSpan.Union
local EMPTY_SET = __OvaleTimeSpan.OvaleTimeSpan.EMPTY_SET
local UNIVERSE = __OvaleTimeSpan.OvaleTimeSpan.UNIVERSE
local INFINITY = math.huge
local API_GetTime = GetTime
local API_GetActionCooldown = GetActionCooldown
local API_GetActionTexture = GetActionTexture
local API_GetItemIcon = GetItemIcon
local API_GetItemCooldown = GetItemCooldown
local API_GetItemSpell = GetItemSpell
local API_GetSpellTexture = GetSpellTexture
local API_IsActionInRange = IsActionInRange
local API_IsCurrentAction = IsCurrentAction
local API_IsItemInRange = IsItemInRange
local API_IsUsableAction = IsUsableAction
local API_IsUsableItem = IsUsableItem
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleBestAction)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleBestAction)
local COMPUTE_VISITOR = {
    ["action"] = "ComputeAction",
    ["arithmetic"] = "ComputeArithmetic",
    ["compare"] = "ComputeCompare",
    ["custom_function"] = "ComputeCustomFunction",
    ["function"] = "ComputeFunction",
    ["group"] = "ComputeGroup",
    ["if"] = "ComputeIf",
    ["logical"] = "ComputeLogical",
    ["lua"] = "ComputeLua",
    ["state"] = "ComputeState",
    ["unless"] = "ComputeIf",
    ["value"] = "ComputeValue"
}
local self_serial = 0
local self_timeSpan = {}
local self_valuePool = __OvalePool.OvalePool("OvaleBestAction_valuePool")
local self_value = {}
local SetValue = function(node, value, origin, rate)
    local result = self_value[node]
    if  not result then
        result = self_valuePool:Get()
        self_value[node] = result
    end
    result.type = "value"
    result.value = value or 0
    result.origin = origin or 0
    result.rate = rate or 0
    return result
end
local AsValue = function(atTime, timeSpan, node)
    local value, origin, rate
    if node and node.type == "value" then
        value, origin, rate = node.value, node.origin, node.rate
    elseif timeSpan and HasTime(timeSpan, atTime) then
        value, origin, rate, timeSpan = 1, 0, 0, UNIVERSE
    else
        value, origin, rate, timeSpan = 0, 0, 0, UNIVERSE
    end
    return value, origin, rate, timeSpan
end
local GetTimeSpan = function(node, defaultTimeSpan)
    local timeSpan = self_timeSpan[node]
    if timeSpan then
        if defaultTimeSpan then
            CopyTimeSpan(timeSpan, defaultTimeSpan)
        end
    else
        self_timeSpan[node] = __OvaleTimeSpan.OvaleTimeSpan:New(defaultTimeSpan)
        timeSpan = self_timeSpan[node]
    end
    return timeSpan
end
local GetActionItemInfo = function(element, state, atTime, target)
    OvaleBestAction:StartProfiling("OvaleBestAction_GetActionItemInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
    local itemId = element.positionalParams[1]
    if _type(itemId) ~= "number" then
        itemId = OvaleEquipment:GetEquippedItem(itemId)
    end
    if  not itemId then
        state:Log("Unknown item '%s'.", element.positionalParams[1])
    else
        state:Log("Item ID '%s'", itemId)
        local action = OvaleActionBar:GetForItem(itemId)
        local spellName = API_GetItemSpell(itemId)
        if element.namedParams.texture then
            actionTexture = "Interface\Icons\" + element.namedParams.texture
        end
        actionTexture = actionTexture or API_GetItemIcon(itemId)
        actionInRange = API_IsItemInRange(itemId, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = API_GetItemCooldown(itemId)
        actionUsable = spellName and API_IsUsableItem(itemId) and state:IsUsableItem(itemId)
        if action then
            actionShortcut = OvaleActionBar:GetBinding(action)
            actionIsCurrent = API_IsCurrentAction(action)
        end
        actionType = "item"
        actionId = itemId
    end
    OvaleBestAction:StopProfiling("OvaleBestAction_GetActionItemInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end
local GetActionMacroInfo = function(element, state, atTime, target)
    OvaleBestAction:StartProfiling("OvaleBestAction_GetActionMacroInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
    local macro = element.positionalParams[1]
    local action = OvaleActionBar:GetForMacro(macro)
    if  not action then
        state:Log("Unknown macro '%s'.", macro)
    else
        if element.namedParams.texture then
            actionTexture = "Interface\Icons\" + element.namedParams.texture
        end
        actionTexture = actionTexture or API_GetActionTexture(action)
        actionInRange = API_IsActionInRange(action, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = API_GetActionCooldown(action)
        actionUsable = API_IsUsableAction(action)
        actionShortcut = OvaleActionBar:GetBinding(action)
        actionIsCurrent = API_IsCurrentAction(action)
        actionType = "macro"
        actionId = macro
    end
    OvaleBestAction:StopProfiling("OvaleBestAction_GetActionMacroInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end
local GetActionSpellInfo = function(element, state, atTime, target)
    OvaleBestAction:StartProfiling("OvaleBestAction_GetActionSpellInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionResourceExtend, actionCharges
    local targetGUID = OvaleGUID:UnitGUID(target)
    local spellId = element.positionalParams[1]
    local si = OvaleData.spellInfo[spellId]
    local replacedSpellId = nil
    if si and si.replace then
        local replacement = state:GetSpellInfoProperty(spellId, atTime, "replace", targetGUID)
        if replacement then
            replacedSpellId = spellId
            spellId = replacement
            si = OvaleData.spellInfo[spellId]
            state:Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId)
        end
    end
    local action = OvaleActionBar:GetForSpell(spellId)
    if  not action and replacedSpellId then
        state:Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
        action = OvaleActionBar:GetForSpell(replacedSpellId)
    end
    local isKnownSpell = OvaleSpellBook:IsKnownSpell(spellId)
    if  not isKnownSpell and replacedSpellId then
        state:Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
        isKnownSpell = OvaleSpellBook:IsKnownSpell(replacedSpellId)
    end
    if  not isKnownSpell and  not action then
        state:Log("Unknown spell ID '%s'.", spellId)
    else
        local isUsable, noMana = state:IsUsableSpell(spellId, atTime, targetGUID)
        if isUsable or noMana then
            if element.namedParams.texture then
                actionTexture = "Interface\Icons\" + element.namedParams.texture
            end
            actionTexture = actionTexture or API_GetSpellTexture(spellId)
            actionInRange = OvaleSpellBook:IsSpellInRange(spellId, target)
            actionCooldownStart, actionCooldownDuration, actionEnable = state:GetSpellCooldown(spellId)
            actionCharges = state:GetSpellCharges(spellId)
            actionResourceExtend = 0
            actionUsable = isUsable
            if action then
                actionShortcut = OvaleActionBar:GetBinding(action)
                actionIsCurrent = API_IsCurrentAction(action)
            end
            actionType = "spell"
            actionId = spellId
            if si then
                if si.texture then
                    actionTexture = "Interface\Icons\" + si.texture
                end
                if actionCooldownStart and actionCooldownDuration then
                    local extraPower = element.namedParams.extra_amount or 0
                    local seconds = state:GetTimeToSpell(spellId, atTime, targetGUID, extraPower)
                    if seconds > 0 and seconds > actionCooldownDuration then
                        if actionCooldownDuration > 0 then
                            actionResourceExtend = seconds - actionCooldownDuration
                        else
                            actionResourceExtend = seconds
                        end
                        state:Log("Spell ID '%s' requires an extra %fs for primary resource.", spellId, actionResourceExtend)
                    end
                end
            end
        end
    end
    OvaleBestAction:StopProfiling("OvaleBestAction_GetActionSpellInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, actionResourceExtend, actionCharges
end
local GetActionTextureInfo = function(element, state, atTime, target)
    OvaleBestAction:StartProfiling("OvaleBestAction_GetActionTextureInfo")
    local actionTexture
    do
        local texture = element.positionalParams[1]
        local spellId = _tonumber(texture)
        if spellId then
            actionTexture = API_GetSpellTexture(spellId)
        else
            actionTexture = "Interface\Icons\" + texture
        end
    end
    local actionInRange = nil
    local actionCooldownStart = 0
    local actionCooldownDuration = 0
    local actionEnable = 1
    local actionUsable = true
    local actionShortcut = nil
    local actionIsCurrent = nil
    local actionType = "texture"
    local actionId = actionTexture
    OvaleBestAction:StopProfiling("OvaleBestAction_GetActionTextureInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end
local OvaleBestAction = __class()
function OvaleBestAction:OnInitialize()
    OvaleAST = Ovale.OvaleAST
    OvaleActionBar = Ovale.OvaleActionBar
    OvaleCompile = Ovale.OvaleCompile
    OvaleCondition = Ovale.OvaleCondition
    OvaleCooldown = Ovale.OvaleCooldown
    OvaleData = Ovale.OvaleData
    OvaleGUID = Ovale.OvaleGUID
    OvaleEquipment = Ovale.OvaleEquipment
    OvaleFuture = Ovale.OvaleFuture
    OvalePower = Ovale.OvalePower
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleStance = Ovale.OvaleStance
end
function OvaleBestAction:OnEnable()
    self:RegisterMessage("Ovale_ScriptChanged")
end
function OvaleBestAction:OnDisable()
    self:UnregisterMessage("Ovale_ScriptChanged")
end
function OvaleBestAction:Ovale_ScriptChanged()
    for node, timeSpan in _pairs(self_timeSpan) do
        ReleaseTimeSpan(timeSpan)
        self_timeSpan[node] = nil
    end
    for node, value in _pairs(self_value) do
        self_valuePool:Release(value)
        self_value[node] = nil
    end
end
function OvaleBestAction:StartNewAction(state)
    state:Reset()
    OvaleFuture:ApplyInFlightSpells(state)
    self_serial = self_serial + 1
end
function OvaleBestAction:GetActionInfo(element, state, atTime)
    if element and element.type == "action" then
        if element.serial and element.serial >= self_serial then
            state:Log("[%d]    using cached result (age = %d)", element.nodeId, element.serial)
            return element.actionTexture, element.actionInRange, element.actionCooldownStart, element.actionCooldownDuration, element.actionUsable, element.actionShortcut, element.actionIsCurrent, element.actionEnable, element.actionType, element.actionId, element.actionTarget, element.actionResourceExtend, element.actionCharges
        else
            local target = element.namedParams.target or state.defaultTarget
            if element.lowername == "item" then
                return GetActionItemInfo(element, state, atTime, target)
            elseif element.lowername == "macro" then
                return GetActionMacroInfo(element, state, atTime, target)
            elseif element.lowername == "spell" then
                return GetActionSpellInfo(element, state, atTime, target)
            elseif element.lowername == "texture" then
                return GetActionTextureInfo(element, state, atTime, target)
            end
        end
    end
    return nil
end
function OvaleBestAction:GetAction(node, state, atTime)
    self:StartProfiling("OvaleBestAction_GetAction")
    local groupNode = node.child[1]
    local timeSpan, element = self:Compute(groupNode, state, atTime)
    if element and element.type == "state" then
        local variable, value = element.positionalParams[1], element.positionalParams[2]
        local isFuture =  not HasTime(timeSpan, atTime)
        state:PutState(variable, value, isFuture)
    end
    self:StopProfiling("OvaleBestAction_GetAction")
    return timeSpan, element
end
function OvaleBestAction:PostOrderCompute(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan, result
    local postOrder = element.postOrder
    if postOrder and  not (element.serial and element.serial >= self_serial) then
        local index = 1
        local N = #postOrder
        while index < Ndo
            local childNode, parentNode = postOrder[index], postOrder[index + 1]
            index = index + 2
            timeSpan, result = self:PostOrderCompute(childNode, state, atTime)
            if parentNode then
                local shortCircuit = false
                if parentNode.child and parentNode.child[1] == childNode then
                    if parentNode.type == "if" and Measure(timeSpan) == 0 then
                        state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId)
                        shortCircuit = true
                    elseif parentNode.type == "unless" and IsUniverse(timeSpan) then
                        state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                        shortCircuit = true
                    elseif parentNode.type == "logical" and parentNode.operator == "and" and Measure(timeSpan) == 0 then
                        state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId)
                        shortCircuit = true
                    elseif parentNode.type == "logical" and parentNode.operator == "or" and IsUniverse(timeSpan) then
                        state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                        shortCircuit = true
                    end
                end
                if shortCircuit then
                    while parentNode ~= postOrder[index] and index <= Ndo
                        index = index + 2
end
                    if index > N then
                        self:Error("Ran off end of postOrder node list for node %d.", element.nodeId)
                    end
                end
            end
end
    end
    timeSpan, result = self:RecursiveCompute(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    return timeSpan, result
end
function OvaleBestAction:RecursiveCompute(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan, result
    if element then
        if element.serial and element.serial >= self_serial then
            timeSpan = element.timeSpan
            result = element.result
        else
            if element.asString then
                state:Log("[%d] >>> Computing '%s' at time=%f: %s", element.nodeId, element.type, atTime, element.asString)
            else
                state:Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.type, atTime)
            end
            local visitor = COMPUTE_VISITOR[element.type]
            if visitor and self[visitor] then
                timeSpan, result = self[visitor](self, element, state, atTime)
                element.serial = self_serial
                element.timeSpan = timeSpan
                element.result = result
            else
                state:Log("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type)
            end
            if result and result.type == "value" then
                state:Log("[%d] <<< '%s' returns %s with value = %s, %s, %s", element.nodeId, element.type, timeSpan, result.value, result.origin, result.rate)
            elseif result and result.nodeId then
                state:Log("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, timeSpan)
            else
                state:Log("[%d] <<< '%s' returns %s", element.nodeId, element.type, timeSpan)
            end
        end
    end
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, result
end
function OvaleBestAction:ComputeBool(element, state, atTime)
    local timeSpan, newElement = self:Compute(element, state, atTime)
    if newElement and newElement.type == "value" and newElement.value == 0 and newElement.rate == 0 then
        return EMPTY_SET
    else
        return timeSpan
    end
end
function OvaleBestAction:ComputeAction(element, state, atTime)
    self:StartProfiling("OvaleBestAction_ComputeAction")
    local nodeId = element.nodeId
    local timeSpan = GetTimeSpan(element)
    local result
    state:Log("[%d]    evaluating action: %s(%s)", nodeId, element.name, element.paramsAsString)
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend, actionCharges = self:GetActionInfo(element, state, atTime)
    element.actionTexture = actionTexture
    element.actionInRange = actionInRange
    element.actionCooldownStart = actionCooldownStart
    element.actionCooldownDuration = actionCooldownDuration
    element.actionUsable = actionUsable
    element.actionShortcut = actionShortcut
    element.actionIsCurrent = actionIsCurrent
    element.actionEnable = actionEnable
    element.actionType = actionType
    element.actionId = actionId
    element.actionTarget = actionTarget
    element.actionResourceExtend = actionResourceExtend
    element.actionCharges = actionCharges
    local action = element.positionalParams[1]
    if  not actionTexture then
        state:Log("[%d]    Action %s not found.", nodeId, action)
        _wipe(timeSpan)
    elseif  not (actionEnable and actionEnable > 0) then
        state:Log("[%d]    Action %s not enabled.", nodeId, action)
        _wipe(timeSpan)
    elseif element.namedParams.usable == 1 and  not actionUsable then
        state:Log("[%d]    Action %s not usable.", nodeId, action)
        _wipe(timeSpan)
    else
        local spellInfo
        if actionType == "spell" then
            local spellId = actionId
            spellInfo = spellId and OvaleData.spellInfo[spellId]
            if spellInfo and spellInfo.casttime then
                element.castTime = spellInfo.casttime
            else
                element.castTime = OvaleSpellBook:GetCastTime(spellId)
            end
        else
            element.castTime = 0
        end
        local start
        if actionCooldownStart and actionCooldownStart > 0 and (actionCharges == nil or actionCharges == 0) then
            state:Log("[%d]    Action %s (actionCharges=%s)", nodeId, action, actionCharges or "(nil)")
            if actionCooldownDuration and actionCooldownDuration > 0 then
                state:Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, actionCooldownStart, actionCooldownDuration)
                start = actionCooldownStart + actionCooldownDuration
            else
                state:Log("[%d]    Action %s is waiting on the GCD (start=%f).", nodeId, action, actionCooldownStart)
                start = actionCooldownStart
            end
        else
            if actionCharges == nil then
                state:Log("[%d]    Action %s is off cooldown.", nodeId, action)
            else
                state:Log("[%d]    Action %s still has %f charges.", nodeId, action, actionCharges)
            end
            start = state.currentTime
        end
        if actionResourceExtend and actionResourceExtend > 0 then
            if element.namedParams.pool_resource and element.namedParams.pool_resource == 1 then
                state:Log("[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.", nodeId, action)
            else
                state:Log("[%d]    Action %s is waiting on resources (start=%f, extend=%f).", nodeId, action, start, actionResourceExtend)
                start = start + actionResourceExtend
            end
        end
        state:Log("[%d]    start=%f atTime=%f", nodeId, start, atTime)
        local offgcd = element.namedParams.offgcd or (spellInfo and spellInfo.offgcd) or 0
        element.offgcd = (offgcd == 1) and true or nil
        if element.offgcd then
            state:Log("[%d]    Action %s is off the global cooldown.", nodeId, action)
        elseif start < atTime then
            state:Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action)
            local newStart = atTime
            if state:IsChanneling(atTime) then
                local spellId = state.currentSpellId
                local si = spellId and OvaleData.spellInfo[spellId]
                if si then
                    local channel = si.channel or si.canStopChannelling
                    if channel then
                        local hasteMultiplier = state:GetHasteMultiplier(si.haste)
                        local numTicks = floor(channel * hasteMultiplier + 0.5)
                        local tick = (state.endCast - state.startCast) / numTicks
                        local tickTime = state.startCast
                        for i = 1, numTicks, 1 do
                            tickTime = tickTime + tick
                            if newStart <= tickTime then
                                break
                            end
                        end
                        newStart = tickTime
                        state:Log("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spellId, newStart, numTicks, tick, tickTime)
                    end
                end
            end
            if start < newStart then
                start = newStart
            end
        end
        state:Log("[%d]    Action %s can start at %f.", nodeId, action, start)
        CopyTimeSpan(timeSpan, start, INFINITY)
        result = element
    end
    self:StopProfiling("OvaleBestAction_ComputeAction")
    return timeSpan, result
end
function OvaleBestAction:ComputeArithmetic(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan = GetTimeSpan(element)
    local result
    local a, b, c, timeSpanA = AsValue(atTime, self:Compute(element.child[1], state, atTime))
    local x, y, z, timeSpanB = AsValue(atTime, self:Compute(element.child[2], state, atTime))
    Intersect(timeSpanA, timeSpanB, timeSpan)
    if Measure(timeSpan) == 0 then
        state:Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
        result = SetValue(element, 0)
    else
        local operator = element.operator
        local t = atTime
        state:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
        local l, m, n
        local A = a + (t - b) * c
        local B = x + (t - y) * z
        if operator == "+" then
            l = A + B
            m = t
            n = c + z
        elseif operator == "-" then
            l = A - B
            m = t
            n = c - z
        elseif operator == "*" then
            l = A * B
            m = t
            n = A * z + B * c
        elseif operator == "/" then
            l = A / B
            m = t
            local numerator = B * c - A * z
            if numerator ~= INFINITY then
                n = numerator / (B ^ 2)
            else
                n = numerator
            end
            local bound
            if z == 0 then
                bound = INFINITY
            else
                bound = abs(B / z)
            end
            local scratch = IntersectInterval(timeSpan, t - bound, t + bound)
            CopyTimeSpan(timeSpan, scratch)
            ReleaseTimeSpan(scratch)
        elseif operator == "%" then
            if c == 0 and z == 0 then
                l = A % B
                m = t
                n = 0
            else
                self:Error("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId)
                l = 0
                m = 0
                n = 0
            end
        end
        state:Log("[%d]    arithmetic '%s' returns %s+(t-%s)*%s", element.nodeId, operator, l, m, n)
        result = SetValue(element, l, m, n)
    end
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, result
end
function OvaleBestAction:ComputeCompare(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan = GetTimeSpan(element)
    local a, b, c, timeSpanA = AsValue(atTime, self:Compute(element.child[1], state, atTime))
    local x, y, z, timeSpanB = AsValue(atTime, self:Compute(element.child[2], state, atTime))
    Intersect(timeSpanA, timeSpanB, timeSpan)
    if Measure(timeSpan) == 0 then
        state:Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
    else
        local operator = element.operator
        state:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
        local A = a - b * c
        local B = x - y * z
        if c == z then
            if  not ((operator == "==" and A == B) or (operator == "!=" and A ~= B) or (operator == "<" and A < B) or (operator == "<=" and A <= B) or (operator == ">" and A > B) or (operator == ">=" and A >= B)) then
                _wipe(timeSpan)
            end
        else
            local diff = B - A
            local t
            if diff == INFINITY then
                t = INFINITY
            else
                t = diff / (c - z)
            end
            t = (t > 0) and t or 0
            state:Log("[%d]    intersection at t = %s", element.nodeId, t)
            local scratch
            if (c > z and operator == "<") or (c > z and operator == "<=") or (c < z and operator == ">") or (c < z and operator == ">=") then
                scratch = IntersectInterval(timeSpan, 0, t)
            elseif (c < z and operator == "<") or (c < z and operator == "<=") or (c > z and operator == ">") or (c > z and operator == ">=") then
                scratch = IntersectInterval(timeSpan, t, INFINITY)
            end
            if scratch then
                CopyTimeSpan(timeSpan, scratch)
                ReleaseTimeSpan(scratch)
            else
                _wipe(timeSpan)
            end
        end
        state:Log("[%d]    compare '%s' returns %s", element.nodeId, operator, timeSpan)
    end
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan
end
function OvaleBestAction:ComputeCustomFunction(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan = GetTimeSpan(element)
    local result
    local node = OvaleCompile:GetFunctionNode(element.name)
    if node then
        local timeSpanA, elementA = self:Compute(node.child[1], state, atTime)
        CopyTimeSpan(timeSpan, timeSpanA)
        result = elementA
    else
        _wipe(timeSpan)
    end
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, result
end
function OvaleBestAction:ComputeFunction(element, state, atTime)
    self:StartProfiling("OvaleBestAction_ComputeFunction")
    local timeSpan = GetTimeSpan(element)
    local result
    local start, ending, value, origin, rate = OvaleCondition:EvaluateCondition(element.func, element.positionalParams, element.namedParams, state, atTime)
    if start and ending then
        CopyTimeSpan(timeSpan, start, ending)
    else
        _wipe(timeSpan)
    end
    if value then
        result = SetValue(element, value, origin, rate)
    end
    state:Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)
    self:StopProfiling("OvaleBestAction_ComputeFunction")
    return timeSpan, result
end
function OvaleBestAction:ComputeGroup(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local bestTimeSpan, bestElement, bestCastTime
    local best = __OvaleTimeSpan.OvaleTimeSpan:New()
    local current = __OvaleTimeSpan.OvaleTimeSpan:New()
    for _, node in _ipairs(element.child) do
        local currentTimeSpan, currentElement = self:Compute(node, state, atTime)
        IntersectInterval(currentTimeSpan, atTime, INFINITY, current)
        if Measure(current) > 0 then
            local nodeString = (currentElement and currentElement.nodeId) and " [" + currentElement.nodeId + "]" or ""
            state:Log("[%d]    group checking [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
            local currentCastTime
            if currentElement then
                currentCastTime = currentElement.castTime
            end
            local gcd = state:GetGCD()
            if  not currentCastTime or currentCastTime < gcd then
                currentCastTime = gcd
            end
            local currentIsBetter = false
            if Measure(best) == 0 then
                state:Log("[%d]    group first best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                currentIsBetter = true
            else
                local threshold = (bestElement and bestElement.namedParams) and bestElement.namedParams.wait or 0
                if best[1] - current[1] > threshold then
                    state:Log("[%d]    group new best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                    currentIsBetter = true
                end
            end
            if currentIsBetter then
                CopyTimeSpan(best, current)
                bestTimeSpan = currentTimeSpan
                bestElement = currentElement
                bestCastTime = currentCastTime
            end
        end
    end
    __OvaleTimeSpan.OvaleTimeSpan:Release(best, current)
    local timeSpan = GetTimeSpan(element, bestTimeSpan)
    if  not bestTimeSpan then
        _wipe(timeSpan)
    end
    if bestElement then
        local id = bestElement.value
        if bestElement.positionalParams then
            id = bestElement.positionalParams[1]
        end
        state:Log("[%d]    group best action %s remains %s", element.nodeId, id, timeSpan)
    else
        state:Log("[%d]    group no best action returns %s", element.nodeId, timeSpan)
    end
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, bestElement
end
function OvaleBestAction:ComputeIf(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan = GetTimeSpan(element)
    local result
    local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
    local conditionTimeSpan = timeSpanA
    if element.type == "unless" then
        conditionTimeSpan = Complement(timeSpanA)
    end
    if Measure(conditionTimeSpan) == 0 then
        CopyTimeSpan(timeSpan, conditionTimeSpan)
        state:Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan)
    else
        local timeSpanB, elementB = self:Compute(element.child[2], state, atTime)
        Intersect(conditionTimeSpan, timeSpanB, timeSpan)
        state:Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, timeSpanB)
        result = elementB
    end
    if element.type == "unless" then
        ReleaseTimeSpan(conditionTimeSpan)
    end
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, result
end
function OvaleBestAction:ComputeLogical(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local timeSpan = GetTimeSpan(element)
    local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
    if element.operator == "and" then
        if Measure(timeSpanA) == 0 then
            CopyTimeSpan(timeSpan, timeSpanA)
            state:Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator)
        else
            local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
            Intersect(timeSpanA, timeSpanB, timeSpan)
        end
    elseif element.operator == "not" then
        Complement(timeSpanA, timeSpan)
    elseif element.operator == "or" then
        if IsUniverse(timeSpanA) then
            CopyTimeSpan(timeSpan, timeSpanA)
            state:Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator)
        else
            local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
            Union(timeSpanA, timeSpanB, timeSpan)
        end
    elseif element.operator == "xor" then
        local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
        local left = Union(timeSpanA, timeSpanB)
        local scratch = Intersect(timeSpanA, timeSpanB)
        local right = Complement(scratch)
        Intersect(left, right, timeSpan)
        __OvaleTimeSpan.OvaleTimeSpan:Release(left, scratch, right)
    else
        _wipe(timeSpan)
    end
    state:Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, timeSpan)
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan
end
function OvaleBestAction:ComputeLua(element, state, atTime)
    self:StartProfiling("OvaleBestAction_ComputeLua")
    local value = _loadstring(element.lua)()
    state:Log("[%d]    lua returns %s", element.nodeId, value)
    local result
    if value then
        result = SetValue(element, value)
    end
    local timeSpan = GetTimeSpan(element, UNIVERSE)
    self:StopProfiling("OvaleBestAction_ComputeLua")
    return timeSpan, result
end
function OvaleBestAction:ComputeState(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    local result = element
    _assert(element.func == "setstate")
    state:Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2])
    local timeSpan = GetTimeSpan(element, UNIVERSE)
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, result
end
function OvaleBestAction:ComputeValue(element, state, atTime)
    self:StartProfiling("OvaleBestAction_Compute")
    state:Log("[%d]    value is %s", element.nodeId, element.value)
    local timeSpan = GetTimeSpan(element, UNIVERSE)
    self:StopProfiling("OvaleBestAction_Compute")
    return timeSpan, element
end
OvaleBestAction.Compute = OvaleBestAction.PostOrderCompute
end))
