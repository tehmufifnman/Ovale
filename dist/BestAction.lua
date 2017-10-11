local __addonName, __addon = ...
            __addon.require("./BestAction", { "./Debug", "./Pool", "./Profiler", "./TimeSpan", "./ActionBar", "./Compile", "./Condition", "./Data", "./Equipment", "./GUID", "./SpellBook", "./Ovale", "./State", "./PaperDoll", "./DataState", "./SpellBookState", "./FutureState", "./CooldownState" }, function(__exports, __Debug, __Pool, __Profiler, __TimeSpan, __ActionBar, __Compile, __Condition, __Data, __Equipment, __GUID, __SpellBook, __Ovale, __State, __PaperDoll, __DataState, __SpellBookState, __FutureState, __CooldownState)
local OvaleBestActionBase = __Ovale.Ovale:NewModule("OvaleBestAction", "AceEvent-3.0")
local abs = math.abs
local _assert = assert
local floor = math.floor
local _ipairs = ipairs
local _loadstring = loadstring
local _pairs = pairs
local _tonumber = tonumber
local _type = type
local _wipe = wipe
local INFINITY = math.huge
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
local self_serial = 0
local self_timeSpan = {}
local self_valuePool = __Pool.OvalePool("OvaleBestAction_valuePool")
local self_value = {}
__exports.OvaleBestAction = nil
local function SetValue(node, value, origin, rate)
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
    elseif timeSpan and timeSpan:HasTime(atTime) then
        value, origin, rate, timeSpan = 1, 0, 0, __TimeSpan.UNIVERSE
    else
        value, origin, rate, timeSpan = 0, 0, 0, __TimeSpan.UNIVERSE
    end
    return value, origin, rate, timeSpan
end

local GetTimeSpan = function(node, defaultTimeSpan)
    local timeSpan = self_timeSpan[node]
    if timeSpan then
        if defaultTimeSpan then
            timeSpan:copyFromArray(defaultTimeSpan)
        end
    else
        self_timeSpan[node] = __TimeSpan.newTimeSpanFromArray(defaultTimeSpan)
        timeSpan = self_timeSpan[node]
    end
    return timeSpan
end

local GetActionItemInfo = function(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionItemInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
    local itemId = element.positionalParams[1]
    if _type(itemId) ~= "number" then
        itemId = __Equipment.OvaleEquipment:GetEquippedItem(itemId)
    end
    if  not itemId then
        state:Log("Unknown item '%s'.", element.positionalParams[1])
    else
        state:Log("Item ID '%s'", itemId)
        local action = __ActionBar.OvaleActionBar:GetForItem(itemId)
        local spellName = API_GetItemSpell(itemId)
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or API_GetItemIcon(itemId)
        actionInRange = API_IsItemInRange(itemId, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = API_GetItemCooldown(itemId)
        actionUsable = spellName and API_IsUsableItem(itemId) and __SpellBookState.spellBookState:IsUsableItem(itemId)
        if action then
            actionShortcut = __ActionBar.OvaleActionBar:GetBinding(action)
            actionIsCurrent = API_IsCurrentAction(action)
        end
        actionType = "item"
        actionId = itemId
    end
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionItemInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local GetActionMacroInfo = function(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionMacroInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
    local macro = element.positionalParams[1]
    local action = __ActionBar.OvaleActionBar:GetForMacro(macro)
    if  not action then
        state:Log("Unknown macro '%s'.", macro)
    else
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or API_GetActionTexture(action)
        actionInRange = API_IsActionInRange(action, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = API_GetActionCooldown(action)
        actionUsable = API_IsUsableAction(action)
        actionShortcut = __ActionBar.OvaleActionBar:GetBinding(action)
        actionIsCurrent = API_IsCurrentAction(action)
        actionType = "macro"
        actionId = macro
    end
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionMacroInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local GetActionSpellInfo = function(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionSpellInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionResourceExtend, actionCharges
    local targetGUID = __GUID.OvaleGUID:UnitGUID(target)
    local spellId = element.positionalParams[1]
    local si = __Data.OvaleData.spellInfo[spellId]
    local replacedSpellId = nil
    if si and si.replace then
        local replacement = __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "replace", targetGUID)
        if replacement then
            replacedSpellId = spellId
            spellId = replacement
            si = __Data.OvaleData.spellInfo[spellId]
            state:Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId)
        end
    end
    local action = __ActionBar.OvaleActionBar:GetForSpell(spellId)
    if  not action and replacedSpellId then
        state:Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
        action = __ActionBar.OvaleActionBar:GetForSpell(replacedSpellId)
    end
    local isKnownSpell = __SpellBook.OvaleSpellBook:IsKnownSpell(spellId)
    if  not isKnownSpell and replacedSpellId then
        state:Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
        isKnownSpell = __SpellBook.OvaleSpellBook:IsKnownSpell(replacedSpellId)
    end
    if  not isKnownSpell and  not action then
        state:Log("Unknown spell ID '%s'.", spellId)
    else
        local isUsable, noMana = __SpellBookState.spellBookState:IsUsableSpell(spellId, atTime, targetGUID)
        if isUsable or noMana then
            if element.namedParams.texture then
                actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
            end
            actionTexture = actionTexture or API_GetSpellTexture(spellId)
            actionInRange = __SpellBook.OvaleSpellBook:IsSpellInRange(spellId, target)
            actionCooldownStart, actionCooldownDuration, actionEnable = __CooldownState.cooldownState:GetSpellCooldown(spellId)
            actionCharges = __CooldownState.cooldownState:GetSpellCharges(spellId)
            actionResourceExtend = 0
            actionUsable = isUsable
            if action then
                actionShortcut = __ActionBar.OvaleActionBar:GetBinding(action)
                actionIsCurrent = API_IsCurrentAction(action)
            end
            actionType = "spell"
            actionId = spellId
            if si then
                if si.texture then
                    actionTexture = "Interface\\Icons\\" .. si.texture
                end
                if actionCooldownStart and actionCooldownDuration then
                    local extraPower = element.namedParams.extra_amount or 0
                    local seconds = __SpellBookState.spellBookState:GetTimeToSpell(spellId, atTime, targetGUID, extraPower)
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
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionSpellInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, actionResourceExtend, actionCharges
end

local GetActionTextureInfo = function(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionTextureInfo")
    local actionTexture
    do
        local texture = element.positionalParams[1]
        local spellId = _tonumber(texture)
        if spellId then
            actionTexture = API_GetSpellTexture(spellId)
        else
            actionTexture = "Interface\\Icons\\" .. texture
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
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionTextureInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local OvaleBestActionClass = __addon.__class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleBestActionBase)), {
    constructor = function(self)
        self.ComputeAction = function(element, state, atTime)
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
                    spellInfo = spellId and __Data.OvaleData.spellInfo[spellId]
                    if spellInfo and spellInfo.casttime then
                        element.castTime = spellInfo.casttime
                    else
                        element.castTime = __SpellBook.OvaleSpellBook:GetCastTime(spellId)
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
                    if __FutureState.futureState:IsChanneling(atTime) then
                        local spellId = __FutureState.futureState.currentSpellId
                        local si = spellId and __Data.OvaleData.spellInfo[spellId]
                        if si then
                            local channel = si.channel or si.canStopChannelling
                            if channel then
                                local hasteMultiplier = __PaperDoll.paperDollState:GetHasteMultiplier(si.haste)
                                local numTicks = floor(channel * hasteMultiplier + 0.5)
                                local tick = (__FutureState.futureState.endCast - __FutureState.futureState.startCast) / numTicks
                                local tickTime = __FutureState.futureState.startCast
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
                timeSpan:Copy(start, INFINITY)
                result = element
            end
            self:StopProfiling("OvaleBestAction_ComputeAction")
            return timeSpan, result
        end
        self.ComputeArithmetic = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local result
            local rawTimeSpanA = self:Compute(element.child[1], state, atTime)
            local a, b, c, timeSpanA = AsValue(atTime, rawTimeSpanA)
            local rawTimeSpanB = self:Compute(element.child[2], state, atTime)
            local x, y, z, timeSpanB = AsValue(atTime, rawTimeSpanB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
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
                    local scratch = timeSpan:IntersectInterval(t - bound, t + bound)
                    timeSpan:copyFromArray(scratch)
                    scratch:Release()
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
        self.ComputeCompare = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local rawTimeSpanA = self:Compute(element.child[1], state, atTime)
            local a, b, c, timeSpanA = AsValue(atTime, rawTimeSpanA)
            local rawTimeSpanB = self:Compute(element.child[2], state, atTime)
            local x, y, z, timeSpanB = AsValue(atTime, rawTimeSpanB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
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
                        scratch = timeSpan:IntersectInterval(0, t)
                    elseif (c < z and operator == "<") or (c < z and operator == "<=") or (c > z and operator == ">") or (c > z and operator == ">=") then
                        scratch = timeSpan:IntersectInterval(t, INFINITY)
                    end
                    if scratch then
                        timeSpan:copyFromArray(scratch)
                        scratch:Release()
                    else
                        _wipe(timeSpan)
                    end
                end
                state:Log("[%d]    compare '%s' returns %s", element.nodeId, operator, timeSpan)
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, element
        end
        self.ComputeCustomFunction = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local result
            local node = __Compile.OvaleCompile:GetFunctionNode(element.name)
            if node then
                local timeSpanA, elementA = self:Compute(node.child[1], state, atTime)
                timeSpan:copyFromArray(timeSpanA)
                result = elementA
            else
                _wipe(timeSpan)
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeFunction = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_ComputeFunction")
            local timeSpan = GetTimeSpan(element)
            local result
            local start, ending, value, origin, rate = __Condition.OvaleCondition:EvaluateCondition(element.func, element.positionalParams, element.namedParams, state, atTime)
            if start and ending then
                timeSpan:Copy(start, ending)
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
        self.ComputeGroup = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local bestTimeSpan, bestElement, bestCastTime
            local best = __TimeSpan.newTimeSpan()
            local current = __TimeSpan.newTimeSpan()
            for _, node in _ipairs(element.child) do
                local currentTimeSpan, currentElement = self:Compute(node, state, atTime)
                currentTimeSpan:IntersectInterval(atTime, INFINITY, current)
                if current:Measure() > 0 then
                    local nodeString = (currentElement and currentElement.nodeId) and " [" .. currentElement.nodeId .. "]" or ""
                    state:Log("[%d]    group checking [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                    local currentCastTime
                    if currentElement then
                        currentCastTime = currentElement.castTime
                    end
                    local gcd = __FutureState.futureState:GetGCD()
                    if  not currentCastTime or currentCastTime < gcd then
                        currentCastTime = gcd
                    end
                    local currentIsBetter = false
                    if best:Measure() == 0 then
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
                        best:copyFromArray(current)
                        bestTimeSpan = currentTimeSpan
                        bestElement = currentElement
                        bestCastTime = currentCastTime
                    end
                end
            end
            __TimeSpan.releaseTimeSpans(best, current)
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
        self.ComputeIf = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local result
            local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
            local conditionTimeSpan = timeSpanA
            if element.type == "unless" then
                conditionTimeSpan = timeSpanA:Complement()
            end
            if conditionTimeSpan:Measure() == 0 then
                timeSpan:copyFromArray(conditionTimeSpan)
                state:Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan)
            else
                local timeSpanB, elementB = self:Compute(element.child[2], state, atTime)
                conditionTimeSpan:Intersect(timeSpanB, timeSpan)
                state:Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, timeSpanB)
                result = elementB
            end
            if element.type == "unless" then
                conditionTimeSpan:Release()
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeLogical = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
            if element.operator == "and" then
                if timeSpanA:Measure() == 0 then
                    timeSpan:copyFromArray(timeSpanA)
                    state:Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator)
                else
                    local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
                    timeSpanA:Intersect(timeSpanB, timeSpan)
                end
            elseif element.operator == "not" then
                timeSpanA:Complement(timeSpan)
            elseif element.operator == "or" then
                if timeSpanA:IsUniverse() then
                    timeSpan:copyFromArray(timeSpanA)
                    state:Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator)
                else
                    local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
                    timeSpanA:Union(timeSpanB, timeSpan)
                end
            elseif element.operator == "xor" then
                local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
                local left = timeSpanA:Union(timeSpanB)
                local scratch = timeSpanA:Intersect(timeSpanB)
                local right = scratch:Complement()
                left:Intersect(right, timeSpan)
                __TimeSpan.releaseTimeSpans(left, scratch, right)
            else
                _wipe(timeSpan)
            end
            state:Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, timeSpan)
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, element
        end
        self.ComputeLua = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_ComputeLua")
            local value = _loadstring(element.lua)()
            state:Log("[%d]    lua returns %s", element.nodeId, value)
            local result
            if value then
                result = SetValue(element, value)
            end
            local timeSpan = GetTimeSpan(element, __TimeSpan.UNIVERSE)
            self:StopProfiling("OvaleBestAction_ComputeLua")
            return timeSpan, result
        end
        self.ComputeState = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local result = element
            _assert(element.func == "setstate")
            state:Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2])
            local timeSpan = GetTimeSpan(element, __TimeSpan.UNIVERSE)
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeValue = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            state:Log("[%d]    value is %s", element.nodeId, element.value)
            local timeSpan = GetTimeSpan(element, __TimeSpan.UNIVERSE)
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, element
        end
        self.COMPUTE_VISITOR = {
            ["action"] = self.ComputeAction,
            ["arithmetic"] = self.ComputeArithmetic,
            ["compare"] = self.ComputeCompare,
            ["custom_function"] = self.ComputeCustomFunction,
            ["function"] = self.ComputeFunction,
            ["group"] = self.ComputeGroup,
            ["if"] = self.ComputeIf,
            ["logical"] = self.ComputeLogical,
            ["lua"] = self.ComputeLua,
            ["state"] = self.ComputeState,
            ["unless"] = self.ComputeIf,
            ["value"] = self.ComputeValue
        }
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleBestActionBase)).constructor(self)
        self:RegisterMessage("Ovale_ScriptChanged")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_ScriptChanged")
    end,
    Ovale_ScriptChanged = function(self)
        for node, timeSpan in _pairs(self_timeSpan) do
            timeSpan:Release()
            self_timeSpan[node] = nil
        end
        for node, value in _pairs(self_value) do
            self_valuePool:Release(value)
            self_value[node] = nil
        end
    end,
    StartNewAction = function(self)
        __State.OvaleState:ResetState()
        __FutureState.futureState:ApplyInFlightSpells()
        self_serial = self_serial + 1
    end,
    GetActionInfo = function(self, element, state, atTime)
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
    end,
    GetAction = function(self, node, state, atTime)
        self:StartProfiling("OvaleBestAction_GetAction")
        local groupNode = node.child[1]
        local timeSpan, element = self:Compute(groupNode, state, atTime)
        if element and element.type == "state" then
            local variable, value = element.positionalParams[1], element.positionalParams[2]
            local isFuture =  not timeSpan:HasTime(atTime)
            state:PutState(variable, value, isFuture)
        end
        self:StopProfiling("OvaleBestAction_GetAction")
        return timeSpan, element
    end,
    PostOrderCompute = function(self, element, state, atTime)
        self:StartProfiling("OvaleBestAction_Compute")
        local timeSpan, result
        local postOrder = element.postOrder
        if postOrder and  not (element.serial and element.serial >= self_serial) then
            local index = 1
            local N = #postOrder
            while index < N do
                local childNode, parentNode = postOrder[index], postOrder[index + 1]
                index = index + 2
                timeSpan, result = self:PostOrderCompute(childNode, state, atTime)
                if parentNode then
                    local shortCircuit = false
                    if parentNode.child and parentNode.child[1] == childNode then
                        if parentNode.type == "if" and timeSpan:Measure() == 0 then
                            state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "unless" and timeSpan:IsUniverse() then
                            state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "and" and timeSpan:Measure() == 0 then
                            state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "or" and timeSpan:IsUniverse() then
                            state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        end
                    end
                    if shortCircuit then
                        while parentNode ~= postOrder[index] and index <= N do
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
    end,
    RecursiveCompute = function(self, element, state, atTime)
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
                local visitor = self.COMPUTE_VISITOR[element.type]
                if visitor then
                    timeSpan, result = visitor(element, state, atTime)
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
    end,
    ComputeBool = function(self, element, state, atTime)
        local timeSpan, newElement = self:Compute(element, state, atTime)
        if newElement and newElement.type == "value" and newElement.value == 0 and newElement.rate == 0 then
            return __TimeSpan.EMPTY_SET
        else
            return timeSpan
        end
    end,
    Compute = function(self, element, state, atTime)
        return self:PostOrderCompute(element, state, atTime)
    end,
})
__exports.OvaleBestAction = OvaleBestActionClass()
end)
