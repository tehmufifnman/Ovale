local OVALE, Ovale = ...
local OvaleQueue = {}
Ovale.OvaleQueue = OvaleQueue
local _setmetatable = setmetatable
OvaleQueue.name = "OvaleQueue"
OvaleQueue.first = 1
OvaleQueue.last = 0
OvaleQueue.__index = OvaleQueue
local BackToFrontIterator = function(invariant, control)
    control = control - 1
    local element = invariant[control]
    if element then
        return control, element
    end
end
local FrontToBackIterator = function(invariant, control)
    control = control + 1
    local element = invariant[control]
    if element then
        return control, element
    end
end
local OvaleQueue = __class()
function OvaleQueue:NewDeque(name)
    return _setmetatable({
        name = name,
        first = 0,
        last = -1
    }, OvaleQueue)
end
function OvaleQueue:InsertFront(element)
    local first = self.first - 1
    self.first = first
    self[first] = element
end
function OvaleQueue:InsertBack(element)
    local last = self.last + 1
    self.last = last
    self[last] = element
end
function OvaleQueue:RemoveFront()
    local first = self.first
    local element = self[first]
    if element then
        self[first] = nil
        self.first = first + 1
    end
    return element
end
function OvaleQueue:RemoveBack()
    local last = self.last
    local element = self[last]
    if element then
        self[last] = nil
        self.last = last - 1
    end
    return element
end
function OvaleQueue:At(index)
    if index > self:Size() then
        break
    end
    return self[self.first + index - 1]
end
function OvaleQueue:Front()
    return self[self.first]
end
function OvaleQueue:Back()
    return self[self.last]
end
function OvaleQueue:BackToFrontIterator()
    return BackToFrontIterator, self, self.last + 1
end
function OvaleQueue:FrontToBackIterator()
    return FrontToBackIterator, self, self.first - 1
end
function OvaleQueue:Reset()
    for i in self:BackToFrontIterator() do
        self[i] = nil
    end
    self.first = 0
    self.last = -1
end
function OvaleQueue:Size()
    return self.last - self.first + 1
end
function OvaleQueue:DebuggingInfo()
    Ovale:Print("Queue %s has %d item(s), first=%d, last=%d.", self.name, self:Size(), self.first, self.last)
end
OvaleQueue.NewQueue = OvaleQueue.NewDeque
OvaleQueue.Insert = OvaleQueue.InsertBack
OvaleQueue.Remove = OvaleQueue.RemoveFront
OvaleQueue.Iterator = OvaleQueue.FrontToBackIterator
OvaleQueue.NewStack = OvaleQueue.NewDeque
OvaleQueue.Push = OvaleQueue.InsertBack
OvaleQueue.Pop = OvaleQueue.RemoveBack
OvaleQueue.Top = OvaleQueue.Back
