local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Frame", { "AceGUI-3.0", "Masque", "./BestAction", "./Compile", "./Cooldown", "./Debug", "./Future", "./GUID", "./SpellFlash", "./State", "./TimeSpan", "./Ovale", "./Icon", "./Enemies" }, function(__exports, AceGUI, Masque, __BestAction, __Compile, __Cooldown, __Debug, __Future, __GUID, __SpellFlash, __State, __TimeSpan, __Ovale, __Icon, __Enemies)
local Type = __Ovale.Ovale:GetName()
local Version = 7
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local _tostring = tostring
local _wipe = wipe
local API_CreateFrame = CreateFrame
local API_GetTime = GetTime
local API_RegisterStateDriver = RegisterStateDriver
local INFINITY = math.huge
local MIN_REFRESH_TIME = 0.05
local frameOnClose = function(self)
    self.obj:Fire("OnClose")
end

local closeOnClick = function(self)
    self.obj:Hide()
end

local frameOnMouseDown = function(self)
    if ( not __Ovale.Ovale.db.profile.apparence.verrouille) then
        self:StartMoving()
        AceGUI:ClearFocus()
    end
end

local frameOnMouseUp = function(self)
    self:StopMovingOrSizing()
    local profile = __Ovale.Ovale.db.profile
    local x, y = self:GetCenter()
    local parentX, parentY = self:GetParent():GetCenter()
    profile.apparence.offsetX = x - parentX
    profile.apparence.offsetY = y - parentY
end

local frameOnEnter = function(self)
    local profile = __Ovale.Ovale.db.profile
    if  not (profile.apparence.enableIcons and profile.apparence.verrouille) then
        self.obj.barre:Show()
    end
end

local frameOnLeave = function(self)
    self.obj.barre:Hide()
end

local frameOnUpdate = function(self, elapsed)
    self.obj:OnUpdate(elapsed)
end

local OvaleFrame = __class(nil, {
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
    GetScore = function(self, spellId)
        for k, action in _pairs(self.actions) do
            if action.spellId == spellId then
                if  not action.waitStart then
                    return 1
                else
                    local now = API_GetTime()
                    local lag = now - action.waitStart
                    if lag > 5 then
                        return nil
                    elseif lag > 1.5 then
                        return 0
                    elseif lag > 0 then
                        return 1 - lag / 1.5
                    else
                        return 1
                    end
                end
            end
        end
        return 0
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
                __Ovale.Ovale:UpdateFrame()
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
                    __Enemies.enemiesState.enemies = node.namedParams.enemies
                else
                    __Enemies.enemiesState.enemies = nil
                end
                __State.OvaleState:Log("+++ Icon %d", k)
                __BestAction.OvaleBestAction:StartNewAction()
                local atTime = __Future.futureState.nextCast
                if __Future.futureState.lastSpellId ~= __Future.futureState.lastGCDSpellId then
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
                if profile.apparence.spellFlash.enabled then
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
            if actionType == "spell" and actionId == __Future.futureState.currentSpellId and start and __Future.futureState.nextCast and start < __Future.futureState.nextCast then
                start = __Future.futureState.nextCast
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
                    __Future.futureState:ApplySpell(actionId, __GUID.OvaleGUID:UnitGUID(actionTarget), start)
                    local atTime = __Future.futureState.nextCast
                    if actionId ~= __Future.futureState.lastGCDSpellId then
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
    end,
    UpdateIcons = function(self)
        for k, action in _pairs(self.actions) do
            for i, icon in _pairs(action.icons) do
                icon:Hide()
            end
            for i, icon in _pairs(action.secureIcons) do
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
                        action.icons[l] = __Icon.OvaleIcon(k .. l, self.frame, false)
                    end
                    icon = action.icons[l]
                else
                    if  not action.secureIcons[l] then
                        action.secureIcons[l] = __Icon.OvaleIcon(k .. l, self.frame, true)
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
                    self.skinGroup:AddButton(icon)
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
        self.type = "Frame"
        self.localstatus = {}
        self.actions = {}
        local hider = API_CreateFrame("Frame", __Ovale.Ovale:GetName(), UIParent, "SecureHandlerStateTemplate")
        hider:SetAllPoints(self.frame)
        API_RegisterStateDriver(hider, "visibility", "[petbattle] hide; show")
        local frame = API_CreateFrame("Frame", nil, hider)
        local profile = __Ovale.Ovale.db.profile
        self.frame = frame
        self.hider = hider
        self.updateFrame = API_CreateFrame("Frame", __Ovale.Ovale:GetName())
        self.barre = self.frame:CreateTexture()
        self.content = API_CreateFrame("Frame", nil, self.updateFrame)
        if Masque then
            self.skinGroup = Masque:Group(__Ovale.Ovale:GetName())
        end
        self.timeSinceLastUpdate = INFINITY
        self.obj = nil
        frame.obj = self
        frame:SetWidth(100)
        frame:SetHeight(100)
        self:UpdateFrame()
        frame:SetMovable(true)
        frame:SetFrameStrata("MEDIUM")
        frame:SetScript("OnMouseDown", frameOnMouseDown)
        frame:SetScript("OnMouseUp", frameOnMouseUp)
        frame:SetScript("OnEnter", frameOnEnter)
        frame:SetScript("OnLeave", frameOnLeave)
        frame:SetScript("OnHide", frameOnClose)
        frame:SetAlpha(profile.apparence.alpha)
        self.updateFrame:SetScript("OnUpdate", frameOnUpdate)
        self.updateFrame.obj = self
        self.barre:SetTexture(0, 0.8, 0)
        self.barre:SetPoint("TOPLEFT", 0, 0)
        self.barre:Hide()
        local content = self.content
        content.obj = self
        content:SetWidth(200)
        content:SetHeight(100)
        content:Hide()
        content:SetAlpha(profile.apparence.optionsAlpha)
        AceGUI:RegisterAsContainer(self)
    end,
})
AceGUI:RegisterWidgetType(Type, OvaleFrame, Version)
end)
