local __addonName, __addon = ...
            __addon.require("./Power", { "./Localization", "./Debug", "./Profiler", "./Ovale", "./Aura", "./Future", "./Data", "./State", "./PaperDoll", "./Requirement", "./FutureState", "./LastSpell", "./DataState" }, function(__exports, __Localization, __Debug, __Profiler, __Ovale, __Aura, __Future, __Data, __State, __PaperDoll, __Requirement, __FutureState, __LastSpell, __DataState)
local OvalePowerBase = __Ovale.Ovale:NewModule("OvalePower", "AceEvent-3.0")
local ceil = math.ceil
local _pairs = pairs
local tconcat = table.concat
local _wipe = wipe
local API_GetPowerRegen = GetPowerRegen
local API_GetSpellPowerCost = GetSpellPowerCost
local API_GetTime = GetTime
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitPowerType = UnitPowerType
local INFINITY = math.huge
local _type = type
local self_SpellcastInfoPowerTypes = {
    [1] = "chi",
    [2] = "holy"
}
do
    local debugOptions = {
        power = {
            name = __Localization.L["Power"],
            type = "group",
            args = {
                power = {
                    name = __Localization.L["Power"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.powerState:DebugPower()
                    end

                }
            }
        }
    }
    for k, v in _pairs(debugOptions) do
        __Debug.OvaleDebug.options.args[k] = v
    end
end
local function isString(s)
    return _type(s) == "string"
end
local OvalePowerClass = __addon.__class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvalePowerBase)), {
    constructor = function(self)
        self.powerType = nil
        self.powerRate = nil
        self.power = {}
        self.maxPower = {}
        self.activeRegen = 0
        self.inactiveRegen = 0
        self.POWER_INFO = {
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
        self.PRIMARY_POWER = {
            energy = true,
            focus = true,
            mana = true
        }
        self.POWER_TYPE = {}
        self.POOLED_RESOURCE = {
            ["DRUID"] = "energy",
            ["HUNTER"] = "focus",
            ["MONK"] = "energy",
            ["ROGUE"] = "energy"
        }
        self.CopySpellcastInfo = function(mod, spellcast, dest)
            for _, powerType in _pairs(self_SpellcastInfoPowerTypes) do
                if spellcast[powerType] then
                    dest[powerType] = spellcast[powerType]
                end
            end
        end
        self.SaveSpellcastInfo = function(mod, spellcast, atTime, state)
            local spellId = spellcast.spellId
            if spellId then
                local si = __Data.OvaleData.spellInfo[spellId]
                if si then
                    local dataModule = state or __DataState.dataState
                    local powerModule
                    if state then
                        powerModule = __exports.powerState
                    else
                        powerModule = self
                    end
                    for _, powerType in _pairs(self_SpellcastInfoPowerTypes) do
                        if si[powerType] == "finisher" then
                            local maxCostParam = "max_" .. powerType
                            local maxCost = si[maxCostParam] or 1
                            local cost = dataModule:GetSpellInfoProperty(spellId, atTime, powerType, spellcast.target)
                            if isString(cost) then
                                if cost == "finisher" then
                                    local power = powerModule:GetPower(powerType, atTime)
                                    if power > maxCost then
                                        spellcast[powerType] = maxCost
                                    else
                                        spellcast[powerType] = power
                                    end
                                end
                            elseif cost == 0 then
                                spellcast[powerType] = maxCost
                            end
                            spellcast[powerType] = cost
                        end
                    end
                end
            end
        end
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvalePowerBase)).constructor(self)
        for powerType, v in _pairs(self.POWER_INFO) do
            if  not v.id then
                self:Print("Unknown resource %s", v.token)
            end
            self.POWER_TYPE[v.id] = powerType
            self.POWER_TYPE[v.token] = powerType
        end
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
            __Requirement.RegisterRequirement(powerType, "RequirePowerHandler", self)
        end
        __LastSpell.lastSpell:RegisterSpellcastInfo(self)
    end,
    OnDisable = function(self)
        __LastSpell.lastSpell:UnregisterSpellcastInfo(self)
        for powerType in _pairs(self.POWER_INFO) do
            __Requirement.UnregisterRequirement(powerType)
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
    end,
    EventHandler = function(self, event)
        self:UpdatePowerType(event)
        self:UpdateMaxPower(event)
        self:UpdatePower(event)
        self:UpdatePowerRegen(event)
    end,
    UNIT_DISPLAYPOWER = function(self, event, unitId)
        if unitId == "player" then
            self:UpdatePowerType(event)
            self:UpdatePowerRegen(event)
        end
    end,
    UNIT_LEVEL = function(self, event, unitId)
        if unitId == "player" then
            self:EventHandler(event)
        end
    end,
    UNIT_MAXPOWER = function(self, event, unitId, powerToken)
        if unitId == "player" then
            local powerType = self.POWER_TYPE[powerToken]
            if powerType then
                self:UpdateMaxPower(event, powerType)
            end
        end
    end,
    UNIT_POWER = function(self, event, unitId, powerToken)
        if unitId == "player" then
            local powerType = self.POWER_TYPE[powerToken]
            if powerType then
                self:UpdatePower(event, powerType)
            end
        end
    end,
    UNIT_RANGEDDAMAGE = function(self, event, unitId)
        if unitId == "player" then
            self:UpdatePowerRegen(event)
        end
    end,
    UpdateMaxPower = function(self, event, powerType)
        self:StartProfiling("OvalePower_UpdateMaxPower")
        if powerType then
            local powerInfo = self.POWER_INFO[powerType]
            local maxPower = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
            if self.maxPower[powerType] ~= maxPower then
                self.maxPower[powerType] = maxPower
                __Ovale.Ovale:needRefresh()
            end
        else
            for powerType, powerInfo in _pairs(self.POWER_INFO) do
                local maxPower = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
                if self.maxPower[powerType] ~= maxPower then
                    self.maxPower[powerType] = maxPower
                    __Ovale.Ovale:needRefresh()
                end
            end
        end
        self:StopProfiling("OvalePower_UpdateMaxPower")
    end,
    UpdatePower = function(self, event, powerType)
        self:StartProfiling("OvalePower_UpdatePower")
        if powerType then
            local powerInfo = self.POWER_INFO[powerType]
            local power = API_UnitPower("player", powerInfo.id, powerInfo.segments)
            if self.power[powerType] ~= power then
                self.power[powerType] = power
                __Ovale.Ovale:needRefresh()
            end
            self:DebugTimestamp("%s: %d -> %d (%s).", event, self.power[powerType], power, powerType)
        else
            for powerType, powerInfo in _pairs(self.POWER_INFO) do
                local power = API_UnitPower("player", powerInfo.id, powerInfo.segments)
                if self.power[powerType] ~= power then
                    self.power[powerType] = power
                    __Ovale.Ovale:needRefresh()
                end
                self:DebugTimestamp("%s: %d -> %d (%s).", event, self.power[powerType], power, powerType)
            end
        end
        __Ovale.Ovale:needRefresh()
        self:StopProfiling("OvalePower_UpdatePower")
    end,
    UpdatePowerRegen = function(self, event)
        self:StartProfiling("OvalePower_UpdatePowerRegen")
        local inactiveRegen, activeRegen = API_GetPowerRegen()
        if self.inactiveRegen ~= inactiveRegen or self.activeRegen ~= activeRegen then
            self.inactiveRegen, self.activeRegen = inactiveRegen, activeRegen
            __Ovale.Ovale:needRefresh()
        end
        self:StopProfiling("OvalePower_UpdatePowerRegen")
    end,
    UpdatePowerType = function(self, event)
        self:StartProfiling("OvalePower_UpdatePowerType")
        local currentType = API_UnitPowerType("player")
        local powerType = self.POWER_TYPE[currentType]
        if self.powerType ~= powerType then
            self.powerType = powerType
            __Ovale.Ovale:needRefresh()
        end
        __Ovale.Ovale:needRefresh()
        self:StopProfiling("OvalePower_UpdatePowerType")
    end,
    GetSpellCost = function(self, spellId, powerType)
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
    end,
    GetPower = function(self, powerType, atTime)
        local power = (self.power and self.power[powerType]) or self[powerType] or 0
        local powerRate = 0
        if self.powerType and self.powerType == powerType and self.activeRegen then
            powerRate = self.activeRegen
        elseif self.powerRate and self.powerRate[powerType] then
            powerRate = self.powerRate[powerType]
        end
        if atTime then
            local now = __State.baseState.currentTime or API_GetTime()
            local seconds = atTime - now
            if seconds > 0 then
                power = power + powerRate * seconds
            end
        end
        return power
    end,
    PowerCost = function(self, spellId, powerType, atTime, targetGUID, maximumCost)
        self:StartProfiling("OvalePower_PowerCost")
        local buffParam = "buff_" .. powerType
        local spellCost = 0
        local spellRefund = 0
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si[powerType] then
            local cost = __Data.OvaleData:GetSpellInfoProperty(spellId, atTime, powerType, targetGUID)
            local costNumber
            if isString(cost) then
                if cost == "finisher" then
                    cost = self:GetPower(powerType, atTime)
                    local minCostParam = "min_" .. powerType
                    local maxCostParam = "max_" .. powerType
                    local minCost = si[minCostParam] or 1
                    local maxCost = si[maxCostParam]
                    if cost < minCost then
                        costNumber = minCost
                    end
                    if maxCost and cost > maxCost then
                        costNumber = maxCost
                    end
                elseif cost == "refill" then
                    costNumber = self:GetPower(powerType, atTime) - self.maxPower[powerType]
                end
                costNumber = 0
            else
                local buffExtraParam = buffParam
                local buffAmountParam = buffParam .. "_amount"
                local buffExtra = si[buffExtraParam]
                if buffExtra then
                    local aura = __Aura.OvaleAura:GetAura("player", buffExtra, nil, true)
                    local isActiveAura = __Aura.OvaleAura:IsActiveAura(aura, atTime)
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
                        local siAura = __Data.OvaleData.spellInfo[buffExtra]
                        if siAura and siAura.stacking == 1 then
                            buffAmount = buffAmount * aura.stacks
                        end
                        cost = cost + buffAmount
                        self:Log("Spell ID '%d' had %f %s added from aura ID '%d'.", spellId, buffAmount, powerType, aura.spellId)
                    end
                end
                costNumber = cost
            end
            local extraPowerParam = "extra_" .. powerType
            local extraPower = __Data.OvaleData:GetSpellInfoProperty(spellId, atTime, extraPowerParam, targetGUID)
            if extraPower and  not isString(extraPower) then
                if  not maximumCost then
                    local power = math.floor(self:GetPower(powerType, atTime))
                    power = power > cost and power - costNumber or 0
                    if extraPower >= power then
                        extraPower = power
                    end
                end
                costNumber = costNumber + extraPower
            end
            spellCost = ceil(costNumber)
            local refundParam = "refund_" .. powerType
            local refund = __Data.OvaleData:GetSpellInfoProperty(spellId, atTime, refundParam, targetGUID)
            if isString(refund) then
                if refund == "cost" then
                    spellRefund = ceil(spellCost)
                end
            else
                spellRefund = ceil(refund or 0)
            end
        else
            local cost = self:GetSpellCost(spellId, powerType)
            if cost then
                spellCost = cost
            end
        end
        self:StopProfiling("OvalePower_PowerCost")
        return spellCost, spellRefund
    end,
    RequirePowerHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
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
            __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement)
        end
        return verified, requirement, index
    end,
    DebugPower = function(self)
        self:Print("Power type: %s", self.powerType)
        for powerType, v in _pairs(self.power) do
            self:Print("Power (%s): %d / %d", powerType, v, self.maxPower[powerType])
        end
        self:Print("Active regen: %f", self.activeRegen)
        self:Print("Inactive regen: %f", self.inactiveRegen)
    end,
})
local output = {}
local PowerState = __addon.__class(nil, {
    InitializeState = function(self)
        for powerType in _pairs(__exports.OvalePower.POWER_INFO) do
            self[powerType] = 0
        end
        self.powerRate = {}
    end,
    ResetState = function(self)
        __exports.OvalePower:StartProfiling("OvalePower_ResetState")
        for powerType in _pairs(__exports.OvalePower.POWER_INFO) do
            self[powerType] = __exports.OvalePower.power[powerType] or 0
        end
        for powerType in _pairs(__exports.OvalePower.POWER_INFO) do
            self.powerRate[powerType] = 0
        end
        if __Future.OvaleFuture.inCombat then
            self.powerRate[__exports.OvalePower.powerType] = __exports.OvalePower.activeRegen
        else
            self.powerRate[__exports.OvalePower.powerType] = __exports.OvalePower.inactiveRegen
        end
        __exports.OvalePower:StopProfiling("OvalePower_ResetState")
    end,
    CleanState = function(self)
        for powerType in _pairs(__exports.OvalePower.POWER_INFO) do
            self[powerType] = nil
        end
        for k in _pairs(self.powerRate) do
            self.powerRate[k] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_ApplySpellStartCast")
        if isChanneled then
            if __State.baseState.inCombat then
                self.powerRate[__exports.OvalePower.powerType] = __exports.OvalePower.activeRegen
            end
            self:ApplyPowerCost(spellId, targetGUID, startCast, spellcast)
        end
        __exports.OvalePower:StopProfiling("OvalePower_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_ApplySpellAfterCast")
        if  not isChanneled then
            if __State.baseState.inCombat then
                self.powerRate[__exports.OvalePower.powerType] = __exports.OvalePower.activeRegen
            end
            self:ApplyPowerCost(spellId, targetGUID, endCast, spellcast)
        end
        __exports.OvalePower:StopProfiling("OvalePower_ApplySpellAfterCast")
    end,
    ApplyPowerCost = function(self, spellId, targetGUID, atTime, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_state_ApplyPowerCost")
        local si = __Data.OvaleData.spellInfo[spellId]
        do
            local cost, powerType = __exports.OvalePower:GetSpellCost(spellId)
            if cost and powerType and self[powerType] and  not (si and si[powerType]) then
                self[powerType] = self[powerType] - cost
            end
        end
        if si then
            for powerType, powerInfo in _pairs(__exports.OvalePower.POWER_INFO) do
                local cost, refund = self:PowerCost(spellId, powerType, atTime, targetGUID)
                local power = self[powerType] or 0
                if cost then
                    power = power - cost + refund
                    local seconds = __FutureState.futureState.nextCast - atTime
                    if seconds > 0 then
                        local powerRate = self.powerRate[powerType] or 0
                        power = power + powerRate * seconds
                    end
                    local mini = powerInfo.mini or 0
                    local maxi = __exports.OvalePower.maxPower[powerType]
                    if mini and power < mini then
                        power = mini
                    end
                    if maxi and power > maxi then
                        power = maxi
                    end
                    self[powerType] = power
                end
            end
        end
        __exports.OvalePower:StopProfiling("OvalePower_state_ApplyPowerCost")
    end,
    TimeToPower = function(self, spellId, atTime, targetGUID, powerType, extraPower)
        local seconds = 0
        powerType = powerType or __exports.OvalePower.POOLED_RESOURCE[__PaperDoll.paperDollState.class]
        if powerType then
            local cost = self:PowerCost(spellId, powerType, atTime, targetGUID)
            local power = self:GetPower(powerType, atTime)
            local powerRate = self.powerRate[powerType] or 0
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
    end,
    GetPower = function(self, powerType, atTime)
        return __exports.OvalePower:GetPower(powerType, atTime)
    end,
    PowerCost = function(self, spellId, powerType, atTime, targetGUID, maximumCost)
        return __exports.OvalePower:PowerCost(spellId, powerType, atTime, targetGUID, maximumCost)
    end,
    RequirePowerHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        return __exports.OvalePower:RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    end,
    DebugPower = function(self)
        _wipe(output)
        for powerType in _pairs(__exports.OvalePower.POWER_INFO) do
            output[#output + 1] = __Ovale.MakeString("%s = %d", powerType, self[powerType])
        end
        return tconcat(output, "\n")
    end,
    constructor = function(self)
        self.powerRate = nil
    end
})
__exports.powerState = PowerState()
__State.OvaleState:RegisterState(__exports.powerState)
__exports.OvalePower = OvalePowerClass()
end)
