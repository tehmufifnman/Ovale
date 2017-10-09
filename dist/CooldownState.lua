local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./CooldownState", { "./State", "./Cooldown", "./DataState", "./PaperDoll", "./Ovale", "./Data", "./Aura" }, function(__exports, __State, __Cooldown, __DataState, __PaperDoll, __Ovale, __Data, __Aura)
local API_GetSpellCharges = GetSpellCharges
local strsub = string.sub
local _pairs = pairs
local COOLDOWN_THRESHOLD = 0.1
local CooldownState = __class(nil, {
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __Cooldown.OvaleCooldown:StartProfiling("OvaleCooldown_ApplySpellStartCast")
        if isChanneled then
            self:ApplyCooldown(spellId, targetGUID, startCast)
        end
        __Cooldown.OvaleCooldown:StopProfiling("OvaleCooldown_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __Cooldown.OvaleCooldown:StartProfiling("OvaleCooldown_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyCooldown(spellId, targetGUID, endCast)
        end
        __Cooldown.OvaleCooldown:StopProfiling("OvaleCooldown_ApplySpellAfterCast")
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
            __Cooldown.OvaleCooldown:Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang and "OFF" or  not isBang and "ON", atTime, result, cd.duration)
        else
            __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement)
        end
        return verified, requirement, index
    end,
    InitializeState = function(self)
        self.cd = {}
    end,
    ResetState = function(self)
        for _, cd in _pairs(self.cd) do
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
        __Cooldown.OvaleCooldown:StartProfiling("OvaleCooldown_state_ApplyCooldown")
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
        __Cooldown.OvaleCooldown:Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges or "(nil)")
        __Cooldown.OvaleCooldown:StopProfiling("OvaleCooldown_state_ApplyCooldown")
    end,
    DebugCooldown = function(self)
        for spellId, cd in _pairs(self.cd) do
            if cd.start then
                if cd.charges then
                    __Cooldown.OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration)
                else
                    __Cooldown.OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
                end
            end
        end
    end,
    GetCD = function(self, spellId)
        __Cooldown.OvaleCooldown:StartProfiling("OvaleCooldown_state_GetCD")
        local cdName = spellId
        local si = __Data.OvaleData.spellInfo[spellId]
        if si and si.sharedcd then
            cdName = si.sharedcd
        end
        if  not self.cd[cdName] then
            self.cd[cdName] = {}
        end
        local cd = self.cd[cdName]
        if  not cd.start or  not cd.serial or cd.serial < __Cooldown.OvaleCooldown.serial then
            local start, duration, enable = __Cooldown.OvaleCooldown:GetSpellCooldown(spellId)
            if si and si.forcecd then
                start, duration = __Cooldown.OvaleCooldown:GetSpellCooldown(si.forcecd)
            end
            cd.serial = __Cooldown.OvaleCooldown.serial
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
        __Cooldown.OvaleCooldown:StopProfiling("OvaleCooldown_state_GetCD")
        return cd
    end,
    GetSpellCooldown = function(self, spellId)
        local cd = self:GetCD(spellId)
        return cd.start, cd.duration, cd.enable
    end,
    GetSpellCooldownDuration = function(self, spellId, atTime, targetGUID)
        local start, duration = self:GetSpellCooldown(spellId)
        if duration > 0 and start + duration > atTime then
            __Cooldown.OvaleCooldown:Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
        else
            local si = __Data.OvaleData.spellInfo[spellId]
            duration = __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "cd", targetGUID)
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
            __Cooldown.OvaleCooldown:Log("Spell %d has a base cooldown of %fs.", spellId, duration)
            if duration > 0 then
                local haste = __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID)
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
    constructor = function(self)
        self.cd = nil
    end
})
__exports.cooldownState = CooldownState()
__State.OvaleState:RegisterState(__exports.cooldownState)
end)
