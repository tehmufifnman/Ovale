local OVALE, Ovale = ...
require(OVALE, Ovale, "Frame", { "./OvaleBestAction", "./OvaleCompile", "./OvaleCooldown", "./OvaleDebug", "./OvaleFuture", "./OvaleGUID", "./OvaleSpellFlash", "./OvaleState", "./OvaleTimeSpan", "./db", "./db", "./db", "./db", "./db", "./db", "./db" }, function(__exports, __OvaleBestAction, __OvaleCompile, __OvaleCooldown, __OvaleDebug, __OvaleFuture, __OvaleGUID, __OvaleSpellFlash, __OvaleState, __OvaleTimeSpan, __db, __db, __db, __db, __db, __db, __db)
do
    local AceGUI = LibStub("AceGUI-3.0")
    local Masque = LibStub("Masque", true)
    local Type = OVALE + "Frame"
    local Version = 7
    local _ipairs = ipairs
    local _next = next
    local _pairs = pairs
    local _tostring = tostring
    local _wipe = wipe
    local API_CreateFrame = CreateFrame
    local API_GetTime = GetTime
    local API_RegisterStateDriver = RegisterStateDriver
    local NextTime = __OvaleTimeSpan.OvaleTimeSpan.NextTime
    local INFINITY = math.huge
    local MIN_REFRESH_TIME = 0.05
    local frameOnClose = function(self)
        self.obj:Fire("OnClose")
    end
    local closeOnClick = function(self)
        self.obj:Hide()
    end
    local frameOnMouseDown = function(self)
        if ( not Ovale.db.profile.apparence.verrouille) then
            self:StartMoving()
            AceGUI:ClearFocus()
        end
    end
    local ToggleOptions = function(self)
        if (self.content:IsShown()) then
            self.content:Hide()
        else
            self.content:Show()
        end
    end
    local frameOnMouseUp = function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local parentX, parentY = self:GetParent():GetCenter()
        __db.profile.apparence.offsetX = x - parentX
        __db.profile.apparence.offsetY = y - parentY
    end
    local frameOnEnter = function(self)
        if  not (__db.profile.apparence.enableIcons and __db.profile.apparence.verrouille) then
            self.obj.barre:Show()
        end
    end
    local frameOnLeave = function(self)
        self.obj.barre:Hide()
    end
    local frameOnUpdate = function(self, elapsed)
        self.obj:OnUpdate(elapsed)
    end
    local Hide = function(self)
        self.frame:Hide()
    end
    local Show = function(self)
        self.frame:Show()
    end
    local OnAcquire = function(self)
        self.frame:SetParent(UIParent)
    end
    local OnRelease = function(self)
    end
    local OnWidthSet = function(self, width)
        local content = self.content
        local contentwidth = width - 34
        if contentwidth < 0 then
            contentwidth = 0
        end
        content:SetWidth(contentwidth)
        content.width = contentwidth
    end
    local OnHeightSet = function(self, height)
        local content = self.content
        local contentheight = height - 57
        if contentheight < 0 then
            contentheight = 0
        end
        content:SetHeight(contentheight)
        content.height = contentheight
    end
    local OnLayoutFinished = function(self, width, height)
        if ( not width) then
            width = self.content:GetWidth()
        end
        self.content:SetWidth(width)
        self.content:SetHeight(height + 50)
    end
    local GetScore = function(self, spellId)
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
    end
    local OnUpdate = function(self, elapsed)
        local guid = __OvaleGUID.OvaleGUID:UnitGUID("target") or __OvaleGUID.OvaleGUID:UnitGUID("focus")
        if guid then
            Ovale.refreshNeeded[guid] = true
        end
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
        local refresh = __OvaleDebug.OvaleDebug.trace or self.timeSinceLastUpdate > MIN_REFRESH_TIME and _next(Ovale.refreshNeeded)
        if refresh then
            Ovale:AddRefreshInterval(self.timeSinceLastUpdate * 1000)
            local state = __OvaleState.OvaleState.state
            state:Initialize()
            if __OvaleCompile.OvaleCompile:EvaluateScript() then
                Ovale:UpdateFrame()
            end
            local iconNodes = __OvaleCompile.OvaleCompile:GetIconNodes()
            for k, node in _ipairs(iconNodes) do
                if node.namedParams and node.namedParams.target then
                    state.defaultTarget = node.namedParams.target
                else
                    state.defaultTarget = "target"
                end
                if node.namedParams and node.namedParams.enemies then
                    state.enemies = node.namedParams.enemies
                else
                    state.enemies = nil
                end
                state:Log("+++ Icon %d", k)
                __OvaleBestAction.OvaleBestAction:StartNewAction(state)
                local atTime = state.nextCast
                if state.lastSpellId ~= state.lastGCDSpellId then
                    atTime = state.currentTime
                end
                local timeSpan, element = __OvaleBestAction.OvaleBestAction:GetAction(node, state, atTime)
                local start
                if element and element.offgcd then
                    start = NextTime(timeSpan, state.currentTime)
                else
                    start = NextTime(timeSpan, atTime)
                end
                if __db.profile.apparence.enableIcons then
                    self:UpdateActionIcon(state, node, self.actions[k], element, start)
                end
                if __db.profile.apparence.spellFlash.enabled then
                    __OvaleSpellFlash.OvaleSpellFlash:Flash(state, node, element, start)
                end
            end
            _wipe(Ovale.refreshNeeded)
            __OvaleDebug.OvaleDebug:UpdateTrace()
            Ovale:PrintOneTimeMessages()
            self.timeSinceLastUpdate = 0
        end
    end
    local UpdateActionIcon = function(self, state, node, action, element, start, now)
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
            local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend = __OvaleBestAction.OvaleBestAction:GetActionInfo(element, state)
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
            if actionType == "spell" and actionId == state.currentSpellId and start and state.nextCast and start < state.nextCast then
                start = state.nextCast
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
            if __db.profile.apparence.moving and icons[1].cooldownStart and icons[1].cooldownEnd then
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
            if (node.namedParams.size ~= "small" and  not node.namedParams.nocd and __db.profile.apparence.predictif) then
                if start then
                    state:Log("****Second icon %s", start)
                    state:ApplySpell(actionId, __OvaleGUID.OvaleGUID:UnitGUID(actionTarget), start)
                    local atTime = state.nextCast
                    if actionId ~= state.lastGCDSpellId then
                        atTime = state.currentTime
                    end
                    local timeSpan, nextElement = __OvaleBestAction.OvaleBestAction:GetAction(node, state, atTime)
                    local start
                    if nextElement and nextElement.offgcd then
                        start = NextTime(timeSpan, state.currentTime)
                    else
                        start = NextTime(timeSpan, atTime)
                    end
                    icons[2]:Update(nextElement, start, __OvaleBestAction.OvaleBestAction:GetActionInfo(nextElement, state))
                else
                    icons[2]:Update(element, nil)
                end
            end
        end
    end
    local UpdateFrame = function(self)
        self.frame:SetPoint("CENTER", self.hider, "CENTER", __db.profile.apparence.offsetX, __db.profile.apparence.offsetY)
        self.frame:EnableMouse( not __db.profile.apparence.clickThru)
    end
    local UpdateIcons = function(self)
        for k, action in _pairs(self.actions) do
            for i, icon in _pairs(action.icons) do
                icon:Hide()
            end
            for i, icon in _pairs(action.secureIcons) do
                icon:Hide()
            end
        end
        self.frame:EnableMouse( not __db.profile.apparence.clickThru)
        local left = 0
        local maxHeight = 0
        local maxWidth = 0
        local top = 0
        local BARRE = 8
        local margin = __db.profile.apparence.margin
        local iconNodes = __OvaleCompile.OvaleCompile:GetIconNodes()
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
                newScale = __db.profile.apparence.smallIconScale
                width = newScale * 36 + margin
                height = newScale * 36 + margin
                nbIcons = 1
            else
                newScale = __db.profile.apparence.iconScale
                width = newScale * 36 + margin
                height = newScale * 36 + margin
                if __db.profile.apparence.predictif and node.namedParams.type ~= "value" then
                    nbIcons = 2
                else
                    nbIcons = 1
                end
            end
            if (top + height > __db.profile.apparence.iconScale * 36 + margin) then
                top = 0
                left = maxWidth
            end
            action.scale = newScale
            if (__db.profile.apparence.vertical) then
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
                        action.icons[l] = API_CreateFrame("CheckButton", "Icon" + k + "n" + l, self.frame, OVALE + "IconTemplate")
                    end
                    icon = action.icons[l]
                else
                    if  not action.secureIcons[l] then
                        action.secureIcons[l] = API_CreateFrame("CheckButton", "SecureIcon" + k + "n" + l, self.frame, "Secure" + OVALE + "IconTemplate")
                    end
                    icon = action.secureIcons[l]
                end
                local scale = action.scale
                if l > 1 then
                    scale = scale * __db.profile.apparence.secondIconScale
                end
                icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (action.left + (l - 1) * action.dx) / scale, (action.top - (l - 1) * action.dy) / scale)
                icon:SetScale(scale)
                icon:SetRemainsFont(__db.profile.apparence.remainsFontColor)
                icon:SetFontScale(__db.profile.apparence.fontScale)
                icon:SetParams(node.positionalParams, node.namedParams)
                icon:SetHelp((node.namedParams ~= nil and node.namedParams.help) or nil)
                icon:SetRangeIndicator(__db.profile.apparence.targetText)
                icon:EnableMouse( not __db.profile.apparence.clickThru)
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
        if (__db.profile.apparence.vertical) then
            self.barre:SetWidth(maxHeight - margin)
            self.barre:SetHeight(BARRE)
            self.frame:SetWidth(maxHeight + __db.profile.apparence.iconShiftY)
            self.frame:SetHeight(maxWidth + BARRE + margin + __db.profile.apparence.iconShiftX)
            self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxHeight + __db.profile.apparence.iconShiftX, __db.profile.apparence.iconShiftY)
        else
            self.barre:SetWidth(maxWidth - margin)
            self.barre:SetHeight(BARRE)
            self.frame:SetWidth(maxWidth)
            self.frame:SetHeight(maxHeight + BARRE + margin)
            self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxWidth + __db.profile.apparence.iconShiftX, __db.profile.apparence.iconShiftY)
        end
    end
    local Constructor = function()
        local hider = API_CreateFrame("Frame", OVALE + "PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate")
        hider:SetAllPoints(true)
        API_RegisterStateDriver(hider, "visibility", "[petbattle] hide; show")
        local frame = API_CreateFrame("Frame", nil, hider)
        local self = {}
        self.Hide = Hide
        self.Show = Show
        self.OnRelease = OnRelease
        self.OnAcquire = OnAcquire
        self.LayoutFinished = OnLayoutFinished
        self.UpdateActionIcon = UpdateActionIcon
        self.UpdateFrame = UpdateFrame
        self.UpdateIcons = UpdateIcons
        self.ToggleOptions = ToggleOptions
        self.OnUpdate = OnUpdate
        self.GetScore = GetScore
        self.type = "Frame"
        self.localstatus = {}
        self.actions = {}
        self.frame = frame
        self.hider = hider
        self.updateFrame = API_CreateFrame("Frame", OVALE + "UpdateFrame")
        self.barre = self.frame:CreateTexture()
        self.content = API_CreateFrame("Frame", nil, self.updateFrame)
        if Masque then
            self.skinGroup = Masque:Group(OVALE)
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
        frame:SetAlpha(__db.profile.apparence.alpha)
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
        content:SetAlpha(__db.profile.apparence.optionsAlpha)
        AceGUI:RegisterAsContainer(self)
        return self
    end
    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
end))
