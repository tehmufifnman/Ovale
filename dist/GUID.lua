local OVALE, Ovale = ...
require(OVALE, Ovale, "GUID", { "./OvaleDebug" }, function(__exports, __OvaleDebug)
local OvaleGUID = Ovale:NewModule("OvaleGUID", "AceEvent-3.0")
Ovale.OvaleGUID = OvaleGUID
local floor = math.floor
local _ipairs = ipairs
local _setmetatable = setmetatable
local tinsert = table.insert
local tremove = table.remove
local _type = type
local _unpack = unpack
local API_GetTime = GetTime
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleGUID)
local PET_UNIT = {}
do
    PET_UNIT["player"] = "pet"
    for i = 1, 5, 1 do
        PET_UNIT["arena" + i] = "arenapet" + i
    end
    for i = 1, 4, 1 do
        PET_UNIT["party" + i] = "partypet" + i
    end
    for i = 1, 40, 1 do
        PET_UNIT["raid" + i] = "raidpet" + i
    end
    _setmetatable(PET_UNIT, {
        __index = function(t, unitId)
            return unitId + "pet"
        end
    })
end
local UNIT_AURA_UNITS = {}
do
    tinsert(UNIT_AURA_UNITS, "player")
    tinsert(UNIT_AURA_UNITS, "pet")
    tinsert(UNIT_AURA_UNITS, "vehicle")
    tinsert(UNIT_AURA_UNITS, "target")
    tinsert(UNIT_AURA_UNITS, "focus")
    for i = 1, 40, 1 do
        local unitId = "raid" + i
        tinsert(UNIT_AURA_UNITS, unitId)
        tinsert(UNIT_AURA_UNITS, PET_UNIT[unitId])
    end
    for i = 1, 4, 1 do
        local unitId = "party" + i
        tinsert(UNIT_AURA_UNITS, unitId)
        tinsert(UNIT_AURA_UNITS, PET_UNIT[unitId])
    end
    for i = 1, 4, 1 do
        tinsert(UNIT_AURA_UNITS, "boss" + i)
    end
    for i = 1, 5, 1 do
        local unitId = "arena" + i
        tinsert(UNIT_AURA_UNITS, unitId)
        tinsert(UNIT_AURA_UNITS, PET_UNIT[unitId])
    end
    tinsert(UNIT_AURA_UNITS, "npc")
end
local UNIT_AURA_UNIT = {}
do
    for i, unitId in _ipairs(UNIT_AURA_UNITS) do
        UNIT_AURA_UNIT[unitId] = i
    end
    _setmetatable(UNIT_AURA_UNIT, {
        __index = function(t, unitId)
            return #UNIT_AURA_UNITS + 1
        end
    })
end
OvaleGUID.unitGUID = {}
OvaleGUID.guidUnit = {}
OvaleGUID.unitName = {}
OvaleGUID.nameUnit = {}
OvaleGUID.guidName = {}
OvaleGUID.nameGUID = {}
OvaleGUID.petGUID = {}
OvaleGUID.UNIT_AURA_UNIT = UNIT_AURA_UNIT
local BinaryInsert
local BinaryRemove
local BinarySearch
do
    local compareDefault = function(a, b)
        return a < b
    end
    BinaryInsert = function(t, value, unique, compare)
        if _type(unique) == "function" then
            unique, compare = nil, unique
        end
        compare = compare or compareDefault
        local low, high = 1, #t
        while low <= highdo
            local mid = floor((low + high) / 2)
            if compare(value, t[mid]) then
                high = mid - 1
            elseif  not unique or compare(t[mid], value) then
                low = mid + 1
            else
                return mid
            end
end
        tinsert(t, low, value)
        return low
    end
    BinaryRemove = function(t, value, compare)
        local index = BinarySearch(t, value, compare)
        if index then
            tremove(t, index)
        end
        return index
    end
    BinarySearch = function(t, value, compare)
        compare = compare or compareDefault
        local low, high = 1, #t
        while low <= highdo
            local mid = floor((low + high) / 2)
            if compare(value, t[mid]) then
                high = mid - 1
            elseif compare(t[mid], value) then
                low = mid + 1
            else
                return mid
            end
end
        return nil
    end
end
local CompareUnit = function(a, b)
    return UNIT_AURA_UNIT[a] < UNIT_AURA_UNIT[b]
end
local OvaleGUID = __class()
function OvaleGUID:OnEnable()
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllUnits")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("UNIT_TARGET")
end
function OvaleGUID:OnDisable()
    self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
    self:UnregisterEvent("GROUP_ROSTER_UPDATE")
    self:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("UNIT_NAME_UPDATE")
    self:UnregisterEvent("UNIT_PET")
    self:UnregisterEvent("UNIT_TARGET")
end
function OvaleGUID:ARENA_OPPONENT_UPDATE(event, unitId, eventType)
    if eventType ~= "cleared" or self.unitGUID[unitId] then
        self:Debug(event, unitId, eventType)
        self:UpdateUnitWithTarget(unitId)
    end
end
function OvaleGUID:GROUP_ROSTER_UPDATE(event)
    self:Debug(event)
    self:UpdateAllUnits()
    self:SendMessage("Ovale_GroupChanged")
