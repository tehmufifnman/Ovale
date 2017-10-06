local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./ActionBar", { "./Localization", "./Debug", "./Profiler", "./SpellBook", "./Ovale" }, function(__exports, __Localization, __Debug, __Profiler, __SpellBook, __Ovale)
local OvaleActionBarBase = __Ovale.Ovale:NewModule("OvaleActionBar", "AceEvent-3.0", "AceTimer-3.0")
local gsub = string.gsub
local strlen = string.len
local strmatch = string.match
local strupper = string.upper
local tconcat = table.concat
local _tonumber = tonumber
local tsort = table.sort
local tinsert = table.insert
local _wipe = wipe
local API_GetActionInfo = GetActionInfo
local API_GetActionText = GetActionText
local API_GetBindingKey = GetBindingKey
local API_GetBonusBarIndex = GetBonusBarIndex
local API_GetMacroItem = GetMacroItem
local API_GetMacroSpell = GetMacroSpell
local OvaleActionBarClass = __class(__Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleActionBarBase)), {
    constructor = function(self)
        self.debugOptions = {
            actionbar = {
                name = __Localization.L["Action bar"],
                type = "group",
                args = {
                    spellbook = {
                        name = __Localization.L["Action bar"],
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            return self:DebugActions()
                        end
                    }
                }
            }
        }
        self.action = {}
        self.keybind = {}
        self.spell = {}
        self.macro = {}
        self.item = {}
        self.output = {}
        __Profiler.OvaleProfiler:RegisterProfiling(__Debug.OvaleDebug:RegisterDebugging(OvaleActionBarBase)).constructor(self)
        for k, v in pairs(self.debugOptions) do
            __Debug.OvaleDebug.options.args[k] = v
        end
    end,
    GetKeyBinding = function(self, slot)
        local name
        if Bartender4 then
            name = "CLICK BT4Button " .. slot .. ":LeftButton"
        else
            if slot <= 24 or slot > 72 then
                name = "ACTIONBUTTON" .. ((slot - 1) % 12) + 1
            elseif slot <= 36 then
                name = "MULTIACTIONBAR3BUTTON" .. slot - 24
            elseif slot <= 48 then
                name = "MULTIACTIONBAR4BUTTON" .. slot - 36
            elseif slot <= 60 then
                name = "MULTIACTIONBAR2BUTTON" .. slot - 48
            else
                name = "MULTIACTIONBAR1BUTTON" .. slot - 60
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
    end,
    ParseHyperlink = function(self, hyperlink)
        local color, linkType, linkData, text = strmatch(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
        return color, linkType, linkData, text
    end,
    OnEnable = function(self)
        self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", self.UpdateActionSlots)
        self:RegisterEvent("UPDATE_BINDINGS")
        self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", self.UpdateActionSlots)
        self:RegisterMessage("Ovale_StanceChanged", self.UpdateActionSlots)
        self:RegisterMessage("Ovale_TalentsChanged", self.UpdateActionSlots)
    end,
    OnDisable = function(self)
        self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("UPDATE_BINDINGS")
        self:UnregisterEvent("UPDATE_BONUS_ACTIONBAR")
        self:UnregisterMessage("Ovale_StanceChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    ACTIONBAR_SLOT_CHANGED = function(self, event, slot)
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
    end,
    UPDATE_BINDINGS = function(self, event)
        self:Debug("%s: Updating key bindings.", event)
        self:UpdateKeyBindings()
    end,
    TimerUpdateActionSlots = function(self)
        self:UpdateActionSlots("TimerUpdateActionSlots")
    end,
    UpdateActionSlots = function(self, event)
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
    end,
    UpdateActionSlot = function(self, slot)
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
        local actionType, actionId, subType = API_GetActionInfo(slot)
        if actionType == "spell" then
            local id = _tonumber(actionId)
            if id then
                if  not self.spell[id] or slot < self.spell[id] then
                    self.spell[id] = slot
                end
                self.action[slot] = id
            end
        elseif actionType == "item" then
            local id = _tonumber(actionId)
            if id then
                if  not self.item[id] or slot < self.item[id] then
                    self.item[id] = slot
                end
                self.action[slot] = id
            end
        elseif actionType == "macro" then
            local id = _tonumber(actionId)
            if id then
                local actionText = API_GetActionText(slot)
                if actionText then
                    if  not self.macro[actionText] or slot < self.macro[actionText] then
                        self.macro[actionText] = slot
                    end
                    local _, __, spellId = API_GetMacroSpell(id)
                    if spellId then
                        if  not self.spell[spellId] or slot < self.spell[spellId] then
                            self.spell[spellId] = slot
                        end
                        self.action[slot] = spellId
                    else
                        local _, hyperlink = API_GetMacroItem(id)
                        if hyperlink then
                            local _, __, linkData = self:ParseHyperlink(hyperlink)
                            local itemIdText = gsub(linkData, ":.*", "")
                            local itemId = _tonumber(itemIdText)
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
        self.keybind[slot] = self:GetKeyBinding(slot)
        self:StopProfiling("OvaleActionBar_UpdateActionSlot")
    end,
    UpdateKeyBindings = function(self)
        self:StartProfiling("OvaleActionBar_UpdateKeyBindings")
        for slot = 1, 120, 1 do
            self.keybind[slot] = self:GetKeyBinding(slot)
        end
        self:StopProfiling("OvaleActionBar_UpdateKeyBindings")
    end,
    GetForSpell = function(self, spellId)
        return self.spell[spellId]
    end,
    GetForMacro = function(self, macroName)
        return self.macro[macroName]
    end,
    GetForItem = function(self, itemId)
        return self.item[itemId]
    end,
    GetBinding = function(self, slot)
        return self.keybind[slot]
    end,
    OutputTableValues = function(self, output, tbl)
    end,
    DebugActions = function(self)
        _wipe(self.output)
        local array = {}
        for k, v in pairs(self.spell) do
            tinsert(array, tostring(self:GetKeyBinding(v)) .. ": " .. tostring(k) .. " " .. tostring(__SpellBook.OvaleSpellBook:GetSpellName(k)))
        end
        tsort(array)
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        local total = 0
        for _ in pairs(self.spell) do
            total = total + 1
        end
        self.output[#self.output + 1] = "Total spells: " .. total
        return tconcat(self.output, "\\n")
    end,
})
__exports.OvaleActionBar = OvaleActionBarClass()
end)
