local __addonName, __addon = ...
            __addon.require("./LastSpell", { "./Pool" }, function(__exports, __Pool)
local _pairs = pairs
local tremove = table.remove
local tinsert = table.insert
__exports.self_pool = __Pool.OvalePool("OvaleFuture_pool")
local LastSpell = __addon.__class(nil, {
    LastInFlightSpell = function(self)
        local spellcast
        if self.lastGCDSpellcast.success then
            spellcast = self.lastGCDSpellcast
        end
        for i = #self.queue, 1, -1 do
            local sc = self.queue[i]
            if sc.success then
                if  not spellcast or spellcast.success < sc.success then
                    spellcast = sc
                end
                break
            end
        end
        return spellcast
    end,
    CopySpellcastInfo = function(self, spellcast, dest)
        if spellcast.damageMultiplier then
            dest.damageMultiplier = spellcast.damageMultiplier
        end
        for _, mod in _pairs(self.modules) do
            local func = mod.CopySpellcastInfo
            if func then
                func(mod, spellcast, dest)
            end
        end
    end,
    RegisterSpellcastInfo = function(self, mod)
        tinsert(self.modules, mod)
    end,
    UnregisterSpellcastInfo = function(self, mod)
        for i = #self.modules, 1, -1 do
            if self.modules[i] == mod then
                tremove(self.modules, i)
            end
        end
    end,
    LastSpellSent = function(self)
        local spellcast = nil
        if self.lastGCDSpellcast.success then
            spellcast = self.lastGCDSpellcast
        end
        for i = #self.queue, 1, -1 do
            local sc = self.queue[i]
            if sc.success then
                if  not spellcast or (spellcast.success and spellcast.success < sc.success) or ( not spellcast.success and spellcast.queued < sc.success) then
                    spellcast = sc
                end
            elseif  not sc.start and  not sc.stop then
                if spellcast.success and spellcast.success < sc.queued then
                    spellcast = sc
                elseif spellcast.queued < sc.queued then
                    spellcast = sc
                end
            end
        end
        return spellcast
    end,
    constructor = function(self)
        self.lastSpellcast = nil
        self.lastGCDSpellcast = {}
        self.queue = {}
        self.modules = {}
    end
})
__exports.lastSpell = LastSpell()
end)
