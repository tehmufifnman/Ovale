local __addonName, __addon = ...
            __addon.require("./Cooldown", { "./Debug", "./Profiler", "./Data", "./SpellBook", "./Ovale", "./LastSpell", "./Requirement", "./DataState", "AceEvent-3.0" }, function(__exports, __Debug, __Profiler, __Data, __SpellBook, __Ovale, __LastSpell, __Requirement, __DataState, aceEvent)
local OvaleCooldownBase = __Ovale.Ovale:NewModule("OvaleCooldown", aceEvent)
local _next = next
local _pairs = pairs
local API_GetSpellCooldown = GetSpellCooldown
local API_GetTime = GetTime
local GLOBAL_COOLDOWN = 61304
local COOLDOWN_THRESHOLD = 0.1
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
local OvaleCooldownClass = __addon.__class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleCooldownBase)), {
    constructor = function(self)
        self.serial = 0
        self.sharedCooldown = {}
        self.gcd = {
            serial = 0,
            start = 0,
            duration = 0
        }
        self.SaveSpellcastInfo = function(mod, spellcast, atTime, state)
            local spellId = spellcast.spellId
            if spellId then
                local gcd
                if state then
                    gcd = state:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
                else
                    gcd = __Data.OvaleData:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
                end
                if gcd and gcd == 0 then
                    spellcast.offgcd = true
                end
            end
        end
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleCooldownBase)).constructor(self)
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
        __LastSpell.lastSpell:RegisterSpellcastInfo(self)
        __Requirement.RegisterRequirement("oncooldown", "RequireCooldownHandler", self)
    end,
    OnDisable = function(self)
        __LastSpell.lastSpell:UnregisterSpellcastInfo(self)
        __Requirement.UnregisterRequirement("oncooldown")
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
            __Ovale.Ovale:needRefresh()
            self:Debug(event, self.serial)
        end
    end,
    ResetSharedCooldowns = function(self)
        for _, spellTable in _pairs(self.sharedCooldown) do
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
})
__exports.OvaleCooldown = OvaleCooldownClass()
end)
