local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Cooldown", { "./Debug", "./Profiler", "./Data", "./Future", "./GUID", "./PaperDoll", "./SpellBook", "./Stance", "./State", "./Ovale", "./Aura" }, function(__exports, __Debug, __Profiler, __Data, __Future, __GUID, __PaperDoll, __SpellBook, __Stance, __State, __Ovale, __Aura)
local OvaleCooldownBase = __Ovale.Ovale:NewModule("OvaleCooldown", "AceEvent-3.0")
local _next = next
local _pairs = pairs
local API_GetSpellCharges = GetSpellCharges
local API_GetSpellCooldown = GetSpellCooldown
local API_GetTime = GetTime
local GLOBAL_COOLDOWN = 61304
local COOLDOWN_THRESHOLD = 0.1
local strsub = string.sub
local BASE_GCD = {
    ["DEATHKNIGHT"] = {
        [1] = 1.5,
        [2] = "melee"
    },
    ["DEMONHUNTER"] = {
        [1] = 1.5,
        [2] = "melee"
    },
    ["DRUID"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["HUNTER"] = {
        [1] = 1.5,
        [2] = "ranged"
    },
    ["MAGE"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["MONK"] = {
        [1] = 1,
        [2] = false
    },
    ["PALADIN"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["PRIEST"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["ROGUE"] = {
        [1] = 1,
        [2] = false
    },
    ["SHAMAN"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["WARLOCK"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["WARRIOR"] = {
        [1] = 1.5,
        [2] = "melee"
    }
}
local OvaleCooldownClass = __class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleCooldownBase)), {
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "Update")
        self:RegisterEvent("BAG_UPDATE_COOLDOWN", "Update")
        self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "Update")
        self:RegisterEvent("SPELL_UPDATE_CHARGES", "Update")
        self:RegisterEvent("SPELL_UPDATE_USABLE", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:RegisterEvent("UNIT_SPELLCAST_START", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "Update")
        self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "Update")
        __Future.OvaleFuture:RegisterSpellcastInfo(self)
        __Data.OvaleData:RegisterRequirement("oncooldown", "RequireCooldownHandler", self)
    end,
    OnDisable = function(self)
        __Future.OvaleFuture:UnregisterSpellcastInfo(self)
        __Data.OvaleData:UnregisterRequirement("oncooldown")
        self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
        self:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
        self:UnregisterEvent("SPELL_UPDATE_CHARGES")
        self:UnregisterEvent("SPELL_UPDATE_USABLE")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:UnregisterEvent("UNIT_SPELLCAST_START")
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
    end,
    UNIT_SPELLCAST_INTERRUPTED = function(self, event, unit, name, rank, lineId, spellId)
        if unit == "player" or unit == "pet" then
            self:Update(event, unit)
            self:Debug("Resetting global cooldown.")
            local cd = self.gcd
            cd.start = 0
            cd.duration = 0
        end
    end,
    Update = function(self, event, unit)
        if  not unit or unit == "player" or unit == "pet" then
            self.serial = self.serial + 1
            __Ovale.Ovale.refreshNeeded[__Ovale.Ovale.playerGUID] = true
            self:Debug(event, self.serial)
        end
    end,
    ResetSharedCooldowns = function(self)
        for name, spellTable in _pairs(self.sharedCooldown) do
            for spellId in _pairs(spellTable) do
                spellTable[spellId] = nil
            end
        end
    end,
    IsSharedCooldown = function(self, name)
        local spellTable = self.sharedCooldown[name]
        return (spellTable and _next(spellTable) ~= nil)
    end,
    AddSharedCooldown = function(self, name, spellId)
        self.sharedCooldown[name] = self.sharedCooldown[name] or {}
        self.sharedCooldown[name][spellId] = true
    end,
    GetGlobalCooldown = function(self, now)
        local cd = self.gcd
        if  not cd.start or  not cd.serial or cd.serial < self.serial then
            now = now or API_GetTime()
            if now >= cd.start + cd.duration then
                cd.start, cd.duration = API_GetSpellCooldown(GLOBAL_COOLDOWN)
            end
        end
        return cd.start, cd.duration
    end,
    GetSpellCooldown = function(self, spellId)
        local cdStart, cdDuration, cdEnable = 0, 0, 1
        if self.sharedCooldown[spellId] then
            for id in _pairs(self.sharedCooldown[spellId]) do
                local start, duration, enable = self:GetSpellCooldown(id)
                if start then
                    cdStart, cdDuration, cdEnable = start, duration, enable
                    break
                end
            end
        else
            local start, duration, enable
            local index, bookType = __SpellBook.OvaleSpellBook:GetSpellBookIndex(spellId)
            if index and bookType then
                start, duration, enable = API_GetSpellCooldown(index, bookType)
            else
                start, duration, enable = API_GetSpellCooldown(spellId)
            end
            if start and start > 0 then
                local gcdStart, gcdDuration = self:GetGlobalCooldown()
                if start + duration > gcdStart + gcdDuration then
                    cdStart, cdDuration, cdEnable = start, duration, enable
                else
                    cdStart = start + duration
                    cdDuration = 0
                    cdEnable = enable
                end
            else
                cdStart, cdDuration, cdEnable = start or 0, duration, enable
            end
        end
        return cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable
    end,
    GetBaseGCD = function(self)
        local gcd, haste
        local baseGCD = BASE_GCD[__Ovale.Ovale.playerClass]
        if baseGCD then
            gcd, haste = baseGCD[1], baseGCD[2]
        else
            gcd, haste = 1.5, "spell"
        end
        return gcd, haste
    end,
    CopySpellcastInfo = function(self, spellcast, dest)
        if spellcast.offgcd then
            dest.offgcd = spellcast.offgcd
        end
    end,
    SaveSpellcastInfo = function(self, spellcast, atTime, state)
        local spellId = spellcast.spellId
        if spellId then
            local dataModule = state or __Data.OvaleData
            local gcd = dataModule:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
            if gcd and gcd == 0 then
                spellcast.offgcd = true
            end
        end
    end,
})
local CooldownState = __class(nil, {
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleCooldown:StartProfiling("OvaleCooldown_ApplySpellStartCast")
        if isChanneled then
            self:ApplyCooldown(spellId, targetGUID, startCast)
        end
        __exports.OvaleCooldown:StopProfiling("OvaleCooldown_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleCooldown:StartProfiling("OvaleCooldown_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyCooldown(spellId, targetGUID, endCast)
        end
        __exports.OvaleCooldown:StopProfiling("OvaleCooldown_ApplySpellAfterCast")
    end,
    RequireCooldownHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        local cdSpellId = tokens
        local verified = false
        if index then
            cdSpellId = tokens[index]
            index = index + 1
        end
        if cdSpellId then
            local isBang = false
            if strsub(cdSpellId, 1, 1) == "!" then
                isBang = true
                cdSpellId = strsub(cdSpellId, 2)
            end
            local cd = self:GetCD(cdSpellId)
            verified =  not isBang and cd.duration > 0 or isBang and cd.duration <= 0
            local result = verified and "passed" or "FAILED"
            __exports.OvaleCooldown:Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang and "OFF" or  not isBang and "ON", atTime, result, cd.duration)
        else
            __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement)
        end
        return verified, requirement, index
    end,
    InitializeState = function(self)
        self.cd = {}
    end,
    ResetState = function(self)
        for spellId, cd in _pairs(self.cd) do
            cd.serial = nil
        end
    end,
    CleanState = function(self)
        for spellId, cd in _pairs(self.cd) do
            for k in _pairs(cd) do
                cd[k] = nil
            end
            self.cd[spellId] = nil
        end
    end,
    ApplyCooldown = function(self, spellId, targetGUID, atTime)
        __exports.OvaleCooldown:StartProfiling("OvaleCooldown_state_ApplyCooldown")
        local cd = self:GetCD(spellId)
        local duration = self:GetSpellCooldownDuration(spellId, atTime, targetGUID)
        if duration == 0 then
            cd.start = 0
            cd.duration = 0
            cd.enable = 1
        else
            cd.start = atTime
            cd.duration = duration
            cd.enable = 1
        end
        if cd.charges and cd.charges > 0 then
            cd.chargeStart = cd.start
            cd.charges = cd.charges - 1
            if cd.charges == 0 then
                cd.duration = cd.chargeDuration
            end
        end
        __exports.OvaleCooldown:Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges or "(nil)")
        __exports.OvaleCooldown:StopProfiling("OvaleCooldown_state_ApplyCooldown")
    end,
    DebugCooldown = function(self)
        for spellId, cd in _pairs(self.cd) do
            if cd.start then
                if cd.charges then
                    __exports.OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration)
                else
                    __exports.OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
                end
            end
        end
    end,
    GetGCD = function(self, spellId, atTime, targetGUID)
        spellId = spellId or __Future.futureState.currentSpellId
        if  not atTime then
            if __Future.futureState.endCast and __Future.futureState.endCast > __State.baseState.currentTime then
                atTime = __Future.futureState.endCast
            else
                atTime = __State.baseState.currentTime
            end
        end
        targetGUID = targetGUID or __GUID.OvaleGUID:UnitGUID(__State.baseState.defaultTarget)
        local gcd = spellId and __Data.dataState:GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID)
        if  not gcd then
            local haste
            gcd, haste = __exports.OvaleCooldown:GetBaseGCD()
            if __Ovale.Ovale.playerClass == "MONK" and __PaperDoll.OvalePaperDoll:IsSpecialization("mistweaver") then
                gcd = 1.5
                haste = "spell"
            elseif __Ovale.Ovale.playerClass == "DRUID" then
                if __Stance.OvaleStance:IsStance("druid_cat_form") then
                    gcd = 1
                    haste = false
                end
            end
            local gcdHaste = spellId and __Data.dataState:GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID)
            if gcdHaste then
                haste = gcdHaste
            else
                local siHaste = spellId and __Data.dataState:GetSpellInfoProperty(spellId, atTime, "haste", targetGUID)
                if siHaste then
                    haste = siHaste
                end
            end
            local multiplier = __PaperDoll.paperDollState:GetHasteMultiplier(haste)
            gcd = gcd / multiplier
            gcd = (gcd > 0.75) and gcd or 0.75
        end
        return gcd
    end,
    GetCD = function(self, spellId)
        __exports.OvaleCooldown:StartProfiling("OvaleCooldown_state_GetCD")
        local cdName = spellId
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.sharedcd then
            cdName = si.sharedcd
        end
        if  not self.cd[cdName] then
            self.cd[cdName] = {}
        end
        local cd = self.cd[cdName]
        if  not cd.start or  not cd.serial or cd.serial < __exports.OvaleCooldown.serial then
            local start, duration, enable = __exports.OvaleCooldown:GetSpellCooldown(spellId)
            if si and si.forcecd then
                start, duration = __exports.OvaleCooldown:GetSpellCooldown(si.forcecd)
            end
            cd.serial = __exports.OvaleCooldown.serial
            cd.start = start - COOLDOWN_THRESHOLD
            cd.duration = duration
            cd.enable = enable
            local charges, maxCharges, chargeStart, chargeDuration = API_GetSpellCharges(spellId)
            if charges then
                cd.charges = charges
                cd.maxCharges = maxCharges
                cd.chargeStart = chargeStart
                cd.chargeDuration = chargeDuration
            end
        end
        local now = __State.baseState.currentTime
        if cd.start then
            if cd.start + cd.duration <= now then
                cd.start = 0
                cd.duration = 0
            end
        end
        if cd.charges then
            local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
            while chargeStart + chargeDuration <= now and charges < maxCharges do
                chargeStart = chargeStart + chargeDuration
                charges = charges + 1
            end
            cd.charges = charges
            cd.chargeStart = chargeStart
        end
        __exports.OvaleCooldown:StopProfiling("OvaleCooldown_state_GetCD")
        return cd
    end,
    GetSpellCooldown = function(self, spellId)
        local cd = self:GetCD(spellId)
        return cd.start, cd.duration, cd.enable
    end,
    GetSpellCooldownDuration = function(self, spellId, atTime, targetGUID)
        local start, duration = self:GetSpellCooldown(spellId)
        if duration > 0 and start + duration > atTime then
            __exports.OvaleCooldown:Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
        else
            local si = __Data.OvaleData.spellInfo[spellId]
            duration = __Data.dataState:GetSpellInfoProperty(spellId, atTime, "cd", targetGUID)
            if duration then
                if si and si.addcd then
                    duration = duration + si.addcd
                end
                if duration < 0 then
                    duration = 0
                end
            else
                duration = 0
            end
            __exports.OvaleCooldown:Log("Spell %d has a base cooldown of %fs.", spellId, duration)
            if duration > 0 then
                local haste = __Data.dataState:GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID)
                local multiplier = __PaperDoll.paperDollState:GetHasteMultiplier(haste)
                duration = duration / multiplier
                if si and si.buff_cdr then
                    local aura = __Aura.auraState:GetAura("player", si.buff_cdr)
                    if __Aura.auraState:IsActiveAura(aura, atTime) then
                        duration = duration * aura.value1
                    end
                end
            end
        end
        return duration
    end,
    GetSpellCharges = function(self, spellId, atTime)
        atTime = atTime or __State.baseState.currentTime
        local cd = self:GetCD(spellId)
        local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
        if charges then
            while chargeStart + chargeDuration <= atTime and charges < maxCharges do
                chargeStart = chargeStart + chargeDuration
                charges = charges + 1
            end
        end
        return charges, maxCharges, chargeStart, chargeDuration
    end,
    ResetSpellCooldown = function(self, spellId, atTime)
        local now = __State.baseState.currentTime
        if atTime >= now then
            local cd = self:GetCD(spellId)
            if cd.start + cd.duration > now then
                cd.start = now
                cd.duration = atTime - now
            end
        end
    end,
})
__exports.OvaleCooldown = OvaleCooldownClass()
__exports.cooldownState = CooldownState()
__State.OvaleState:RegisterState(__exports.cooldownState)
end)
