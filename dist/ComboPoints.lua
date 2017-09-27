local OVALE, Ovale = ...
require(OVALE, Ovale, "ComboPoints", { "./L", "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __L, __OvaleDebug, __OvaleProfiler)
local OvaleComboPoints = Ovale:NewModule("OvaleComboPoints", "AceEvent-3.0")
Ovale.OvaleComboPoints = OvaleComboPoints
local OvaleAura = nil
local OvaleData = nil
local OvaleEquipment = nil
local OvaleFuture = nil
local OvalePaperDoll = nil
local OvalePower = nil
local OvaleSpellBook = nil
local OvaleState = nil
local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime
local API_UnitPower = UnitPower
local _MAX_COMBO_POINTS = MAX_COMBO_POINTS
local _UNKNOWN = UNKNOWN
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleComboPoints)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleComboPoints)
local self_playerGUID = nil
local ANTICIPATION = 115189
local ANTICIPATION_DURATION = 15
local ANTICIPATION_TALENT = 18
local self_hasAnticipation = false
local RUTHLESSNESS = 14161
local self_hasRuthlessness = false
local ENVENOM = 32645
local self_hasAssassination4pT17 = false
local self_pendingComboEvents = {}
local PENDING_THRESHOLD = 0.8
local self_updateSpellcastInfo = {}
OvaleComboPoints.combo = 0
local AddPendingComboEvent = function(atTime, spellId, guid, reason, combo)
    local comboEvent = {
        atTime = atTime,
        spellId = spellId,
        guid = guid,
        reason = reason,
        combo = combo
    }
    tinsert(self_pendingComboEvents, comboEvent)
    Ovale.refreshNeeded[self_playerGUID] = true
