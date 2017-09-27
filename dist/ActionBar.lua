local OVALE, Ovale = ...
require(OVALE, Ovale, "ActionBar", { "./L", "./OvaleDebug", "./OvaleProfiler" }, function(__exports, __L, __OvaleDebug, __OvaleProfiler)
local OvaleActionBar = Ovale:NewModule("OvaleActionBar", "AceEvent-3.0", "AceTimer-3.0")
Ovale.OvaleActionBar = OvaleActionBar
local OvaleSpellBook = nil
local gsub = string.gsub
local strlen = string.len
local strmatch = string.match
local strupper = string.upper
local tconcat = table.concat
local _tonumber = tonumber
local tsort = table.sort
local _wipe = wipe
local API_GetActionInfo = GetActionInfo
local API_GetActionText = GetActionText
local API_GetBindingKey = GetBindingKey
local API_GetBonusBarIndex = GetBonusBarIndex
local API_GetMacroItem = GetMacroItem
local API_GetMacroSpell = GetMacroSpell
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleActionBar)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleActionBar)
do
    local debugOptions = {
        actionbar = {
            name = __L.L["Action bar"],
            type = "group",
            args = {
                spellbook = {
                    name = __L.L["Action bar"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return OvaleActionBar:DebugActions()
                    end
                }
            }
        }
    }
    for k, v in pairs(debugOptions) do
        __OvaleDebug.OvaleDebug.options.args[k] = v
    end
end
OvaleActionBar.action = {}
OvaleActionBar.keybind = {}
OvaleActionBar.spell = {}
OvaleActionBar.macro = {}
OvaleActionBar.item = {}
local GetKeyBinding = function(slot)
    local name
    if Bartender4 then
        name = "CLICK BT4Button" + slot + ":LeftButton"
    else
        if slot <= 24 or slot > 72 then
            name = "ACTIONBUTTON" + (((slot - 1) % 12) + 1)
        elseif slot <= 36 then
            name = "MULTIACTIONBAR3BUTTON" + (slot - 24)
        elseif slot <= 48 then
            name = "MULTIACTIONBAR4BUTTON" + (slot - 36)
        elseif slot <= 60 then
            name = "MULTIACTIONBAR2BUTTON" + (slot - 48)
        else
            name = "MULTIACTIONBAR1BUTTON" + (slot - 60)
        end
    end
    local key = name and API_GetBindingKey(name)
    if key and strlen(key) > 4 then
        key = strupper(key)
        key = gsub(key, "%s+", "")
        key = gsub(key, "ALT%-", "A")
        key = gsub(key, "CTRL%-", "C")
        key = gsub(key, "SHIFT%-", "S")
        key = gsub(key, "NUMPAD", "N")
        key = gsub(key, "PLUS", "+")
        key = gsub(key, "MINUS", "-")
        key = gsub(key, "MULTIPLY", "*")
        key = gsub(key, "DIVIDE", "/")
    end
    return key
end
local ParseHyperlink = function(hyperlink)
    local color, linkType, linkData, text = strmatch(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
    return color, linkType, linkData, text
end
local OvaleActionBar = __class()
function OvaleActionBar:OnEnable()
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateActionSlots")
    self:RegisterEvent("UPDATE_BINDINGS")
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "UpdateActionSlots")
    self:RegisterMessage("Ovale_StanceChanged", "UpdateActionSlots")
    self:RegisterMessage("Ovale_TalentsChanged", "UpdateActionSlots")
    OvaleSpellBook = Ovale.OvaleSpellBook
end
function OvaleActionBar:OnDisable()
    self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("UPDATE_BINDINGS")
    self:UnregisterEvent("UPDATE_BONUS_ACTIONBAR")
    self:UnregisterMessage("Ovale_StanceChanged")
    self:UnregisterMessage("Ovale_TalentsChanged")
end
function OvaleActionBar:ACTIONBAR_SLOT_CHANGED(event, slot)
    slot = _tonumber(slot)
    if slot == 0 then
        self:UpdateActionSlots(event)
    elseif slot then
        local bonus = _tonumber(API_GetBonusBarIndex()) * 12
        local bonusStart = (bonus > 0) and (bonus - 11) or 1
        local isBonus = slot >= bonusStart and slot < bonusStart + 12
        if isBonus or slot > 12 and slot < 73 then
            self:UpdateActionSlot(slot)
        end
    end
end
function OvaleActionBar:UPDATE_BINDINGS(event)
    self:Debug("%s: Updating key bindings.", event)
    self:UpdateKeyBindings()
end
function OvaleActionBar:TimerUpdateActionSlots()
    self:UpdateActionSlots("TimerUpdateActionSlots")
end
function OvaleActionBar:UpdateActionSlots(event)
    self:StartProfiling("OvaleActionBar_UpdateActionSlots")
    self:Debug("%s: Updating all action slot mappings.", event)
    _wipe(self.action)
    _wipe(self.item)
    _wipe(self.macro)
    _wipe(self.spell)
    local start = 1
    local bonus = _tonumber(API_GetBonusBarIndex()) * 12
    if bonus > 0 then
        start = 13
        for slot = bonus - 11, bonus, 1 do
            self:UpdateActionSlot(slot)
        end
    end
    for slot = start, 72, 1 do
        self:UpdateActionSlot(slot)
    end
    if event ~= "TimerUpdateActionSlots" then
        self:ScheduleTimer("TimerUpdateActionSlots", 1)
    end
    self:StopProfiling("OvaleActionBar_UpdateActionSlots")
end
function OvaleActionBar:UpdateActionSlot(slot)
    self:StartProfiling("OvaleActionBar_UpdateActionSlot")
    local action = self.action[slot]
    if self.spell[action] == slot then
        self.spell[action] = nil
    elseif self.item[action] == slot then
        self.item[action] = nil
    elseif self.macro[action] == slot then
        self.macro[action] = nil
    end
    self.action[slot] = nil
    local actionType, id, subType = API_GetActionInfo(slot)
    if actionType == "spell" then
        id = _tonumber(id)
        if id then
            if  not self.spell[id] or slot < self.spell[id] then
                self.spell[id] = slot
            end
            self.action[slot] = id
        end
    elseif actionType == "item" then
        id = _tonumber(id)
        if id then
            if  not self.item[id] or slot < self.item[id] then
                self.item[id] = slot
            end
            self.action[slot] = id
        end
    elseif actionType == "macro" then
        id = _tonumber(id)
        if id then
            local actionText = API_GetActionText(slot)
            if actionText then
                if  not self.macro[actionText] or slot < self.macro[actionText] then
                    self.macro[actionText] = slot
                end
                local _, _, spellId = API_GetMacroSpell(id)
                if spellId then
                    if  not self.spell[spellId] or slot < self.spell[spellId] then
                        self.spell[spellId] = slot
                    end
                    self.action[slot] = spellId
                else
                    local _, hyperlink = API_GetMacroItem(id)
                    if hyperlink then
                        local _, _, linkData = ParseHyperlink(hyperlink)
                        local itemId = gsub(linkData, ":.*", "")
                        itemId = _tonumber(itemId)
                        if itemId then
                            if  not self.item[itemId] or slot < self.item[itemId] then
                                self.item[itemId] = slot
                            end
                            self.action[slot] = itemId
                        end
                    end
                end
                if  not self.action[slot] then
                    self.action[slot] = actionText
                end
            end
        end
    end
    if self.action[slot] then
        self:Debug("Mapping button %s to %s.", slot, self.action[slot])
    else
        self:Debug("Clearing mapping for button %s.", slot)
    end
    self.keybind[slot] = GetKeyBinding(slot)
    self:StopProfiling("OvaleActionBar_UpdateActionSlot")
end
function OvaleActionBar:UpdateKeyBindings()
    self:StartProfiling("OvaleActionBar_UpdateKeyBindings")
    for slot = 1, 120, 1 do
        self.keybind[slot] = GetKeyBinding(slot)
    end
    self:StopProfiling("OvaleActionBar_UpdateKeyBindings")
end
function OvaleActionBar:GetForSpell(spellId)
    return self.spell[spellId]
end
function OvaleActionBar:GetForMacro(macroName)
    return self.macro[macroName]
end
function OvaleActionBar:GetForItem(itemId)
    return self.item[itemId]
end
function OvaleActionBar:GetBinding(slot)
    return self.keybind[slot]
end
do
    local output = {}
    local OutputTableValues = function(output, tbl)
    end
local OvaleActionBar = __class()
    function OvaleActionBar:DebugActions()
        _wipe(output)
        local array = {}
        for k, v in pairs(self.spell) do
            tinsert(array, tostring(GetKeyBinding(v)) + ": " + tostring(k) + " " + tostring(OvaleSpellBook:GetSpellName(k)))
        end
        tsort(array)
        for _, v in ipairs(array) do
            output[#output + 1] = v
        end
        local total = 0
        for _ in pairs(self.spell) do
            total = total + 1
        end
        output[#output + 1] = "Total spells: " + total
        return tconcat(output, "\n")
    end
end
end))
