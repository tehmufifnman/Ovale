local OVALE, Ovale = ...
local OvaleTimeSpan = {}
Ovale.OvaleTimeSpan = OvaleTimeSpan
local _select = select
local _setmetatable = setmetatable
local format = string.format
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local _type = type
local _wipe = wipe
local INFINITY = math.huge
local self_pool = {}
local self_poolSize = 0
local self_poolUnused = 0
local EMPTY_SET = _setmetatable({}, OvaleTimeSpan)
local UNIVERSE = _setmetatable({
    1 = 0,
    2 = INFINITY
}, OvaleTimeSpan)
OvaleTimeSpan.__index = OvaleTimeSpan
do
    _setmetatable(OvaleTimeSpan, {
        __call = function(self, ...)
            return self:New(...)
        end
    })
end
OvaleTimeSpan.EMPTY_SET = EMPTY_SET
OvaleTimeSpan.UNIVERSE = UNIVERSE
local CompareIntervals = function(startA, endA, startB, endB)
    if startA == startB and endA == endB then
        return 0
    elseif startA < startB and endA >= startB and endA <= endB then
        return -1
    elseif startB < startA and endB >= startA and endB <= endA then
        return 1
    elseif (startA == startB and endA > endB) or (startA < startB and endA == endB) or (startA < startB and endA > endB) then
        return -2
    elseif (startB == startA and endB > endA) or (startB < startA and endB == endA) or (startB < startA and endB > endA) then
        return 2
    elseif endA <= startB then
        return -3
    elseif endB <= startA then
        return 3
    end
    return 99
end
local OvaleTimeSpan = __class()
function OvaleTimeSpan:New(...)
    local obj = tremove(self_pool)
    if obj then
        self_poolUnused = self_poolUnused - 1
    else
        obj = {}
        self_poolSize = self_poolSize + 1
    end
    _setmetatable(obj, self)
    obj = OvaleTimeSpan:Copy(obj, ...)
    return obj
end
function OvaleTimeSpan:Release(...)
    local A = ...
    if A then
        local argc = _select("#", ...)
        for i = 1, argc, 1 do
            A = _select(i, ...)
            _wipe(A)
            tinsert(self_pool, A)
        end
        self_poolUnused = self_poolUnused + argc
    else
        _wipe(self)
        tinsert(self_pool, self)
        self_poolUnused = self_poolUnused + 1
    end
end
function OvaleTimeSpan:GetPoolInfo()
    return self_poolSize, self_poolUnused
end
function OvaleTimeSpan:__tostring()
    if #self == 0 then
        return "empty set"
    else
        return format("(%s)", tconcat(self, ", "))
    end
end
function OvaleTimeSpan:Copy(...)
    local A = ...
    local count = 0
    if _type(A) == "table" then
        count = #A
        for i = 1, count, 1 do
            self[i] = A[i]
        end
    else
        count = _select("#", ...)
        for i = 1, count, 1 do
            self[i] = _select(i, ...)
        end
    end
    for i = count + 1, #self, 1 do
        self[i] = nil
    end
    return self
end
function OvaleTimeSpan:IsEmpty()
    return #self == 0
end
function OvaleTimeSpan:IsUniverse()
    return self[1] == 0 and self[2] == INFINITY
end
function OvaleTimeSpan:Equals(B)
    local A = self
    local countA = #A
    local countB = B and #B or 0
    if countA ~= countB then
        return false
    end
    for k = 1, countA, 1 do
        if A[k] ~= B[k] then
            return false
        end
    end
    return true
end
function OvaleTimeSpan:HasTime(atTime)
    local A = self
    for i = 1, #A, 2 do
        if A[i] <= atTime and atTime <= A[i + 1] then
            return true
        end
    end
    return false
end
function OvaleTimeSpan:NextTime(atTime)
    local A = self
    for i = 1, #A, 2 do
        if atTime < A[i] then
            return A[i]
        elseif A[i] <= atTime and atTime <= A[i + 1] then
            return atTime
        end
    end
end
function OvaleTimeSpan:Measure()
    local A = self
    local measure = 0
    for i = 1, #A, 2 do
        measure = measure + (A[i + 1] - A[i])
    end
    return measure
end
function OvaleTimeSpan:Complement(result)
    local A = self
    local countA = #A
    if countA == 0 then
        if result then
            result:Copy(UNIVERSE)
        else
            result = OvaleTimeSpan:New(UNIVERSE)
        end
    else
        result = result or OvaleTimeSpan:New()
        local countResult = 0
        local i, k = 1, 1
        if A[i] == 0 then
            i = i + 1
        else
            result[k] = 0
            countResult = k
            k = k + 1
        end
        while i < countAdo
            result[k] = A[i]
            countResult = k
            i, k = i + 1, k + 1
end
        if A[i] < INFINITY then
            result[k], result[k + 1] = A[i], INFINITY
            countResult = k + 1
        end
        for j = countResult + 1, #result, 1 do
            result[j] = nil
        end
    end
    return result