end
local RemovePendingComboEvents = function(atTime, spellId, guid, reason, combo)
    local count = 0
    for k = #self_pendingComboEvents, 1, -1 do
        local comboEvent = self_pendingComboEvents[k]
        if (atTime and atTime - comboEvent.atTime > PENDING_THRESHOLD) or (comboEvent.spellId == spellId and comboEvent.guid == guid and ( not reason or comboEvent.reason == reason) and ( not combo or comboEvent.combo == combo)) then
            if comboEvent.combo == "finisher" then
                OvaleComboPoints:Debug("Removing expired %s event: spell %d combo point finisher from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.reason)
            else
                OvaleComboPoints:Debug("Removing expired %s event: spell %d for %d combo points from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.combo, comboEvent.reason)
            end
            count = count + 1
            tremove(self_pendingComboEvents, k)
            Ovale.refreshNeeded[self_playerGUID] = true
        end
    end
    return count
end
local OvaleComboPoints = __class()
function OvaleComboPoints:OnInitialize()
    OvaleAura = Ovale.OvaleAura
    OvaleData = Ovale.OvaleData
    OvaleEquipment = Ovale.OvaleEquipment
    OvaleFuture = Ovale.OvaleFuture
    OvalePaperDoll = Ovale.OvalePaperDoll
    OvalePower = Ovale.OvalePower
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleState = Ovale.OvaleState
end
function OvaleComboPoints:OnEnable()
    self_playerGUID = Ovale.playerGUID
    if Ovale.playerClass == "ROGUE" or Ovale.playerClass == "DRUID" then
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_POWER")
        self:RegisterEvent("Ovale_EquipmentChanged")
        self:RegisterMessage("Ovale_SpellFinished")
        self:RegisterMessage("Ovale_TalentsChanged")
        OvaleData:RegisterRequirement("combo", "RequireComboPointsHandler", self)
        OvaleFuture:RegisterSpellcastInfo(self)
        OvaleState:RegisterState(self, self.statePrototype)
    end
end
function OvaleComboPoints:OnDisable()
    if Ovale.playerClass == "ROGUE" or Ovale.playerClass == "DRUID" then
        OvaleState:UnregisterState(self)
        OvaleFuture:UnregisterSpellcastInfo(self)
        OvaleData:UnregisterRequirement("combo")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self:UnregisterEvent("UNIT_POWER")
        self:UnregisterEvent("Ovale_EquipmentChanged")
        self:UnregisterMessage("Ovale_SpellFinished")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end
end
function OvaleComboPoints:PLAYER_TARGET_CHANGED(event, cause)
    if cause == "NIL" or cause == "down" then
    else
        self:Update()
    end
end
function OvaleComboPoints:UNIT_POWER(event, unitId, powerToken)
    if powerToken ~= OvalePower.POWER_INFO.combopoints.token then
        break
    end
    if unitId == "player" then
        local oldCombo = self.combo
        self:Update()
        local difference = self.combo - oldCombo
        self:DebugTimestamp("%s: %d -> %d.", event, oldCombo, self.combo)
        local now = API_GetTime()
        RemovePendingComboEvents(now)
        local pendingMatched = false
        if #self_pendingComboEvents > 0 then
            local comboEvent = self_pendingComboEvents[1]
            local spellId, guid, reason, combo = comboEvent.spellId, comboEvent.guid, comboEvent.reason, comboEvent.combo
            if combo == difference or (combo == "finisher" and self.combo == 0 and difference < 0) then
                self:Debug("    Matches pending %s event for %d.", reason, spellId)
                pendingMatched = true
                tremove(self_pendingComboEvents, 1)
            end
        end
    end
end
function OvaleComboPoints:Ovale_EquipmentChanged(event)
    self_hasAssassination4pT17 = (Ovale.playerClass == "ROGUE" and OvalePaperDoll:IsSpecialization("assassination") and OvaleEquipment:GetArmorSetCount("T17") >= 4)
end
function OvaleComboPoints:Ovale_SpellFinished(event, atTime, spellId, targetGUID, finish)
    self:Debug("%s (%f): Spell %d finished (%s) on %s", event, atTime, spellId, finish, targetGUID or _UNKNOWN)
    local si = OvaleData.spellInfo[spellId]
    if si and si.combo == "finisher" and finish == "hit" then
        self:Debug("    Spell %d hit and consumed all combo points.", spellId)
        AddPendingComboEvent(atTime, spellId, targetGUID, "finisher", "finisher")
        if self_hasRuthlessness and self.combo == _MAX_COMBO_POINTS then
            self:Debug("    Spell %d has 100% chance to grant an extra combo point from Ruthlessness.", spellId)
            AddPendingComboEvent(atTime, spellId, targetGUID, "Ruthlessness", 1)
        end
        if self_hasAssassination4pT17 and spellId == ENVENOM then
            self:Debug("    Spell %d refunds 1 combo point from Assassination 4pT17 set bonus.", spellId)
            AddPendingComboEvent(atTime, spellId, targetGUID, "Assassination 4pT17", 1)
        end
        if self_hasAnticipation and targetGUID ~= self_playerGUID then
            if OvaleSpellBook:IsHarmfulSpell(spellId) then
                local aura = OvaleAura:GetAuraByGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true)
                if OvaleAura:IsActiveAura(aura, atTime) then
                    self:Debug("    Spell %d hit with %d Anticipation charges.", spellId, aura.stacks)
                    AddPendingComboEvent(atTime, spellId, targetGUID, "Anticipation", aura.stacks)
                end
            end
        end
    end
end
function OvaleComboPoints:Ovale_TalentsChanged(event)
    if Ovale.playerClass == "ROGUE" then
        self_hasAnticipation = OvaleSpellBook:GetTalentPoints(ANTICIPATION_TALENT) > 0
        self_hasRuthlessness = OvaleSpellBook:IsKnownSpell(RUTHLESSNESS)
    end
end
function OvaleComboPoints:Update()
    self:StartProfiling("OvaleComboPoints_Update")
    self.combo = API_UnitPower("player", 4)
    Ovale.refreshNeeded[self_playerGUID] = true
    self:StopProfiling("OvaleComboPoints_Update")
end
function OvaleComboPoints:GetComboPoints()
    local now = API_GetTime()
    RemovePendingComboEvents(now)
    local total = self.combo
    for k = 1, #self_pendingComboEvents, 1 do
        local combo = self_pendingComboEvents[k].combo
        if combo == "finisher" then
            total = 0
        else
            total = total + combo
        end
        if total > _MAX_COMBO_POINTS then
            total = _MAX_COMBO_POINTS
        end
    end
    return total
end
function OvaleComboPoints:DebugComboPoints()
    self:Print("Player has %d combo points.", self.combo)
end
function OvaleComboPoints:ComboPointCost(spellId, atTime, targetGUID)
    OvaleComboPoints:StartProfiling("OvaleComboPoints_ComboPointCost")
    local spellCost = 0
    local spellRefund = 0
    local si = OvaleData.spellInfo[spellId]
    if si and si.combo then
        local GetAura, IsActiveAura
        local GetSpellInfoProperty
        local auraModule, dataModule
        GetAura, auraModule = self:GetMethod("GetAura", OvaleAura)
        IsActiveAura, auraModule = self:GetMethod("IsActiveAura", OvaleAura)
        GetSpellInfoProperty, dataModule = self:GetMethod("GetSpellInfoProperty", OvaleData)
        local cost = GetSpellInfoProperty(dataModule, spellId, atTime, "combo", targetGUID)
        if cost == "finisher" then
            cost = self:GetComboPoints()
            local minCost = si.min_combo or si.mincombo or 1
            local maxCost = si.max_combo
            if cost < minCost then
                cost = minCost
            end
            if maxCost and cost > maxCost then
                cost = maxCost
            end
        else
            local buffExtra = si.buff_combo
            if buffExtra then
                local aura = GetAura(auraModule, "player", buffExtra, nil, true)
                local isActiveAura = IsActiveAura(auraModule, aura, atTime)
                if isActiveAura then
                    local buffAmount = si.buff_combo_amount or 1
                    cost = cost + buffAmount
                end
            end
            cost = -1 * cost
        end
        spellCost = cost
        local refundParam = "refund_combo"
        local refund = GetSpellInfoProperty(dataModule, spellId, atTime, refundParam, targetGUID)
        if refund == "cost" then
            refund = spellCost
        end
        spellRefund = refund or 0
    end
    OvaleComboPoints:StopProfiling("OvaleComboPoints_ComboPointCost")
    return spellCost, spellRefund
end
function OvaleComboPoints:RequireComboPointsHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    local verified = false
    local cost = tokens
    if index then
        cost = tokens[index]
        index = index + 1
    end
    if cost then
        cost = self:ComboPointCost(spellId, atTime, targetGUID)
        if cost > 0 then
            local power = self:GetComboPoints()
            if power >= cost then
                verified = true
            end
        else
            verified = true
        end
        if cost > 0 then
            local result = verified and "passed" or "FAILED"
            self:Log("    Require %d combo point(s) at time=%f: %s", cost, atTime, result)
        end
    else
        Ovale:OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement)
    end
    return verified, requirement, index
