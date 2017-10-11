local __addonName, __addon = ...
            __addon.require("./BossMod", { "./Debug", "./Profiler", "./Ovale", "./State" }, function(__exports, __Debug, __Profiler, __Ovale, __State)
local OvaleBossModBase = __Ovale.Ovale:NewModule("OvaleBossMod")
local API_GetNumGroupMembers = GetNumGroupMembers
local API_IsInGroup = IsInGroup
local API_IsInInstance = IsInInstance
local API_IsInRaid = IsInRaid
local API_UnitExists = UnitExists
local API_UnitLevel = UnitLevel
local _BigWigsLoader = BigWigsLoader
local _DBM = DBM
local OvaleBossModClass = __addon.__class(__Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleBossModBase)), {
    constructor = function(self)
        self.EngagedDBM = nil
        self.EngagedBigWigs = nil
        __Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleBossModBase)).constructor(self)
        if _DBM then
            self:Debug("DBM is loaded")
            hooksecurefunc(_DBM, "StartCombat", function(_DBM, mod, delay, event, ...)
                if event ~= "TIMER_RECOVERY" then
                    self.EngagedDBM = mod
                end
            end)
            hooksecurefunc(_DBM, "EndCombat", function(_DBM, mod)
                self.EngagedDBM = nil
            end)
        end
        if _BigWigsLoader then
            self:Debug("BigWigs is loaded")
            _BigWigsLoader:RegisterMessage(__exports.OvaleBossMod, "BigWigs_OnBossEngage", function(_, mod, diff)
                self.EngagedBigWigs = mod
            end)
            _BigWigsLoader:RegisterMessage(__exports.OvaleBossMod, "BigWigs_OnBossDisable", function(_, mod)
                self.EngagedBigWigs = nil
            end)
        end
    end,
    OnDisable = function(self)
    end,
    IsBossEngaged = function(self, state)
        if  not state.inCombat then
            return false
        end
        local dbmEngaged = (_DBM ~= nil and self.EngagedDBM ~= nil and self.EngagedDBM.inCombat)
        local bigWigsEngaged = (_BigWigsLoader ~= nil and self.EngagedBigWigs ~= nil and self.EngagedBigWigs.isEngaged)
        local neitherEngaged = (_DBM == nil and _BigWigsLoader == nil and self:ScanTargets())
        if dbmEngaged then
            self:Debug("DBM Engaged: [name=%s]", self.EngagedDBM.localization.general.name)
        end
        if bigWigsEngaged then
            self:Debug("BigWigs Engaged: [name=%s]", self.EngagedBigWigs.displayName)
        end
        return dbmEngaged or bigWigsEngaged or neitherEngaged
    end,
    ScanTargets = function(self)
        self:StartProfiling("OvaleBossMod:ScanTargets")
        local RecursiveScanTargets = function(target, depth)
            local isWorldBoss = false
            local dep = depth or 1
            isWorldBoss = target ~= nil and API_UnitExists(target) and API_UnitLevel(target) < 0
            if isWorldBoss then
                self:Debug("%s is worldboss (%s)", target, UnitName(target))
            end
            return isWorldBoss or (dep <= 3 and RecursiveScanTargets(target .. "target", dep + 1))
        end
        local bossEngaged = false
        bossEngaged = bossEngaged or API_UnitExists("boss1") or API_UnitExists("boss2") or API_UnitExists("boss3") or API_UnitExists("boss4")
        bossEngaged = bossEngaged or RecursiveScanTargets("target") or RecursiveScanTargets("pet") or RecursiveScanTargets("focus") or RecursiveScanTargets("focuspet") or RecursiveScanTargets("mouseover") or RecursiveScanTargets("mouseoverpet")
        if  not bossEngaged then
            if (API_IsInInstance() and API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
                for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("party" .. i) or RecursiveScanTargets("party" .. i .. "pet")
                end
            end
            if ( not API_IsInInstance() and API_IsInGroup(LE_PARTY_CATEGORY_HOME) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
                for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("party" .. i) or RecursiveScanTargets("party" .. i .. "pet")
                end
            end
            if (API_IsInInstance() and API_IsInRaid(LE_PARTY_CATEGORY_INSTANCE) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
                for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("raid" .. i) or RecursiveScanTargets("raid" .. i .. "pet")
                end
            end
            if ( not API_IsInInstance() and API_IsInRaid(LE_PARTY_CATEGORY_HOME) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
                for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("raid" .. i) or RecursiveScanTargets("raid" .. i .. "pet")
                end
            end
        end
        self:StopProfiling("OvaleBossMod:ScanTargets")
        return bossEngaged
    end,
})
__exports.OvaleBossMod = OvaleBossModClass()
end)
