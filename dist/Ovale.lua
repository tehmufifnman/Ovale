local OVALE, Ovale = ...
Ovale = LibStub("AceAddon-3.0"):NewAddon(Ovale or {}, OVALE or "Ovale", "AceEvent-3.0")
_G["Ovale"] = Ovale
local AceGUI = LibStub("AceGUI-3.0")
local L = nil
local _assert = assert
local format = string.format
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local _select = select
local strfind = string.find
local _strjoin = strjoin
local strlen = string.len
local strmatch = string.match
local _tostring = tostring
local _tostringall = tostringall
local _type = type
local _unpack = unpack
local _wipe = wipe
local API_GetItemInfo = GetItemInfo
local API_GetTime = GetTime
local API_UnitCanAttack = UnitCanAttack
local API_UnitClass = UnitClass
local API_UnitExists = UnitExists
local API_UnitGUID = UnitGUID
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitIsDead = UnitIsDead
local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local INFINITY = math.huge
local OVALE_VERSION = "7.3.0.2"
local REPOSITORY_KEYWORD = "@" + "project-version" + "@"
local self_oneTimeMessage = {}
local MAX_REFRESH_INTERVALS = 500
local self_refreshIntervals = {}
local self_refreshIndex = 1
Ovale.L = nil
Ovale.playerClass = _select(2, API_UnitClass("player"))
Ovale.playerGUID = nil
Ovale.db = nil
Ovale.frame = nil
Ovale.checkBox = {}
Ovale.list = {}
Ovale.checkBoxWidget = {}
Ovale.listWidget = {}
Ovale.refreshNeeded = {}
Ovale.MSG_PREFIX = OVALE
local OnCheckBoxValueChanged = function(widget)
    local name = widget:GetUserData("name")
    Ovale.db.profile.check[name] = widget:GetValue()
    Ovale:SendMessage("Ovale_CheckBoxValueChanged", name)
end
local OnDropDownValueChanged = function(widget)
    local name = widget:GetUserData("name")
    Ovale.db.profile.list[name] = widget:GetValue()
    Ovale:SendMessage("Ovale_ListValueChanged", name)
end
local Ovale = __class()
function Ovale:OnInitialize()
    L = Ovale.L
    BINDING_HEADER_OVALE = OVALE
    local toggleCheckBox = L["Inverser la boîte à cocher "]
    BINDING_NAME_OVALE_CHECKBOX0 = toggleCheckBox + "(1)"
    BINDING_NAME_OVALE_CHECKBOX1 = toggleCheckBox + "(2)"
    BINDING_NAME_OVALE_CHECKBOX2 = toggleCheckBox + "(3)"
    BINDING_NAME_OVALE_CHECKBOX3 = toggleCheckBox + "(4)"
    BINDING_NAME_OVALE_CHECKBOX4 = toggleCheckBox + "(5)"
end
function Ovale:OnEnable()
    self.playerGUID = API_UnitGUID("player")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterMessage("Ovale_CombatStarted")
    self:RegisterMessage("Ovale_OptionChanged")
    self.frame = AceGUI:Create(OVALE + "Frame")
    self:UpdateFrame()
end
function Ovale:OnDisable()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterMessage("Ovale_CombatEnded")
    self:UnregisterMessage("Ovale_OptionChanged")
    self.frame:Hide()
end
function Ovale:PLAYER_ENTERING_WORLD()
    _wipe(self_refreshIntervals)
    self_refreshIndex = 1
    self:ClearOneTimeMessages()
end
function Ovale:PLAYER_TARGET_CHANGED()
    self:UpdateVisibility()
end
function Ovale:Ovale_CombatStarted(event, atTime)
    self:UpdateVisibility()
end
function Ovale:Ovale_CombatEnded(event, atTime)
    self:UpdateVisibility()
end
function Ovale:Ovale_OptionChanged(event, eventType)
    if eventType == "visibility" then
        self:UpdateVisibility()
    else
        if eventType == "layout" then
            self.frame:UpdateFrame()
        end
        self:UpdateFrame()
    end
end
function Ovale:IsPreloaded(moduleList)
    local preloaded = true
    for _, moduleName in _pairs(moduleList) do
        preloaded = preloaded and self[moduleName].ready
    end
    return preloaded
end
function Ovale:ToggleOptions()
    self.frame:ToggleOptions()
end
function Ovale:UpdateVisibility()
    local visible = true
    local profile = self.db.profile
    if  not profile.apparence.enableIcons then
        visible = false
    elseif  not self.frame.hider:IsVisible() then
        visible = false
    else
        if profile.apparence.hideVehicule and API_UnitHasVehicleUI("player") then
            visible = false
        end
        if profile.apparence.avecCible and  not API_UnitExists("target") then
            visible = false
        end
        if profile.apparence.enCombat and  not Ovale.OvaleFuture.inCombat then
            visible = false
        end
        if profile.apparence.targetHostileOnly and (API_UnitIsDead("target") or  not API_UnitCanAttack("player", "target")) then
            visible = false
        end
    end
    if visible then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end
function Ovale:ResetControls()
    _wipe(self.checkBox)
    _wipe(self.list)
