local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Ovale", { "AceAddon-3.0", "AceGUI-3.0", "./Localization" }, function(__exports, AceAddon, AceGUI, __Localization)
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
local REPOSITORY_KEYWORD = "project-version"
local self_oneTimeMessage = {}
local MAX_REFRESH_INTERVALS = 500
local self_refreshIntervals = {}
local self_refreshIndex = 1
__exports.MakeString = function(s, ...)
    if s and strlen(s) > 0 then
        if ... then
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
__exports.RegisterPrinter = function(base)
    return __class(base, {
        GetMethod = function(self, methodName, subModule)
            local func, arg = self[methodName], self
            if  not func then
                func, arg = subModule[methodName], subModule
            end
            _assert(func ~= nil)
            return func, arg
        end,
    })
end
local OvaleClass = __class(AceAddon:NewAddon("Ovale", "AceEvent-3.0"), {
    OnCheckBoxValueChanged = function(self, widget)
        local name = widget:GetUserData("name")
        self.db.profile.check[name] = widget:GetValue()
        self:SendMessage("Ovale_CheckBoxValueChanged", name)
    end,
    OnInitialize = function(self)
        _G["BINDING_HEADER_OVALE"] = "Ovale"
        local toggleCheckBox = __Localization.L["Inverser la boîte à cocher "]
        _G["BINDING_NAME_OVALE_CHECKBOX0"] = toggleCheckBox
        _G["BINDING_NAME_OVALE_CHECKBOX1"] = toggleCheckBox
        _G["BINDING_NAME_OVALE_CHECKBOX2"] = toggleCheckBox
        _G["BINDING_NAME_OVALE_CHECKBOX3"] = toggleCheckBox
        _G["BINDING_NAME_OVALE_CHECKBOX4"] = toggleCheckBox
    end,
    OnEnable = function(self)
        self.playerGUID = API_UnitGUID("player")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterMessage("Ovale_CombatStarted")
        self:RegisterMessage("Ovale_OptionChanged")
        self.frame = AceGUI:Create("OvaleFrame")
        self:UpdateFrame()
    end,
    OnDisable = function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self:UnregisterMessage("Ovale_CombatEnded")
        self:UnregisterMessage("Ovale_OptionChanged")
        self.frame:Hide()
    end,
    PLAYER_ENTERING_WORLD = function(self)
        _wipe(self_refreshIntervals)
        self_refreshIndex = 1
        self:ClearOneTimeMessages()
    end,
    PLAYER_TARGET_CHANGED = function(self)
        self:UpdateVisibility()
    end,
    Ovale_CombatStarted = function(self, event, atTime)
        self:UpdateVisibility()
    end,
    Ovale_CombatEnded = function(self, event, atTime)
        self:UpdateVisibility()
    end,
    Ovale_OptionChanged = function(self, event, eventType)
        if eventType == "visibility" then
            self:UpdateVisibility()
        else
            if eventType == "layout" then
                self.frame:UpdateFrame()
            end
            self:UpdateFrame()
        end
    end,
    IsPreloaded = function(self, moduleList)
        local preloaded = true
        for _, moduleName in _pairs(moduleList) do
            preloaded = preloaded and self[moduleName].ready
        end
        return preloaded
    end,
    ToggleOptions = function(self)
        self.frame:ToggleOptions()
    end,
    UpdateVisibility = function(self)
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
            if profile.apparence.enCombat and  not self.inCombat then
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
    end,
    ResetControls = function(self)
        _wipe(self.checkBox)
        _wipe(self.list)
    end,
    UpdateControls = function(self)
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
                widget:SetCallback("OnValueChanged", self.OnCheckBoxValueChanged)
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
                widget:SetCallback("OnValueChanged", self.OnDropDownValueChanged)
                self.frame:AddChild(widget)
                self.listWidget[name] = widget
            else
                self:OneTimeMessage("Warning: list '%s' is used but has no items.", name)
            end
        end
    end,
    UpdateFrame = function(self)
        self.frame:ReleaseChildren()
        self.frame:UpdateIcons()
        self:UpdateControls()
        self:UpdateVisibility()
    end,
    GetCheckBox = function(self, name)
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
    end,
    IsChecked = function(self, name)
        local widget = self:GetCheckBox(name)
        return widget and widget:GetValue()
    end,
    GetListValue = function(self, name)
        local widget = self.listWidget[name]
        return widget and widget:GetValue()
    end,
    SetCheckBox = function(self, name, on)
        local widget = self:GetCheckBox(name)
        if widget then
            local oldValue = widget:GetValue()
            if oldValue ~= on then
                widget:SetValue(on)
                self:OnCheckBoxValueChanged(widget)
            end
        end
    end,
    ToggleCheckBox = function(self, name)
        local widget = self:GetCheckBox(name)
        if widget then
            local on =  not widget:GetValue()
            widget:SetValue(on)
            self:OnCheckBoxValueChanged(widget)
        end
    end,
    AddRefreshInterval = function(self, milliseconds)
        if milliseconds < INFINITY then
            self_refreshIntervals[self_refreshIndex] = milliseconds
            self_refreshIndex = (self_refreshIndex < MAX_REFRESH_INTERVALS) and (self_refreshIndex + 1) or 1
        end
    end,
    GetRefreshIntervalStatistics = function(self)
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
    end,
    FinalizeString = function(self, s)
        local item, id = strmatch(s, "^(item:)(.+)")
        if item then
            s = API_GetItemInfo(id)
        end
        return s
    end,
    OneTimeMessage = function(self, ...)
        local s = __exports.MakeString(...)
        if  not self_oneTimeMessage[s] then
            self_oneTimeMessage[s] = true
        end
    end,
    ClearOneTimeMessages = function(self)
        _wipe(self_oneTimeMessage)
    end,
    PrintOneTimeMessages = function(self)
        for s in _pairs(self_oneTimeMessage) do
            if self_oneTimeMessage[s] ~= "printed" then
                self:Print(s)
                self_oneTimeMessage[s] = "printed"
            end
        end
    end,
})
__exports.Ovale = OvaleClass()
end)
