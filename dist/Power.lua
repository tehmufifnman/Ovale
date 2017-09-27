local OVALE, Ovale = ...
require(OVALE, Ovale, "Power", { "./L", "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __L, __OvaleDebug, __OvaleProfiler)
local OvalePower = Ovale:NewModule("OvalePower", "AceEvent-3.0")
Ovale.OvalePower = OvalePower
local OvaleAura = nil
local OvaleFuture = nil
local OvaleData = nil
local OvaleState = nil
local ceil = math.ceil
local format = string.format
local gsub = string.gsub
local _pairs = pairs
local strmatch = string.match
local tconcat = table.concat
local _tonumber = tonumber
local _tostring = tostring
local _wipe = wipe
local API_CreateFrame = CreateFrame
local API_GetPowerRegen = GetPowerRegen
local API_GetSpellPowerCost = GetSpellPowerCost
local API_GetTime = GetTime
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitPowerType = UnitPowerType
local INFINITY = math.huge
__OvaleDebug.OvaleDebug:RegisterDebugging(OvalePower)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvalePower)
local self_playerGUID = nil
local self_updateSpellcastInfo = {}
local self_SpellcastInfoPowerTypes = {
    1 = "chi",
    2 = "holy"
}
local self_button = nil
do
    local debugOptions = {
        power = {
            name = __L.L["Power"],
            type = "group",
            args = {
                power = {
                    name = __L.L["Power"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return OvaleState.state:DebugPower()
                    end
                }
            }
        }
    }
    for k, v in _pairs(debugOptions) do
        __OvaleDebug.OvaleDebug.options.args[k] = v
    end
end
OvalePower.powerType = nil
OvalePower.power = {}
OvalePower.maxPower = {}
OvalePower.activeRegen = 0
OvalePower.inactiveRegen = 0
OvalePower.POWER_INFO = {
    alternate = {
        id = SPELL_POWER_ALTERNATE_POWER,
        token = "ALTERNATE_RESOURCE_TEXT",
        mini = 0
    },
    chi = {
        id = SPELL_POWER_CHI,
        token = "CHI",
        mini = 0,
        costString = CHI_COST
    },
    combopoints = {
        id = SPELL_POWER_COMBO_POINTS,
        token = "COMBO_POINTS",
        mini = 0,
        costString = COMBO_POINTS_COST
    },
    energy = {
        id = SPELL_POWER_ENERGY,
        token = "ENERGY",
        mini = 0,
        costString = ENERGY_COST
    },
    focus = {
        id = SPELL_POWER_FOCUS,
        token = "FOCUS",
        mini = 0,
        costString = FOCUS_COST
    },
    holy = {
        id = SPELL_POWER_HOLY_POWER,
        token = "HOLY_POWER",
        mini = 0,
        costString = HOLY_POWER_COST
    },
    mana = {
        id = SPELL_POWER_MANA,
        token = "MANA",
        mini = 0,
        costString = MANA_COST
    },
    rage = {
        id = SPELL_POWER_RAGE,
        token = "RAGE",
        mini = 0,
        costString = RAGE_COST
    },
    runicpower = {
        id = SPELL_POWER_RUNIC_POWER,
        token = "RUNIC_POWER",
        mini = 0,
        costString = RUNIC_POWER_COST
    },
    soulshards = {
        id = SPELL_POWER_SOUL_SHARDS,
        token = "SOUL_SHARDS",
        mini = 0,
        costString = SOUL_SHARDS_COST
    },
    astralpower = {
        id = SPELL_POWER_LUNAR_POWER,
        token = "LUNAR_POWER",
        mini = 0,
        costString = LUNAR_POWER_COST
    },
    insanity = {
        id = SPELL_POWER_INSANITY,
        token = "INSANITY",
        mini = 0,
        costString = INSANITY_COST
    },
    maelstrom = {
        id = SPELL_POWER_MAELSTROM,
        token = "MAELSTROM",
        mini = 0,
        costString = MAELSTROM_COST
    },
    arcanecharges = {
        id = SPELL_POWER_ARCANE_CHARGES,
        token = "ARCANE_CHARGES",
        mini = 0,
        costString = ARCANE_CHARGES_COST
    },
    pain = {
        id = SPELL_POWER_PAIN,
        token = "PAIN",
        mini = 0,
        costString = PAIN_COST
    },
    fury = {
        id = SPELL_POWER_FURY,
        token = "FURY",
        mini = 0,
        costString = FURY_COST
    }
}
OvalePower.PRIMARY_POWER = {
    energy = true,
    focus = true,
    mana = true
}
OvalePower.POWER_TYPE = {}
do
    for powerType, v in _pairs(OvalePower.POWER_INFO) do
        if  not v.id then
            OvalePower:Print("Unknown resource %s", v.token)
        end
        OvalePower.POWER_TYPE[v.id] = powerType
        OvalePower.POWER_TYPE[v.token] = powerType
    end
end
OvalePower.POOLED_RESOURCE = {
    ["DRUID"] = "energy",
    ["HUNTER"] = "focus",
    ["MONK"] = "energy",
    ["ROGUE"] = "energy"
}
local OvalePower = __class()
function OvalePower:OnInitialize()
    OvaleAura = Ovale.OvaleAura
    OvaleData = Ovale.OvaleData
    OvaleFuture = Ovale.OvaleFuture
    OvaleState = Ovale.OvaleState
end
function OvalePower:OnEnable()
    self_playerGUID = Ovale.playerGUID
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
    self:RegisterEvent("PLAYER_LEVEL_UP", "EventHandler")
    self:RegisterEvent("UNIT_DISPLAYPOWER")
    self:RegisterEvent("UNIT_LEVEL")
    self:RegisterEvent("UNIT_MAXPOWER")
    self:RegisterEvent("UNIT_POWER")
    self:RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER")
    self:RegisterEvent("UNIT_RANGEDDAMAGE")
    self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
    self:RegisterMessage("Ovale_StanceChanged", "EventHandler")
    self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
    for powerType in _pairs(self.POWER_INFO) do
        OvaleData:RegisterRequirement(powerType, "RequirePowerHandler", self)
    end
    OvaleFuture:RegisterSpellcastInfo(self)
    OvaleState:RegisterState(self, self.statePrototype)
end
function OvalePower:OnDisable()
    OvaleState:UnregisterState(self)
    OvaleFuture:UnregisterSpellcastInfo(self)
    for powerType in _pairs(self.POWER_INFO) do
        OvaleData:UnregisterRequirement(powerType)
    end
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_LEVEL_UP")
    self:UnregisterEvent("UNIT_DISPLAYPOWER")
    self:UnregisterEvent("UNIT_LEVEL")
    self:UnregisterEvent("UNIT_MAXPOWER")
    self:UnregisterEvent("UNIT_POWER")
    self:UnregisterEvent("UNIT_POWER_FREQUENT")
    self:UnregisterEvent("UNIT_RANGEDDAMAGE")
    self:UnregisterEvent("UNIT_SPELL_HASTE")
    self:UnregisterMessage("Ovale_StanceChanged")
    self:UnregisterMessage("Ovale_TalentsChanged")
end
function OvalePower:EventHandler(event)
    self:UpdatePowerType(event)
    self:UpdateMaxPower(event)
    self:UpdatePower(event)
    self:UpdatePowerRegen(event)
end
function OvalePower:UNIT_DISPLAYPOWER(event, unitId)
    if unitId == "player" then
        self:UpdatePowerType(event)
        self:UpdatePowerRegen(event)
    end
end
function OvalePower:UNIT_LEVEL(event, unitId)
    if unitId == "player" then
        self:EventHandler(event)
    end
end
function OvalePower:UNIT_MAXPOWER(event, unitId, powerToken)
    if unitId == "player" then
        local powerType = self.POWER_TYPE[powerToken]
        if powerType then
            self:UpdateMaxPower(event, powerType)
        end
    end
end
function OvalePower:UNIT_POWER(event, unitId, powerToken)
    if unitId == "player" then
        local powerType = self.POWER_TYPE[powerToken]
        if powerType then
            self:UpdatePower(event, powerType)
        end
    end
end
function OvalePower:UNIT_RANGEDDAMAGE(event, unitId)
    if unitId == "player" then
        self:UpdatePowerRegen(event)
    end
end
function OvalePower:UpdateMaxPower(event, powerType)
    self:StartProfiling("OvalePower_UpdateMaxPower")
    if powerType then
        local powerInfo = self.POWER_INFO[powerType]
        local maxPower = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
        if self.maxPower[powerType] ~= maxPower then
            self.maxPower[powerType] = maxPower
            Ovale.refreshNeeded[self_playerGUID] = true
        end
    else
        for powerType, powerInfo in _pairs(self.POWER_INFO) do
            local maxPower = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
            if self.maxPower[powerType] ~= maxPower then
                self.maxPower[powerType] = maxPower
                Ovale.refreshNeeded[self_playerGUID] = true
            end
        end
    end
    self:StopProfiling("OvalePower_UpdateMaxPower")
end
function OvalePower:UpdatePower(event, powerType)
    self:StartProfiling("OvalePower_UpdatePower")
    if powerType then
        local powerInfo = self.POWER_INFO[powerType]
        local power = API_UnitPower("player", powerInfo.id, powerInfo.segments)
        if self.power[powerType] ~= power then
            self.power[powerType] = power
            Ovale.refreshNeeded[self_playerGUID] = true
        end
        self:DebugTimestamp("%s: %d -> %d (%s).", event, self.power[powerType], power, powerType)
    else
        for powerType, powerInfo in _pairs(self.POWER_INFO) do
            local power = API_UnitPower("player", powerInfo.id, powerInfo.segments)
            if self.power[powerType] ~= power then
                self.power[powerType] = power
                Ovale.refreshNeeded[self_playerGUID] = true
            end
            self:DebugTimestamp("%s: %d -> %d (%s).", event, self.power[powerType], power, powerType)
        end
    end
    Ovale.refreshNeeded[self_playerGUID] = true
    self:StopProfiling("OvalePower_UpdatePower")
end
function OvalePower:UpdatePowerRegen(event)
    self:StartProfiling("OvalePower_UpdatePowerRegen")
    local inactiveRegen, activeRegen = API_GetPowerRegen()
    if self.inactiveRegen ~= inactiveRegen or self.activeRegen ~= activeRegen then
        self.inactiveRegen, self.activeRegen = inactiveRegen, activeRegen
        Ovale.refreshNeeded[self_playerGUID] = true
    end
    self:StopProfiling("OvalePower_UpdatePowerRegen")
end
function OvalePower:UpdatePowerType(event)
    self:StartProfiling("OvalePower_UpdatePowerType")
    local currentType, currentToken = API_UnitPowerType("player")
    local powerType = self.POWER_TYPE[currentType]
    if self.powerType ~= powerType then
        self.powerType = powerType
        Ovale.refreshNeeded[self_playerGUID] = true
    end
    Ovale.refreshNeeded[self_playerGUID] = true
    self:StopProfiling("OvalePower_UpdatePowerType")
end
function OvalePower:GetSpellCost(spellId, powerType)
    self:StartProfiling("OvalePower_GetSpellCost")
    local spellPowerCost = API_GetSpellPowerCost(spellId)[1]
    if spellPowerCost then
        local cost = spellPowerCost.cost
        local typeId = spellPowerCost.type
        for pt, p in _pairs(self.POWER_INFO) do
            if p.id == typeId and (powerType == nil or pt == powerType) then
                return cost, pt
            end
        end
    end
    return nil
end
function OvalePower:GetPower(powerType, atTime)
    local power = (self.power and self.power[powerType]) or self[powerType] or 0
    local powerRate = 0
    if self.powerType and self.powerType == powerType and self.activeRegen then
        powerRate = self.activeRegen
    elseif self.powerRate and self.powerRate[powerType] then
        powerRate = self.powerRate[powerType]
    end
    if atTime then
        local now = self.currentTime or API_GetTime()
        local seconds = atTime - now
        if seconds > 0 then
            power = power + powerRate * seconds
        end
    end
    return power
end
function OvalePower:PowerCost(spellId, powerType, atTime, targetGUID, maximumCost)
    OvalePower:StartProfiling("OvalePower_PowerCost")
    local buffParam = "buff_" + powerType
    local spellCost = 0
    local spellRefund = 0
    local si = OvaleData.spellInfo[spellId]
    if si and si[powerType] then
        local GetAura, GetAuraByGUID, IsActiveAura
        local GetSpellInfoProperty
        local auraModule, dataModule
        GetAura, auraModule = self:GetMethod("GetAura", OvaleAura)
        GetAuraByGUID, auraModule = self:GetMethod("GetAuraByGUID", OvaleAura)
        IsActiveAura, auraModule = self:GetMethod("IsActiveAura", OvaleAura)
        GetSpellInfoProperty, dataModule = self:GetMethod("GetSpellInfoProperty", OvaleData)
        local cost = GetSpellInfoProperty(dataModule, spellId, atTime, powerType, targetGUID)
        if cost == "finisher" then
            cost = self:GetPower(powerType, atTime)
            local minCostParam = "min_" + powerType
            local maxCostParam = "max_" + powerType
            local minCost = si[minCostParam] or 1
            local maxCost = si[maxCostParam]
            if cost < minCost then
                cost = minCost
            end
            if maxCost and cost > maxCost then
                cost = maxCost
            end
        elseif cost == "refill" then
            cost = self:GetPower(powerType, atTime) - OvalePower.maxPower[powerType]
        else
            local buffExtraParam = buffParam
            local buffAmountParam = buffParam + "_amount"
            local buffExtra = si[buffExtraParam]
            if buffExtra then
                local aura = GetAura(auraModule, "player", buffExtra, nil, true)
                local isActiveAura = IsActiveAura(auraModule, aura, atTime)
                if isActiveAura then
                    local buffAmount = 0
                    if type(buffAmountParam) == "number" then
                        buffAmount = si[buffAmountParam] or -1
                    elseif si[buffAmountParam] == "value3" then
                        buffAmount = aura.value3 or -1
                    elseif si[buffAmountParam] == "value2" then
                        buffAmount = aura.value2 or -1
                    elseif si[buffAmountParam] == "value1" then
                        buffAmount = aura.value1 or -1
                    else
                        buffAmount = -1
                    end
                    local siAura = OvaleData.spellInfo[buffExtra]
                    if siAura and siAura.stacking == 1 then
                        buffAmount = buffAmount * aura.stacks
                    end
                    cost = cost + buffAmount
                    self:Log("Spell ID '%d' had %f %s added from aura ID '%d'.", spellId, buffAmount, powerType, aura.spellId)
                end
            end
        end
        local extraPowerParam = "extra_" + powerType
        local extraPower = GetSpellInfoProperty(dataModule, spellId, atTime, extraPowerParam, targetGUID)
        if extraPower then
            if  not maximumCost then
                local power = floor(self:GetPower(powerType, atTime))
                power = power > cost and power - cost or 0
                if extraPower >= power then
                    extraPower = power
                end
            end
            cost = cost + extraPower
        end
        spellCost = ceil(cost)
        local refundParam = "refund_" + powerType
        local refund = GetSpellInfoProperty(dataModule, spellId, atTime, refundParam, targetGUID)
        if refund == "cost" then
            refund = spellCost
        end
        refund = refund or 0
        spellRefund = ceil(refund)
    else
        local cost = OvalePower:GetSpellCost(spellId, powerType)
        if cost then
            spellCost = cost
        end
    end
    OvalePower:StopProfiling("OvalePower_PowerCost")
    return spellCost, spellRefund
end
function OvalePower:RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    local verified = false
    local cost = tokens
    if index then
        cost = tokens[index]
        index = index + 1
    end
    if cost then
        local powerType = requirement
        cost = self:PowerCost(spellId, powerType, atTime, targetGUID)
        if cost > 0 then
            local power = self:GetPower(powerType, atTime)
            if power >= cost then
                verified = true
            end
            self:Log("   Has power %f %s", power, powerType)
        else
            verified = true
        end
        if cost > 0 then
            local result = verified and "passed" or "FAILED"
            self:Log("    Require %f %s at time=%f: %s", cost, powerType, atTime, result)
        end
    else
        Ovale:OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement)
    end
    return verified, requirement, index
end
function OvalePower:DebugPower()
    self:Print("Power type: %s", self.powerType)
    for powerType, v in _pairs(self.power) do
        self:Print("Power (%s): %d / %d", powerType, v, self.maxPower[powerType])
    end
    self:Print("Active regen: %f", self.activeRegen)
    self:Print("Inactive regen: %f", self.inactiveRegen)
end
function OvalePower:CopySpellcastInfo(spellcast, dest)
    for _, powerType in _pairs(self_SpellcastInfoPowerTypes) do
        if spellcast[powerType] then
            dest[powerType] = spellcast[powerType]
        end
    end
end
function OvalePower:SaveSpellcastInfo(spellcast, atTime, state)
    local spellId = spellcast.spellId
    if spellId then
        local si = OvaleData.spellInfo[spellId]
        if si then
            local dataModule = state or OvaleData
            local powerModule = state or self
            for _, powerType in _pairs(self_SpellcastInfoPowerTypes) do
                if si[powerType] == "finisher" then
                    local maxCostParam = "max_" + powerType
                    local maxCost = si[maxCostParam] or 1
                    local cost = dataModule:GetSpellInfoProperty(spellId, atTime, powerType, spellcast.target)
                    if cost == "finisher" then
                        local power = powerModule:GetPower(powerType, atTime)
                        if power > maxCost then
                            cost = maxCost
                        else
                            cost = power
                        end
                    elseif cost == 0 then
                        cost = maxCost
                    end
                    spellcast[powerType] = cost
                end
            end
        end
    end
end
OvalePower.statePrototype = {}
local statePrototype = OvalePower.statePrototype
statePrototype.powerRate = nil
local OvalePower = __class()
function OvalePower:InitializeState(state)
    for powerType in _pairs(self.POWER_INFO) do
        state[powerType] = 0
    end
    state.powerRate = {}
end
function OvalePower:ResetState(state)
    self:StartProfiling("OvalePower_ResetState")
    for powerType in _pairs(self.POWER_INFO) do
        state[powerType] = self.power[powerType] or 0
    end
    for powerType in _pairs(self.POWER_INFO) do
        state.powerRate[powerType] = 0
    end
    if OvaleFuture.inCombat then
        state.powerRate[self.powerType] = self.activeRegen
    else
        state.powerRate[self.powerType] = self.inactiveRegen
    end
    self:StopProfiling("OvalePower_ResetState")
end
function OvalePower:CleanState(state)
    for powerType in _pairs(self.POWER_INFO) do
        state[powerType] = nil
    end
    for k in _pairs(state.powerRate) do
        state.powerRate[k] = nil
    end
end
function OvalePower:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvalePower_ApplySpellStartCast")
    if isChanneled then
        if state.inCombat then
            state.powerRate[self.powerType] = self.activeRegen
        end
        state:ApplyPowerCost(spellId, targetGUID, startCast, spellcast)
    end
    self:StopProfiling("OvalePower_ApplySpellStartCast")
end
function OvalePower:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvalePower_ApplySpellAfterCast")
    if  not isChanneled then
        if state.inCombat then
            state.powerRate[self.powerType] = self.activeRegen
        end
        state:ApplyPowerCost(spellId, targetGUID, endCast, spellcast)
    end
    self:StopProfiling("OvalePower_ApplySpellAfterCast")
end
statePrototype.ApplyPowerCost = function(state, spellId, targetGUID, atTime, spellcast)
    OvalePower:StartProfiling("OvalePower_state_ApplyPowerCost")
    local si = OvaleData.spellInfo[spellId]
    do
        local cost, powerType = OvalePower:GetSpellCost(spellId)
        if cost and powerType and state[powerType] and  not (si and si[powerType]) then
            state[powerType] = state[powerType] - cost
        end
    end
    if si then
        for powerType, powerInfo in _pairs(OvalePower.POWER_INFO) do
            local cost, refund = state:PowerCost(spellId, powerType, atTime, targetGUID)
            local power = state[powerType] or 0
            if cost then
                power = power - cost + refund
                local seconds = state.nextCast - atTime
                if seconds > 0 then
                    local powerRate = state.powerRate[powerType] or 0
                    power = power + powerRate * seconds
                end
                local mini = powerInfo.mini or 0
                local maxi = powerInfo.maxi or OvalePower.maxPower[powerType]
                if mini and power < mini then
                    power = mini
                end
                if maxi and power > maxi then
                    power = maxi
                end
                state[powerType] = power
            end
        end
    end
    OvalePower:StopProfiling("OvalePower_state_ApplyPowerCost")
end
statePrototype.TimeToPower = function(state, spellId, atTime, targetGUID, powerType, extraPower)
    local seconds = 0
    powerType = powerType or OvalePower.POOLED_RESOURCE[state.class]
    if powerType then
        local cost = state:PowerCost(spellId, powerType, atTime, targetGUID)
        local power = state:GetPower(powerType, atTime)
        local powerRate = state.powerRate[powerType] or 0
        if extraPower then
            cost = cost + extraPower
        end
        if power < cost then
            if powerRate > 0 then
                seconds = (cost - power) / powerRate
            else
                seconds = INFINITY
            end
        end
    end
    return seconds
end
statePrototype.GetPower = OvalePower.GetPower
statePrototype.PowerCost = OvalePower.PowerCost
statePrototype.RequirePowerHandler = OvalePower.RequirePowerHandler
do
    local output = {}
    statePrototype.DebugPower = function(state)
        _wipe(output)
        for powerType in _pairs(OvalePower.POWER_INFO) do
            output[#output + 1] = Ovale:MakeString("%s = %d", powerType, state[powerType])
        end
        return tconcat(output, "\n")
    end
end
end))
