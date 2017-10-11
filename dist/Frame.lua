local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Frame", { "AceGUI-3.0", "Masque", "./BestAction", "./Compile", "./Debug", "./FutureState", "./GUID", "./SpellFlash", "./State", "./Ovale", "./Icon", "./Enemies", "./Controls" }, function(__exports, AceGUI, Masque, __BestAction, __Compile, __Debug, __FutureState, __GUID, __SpellFlash, __State, __Ovale, __Icon, __Enemies, __Controls)
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local _wipe = wipe
local _type = type
local strmatch = string.match
local API_CreateFrame = CreateFrame
local API_GetItemInfo = GetItemInfo
local API_GetTime = GetTime
local API_RegisterStateDriver = RegisterStateDriver
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitExists = UnitExists
local API_UnitIsDead = UnitIsDead
local API_UnitCanAttack = UnitCanAttack
local INFINITY = math.huge
local MIN_REFRESH_TIME = 0.05
local OvaleFrame = __class(AceGUI.WidgetContainerBase, {
    ToggleOptions = function(self)
        if (self.content:IsShown()) then
            self.content:Hide()
        else
            self.content:Show()
        end
    end,
    Hide = function(self)
        self.frame:Hide()
    end,
    Show = function(self)
        self.frame:Show()
    end,
    OnAcquire = function(self)
        self.frame:SetParent(UIParent)
    end,
    OnRelease = function(self)
    end,
    OnWidthSet = function(self, width)
        local content = self.content
        local contentwidth = width - 34
        if contentwidth < 0 then
            contentwidth = 0
        end
        content:SetWidth(contentwidth)
    end,
    OnHeightSet = function(self, height)
        local content = self.content
        local contentheight = height - 57
        if contentheight < 0 then
            contentheight = 0
        end
        content:SetHeight(contentheight)
    end,
    OnLayoutFinished = function(self, width, height)
        if ( not width) then
            width = self.content:GetWidth()
        end
        self.content:SetWidth(width)
        self.content:SetHeight(height + 50)
    end,
    UpdateVisibility = function(self)
        local visible = true
        local profile = __Ovale.Ovale.db.profile
        if  not profile.apparence.enableIcons then
            visible = false
        elseif  not self.hider:IsVisible() then
            visible = false
        else
            if profile.apparence.hideVehicule and API_UnitHasVehicleUI("player") then
                visible = false
            end
            if profile.apparence.avecCible and  not API_UnitExists("target") then
                visible = false
            end
            if profile.apparence.enCombat and  not __Ovale.Ovale.inCombat then
                visible = false
            end
            if profile.apparence.targetHostileOnly and (API_UnitIsDead("target") or  not API_UnitCanAttack("player", "target")) then
                visible = false
            end
        end
        if visible then
            self:Show()
        else
            self:Hide()
        end
    end,
    OnUpdate = function(self, elapsed)
        local guid = __GUID.OvaleGUID:UnitGUID("target") or __GUID.OvaleGUID:UnitGUID("focus")
        if guid then
            __Ovale.Ovale.refreshNeeded[guid] = true
        end
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
        local refresh = __Debug.OvaleDebug.trace or self.timeSinceLastUpdate > MIN_REFRESH_TIME and _next(__Ovale.Ovale.refreshNeeded)
        if refresh then
            __Ovale.Ovale:AddRefreshInterval(self.timeSinceLastUpdate * 1000)
            __State.OvaleState:InitializeState()
            if __Compile.OvaleCompile:EvaluateScript() then
                self:UpdateFrame()
            end
            local profile = __Ovale.Ovale.db.profile
            local iconNodes = __Compile.OvaleCompile:GetIconNodes()
            for k, node in _ipairs(iconNodes) do
                if node.namedParams and node.namedParams.target then
                    __State.baseState.defaultTarget = node.namedParams.target
                else
                    __State.baseState.defaultTarget = "target"
                end
                if node.namedParams and node.namedParams.enemies then
                    __Enemies.EnemiesState.enemies = node.namedParams.enemies
                else
                    __Enemies.EnemiesState.enemies = nil
                end
                __State.OvaleState:Log("+++ Icon %d", k)
                __BestAction.OvaleBestAction:StartNewAction()
                local atTime = __FutureState.futureState.nextCast
                if __FutureState.futureState.lastSpellId ~= __FutureState.futureState.lastGCDSpellId then
                    atTime = __State.baseState.currentTime
                end
                local timeSpan, element = __BestAction.OvaleBestAction:GetAction(node, __State.baseState, atTime)
                local start
                if element and element.offgcd then
                    start = timeSpan:NextTime(__State.baseState.currentTime)
                else
                    start = timeSpan:NextTime(atTime)
                end
                if profile.apparence.enableIcons then
                    self:UpdateActionIcon(__State.baseState, node, self.actions[k], element, start)
                end
                if profile.apparence.spellFlash.enabled and __SpellFlash.OvaleSpellFlash then
                    __SpellFlash.OvaleSpellFlash:Flash(__State.baseState, node, element, start)
                end
            end
            _wipe(__Ovale.Ovale.refreshNeeded)
            __Debug.OvaleDebug:UpdateTrace()
            __Ovale.Ovale:PrintOneTimeMessages()
            self.timeSinceLastUpdate = 0
        end
    end,
    UpdateActionIcon = function(self, state, node, action, element, start, now)
        local profile = __Ovale.Ovale.db.profile
        local icons = action.secure and action.secureIcons or action.icons
        now = now or API_GetTime()
        if element and element.type == "value" then
            local value
            if element.value and element.origin and element.rate then
                value = element.value + (now - element.origin) * element.rate
            end
            state:Log("GetAction: start=%s, value=%f", start, value)
            local actionTexture
            if node.namedParams and node.namedParams.texture then
                actionTexture = node.namedParams.texture
            end
            icons[1]:SetValue(value, actionTexture)
            if #icons > 1 then
                icons[2]:Update(element, nil)
            end
        else
            local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend = __BestAction.OvaleBestAction:GetActionInfo(element, state, now)
            if actionResourceExtend and actionResourceExtend > 0 then
                if actionCooldownDuration > 0 then
                    state:Log("Extending cooldown of spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend)
                    actionCooldownDuration = actionCooldownDuration + actionResourceExtend
                elseif element.namedParams.pool_resource and element.namedParams.pool_resource == 1 then
                    state:Log("Delaying spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend)
                    start = start + actionResourceExtend
                end
            end
            state:Log("GetAction: start=%s, id=%s", start, actionId)
            if actionType == "spell" and actionId == __FutureState.futureState.currentSpellId and start and __FutureState.futureState.nextCast and start < __FutureState.futureState.nextCast then
                start = __FutureState.futureState.nextCast
            end
            if start and node.namedParams.nocd and now < start - node.namedParams.nocd then
                icons[1]:Update(element, nil)
            else
                icons[1]:Update(element, start, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend)
            end
            if actionType == "spell" then
                action.spellId = actionId
            else
                action.spellId = nil
            end
            if start and start <= now and actionUsable then
                action.waitStart = action.waitStart or now
            else
                action.waitStart = nil
            end
            if profile.apparence.moving and icons[1].cooldownStart and icons[1].cooldownEnd then
                local top = 1 - (now - icons[1].cooldownStart) / (icons[1].cooldownEnd - icons[1].cooldownStart)
                if top < 0 then
                    top = 0
                elseif top > 1 then
                    top = 1
                end
                icons[1]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + top * action.dx) / action.scale, (action.top - top * action.dy) / action.scale)
                if icons[2] then
                    icons[2]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + (top + 1) * action.dx) / action.scale, (action.top - (top + 1) * action.dy) / action.scale)
                end
            end
            if (node.namedParams.size ~= "small" and  not node.namedParams.nocd and profile.apparence.predictif) then
                if start then
                    state:Log("****Second icon %s", start)
                    __FutureState.futureState:ApplySpell(actionId, __GUID.OvaleGUID:UnitGUID(actionTarget), start)
                    local atTime = __FutureState.futureState.nextCast
                    if actionId ~= __FutureState.futureState.lastGCDSpellId then
                        atTime = state.currentTime
                    end
                    local timeSpan, nextElement = __BestAction.OvaleBestAction:GetAction(node, state, atTime)
                    if nextElement and nextElement.offgcd then
                        start = timeSpan:NextTime(state.currentTime)
                    else
                        start = timeSpan:NextTime(atTime)
                    end
                    icons[2]:Update(nextElement, start, __BestAction.OvaleBestAction:GetActionInfo(nextElement, state, start))
                else
                    icons[2]:Update(element, nil)
                end
            end
        end
    end,
    UpdateFrame = function(self)
        local profile = __Ovale.Ovale.db.profile
        self.frame:SetPoint("CENTER", self.hider, "CENTER", profile.apparence.offsetX, profile.apparence.offsetY)
        self.frame:EnableMouse( not profile.apparence.clickThru)
        self:ReleaseChildren()
        self:UpdateIcons()
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
                self.OnCheckBoxValueChanged(widget)
            end
        end
    end,
    ToggleCheckBox = function(self, name)
        local widget = self:GetCheckBox(name)
        if widget then
            local on =  not widget:GetValue()
            widget:SetValue(on)
            self.OnCheckBoxValueChanged(widget)
        end
    end,
    FinalizeString = function(self, s)
        local item, id = strmatch(s, "^(item:)(.+)")
        if item then
            s = API_GetItemInfo(id)
        end
        return s
    end,
    UpdateControls = function(self)
        local profile = __Ovale.Ovale.db.profile
        _wipe(self.checkBoxWidget)
        for name, checkBox in _pairs(__Controls.checkBoxes) do
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
                self:AddChild(widget)
                self.checkBoxWidget[name] = widget
            else
                __Ovale.Ovale:OneTimeMessage("Warning: checkbox '%s' is used but not defined.", name)
            end
        end
        _wipe(self.listWidget)
        for name, list in _pairs(__Controls.lists) do
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
                self:AddChild(widget)
                self.listWidget[name] = widget
            else
                __Ovale.Ovale:OneTimeMessage("Warning: list '%s' is used but has no items.", name)
            end
        end
    end,
    UpdateIcons = function(self)
        for _, action in _pairs(self.actions) do
            for _, icon in _pairs(action.icons) do
                icon:Hide()
            end
            for _, icon in _pairs(action.secureIcons) do
                icon:Hide()
            end
        end
        local profile = __Ovale.Ovale.db.profile
        self.frame:EnableMouse( not profile.apparence.clickThru)
        local left = 0
        local maxHeight = 0
        local maxWidth = 0
        local top = 0
        local BARRE = 8
        local margin = profile.apparence.margin
        local iconNodes = __Compile.OvaleCompile:GetIconNodes()
        for k, node in _ipairs(iconNodes) do
            if  not self.actions[k] then
                self.actions[k] = {
                    icons = {},
                    secureIcons = {}
                }
            end
            local action = self.actions[k]
            local width, height, newScale
            local nbIcons
            if (node.namedParams ~= nil and node.namedParams.size == "small") then
                newScale = profile.apparence.smallIconScale
                width = newScale * 36 + margin
                height = newScale * 36 + margin
                nbIcons = 1
            else
                newScale = profile.apparence.iconScale
                width = newScale * 36 + margin
                height = newScale * 36 + margin
                if profile.apparence.predictif and node.namedParams.type ~= "value" then
                    nbIcons = 2
                else
                    nbIcons = 1
                end
            end
            if (top + height > profile.apparence.iconScale * 36 + margin) then
                top = 0
                left = maxWidth
            end
            action.scale = newScale
            if (profile.apparence.vertical) then
                action.left = top
                action.top = -left - BARRE - margin
                action.dx = width
                action.dy = 0
            else
                action.left = left
                action.top = -top - BARRE - margin
                action.dx = 0
                action.dy = height
            end
            action.secure = node.secure
            for l = 1, nbIcons, 1 do
                local icon
                if  not node.secure then
                    if  not action.icons[l] then
                        action.icons[l] = __Icon.OvaleIcon("Icon" .. k .. "n" .. l, self, false)
                    end
                    icon = action.icons[l]
                else
                    if  not action.secureIcons[l] then
                        action.secureIcons[l] = __Icon.OvaleIcon("SecureIcon" .. k .. "n" .. l, self, true)
                    end
                    icon = action.secureIcons[l]
                end
                local scale = action.scale
                if l > 1 then
                    scale = scale * profile.apparence.secondIconScale
                end
                icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + (l - 1) * action.dx) / scale, (action.top - (l - 1) * action.dy) / scale)
                icon:SetScale(scale)
                icon:SetRemainsFont(profile.apparence.remainsFontColor)
                icon:SetFontScale(profile.apparence.fontScale)
                icon:SetParams(node.positionalParams, node.namedParams)
                icon:SetHelp((node.namedParams ~= nil and node.namedParams.help) or nil)
                icon:SetRangeIndicator(profile.apparence.targetText)
                icon:EnableMouse( not profile.apparence.clickThru)
                icon.cdShown = (l == 1)
                if Masque then
                    self.skinGroup:AddButton(icon.frame)
                end
                if l == 1 then
                    icon:Show()
                end
            end
            top = top + height
            if (top > maxHeight) then
                maxHeight = top
            end
            if (left + width > maxWidth) then
                maxWidth = left + width
            end
        end
        if (profile.apparence.vertical) then
            self.barre:SetWidth(maxHeight - margin)
            self.barre:SetHeight(BARRE)
            self.frame:SetWidth(maxHeight + profile.apparence.iconShiftY)
            self.frame:SetHeight(maxWidth + BARRE + margin + profile.apparence.iconShiftX)
            self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxHeight + profile.apparence.iconShiftX, profile.apparence.iconShiftY)
        else
            self.barre:SetWidth(maxWidth - margin)
            self.barre:SetHeight(BARRE)
            self.frame:SetWidth(maxWidth)
            self.frame:SetHeight(maxHeight + BARRE + margin)
            self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxWidth + profile.apparence.iconShiftX, profile.apparence.iconShiftY)
        end
    end,
    constructor = function(self)
        self.checkBoxWidget = {}
        self.listWidget = {}
        self.OnCheckBoxValueChanged = function(widget)
            local name = widget:GetUserData("name")
            __Ovale.Ovale.db.profile.check[name] = widget:GetValue()
            __exports.OvaleFrameModule:SendMessage("Ovale_CheckBoxValueChanged", name)
        end
        self.OnDropDownValueChanged = function(widget)
            local name = widget:GetUserData("name")
            __Ovale.Ovale.db.profile.list[name] = widget:GetValue()
            __exports.OvaleFrameModule:SendMessage("Ovale_ListValueChanged", name)
        end
        self.type = "Frame"
        self.localstatus = {}
        self.actions = {}
        AceGUI.WidgetContainerBase.constructor(self)
        local hider = API_CreateFrame("Frame", __Ovale.Ovale:GetName() .. "PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate")
        local frame = API_CreateFrame("Frame", nil, hider)
        hider:SetAllPoints(UIParent)
        API_RegisterStateDriver(hider, "visibility", "[petbattle] hide; show")
        local profile = __Ovale.Ovale.db.profile
        self.frame = frame
        self.hider = hider
        self.updateFrame = API_CreateFrame("Frame", __Ovale.Ovale:GetName() .. "UpdateFrame")
        self.barre = self.frame:CreateTexture()
        self.content = API_CreateFrame("Frame", nil, self.updateFrame)
        if Masque then
            self.skinGroup = Masque:Group(__Ovale.Ovale:GetName())
        end
        self.timeSinceLastUpdate = INFINITY
        frame:SetWidth(100)
        frame:SetHeight(100)
        frame:SetMovable(true)
        frame:SetFrameStrata("MEDIUM")
        frame:SetScript("OnMouseDown", function()
            if ( not __Ovale.Ovale.db.profile.apparence.verrouille) then
                frame:StartMoving()
                AceGUI:ClearFocus()
            end
        end)
        frame:SetScript("OnMouseUp", function()
            frame:StopMovingOrSizing()
            local profile = __Ovale.Ovale.db.profile
            local x, y = frame:GetCenter()
            local parentX, parentY = frame:GetParent():GetCenter()
            profile.apparence.offsetX = x - parentX
            profile.apparence.offsetY = y - parentY
        end)
        frame:SetScript("OnEnter", function()
            local profile = __Ovale.Ovale.db.profile
            if  not (profile.apparence.enableIcons and profile.apparence.verrouille) then
                self.barre:Show()
            end
        end)
        frame:SetScript("OnLeave", function()
            self.barre:Hide()
        end)
        frame:SetScript("OnHide", function()
            return self:Hide()
        end)
        frame:SetAlpha(profile.apparence.alpha)
        self.updateFrame:SetScript("OnUpdate", function(updateFrame, elapsed)
            return self:OnUpdate(elapsed)
        end)
        self.barre:SetTexture(0, 0.8, 0)
        self.barre:SetPoint("TOPLEFT", 0, 0)
        self.barre:Hide()
        local content = self.content
        content:SetWidth(200)
        content:SetHeight(100)
        content:Hide()
        content:SetAlpha(profile.apparence.optionsAlpha)
        AceGUIRegisterAsContainer(self)
        self:UpdateFrame()
    end,
})
__exports.frame = OvaleFrame()
local OvaleFrameBase = __Ovale.Ovale:NewModule("OvaleFrame", "AceEvent-3.0")
local OvaleFrameModuleClass = __class(OvaleFrameBase, {
    Ovale_OptionChanged = function(self, event, eventType)
        if eventType == "visibility" then
            __exports.frame:UpdateVisibility()
        else
            if eventType == "layout" then
                __exports.frame:UpdateFrame()
            end
            __exports.frame:UpdateFrame()
        end
    end,
    PLAYER_TARGET_CHANGED = function(self)
        __exports.frame:UpdateVisibility()
    end,
    Ovale_CombatStarted = function(self, event, atTime)
        __exports.frame:UpdateVisibility()
    end,
    Ovale_CombatEnded = function(self, event, atTime)
        __exports.frame:UpdateVisibility()
    end,
    constructor = function(self)
        OvaleFrameBase.constructor(self)
        self:RegisterMessage("Ovale_OptionChanged")
        self:RegisterMessage("Ovale_CombatStarted")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
    end,
})
__exports.OvaleFrameModule = OvaleFrameModuleClass()
end)
