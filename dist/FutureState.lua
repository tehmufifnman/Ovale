local __addonName, __addon = ...
            __addon.require("./FutureState", { "./Future", "./Cooldown", "./LastSpell", "./SpellBook", "./GUID", "./State", "./Ovale", "./PaperDoll", "./DataState", "./Stance" }, function(__exports, __Future, __Cooldown, __LastSpell, __SpellBook, __GUID, __State, __Ovale, __PaperDoll, __DataState, __Stance)
local _wipe = wipe
local API_GetTime = GetTime
local _pairs = pairs
local tinsert = table.insert
local tremove = table.remove
local SIMULATOR_LAG = 0.005
local FutureState = __addon.__class(nil, {
    InitializeState = function(self)
        self.lastCast = {}
        self.counter = {}
    end,
    ResetState = function(self)
        __Future.OvaleFuture:StartProfiling("OvaleFuture_ResetState")
        local now = API_GetTime()
        __State.baseState.currentTime = now
        __Future.OvaleFuture:Log("Reset state with current time = %f", __State.baseState.currentTime)
        self.inCombat = __Future.OvaleFuture.inCombat
        self.combatStartTime = __Future.OvaleFuture.combatStartTime or 0
        self.nextCast = now
        local reason = ""
        local start, duration = __Cooldown.OvaleCooldown:GetGlobalCooldown(now)
        if start and start > 0 then
            local ending = start + duration
            if self.nextCast < ending then
                self.nextCast = ending
                reason = " (waiting for GCD)"
            end
        end
        local lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound
        for i = #__LastSpell.lastSpell.queue, 1, -1 do
            local spellcast = __LastSpell.lastSpell.queue[i]
            if spellcast.spellId and spellcast.start then
                __Future.OvaleFuture:Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop)
                if  not lastSpellcastFound then
                    self.lastSpellId = spellcast.spellId
                    if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                        self.currentSpellId = spellcast.spellId
                        self.startCast = spellcast.start
                        self.endCast = spellcast.stop
                        self.channel = spellcast.channel
                    end
                    lastSpellcastFound = true
                end
                if  not lastGCDSpellcastFound and  not spellcast.offgcd then
                    self:PushGCDSpellId(spellcast.spellId)
                    if spellcast.stop and self.nextCast < spellcast.stop then
                        self.nextCast = spellcast.stop
                        reason = " (waiting for spellcast)"
                    end
                    lastGCDSpellcastFound = true
                end
                if  not lastOffGCDSpellcastFound and spellcast.offgcd then
                    self.lastOffGCDSpellId = spellcast.spellId
                    lastOffGCDSpellcastFound = true
                end
            end
            if lastGCDSpellcastFound and lastOffGCDSpellcastFound and lastSpellcastFound then
                break
            end
        end
        if  not lastSpellcastFound then
            local spellcast = __LastSpell.lastSpell.lastSpellcast
            if spellcast then
                self.lastSpellId = spellcast.spellId
                if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                    self.currentSpellId = spellcast.spellId
                    self.startCast = spellcast.start
                    self.endCast = spellcast.stop
                    self.channel = spellcast.channel
                end
            end
        end
        if  not lastGCDSpellcastFound then
            local spellcast = __LastSpell.lastSpell.lastGCDSpellcast
            if spellcast then
                self.lastGCDSpellId = spellcast.spellId
                if spellcast.stop and self.nextCast < spellcast.stop then
                    self.nextCast = spellcast.stop
                    reason = " (waiting for spellcast)"
                end
            end
        end
        if  not lastOffGCDSpellcastFound then
            local spellcast = __Future.OvaleFuture.lastOffGCDSpellcast
            if spellcast then
                self.lastOffGCDSpellId = spellcast.spellId
            end
        end
        __Future.OvaleFuture:Log("    lastSpellId = %s, lastGCDSpellId = %s, lastOffGCDSpellId = %s", self.lastSpellId, self.lastGCDSpellId, self.lastOffGCDSpellId)
        __Future.OvaleFuture:Log("    nextCast = %f%s", self.nextCast, reason)
        _wipe(self.lastCast)
        for k, v in _pairs(__Future.OvaleFuture.counter) do
            self.counter[k] = v
        end
        __Future.OvaleFuture:StopProfiling("OvaleFuture_ResetState")
    end,
    CleanState = function(self)
        for k in _pairs(self.lastCast) do
            self.lastCast[k] = nil
        end
        for k in _pairs(self.counter) do
            self.counter[k] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        __Future.OvaleFuture:StartProfiling("OvaleFuture_ApplySpellStartCast")
        if channel then
            __Future.OvaleFuture:UpdateCounters(spellId, startCast, targetGUID)
        end
        __Future.OvaleFuture:StopProfiling("OvaleFuture_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        __Future.OvaleFuture:StartProfiling("OvaleFuture_ApplySpellAfterCast")
        if  not channel then
            __Future.OvaleFuture:UpdateCounters(spellId, endCast, targetGUID)
        end
        __Future.OvaleFuture:StopProfiling("OvaleFuture_ApplySpellAfterCast")
    end,
    GetCounter = function(self, id)
        return self.counter[id] or 0
    end,
    GetCounterValue = function(self, id)
        return self:GetCounter(id)
    end,
    TimeOfLastCast = function(self, spellId)
        return self.lastCast[spellId] or __Future.OvaleFuture.lastCastTime[spellId] or 0
    end,
    IsChanneling = function(self, atTime)
        atTime = atTime or __State.baseState.currentTime
        return self.channel and (atTime < self.endCast)
    end,
    PushGCDSpellId = function(self, spellId)
        if self.lastGCDSpellId then
            tinsert(self.lastGCDSpellIds, self.lastGCDSpellId)
            if #self.lastGCDSpellIds > 5 then
                tremove(self.lastGCDSpellIds, 1)
            end
        end
        self.lastGCDSpellId = spellId
    end,
    ApplySpell = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        __Future.OvaleFuture:StartProfiling("OvaleFuture_state_ApplySpell")
        if spellId then
            if  not targetGUID then
                targetGUID = __Ovale.Ovale.playerGUID
            end
            local castTime
            if startCast and endCast then
                castTime = endCast - startCast
            else
                castTime = __SpellBook.OvaleSpellBook:GetCastTime(spellId) or 0
                startCast = startCast or self.nextCast
                endCast = endCast or (startCast + castTime)
            end
            if  not spellcast then
                spellcast = FutureState.staticSpellcast
                _wipe(spellcast)
                spellcast.caster = __Ovale.Ovale.playerGUID
                spellcast.spellId = spellId
                spellcast.spellName = __SpellBook.OvaleSpellBook:GetSpellName(spellId)
                spellcast.target = targetGUID
                spellcast.targetName = __GUID.OvaleGUID:GUIDName(targetGUID)
                spellcast.start = startCast
                spellcast.stop = endCast
                spellcast.channel = channel
                __PaperDoll.paperDollState:UpdateSnapshot(spellcast)
                local atTime = channel and startCast or endCast
                for _, mod in _pairs(__LastSpell.lastSpell.modules) do
                    local func = mod.SaveSpellcastInfo
                    if func then
                        func(mod, spellcast, atTime, self)
                    end
                end
            end
            self.lastSpellId = spellId
            self.startCast = startCast
            self.endCast = endCast
            self.lastCast[spellId] = endCast
            self.channel = channel
            local gcd = self:GetGCD(spellId, startCast, targetGUID)
            local nextCast = (castTime > gcd) and endCast or (startCast + gcd)
            if self.nextCast < nextCast then
                self.nextCast = nextCast
            end
            if gcd > 0 then
                self:PushGCDSpellId(spellId)
            else
                self.lastOffGCDSpellId = spellId
            end
            local now = API_GetTime()
            if startCast >= now then
                __State.baseState.currentTime = startCast + SIMULATOR_LAG
            else
                __State.baseState.currentTime = now
            end
            __Future.OvaleFuture:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, __State.baseState.currentTime, nextCast, endCast, targetGUID)
            if  not self.inCombat and __SpellBook.OvaleSpellBook:IsHarmfulSpell(spellId) then
                self.inCombat = true
                if channel then
                    self.combatStartTime = startCast
                else
                    self.combatStartTime = endCast
                end
            end
            if startCast > now then
                __State.OvaleState:ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            if endCast > now then
                __State.OvaleState:ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            __State.OvaleState:ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast)
        end
        __Future.OvaleFuture:StopProfiling("OvaleFuture_state_ApplySpell")
    end,
    GetDamageMultiplier = function(self, spellId, targetGUID, atTime)
        return __Future.OvaleFuture:GetDamageMultiplier(spellId, targetGUID, atTime)
    end,
    UpdateCounters = function(self, spellId, atTime, targetGUID)
        return __Future.OvaleFuture:UpdateCounters(spellId, atTime, targetGUID)
    end,
    ApplyInFlightSpells = function(self)
        local now = API_GetTime()
        local index = 1
        while index <= #__LastSpell.lastSpell.queue do
            local spellcast = __LastSpell.lastSpell.queue[index]
            if spellcast.stop then
                local isValid = false
                local description
                if now < spellcast.stop then
                    isValid = true
                    description = spellcast.channel and "channelling" or "being cast"
                elseif now < spellcast.stop + 5 then
                    isValid = true
                    description = "in flight"
                end
                if isValid then
                    if spellcast.target then
                        __State.OvaleState:Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop)
                    else
                        __State.OvaleState:Log("Active spell %s (%d) is %s, now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop)
                    end
                    self:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast)
                else
                    tremove(__LastSpell.lastSpell.queue, index)
                    __LastSpell.self_pool:Release(spellcast)
                    index = index - 1
                end
            end
            index = index + 1
        end
    end,
    GetGCD = function(self, spellId, atTime, targetGUID)
        spellId = spellId or __exports.futureState.currentSpellId
        if  not atTime then
            if __exports.futureState.endCast and __exports.futureState.endCast > __State.baseState.currentTime then
                atTime = __exports.futureState.endCast
            else
                atTime = __State.baseState.currentTime
            end
        end
        targetGUID = targetGUID or __GUID.OvaleGUID:UnitGUID(__State.baseState.defaultTarget)
        local gcd = spellId and __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID)
        if  not gcd then
            local haste
            gcd, haste = __Cooldown.OvaleCooldown:GetBaseGCD()
            if __Ovale.Ovale.playerClass == "MONK" and __PaperDoll.OvalePaperDoll:IsSpecialization("mistweaver") then
                gcd = 1.5
                haste = "spell"
            elseif __Ovale.Ovale.playerClass == "DRUID" then
                if __Stance.OvaleStance:IsStance("druid_cat_form") then
                    gcd = 1
                    haste = false
                end
            end
            local gcdHaste = spellId and __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID)
            if gcdHaste then
                haste = gcdHaste
            else
                local siHaste = spellId and __DataState.dataState:GetSpellInfoProperty(spellId, atTime, "haste", targetGUID)
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
    constructor = function(self)
        self.inCombat = nil
        self.combatStartTime = nil
        self.currentSpellId = nil
        self.startCast = nil
        self.endCast = nil
        self.nextCast = nil
        self.lastCast = nil
        self.channel = nil
        self.lastSpellId = nil
        self.lastGCDSpellId = nil
        self.lastGCDSpellIds = {}
        self.lastOffGCDSpellId = nil
        self.counter = nil
        self.staticSpellcast = {}
    end
})
__exports.futureState = FutureState()
__State.OvaleState:RegisterState(__exports.futureState)
end)