end
function OvaleComboPoints:CopySpellcastInfo(spellcast, dest)
    if spellcast.combo then
        dest.combo = spellcast.combo
    end
end
function OvaleComboPoints:SaveSpellcastInfo(spellcast, atTime, state)
    local spellId = spellcast.spellId
    if spellId then
        local si = OvaleData.spellInfo[spellId]
        if si then
            local dataModule = state or OvaleData
            local comboPointModule = state or self
            if si.combo == "finisher" then
                local combo = dataModule:GetSpellInfoProperty(spellId, atTime, "combo", spellcast.target)
                if combo == "finisher" then
                    local min_combo = si.min_combo or si.mincombo or 1
                    if comboPointModule.combo >= min_combo then
                        combo = comboPointModule.combo
                    else
                        combo = min_combo
                    end
                elseif combo == 0 then
                    combo = _MAX_COMBO_POINTS
                end
                spellcast.combo = combo
            end
        end
    end
end
OvaleComboPoints.statePrototype = {}
local statePrototype = OvaleComboPoints.statePrototype
statePrototype.combo = nil
local OvaleComboPoints = __class()
function OvaleComboPoints:InitializeState(state)
    state.combo = 0
end
function OvaleComboPoints:ResetState(state)
    self:StartProfiling("OvaleComboPoints_ResetState")
    state.combo = self:GetComboPoints()
    for k = 1, #self_pendingComboEvents, 1 do
        local comboEvent = self_pendingComboEvents[k]
        if comboEvent.reason == "Anticipation" then
            state:RemoveAuraOnGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true, comboEvent.atTime)
            break
        end
    end
    self:StopProfiling("OvaleComboPoints_ResetState")
end
function OvaleComboPoints:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
    self:StartProfiling("OvaleComboPoints_ApplySpellAfterCast")
    local si = OvaleData.spellInfo[spellId]
    if si and si.combo then
        local cost, refund = state:ComboPointCost(spellId, endCast, targetGUID)
        local power = state.combo
        power = power - cost + refund
        if power <= 0 then
            power = 0
            if self_hasRuthlessness and state.combo == _MAX_COMBO_POINTS then
                state:Log("Spell %d grants one extra combo point from Ruthlessness.", spellId)
                power = power + 1
            end
            if self_hasAnticipation and state.combo > 0 then
                local aura = state:GetAuraByGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true)
                if state:IsActiveAura(aura, endCast) then
                    power = power + aura.stacks
                    state:RemoveAuraOnGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true, endCast)
                    if power > _MAX_COMBO_POINTS then
                        power = _MAX_COMBO_POINTS
                    end
                end
            end
        end
        if power > _MAX_COMBO_POINTS then
            if self_hasAnticipation and  not si.temp_combo then
                local stacks = power - _MAX_COMBO_POINTS
                local aura = state:GetAuraByGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true)
                if state:IsActiveAura(aura, endCast) then
                    stacks = stacks + aura.stacks
                    if stacks > _MAX_COMBO_POINTS then
                        stacks = _MAX_COMBO_POINTS
                    end
                end
                local start = endCast
                local ending = start + ANTICIPATION_DURATION
                aura = state:AddAuraToGUID(self_playerGUID, ANTICIPATION, self_playerGUID, "HELPFUL", nil, start, ending)
                aura.stacks = stacks
            end
            power = _MAX_COMBO_POINTS
        end
        state.combo = power
    end
    self:StopProfiling("OvaleComboPoints_ApplySpellAfterCast")
end
statePrototype.GetComboPoints = function(state)
    return state.combo
end
statePrototype.ComboPointCost = OvaleComboPoints.ComboPointCost
statePrototype.RequireComboPointsHandler = OvaleComboPoints.RequireComboPointsHandler
end))