end
function OvaleTimeSpan:IntersectInterval(startB, endB, result)
    local A = self
    local countA = #A
    result = result or OvaleTimeSpan:New()
    if countA > 0 and startB and endB then
        local countResult = 0
        local i, k = 1, 1
        while truedo
            if i > countA then
                break
            end
            local startA, endA = A[i], A[i + 1]
            local compare = CompareIntervals(startA, endA, startB, endB)
            if compare == 0 then
                result[k], result[k + 1] = startA, endA
                countResult = k + 1
                break
            elseif compare == -1 then
                if endA > startB then
                    result[k], result[k + 1] = startB, endA
                    countResult = k + 1
                    i, k = i + 2, k + 2
                else
                    i = i + 2
                end
            elseif compare == 1 then
                if endB > startA then
                    result[k], result[k + 1] = startA, endB
                    countResult = k + 1
                end
                break
            elseif compare == -2 then
                result[k], result[k + 1] = startB, endB
                countResult = k + 1
                break
            elseif compare == 2 then
                result[k], result[k + 1] = startA, endA
                countResult = k + 1
                i, k = i + 2, k + 2
            elseif compare == -3 then
                i = i + 2
            elseif compare == 3 then
                break
            end
end
        for n = countResult + 1, #result, 1 do
            result[n] = nil
        end
    end
    return result
end
function OvaleTimeSpan:Intersect(B, result)
    local A = self
    local countA = #A
    local countB = B and #B or 0
    result = result or OvaleTimeSpan:New()
    local countResult = 0
    if countA > 0 and countB > 0 then
        local i, j, k = 1, 1, 1
        while truedo
            if i > countA or j > countB then
                break
            end
            local startA, endA = A[i], A[i + 1]
            local startB, endB = B[j], B[j + 1]
            local compare = CompareIntervals(startA, endA, startB, endB)
            if compare == 0 then
                result[k], result[k + 1] = startA, endA
                countResult = k + 1
                i, j, k = i + 2, j + 2, k + 2
            elseif compare == -1 then
                if endA > startB then
                    result[k], result[k + 1] = startB, endA
                    countResult = k + 1
                    i, k = i + 2, k + 2
                else
                    i = i + 2
                end
            elseif compare == 1 then
                if endB > startA then
                    result[k], result[k + 1] = startA, endB
                    countResult = k + 1
                    j, k = j + 2, k + 2
                else
                    j = j + 2
                end
            elseif compare == -2 then
                result[k], result[k + 1] = startB, endB
                countResult = k + 1
                j, k = j + 2, k + 2
            elseif compare == 2 then
                result[k], result[k + 1] = startA, endA
                countResult = k + 1
                i, k = i + 2, k + 2
            elseif compare == -3 then
                i = i + 2
            elseif compare == 3 then
                j = j + 2
            else
                i = i + 2
                j = j + 2
            end
end
    end
    for n = countResult + 1, #result, 1 do
        result[n] = nil
    end
    return result
end
function OvaleTimeSpan:Union(B, result)
    local A = self
    local countA = #A
    local countB = B and #B or 0
    if countA == 0 then
        if B then
            if result then
                result:Copy(B)
            else
                result = OvaleTimeSpan:New(B)
            end
        end
    elseif countB == 0 then
        if result then
            result:Copy(A)
        else
            result = OvaleTimeSpan:New(A)
        end
    else
        result = result or OvaleTimeSpan:New()
        local countResult = 0
        local i, j, k = 1, 1, 1
        local startTemp, endTemp = A[i], A[i + 1]
        local holdingA = true
        local scanningA = false
        while truedo
            local startA, endA, startB, endB
            if i > countA and j > countB then
                result[k], result[k + 1] = startTemp, endTemp
                countResult = k + 1
                k = k + 2
                break
            end
            if scanningA and i > countA then
                holdingA =  not holdingA
                scanningA =  not scanningA
            else
                startA, endA = A[i], A[i + 1]
            end
            if  not scanningA and j > countB then
                holdingA =  not holdingA
                scanningA =  not scanningA
            else
                startB, endB = B[j], B[j + 1]
            end
            local startCurrent = scanningA and startA or startB
            local endCurrent = scanningA and endA or endB
            local compare = CompareIntervals(startTemp, endTemp, startCurrent, endCurrent)
            if compare == 0 then
                if scanningA then
                    i = i + 2
                else
                    j = j + 2
                end
            elseif compare == -2 then
                if scanningA then
                    i = i + 2
                else
                    j = j + 2
                end
            elseif compare == -1 then
                endTemp = endCurrent
                if scanningA then
                    i = i + 2
                else
                    j = j + 2
                end
            elseif compare == 1 then
                startTemp = startCurrent
                if scanningA then
                    i = i + 2
                else
                    j = j + 2
                end
            elseif compare == 2 then
                startTemp, endTemp = startCurrent, endCurrent
                holdingA =  not holdingA
                scanningA =  not scanningA
                if scanningA then
                    i = i + 2
                else
                    j = j + 2
                end
            elseif compare == -3 then
                if holdingA == scanningA then
                    result[k], result[k + 1] = startTemp, endTemp
                    countResult = k + 1
                    startTemp, endTemp = startCurrent, endCurrent
                    scanningA =  not scanningA
                    k = k + 2
                else
                    scanningA =  not scanningA
                    if scanningA then
                        i = i + 2
                    else
                        j = j + 2
                    end
                end
            elseif compare == 3 then
                startTemp, endTemp = startCurrent, endCurrent
                holdingA =  not holdingA
                scanningA =  not scanningA
            else
                i = i + 2
                j = j + 2
            end
end
        for n = countResult + 1, #result, 1 do
            result[n] = nil
        end
    end
    return result
end
