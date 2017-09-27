local OVALE, Ovale = ...
require(OVALE, Ovale, "BossMod", { "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __OvaleDebug, __OvaleProfiler)
local OvaleBossMod = Ovale:NewModule("OvaleBossMod")
Ovale.OvaleBossMod = OvaleBossMod
local API_GetNumGroupMembers = GetNumGroupMembers
local API_IsInGroup = IsInGroup
local API_IsInInstance = IsInInstance
local API_IsInRaid = IsInRaid
local API_UnitExists = UnitExists
local API_UnitLevel = UnitLevel
local _BigWigsLoader = BigWigsLoader
local _DBM = DBM
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleBossMod)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleBossMod)
local OvaleBossMod = __class()
function OvaleBossMod:OnInitialize()
    OvaleBossMod.EngagedDBM = nil
    OvaleBossMod.EngagedBigWigs = nil
end
function OvaleBossMod:OnEnable()
    if _DBM then
        self:Debug("DBM is loaded")
        hooksecurefunc(_DBM, "StartCombat", function(_DBM, mod, delay, event, ...)
            if event ~= "TIMER_RECOVERY" then
                OvaleBossMod.EngagedDBM = mod
            end
        end)
        hooksecurefunc(_DBM, "EndCombat", function(_DBM, mod)
            OvaleBossMod.EngagedDBM = nil
        end)
    end
    if _BigWigsLoader then
        self:Debug("BigWigs is loaded")
        _BigWigsLoader:RegisterMessage(OvaleBossMod, "BigWigs_OnBossEngage", function(_, mod, diff)
            OvaleBossMod.EngagedBigWigs = mod
        end)
        _BigWigsLoader:RegisterMessage(OvaleBossMod, "BigWigs_OnBossDisable", function(_, mod)
            OvaleBossMod.EngagedBigWigs = nil
        end)
    end
end
function OvaleBossMod:OnDisable()
end
function OvaleBossMod:IsBossEngaged(state)
    if  not state.inCombat then
        return false
    end
    local dbmEngaged = (_DBM ~= nil and OvaleBossMod.EngagedDBM ~= nil and OvaleBossMod.EngagedDBM.inCombat)
    local bigWigsEngaged = (_BigWigsLoader ~= nil and OvaleBossMod.EngagedBigWigs ~= nil and OvaleBossMod.EngagedBigWigs.isEngaged)
    local neitherEngaged = (_DBM == nil and _BigWigsLoader == nil and OvaleBossMod:ScanTargets())
    if dbmEngaged then
        self:Debug("DBM Engaged: [name=%s]", OvaleBossMod.EngagedDBM.localization.general.name)
    end
    if bigWigsEngaged then
        self:Debug("BigWigs Engaged: [name=%s]", OvaleBossMod.EngagedBigWigs.displayName)
    end
    return dbmEngaged or bigWigsEngaged or neitherEngaged
end
function OvaleBossMod:ScanTargets()
    self:StartProfiling("OvaleBossMod:ScanTargets")
    local RecursiveScanTargets = function(target, depth)
        local isWorldBoss = false
        local dep = depth or 1
        local isWorldBoss = target ~= nil and API_UnitExists(target) and API_UnitLevel(target) < 0
        if isWorldBoss then
            self:Debug("%s is worldboss (%s)", target, UnitName(target))
        end
        return isWorldBoss or (dep <= 3 and RecursiveScanTargets(target + "target", dep + 1))
    end
    local bossEngaged = false
    bossEngaged = bossEngaged or API_UnitExists("boss1") or API_UnitExists("boss2") or API_UnitExists("boss3") or API_UnitExists("boss4")
    bossEngaged = bossEngaged or RecursiveScanTargets("target") or RecursiveScanTargets("pet") or RecursiveScanTargets("focus") or RecursiveScanTargets("focuspet") or RecursiveScanTargets("mouseover") or RecursiveScanTargets("mouseoverpet")
    if  not bossEngaged then
        if (API_IsInInstance() and API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
            for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE), 1 do
                bossEngaged = bossEngaged or RecursiveScanTargets("party" + i) or RecursiveScanTargets("party" + i + "pet")
            end
        end
        if ( not API_IsInInstance() and API_IsInGroup(LE_PARTY_CATEGORY_HOME) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
            for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), 1 do
                bossEngaged = bossEngaged or RecursiveScanTargets("party" + i) or RecursiveScanTargets("party" + i + "pet")
            end
        end
        if (API_IsInInstance() and API_IsInRaid(LE_PARTY_CATEGORY_INSTANCE) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
            for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE), 1 do
                bossEngaged = bossEngaged or RecursiveScanTargets("raid" + i) or RecursiveScanTargets("raid" + i + "pet")
            end
        end
        if ( not API_IsInInstance() and API_IsInRaid(LE_PARTY_CATEGORY_HOME) and API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
            for i = 1, API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), 1 do
                bossEngaged = bossEngaged or RecursiveScanTargets("raid" + i) or RecursiveScanTargets("raid" + i + "pet")
            end
        end
    end
    self:StopProfiling("OvaleBossMod:ScanTargets")
    return bossEngaged
end
end))
