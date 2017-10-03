local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Icon", { "./Localization", "./SpellBook", "./State", "./Ovale" }, function(__exports, __Localization, __SpellBook, __State, __Ovale)
local format = string.format
local _next = next
local _pairs = pairs
local strfind = string.find
local strsub = string.sub
local _tostring = tostring
local API_GetTime = GetTime
local API_PlaySoundFile = PlaySoundFile
local INFINITY = math.huge
local COOLDOWN_THRESHOLD = 0.1
local HasScriptControls = function()
    return (_next(__Ovale.Ovale.checkBoxWidget) ~= nil or _next(__Ovale.Ovale.listWidget) ~= nil)
end

__exports.OvaleIcon = __class(nil, {
    constructor = function(self, name, parent, secure)
        if  not secure then
            self.frame = CreateFrame("CheckButton", name, parent, "ActionButtonTemplate")
        else
            self.frame = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, ActionButtonTemplate")
        end
        self:OvaleIcon_OnLoad()
    end,
    SetValue = function(self, value, actionTexture)
        self.icone:Show()
        self.icone:SetTexture(actionTexture)
        self.icone:SetAlpha(__Ovale.Ovale.db.profile.apparence.alpha)
        self.cd:Hide()
        self.focusText:Hide()
        self.rangeIndicator:Hide()
        self.shortcut:Hide()
        if value then
            self.actionType = "value"
            self.actionHelp = nil
            self.value = value
            if value < 10 then
                self.remains:SetFormattedText("%.1f", value)
            elseif value == INFINITY then
                self.remains:SetFormattedText("inf")
            else
                self.remains:SetFormattedText("%d", value)
            end
            self.remains:Show()
        else
            self.remains:Hide()
        end
        self.frame:Show()
    end,
    Update = function(self, element, startTime, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend)
        self.actionType = actionType
        self.actionId = actionId
        self.value = nil
        local now = API_GetTime()
        local profile = __Ovale.Ovale.db.profile
        if startTime and actionTexture then
            local cd = self.cd
            local resetCooldown = false
            if startTime > now then
                local duration = cd:GetCooldownDuration()
                if duration == 0 and self.texture == actionTexture and self.cooldownStart and self.cooldownEnd then
                    resetCooldown = true
                end
                if self.texture ~= actionTexture or  not self.cooldownStart or  not self.cooldownEnd then
                    self.cooldownStart = now
                    self.cooldownEnd = startTime
                    resetCooldown = true
                elseif startTime < self.cooldownEnd - COOLDOWN_THRESHOLD or startTime > self.cooldownEnd + COOLDOWN_THRESHOLD then
                    if startTime - self.cooldownEnd > 0.25 or startTime - self.cooldownEnd < -0.25 then
                        self.cooldownStart = now
                    else
                        local oldCooldownProgressPercent = (now - self.cooldownStart) / (self.cooldownEnd - self.cooldownStart)
                        self.cooldownStart = (now - oldCooldownProgressPercent * startTime) / (1 - oldCooldownProgressPercent)
                    end
                    self.cooldownEnd = startTime
                    resetCooldown = true
                end
                self.texture = actionTexture
            else
                self.cooldownStart = nil
                self.cooldownEnd = nil
            end
            if self.cdShown and profile.apparence.flashIcon and self.cooldownStart and self.cooldownEnd then
                local start, ending = self.cooldownStart, self.cooldownEnd
                local duration = ending - start
                if resetCooldown and duration > COOLDOWN_THRESHOLD then
                    cd:SetDrawEdge(false)
                    cd:SetSwipeColor(0, 0, 0, 0.8)
                    cd:SetCooldown(start, duration)
                    cd:Show()
                end
            else
                self.cd:Hide()
            end
            self.icone:Show()
            self.icone:SetTexture(actionTexture)
            local alpha = profile.apparence.alpha
            if actionUsable then
                self.icone:SetAlpha(alpha)
            else
                alpha = alpha / 2
                self.icone:SetAlpha(alpha)
            end
            if element.namedParams.nored ~= 1 and actionResourceExtend and actionResourceExtend > 0 then
                self.icone:SetVertexColor(0.75, 0.2, 0.2)
            else
                self.icone:SetVertexColor(1, 1, 1)
            end
            self.actionHelp = element.namedParams.help
            if  not (self.cooldownStart and self.cooldownEnd) then
                self.lastSound = nil
            end
            if element.namedParams.sound and  not self.lastSound then
                local delay = element.namedParams.soundtime or 0.5
                if now >= startTime - delay then
                    self.lastSound = element.namedParams.sound
                    API_PlaySoundFile(self.lastSound)
                end
            end
            local red = false
            if  not red and startTime > now and profile.apparence.highlightIcon then
                local lag = 0.6
                local newShouldClick = (startTime < now + lag)
                if self.shouldClick ~= newShouldClick then
                    if newShouldClick then
                        self.frame:SetChecked(true)
                    else
                        self.frame:SetChecked(false)
                    end
                    self.shouldClick = newShouldClick
                end
            elseif self.shouldClick then
                self.shouldClick = false
                self.frame:SetChecked(false)
            end
            if (profile.apparence.numeric or self.namedParams.text == "always") and startTime > now then
                self.remains:SetFormattedText("%.1f", startTime - now)
                self.remains:Show()
            else
                self.remains:Hide()
            end
            if profile.apparence.raccourcis then
                self.shortcut:Show()
                self.shortcut:SetText(actionShortcut)
            else
                self.shortcut:Hide()
            end
            if actionInRange == 1 then
                self.rangeIndicator:SetVertexColor(0.6, 0.6, 0.6)
                self.rangeIndicator:Show()
            elseif actionInRange == 0 then
                self.rangeIndicator:SetVertexColor(1, 0.1, 0.1)
                self.rangeIndicator:Show()
            else
                self.rangeIndicator:Hide()
            end
            if element.namedParams.text then
                self.focusText:SetText(_tostring(element.namedParams.text))
                self.focusText:Show()
            elseif actionTarget and actionTarget ~= "target" then
                self.focusText:SetText(actionTarget)
                self.focusText:Show()
            else
                self.focusText:Hide()
            end
            self.frame:Show()
        else
            self.icone:Hide()
            self.rangeIndicator:Hide()
            self.shortcut:Hide()
            self.remains:Hide()
            self.focusText:Hide()
            if profile.apparence.hideEmpty then
                self.frame:Hide()
            else
                self.frame:Show()
            end
            if self.shouldClick then
                self.frame:SetChecked(false)
                self.shouldClick = false
            end
        end
        return startTime, element
    end,
    SetHelp = function(self, help)
        self.help = help
    end,
    SetParams = function(self, positionalParams, namedParams, secure)
        self.positionalParams = positionalParams
        self.namedParams = namedParams
        self.actionButton = false
        if secure then
            for k, v in _pairs(namedParams) do
                local index = strfind(k, "spell")
                if index then
                    local prefix = strsub(k, 1, index - 1)
                    local suffix = strsub(k, index + 5)
                    self.frame:SetAttribute(prefix .. suffix, "spell")
                    self.frame:SetAttribute("unit", self.namedParams.target or "target")
                    self.frame:SetAttribute(k, __SpellBook.OvaleSpellBook:GetSpellName(v))
                    self.actionButton = true
                end
            end
        end
    end,
    SetRemainsFont = function(self, color)
        self.remains:SetTextColor(color.r, color.g, color.b, 1)
        self.remains:SetJustifyH("left")
        self.remains:SetPoint("BOTTOMLEFT", 2, 2)
    end,
    SetFontScale = function(self, scale)
        self.fontScale = scale
        self.remains:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
        self.shortcut:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
        self.rangeIndicator:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
        self.focusText:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
    end,
    SetRangeIndicator = function(self, text)
        self.rangeIndicator:SetText(text)
    end,
    OvaleIcon_OnMouseUp = function(self)
        if  not self.actionButton then
            __Ovale.Ovale:ToggleOptions()
        end
        self.frame:SetChecked(true)
    end,
    OvaleIcon_OnEnter = function(self)
        if self.help or self.actionType or HasScriptControls() then
            GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMLEFT")
            if self.help then
                GameTooltip:SetText(__Localization.L[self.help])
            end
            if self.actionType then
                local actionHelp = self.actionHelp
                if  not actionHelp then
                    if self.actionType == "spell" then
                        actionHelp = __SpellBook.OvaleSpellBook:GetSpellName(self.actionId)
                    elseif self.actionType == "value" then
                        actionHelp = (self.value < INFINITY) and _tostring(self.value) or "infinity"
                    else
                        actionHelp = format("%s %s", self.actionType, _tostring(self.actionId))
                    end
                end
                GameTooltip:AddLine(actionHelp, 0.5, 1, 0.75)
            end
            if HasScriptControls() then
                GameTooltip:AddLine(__Localization.L["Cliquer pour afficher/cacher les options"], 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end,
    OvaleIcon_OnLeave = function(self)
        if self.help or HasScriptControls() then
            GameTooltip:Hide()
        end
    end,
    OvaleIcon_OnLoad = function(self)
        local name = __Ovale.Ovale:GetName()
        local profile = __Ovale.Ovale.db.profile
        self.icone = _G[name]
        self.shortcut = _G[name]
        self.remains = _G[name]
        self.rangeIndicator = _G[name]
        self.rangeIndicator:SetText(profile.apparence.targetText)
        self.cd = _G[name]
        self.normalTexture = _G[name]
        local fontName, fontHeight, fontFlags = self.shortcut:GetFont()
        self.fontName = fontName
        self.fontHeight = fontHeight
        self.fontFlags = fontFlags
        self.focusText = self.frame:CreateFontString(nil, "OVERLAY")
        self.cdShown = true
        self.shouldClick = false
        self.help = nil
        self.value = nil
        self.fontScale = nil
        self.lastSound = nil
        self.cooldownEnd = nil
        self.cooldownStart = nil
        self.texture = nil
        self.positionalParams = nil
        self.namedParams = nil
        self.actionButton = false
        self.actionType = nil
        self.actionId = nil
        self.actionHelp = nil
        self.frame:SetScript("OnMouseUp", function()
            return self:OvaleIcon_OnMouseUp()
        end)
        self.frame:SetScript("OnEnter", function()
            return self:OvaleIcon_OnEnter()
        end)
        self.frame:SetScript("OnLeave", function()
            return self:OvaleIcon_OnLeave()
        end)
        self.focusText:SetFontObject("GameFontNormalSmall")
        self.focusText:SetAllPoints(self.frame)
        self.focusText:SetTextColor(1, 1, 1)
        self.focusText:SetText(__Localization.L["Focus"])
        self.frame:RegisterForClicks("AnyUp")
        if profile.apparence.clickThru then
            self.frame:EnableMouse(false)
        end
    end,
})
end)