end
function OvaleGUID:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
    self:Debug(event)
    for i = 1, 4, 1 do
        self:UpdateUnitWithTarget("boss" + i)
    end
end
function OvaleGUID:PLAYER_FOCUS_CHANGED(event)
    self:Debug(event)
    self:UpdateUnitWithTarget("focus")
end
function OvaleGUID:PLAYER_TARGET_CHANGED(event, cause)
    self:Debug(event, cause)
    self:UpdateUnit("target")
end
function OvaleGUID:UNIT_NAME_UPDATE(event, unitId)
    self:Debug(event, unitId)
    self:UpdateUnit(unitId)
end
function OvaleGUID:UNIT_PET(event, unitId)
    self:Debug(event, unitId)
    local pet = PET_UNIT[unitId]
    self:UpdateUnitWithTarget(pet)
    if unitId == "player" then
        local guid = self:UnitGUID("pet")
        if guid then
            self.petGUID[guid] = API_GetTime()
        end
        self:SendMessage("Ovale_PetChanged", guid)
    end
    self:SendMessage("Ovale_GroupChanged")
end
function OvaleGUID:UNIT_TARGET(event, unitId)
    if unitId ~= "player" then
        self:Debug(event, unitId)
        local target = unitId + "target"
        self:UpdateUnit(target)
    end
end
function OvaleGUID:UpdateAllUnits()
    for _, unitId in _ipairs(UNIT_AURA_UNITS) do
        self:UpdateUnitWithTarget(unitId)
    end
end
function OvaleGUID:UpdateUnit(unitId)
    local guid = API_UnitGUID(unitId)
    local name = API_UnitName(unitId)
    local previousGUID = self.unitGUID[unitId]
    local previousName = self.unitName[unitId]
    if  not guid or guid ~= previousGUID then
        self.unitGUID[unitId] = nil
        if previousGUID then
            if self.guidUnit[previousGUID] then
                BinaryRemove(self.guidUnit[previousGUID], unitId, CompareUnit)
            end
            Ovale.refreshNeeded[previousGUID] = true
        end
    end
    if  not name or name ~= previousName then
        self.unitName[unitId] = nil
        if previousName and self.nameUnit[previousName] then
            BinaryRemove(self.nameUnit[previousName], unitId, CompareUnit)
        end
    end
    if guid and guid == previousGUID and name and name ~= previousName then
        self.guidName[guid] = nil
        if previousName and self.nameGUID[previousName] then
            BinaryRemove(self.nameGUID[previousName], guid, CompareUnit)
        end
    end
    if guid and guid ~= previousGUID then
        self.unitGUID[unitId] = guid
        do
            local list = self.guidUnit[guid] or {}
            BinaryInsert(list, unitId, true, CompareUnit)
            self.guidUnit[guid] = list
        end
        self:Debug("'%s' is '%s'.", unitId, guid)
        Ovale.refreshNeeded[guid] = true
    end
    if name and name ~= previousName then
        self.unitName[unitId] = name
        do
            local list = self.nameUnit[name] or {}
            BinaryInsert(list, unitId, true, CompareUnit)
            self.nameUnit[name] = list
        end
        self:Debug("'%s' is '%s'.", unitId, name)
    end
    if guid and name then
        local previousNameFromGUID = self.guidName[guid]
        self.guidName[guid] = name
        if name ~= previousNameFromGUID then
            local list = self.nameGUID[name] or {}
            BinaryInsert(list, guid, true)
            self.nameGUID[name] = list
            if guid == previousGUID then
                self:Debug("'%s' changed names to '%s'.", guid, name)
            else
                self:Debug("'%s' is '%s'.", guid, name)
            end
        end
    end
    if guid and guid ~= previousGUID then
        self:SendMessage("Ovale_UnitChanged", unitId, guid)
    end
end
function OvaleGUID:UpdateUnitWithTarget(unitId)
    self:UpdateUnit(unitId)
    self:UpdateUnit(unitId + "target")
end
function OvaleGUID:IsPlayerPet(guid)
    local atTime = self.petGUID[guid]
    return ( not  not atTime), atTime
end
function OvaleGUID:UnitGUID(unitId)
    if unitId then
        return self.unitGUID[unitId] or API_UnitGUID(unitId)
    end
    return nil
end
function OvaleGUID:GUIDUnit(guid)
    if guid and self.guidUnit[guid] then
        return _unpack(self.guidUnit[guid])
    end
    return nil
end
function OvaleGUID:UnitName(unitId)
    if unitId then
        return self.unitName[unitId] or API_UnitName(unitId)
    end
    return nil
end
function OvaleGUID:NameUnit(name)
    if name and self.nameUnit[name] then
        return _unpack(self.nameUnit[name])
    end
    return nil
end
function OvaleGUID:GUIDName(guid)
    if guid then
        return self.guidName[guid]
    end
    return nil
end
function OvaleGUID:NameGUID(name)
    if name and self.nameGUID[name] then
        return _unpack(self.nameGUID[name])
    end
    return nil
end
end))