end
function Ovale:UpdateControls()
    local profile = self.db.profile
    _wipe(self.checkBoxWidget)
    for name, checkBox in _pairs(self.checkBox) do
        if checkBox.text then
            local widget = AceGUI:Create("CheckBox")
            local text = self:FinalizeString(checkBox.text)
            widget:SetLabel(text)
            if profile.check[name] == nil then
                profile.check[name] = checkBox.checked
            end
            if profile.check[name] then
                widget:SetValue(profile.check[name])
            end
            widget:SetUserData("name", name)
            widget:SetCallback("OnValueChanged", OnCheckBoxValueChanged)
            self.frame:AddChild(widget)
            self.checkBoxWidget[name] = widget
        else
            self:OneTimeMessage("Warning: checkbox '%s' is used but not defined.", name)
        end
    end
    _wipe(self.listWidget)
    for name, list in _pairs(self.list) do
        if _next(list.items) then
            local widget = AceGUI:Create("Dropdown")
            widget:SetList(list.items)
            if  not profile.list[name] then
                profile.list[name] = list.default
            end
            if profile.list[name] then
                widget:SetValue(profile.list[name])
            end
            widget:SetUserData("name", name)
            widget:SetCallback("OnValueChanged", OnDropDownValueChanged)
            self.frame:AddChild(widget)
            self.listWidget[name] = widget
        else
            self:OneTimeMessage("Warning: list '%s' is used but has no items.", name)
        end
    end
end
function Ovale:UpdateFrame()
    self.frame:ReleaseChildren()
    self.frame:UpdateIcons()
    self:UpdateControls()
    self:UpdateVisibility()
end
function Ovale:GetCheckBox(name)
    local widget
    if _type(name) == "string" then
        widget = self.checkBoxWidget[name]
    elseif _type(name) == "number" then
        local k = 0
        for _, frame in _pairs(self.checkBoxWidget) do
            if k == name then
                widget = frame
                break
            end
            k = k + 1
        end
    end
    return widget
end
function Ovale:IsChecked(name)
    local widget = self:GetCheckBox(name)
    return widget and widget:GetValue()
end
function Ovale:GetListValue(name)
    local widget = self.listWidget[name]
    return widget and widget:GetValue()
end
function Ovale:SetCheckBox(name, on)
    local widget = self:GetCheckBox(name)
    if widget then
        local oldValue = widget:GetValue()
        if oldValue ~= on then
            widget:SetValue(on)
            OnCheckBoxValueChanged(widget)
        end
    end
end
function Ovale:ToggleCheckBox(name)
    local widget = self:GetCheckBox(name)
    if widget then
        local on =  not widget:GetValue()
        widget:SetValue(on)
        OnCheckBoxValueChanged(widget)
    end
end
function Ovale:AddRefreshInterval(milliseconds)
    if milliseconds < INFINITY then
        self_refreshIntervals[self_refreshIndex] = milliseconds
        self_refreshIndex = (self_refreshIndex < MAX_REFRESH_INTERVALS) and (self_refreshIndex + 1) or 1
    end
end
function Ovale:GetRefreshIntervalStatistics()
    local sumRefresh, minRefresh, maxRefresh, count = 0, INFINITY, 0, 0
    for k, v in _ipairs(self_refreshIntervals) do
        if v > 0 then
            if minRefresh > v then
                minRefresh = v
            end
            if maxRefresh < v then
                maxRefresh = v
            end
            sumRefresh = sumRefresh + v
            count = count + 1
        end
    end
    local avgRefresh = (count > 0) and (sumRefresh / count) or 0
    return avgRefresh, minRefresh, maxRefresh, count
end
function Ovale:FinalizeString(s)
    local item, id = strmatch(s, "^(item:)(.+)")
    if item then
        s = API_GetItemInfo(id)
    end
    return s
end
function Ovale:MakeString(s, ...)
    if s and strlen(s) > 0 then
        if ....length > 0 then
            if strfind(s, "%%%.%d") or strfind(s, "%%[%w]") then
                s = format(s, _tostringall(...))
            else
                s = _strjoin(" ", s, _tostringall(...))
            end
        end
    else
        s = _tostring(nil)
    end
    return s
end
function Ovale:Print(...)
    local name = self:GetName()
    local s = Ovale:MakeString(...)
    _DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
end
function Ovale:Error(...)
    local s = Ovale:MakeString(...)
    self:Print("Fatal error: %s", s)
    Ovale.OvaleDebug.bug = true
end
function Ovale:OneTimeMessage(...)
    local s = self:MakeString(...)
    if  not self_oneTimeMessage[s] then
        self_oneTimeMessage[s] = true
    end
end
function Ovale:ClearOneTimeMessages()
    _wipe(self_oneTimeMessage)
end
function Ovale:PrintOneTimeMessages()
    for s in _pairs(self_oneTimeMessage) do
        if self_oneTimeMessage[s] ~= "printed" then
            self:Print(s)
            self_oneTimeMessage[s] = "printed"
        end
    end
end
function Ovale:GetMethod(methodName, subModule)
    local func, arg = self[methodName], self
    if  not func then
        func, arg = subModule[methodName], subModule
    end
    _assert(func ~= nil)
    return func, arg
end
do
    local DoNothing = function()
    end
    local modulePrototype = {
        Error = Ovale.Error,
        Log = DoNothing,
        Print = Ovale.Print,
        GetMethod = Ovale.GetMethod
    }
    Ovale:SetDefaultModulePrototype(modulePrototype)
end
