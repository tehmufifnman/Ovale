import __addon from "addon";
let [OVALE, Ovale] = __addon;
{
    let AceGUI = LibStub("AceGUI-3.0");
    let Masque = LibStub("Masque", true);
    import { OvaleBestAction } from "./OvaleBestAction";
    import { OvaleCompile } from "./OvaleCompile";
    import { OvaleCooldown } from "./OvaleCooldown";
    import { OvaleDebug } from "./OvaleDebug";
    import { OvaleFuture } from "./OvaleFuture";
    import { OvaleGUID } from "./OvaleGUID";
    import { OvaleSpellFlash } from "./OvaleSpellFlash";
    import { OvaleState } from "./OvaleState";
    import { OvaleTimeSpan } from "./OvaleTimeSpan";
    let Type = OVALE + "Frame";
    let Version = 7;
    let _ipairs = ipairs;
    let _next = next;
    let _pairs = pairs;
    let _tostring = tostring;
    let _wipe = wipe;
    let API_CreateFrame = CreateFrame;
    let API_GetTime = GetTime;
    let API_RegisterStateDriver = RegisterStateDriver;
    let NextTime = OvaleTimeSpan.NextTime;
    let INFINITY = math.huge;
    let MIN_REFRESH_TIME = 0.05;
    const frameOnClose = function(self) {
        this.obj.Fire("OnClose");
    }
    const closeOnClick = function(self) {
        this.obj.Hide();
    }
    const frameOnMouseDown = function(self) {
        if ((!Ovale.db.profile.apparence.verrouille)) {
            this.StartMoving();
            AceGUI.ClearFocus();
        }
    }
    const ToggleOptions = function(self) {
        if ((this.content.IsShown())) {
            this.content.Hide();
        } else {
            this.content.Show();
        }
    }
    const frameOnMouseUp = function(self) {
        this.StopMovingOrSizing();
        import { profile } from "./db";
        let [x, y] = this.GetCenter();
        let [parentX, parentY] = this.GetParent().GetCenter();
        profile.apparence.offsetX = x - parentX;
        profile.apparence.offsetY = y - parentY;
    }
    const frameOnEnter = function(self) {
        import { profile } from "./db";
        if (!(profile.apparence.enableIcons && profile.apparence.verrouille)) {
            this.obj.barre.Show();
        }
    }
    const frameOnLeave = function(self) {
        this.obj.barre.Hide();
    }
    const frameOnUpdate = function(self, elapsed) {
        this.obj.OnUpdate(elapsed);
    }
    const Hide = function(self) {
        this.frame.Hide();
    }
    const Show = function(self) {
        this.frame.Show();
    }
    const OnAcquire = function(self) {
        this.frame.SetParent(UIParent);
    }
    const OnRelease = function(self) {
    }
    const OnWidthSet = function(self, width) {
        let content = this.content;
        let contentwidth = width - 34;
        if (contentwidth < 0) {
            contentwidth = 0;
        }
        content.SetWidth(contentwidth);
        content.width = contentwidth;
    }
    const OnHeightSet = function(self, height) {
        let content = this.content;
        let contentheight = height - 57;
        if (contentheight < 0) {
            contentheight = 0;
        }
        content.SetHeight(contentheight);
        content.height = contentheight;
    }
    const OnLayoutFinished = function(self, width, height) {
        if ((!width)) {
            width = this.content.GetWidth();
        }
        this.content.SetWidth(width);
        this.content.SetHeight(height + 50);
    }
    const GetScore = function(self, spellId) {
        for (const [k, action] of _pairs(this.actions)) {
            if (action.spellId == spellId) {
                if (!action.waitStart) {
                    return 1;
                } else {
                    let now = API_GetTime();
                    let lag = now - action.waitStart;
                    if (lag > 5) {
                        return undefined;
                    } else if (lag > 1.5) {
                        return 0;
                    } else if (lag > 0) {
                        return 1 - lag / 1.5;
                    } else {
                        return 1;
                    }
                }
            }
        }
        return 0;
    }
    const OnUpdate = function(self, elapsed) {
        let guid = OvaleGUID.UnitGUID("target") || OvaleGUID.UnitGUID("focus");
        if (guid) {
            Ovale.refreshNeeded[guid] = true;
        }
        this.timeSinceLastUpdate = this.timeSinceLastUpdate + elapsed;
        let refresh = OvaleDebug.trace || this.timeSinceLastUpdate > MIN_REFRESH_TIME && _next(Ovale.refreshNeeded);
        if (refresh) {
            Ovale.AddRefreshInterval(this.timeSinceLastUpdate * 1000);
            let state = OvaleState.state;
            state.Initialize();
            if (OvaleCompile.EvaluateScript()) {
                Ovale.UpdateFrame();
            }
            import { profile } from "./db";
            let iconNodes = OvaleCompile.GetIconNodes();
            for (const [k, node] of _ipairs(iconNodes)) {
                if (node.namedParams && node.namedParams.target) {
                    state.defaultTarget = node.namedParams.target;
                } else {
                    state.defaultTarget = "target";
                }
                if (node.namedParams && node.namedParams.enemies) {
                    state.enemies = node.namedParams.enemies;
                } else {
                    state.enemies = undefined;
                }
                state.Log("+++ Icon %d", k);
                OvaleBestAction.StartNewAction(state);
                let atTime = state.nextCast;
                if (state.lastSpellId != state.lastGCDSpellId) {
                    atTime = state.currentTime;
                }
                let [timeSpan, element] = OvaleBestAction.GetAction(node, state, atTime);
                let start;
                if (element && element.offgcd) {
                    start = NextTime(timeSpan, state.currentTime);
                } else {
                    start = NextTime(timeSpan, atTime);
                }
                if (profile.apparence.enableIcons) {
                    this.UpdateActionIcon(state, node, this.actions[k], element, start);
                }
                if (profile.apparence.spellFlash.enabled) {
                    OvaleSpellFlash.Flash(state, node, element, start);
                }
            }
            _wipe(Ovale.refreshNeeded);
            OvaleDebug.UpdateTrace();
            Ovale.PrintOneTimeMessages();
            this.timeSinceLastUpdate = 0;
        }
    }
    const UpdateActionIcon = function(self, state, node, action, element, start, now) {
        import { profile } from "./db";
        let icons = action.secure && action.secureIcons || action.icons;
        now = now || API_GetTime();
        if (element && element.type == "value") {
            let value;
            if (element.value && element.origin && element.rate) {
                value = element.value + (now - element.origin) * element.rate;
            }
            state.Log("GetAction: start=%s, value=%f", start, value);
            let actionTexture;
            if (node.namedParams && node.namedParams.texture) {
                actionTexture = node.namedParams.texture;
            }
            icons[1].SetValue(value, actionTexture);
            if (lualength(icons) > 1) {
                icons[2].Update(element, undefined);
            }
        } else {
            let [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend] = OvaleBestAction.GetActionInfo(element, state);
            if (actionResourceExtend && actionResourceExtend > 0) {
                if (actionCooldownDuration > 0) {
                    state.Log("Extending cooldown of spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend);
                    actionCooldownDuration = actionCooldownDuration + actionResourceExtend;
                } else if (element.namedParams.pool_resource && element.namedParams.pool_resource == 1) {
                    state.Log("Delaying spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend);
                    start = start + actionResourceExtend;
                }
            }
            state.Log("GetAction: start=%s, id=%s", start, actionId);
            if (actionType == "spell" && actionId == state.currentSpellId && start && state.nextCast && start < state.nextCast) {
                start = state.nextCast;
            }
            if (start && node.namedParams.nocd && now < start - node.namedParams.nocd) {
                icons[1].Update(element, undefined);
            } else {
                icons[1].Update(element, start, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend);
            }
            if (actionType == "spell") {
                action.spellId = actionId;
            } else {
                action.spellId = undefined;
            }
            if (start && start <= now && actionUsable) {
                action.waitStart = action.waitStart || now;
            } else {
                action.waitStart = undefined;
            }
            if (profile.apparence.moving && icons[1].cooldownStart && icons[1].cooldownEnd) {
                let top = 1 - (now - icons[1].cooldownStart) / (icons[1].cooldownEnd - icons[1].cooldownStart);
                if (top < 0) {
                    top = 0;
                } else if (top > 1) {
                    top = 1;
                }
                icons[1].SetPoint("TOPLEFT", this.frame, "TOPLEFT", (action.left + top * action.dx) / action.scale, (action.top - top * action.dy) / action.scale);
                if (icons[2]) {
                    icons[2].SetPoint("TOPLEFT", this.frame, "TOPLEFT", (action.left + (top + 1) * action.dx) / action.scale, (action.top - (top + 1) * action.dy) / action.scale);
                }
            }
            if ((node.namedParams.size != "small" && !node.namedParams.nocd && profile.apparence.predictif)) {
                if (start) {
                    state.Log("****Second icon %s", start);
                    state.ApplySpell(actionId, OvaleGUID.UnitGUID(actionTarget), start);
                    let atTime = state.nextCast;
                    if (actionId != state.lastGCDSpellId) {
                        atTime = state.currentTime;
                    }
                    let [timeSpan, nextElement] = OvaleBestAction.GetAction(node, state, atTime);
                    let start;
                    if (nextElement && nextElement.offgcd) {
                        start = NextTime(timeSpan, state.currentTime);
                    } else {
                        start = NextTime(timeSpan, atTime);
                    }
                    icons[2].Update(nextElement, start, OvaleBestAction.GetActionInfo(nextElement, state));
                } else {
                    icons[2].Update(element, undefined);
                }
            }
        }
    }
    const UpdateFrame = function(self) {
        import { profile } from "./db";
        this.frame.SetPoint("CENTER", this.hider, "CENTER", profile.apparence.offsetX, profile.apparence.offsetY);
        this.frame.EnableMouse(!profile.apparence.clickThru);
    }
    const UpdateIcons = function(self) {
        for (const [k, action] of _pairs(this.actions)) {
            for (const [i, icon] of _pairs(action.icons)) {
                icon.Hide();
            }
            for (const [i, icon] of _pairs(action.secureIcons)) {
                icon.Hide();
            }
        }
        import { profile } from "./db";
        this.frame.EnableMouse(!profile.apparence.clickThru);
        let left = 0;
        let maxHeight = 0;
        let maxWidth = 0;
        let top = 0;
        let BARRE = 8;
        let margin = profile.apparence.margin;
        let iconNodes = OvaleCompile.GetIconNodes();
        for (const [k, node] of _ipairs(iconNodes)) {
            if (!this.actions[k]) {
                this.actions[k] = {
                    icons: {
                    },
                    secureIcons: {
                    }
                }
            }
            let action = this.actions[k];
            let [width, height, newScale];
            let nbIcons;
            if ((node.namedParams != undefined && node.namedParams.size == "small")) {
                newScale = profile.apparence.smallIconScale;
                width = newScale * 36 + margin;
                height = newScale * 36 + margin;
                nbIcons = 1;
            } else {
                newScale = profile.apparence.iconScale;
                width = newScale * 36 + margin;
                height = newScale * 36 + margin;
                if (profile.apparence.predictif && node.namedParams.type != "value") {
                    nbIcons = 2;
                } else {
                    nbIcons = 1;
                }
            }
            if ((top + height > profile.apparence.iconScale * 36 + margin)) {
                top = 0;
                left = maxWidth;
            }
            action.scale = newScale;
            if ((profile.apparence.vertical)) {
                action.left = top;
                action.top = -left - BARRE - margin;
                action.dx = width;
                action.dy = 0;
            } else {
                action.left = left;
                action.top = -top - BARRE - margin;
                action.dx = 0;
                action.dy = height;
            }
            action.secure = node.secure;
            for (let l = 1; l <= nbIcons; l += 1) {
                let icon;
                if (!node.secure) {
                    if (!action.icons[l]) {
                        action.icons[l] = API_CreateFrame("CheckButton", "Icon" + k + "n" + l, this.frame, OVALE + "IconTemplate");
                    }
                    icon = action.icons[l];
                } else {
                    if (!action.secureIcons[l]) {
                        action.secureIcons[l] = API_CreateFrame("CheckButton", "SecureIcon" + k + "n" + l, this.frame, "Secure" + OVALE + "IconTemplate");
                    }
                    icon = action.secureIcons[l];
                }
                let scale = action.scale;
                if (l > 1) {
                    scale = scale * profile.apparence.secondIconScale;
                }
                icon.SetPoint("TOPLEFT", this.frame, "TOPLEFT", (action.left + (l - 1) * action.dx) / scale, (action.top - (l - 1) * action.dy) / scale);
                icon.SetScale(scale);
                icon.SetRemainsFont(profile.apparence.remainsFontColor);
                icon.SetFontScale(profile.apparence.fontScale);
                icon.SetParams(node.positionalParams, node.namedParams);
                icon.SetHelp((node.namedParams != undefined && node.namedParams.help) || undefined);
                icon.SetRangeIndicator(profile.apparence.targetText);
                icon.EnableMouse(!profile.apparence.clickThru);
                icon.cdShown = (l == 1);
                if (Masque) {
                    this.skinGroup.AddButton(icon);
                }
                if (l == 1) {
                    icon.Show();
                }
            }
            top = top + height;
            if ((top > maxHeight)) {
                maxHeight = top;
            }
            if ((left + width > maxWidth)) {
                maxWidth = left + width;
            }
        }
        if ((profile.apparence.vertical)) {
            this.barre.SetWidth(maxHeight - margin);
            this.barre.SetHeight(BARRE);
            this.frame.SetWidth(maxHeight + profile.apparence.iconShiftY);
            this.frame.SetHeight(maxWidth + BARRE + margin + profile.apparence.iconShiftX);
            this.content.SetPoint("TOPLEFT", this.frame, "TOPLEFT", maxHeight + profile.apparence.iconShiftX, profile.apparence.iconShiftY);
        } else {
            this.barre.SetWidth(maxWidth - margin);
            this.barre.SetHeight(BARRE);
            this.frame.SetWidth(maxWidth);
            this.frame.SetHeight(maxHeight + BARRE + margin);
            this.content.SetPoint("TOPLEFT", this.frame, "TOPLEFT", maxWidth + profile.apparence.iconShiftX, profile.apparence.iconShiftY);
        }
    }
    const Constructor = function() {
        let hider = API_CreateFrame("Frame", OVALE + "PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate");
        hider.SetAllPoints(true);
        API_RegisterStateDriver(hider, "visibility", "[petbattle] hide; show");
        let frame = API_CreateFrame("Frame", undefined, hider);
        let self = {
        }
        import { profile } from "./db";
        this.Hide = Hide;
        this.Show = Show;
        this.OnRelease = OnRelease;
        this.OnAcquire = OnAcquire;
        this.LayoutFinished = OnLayoutFinished;
        this.UpdateActionIcon = UpdateActionIcon;
        this.UpdateFrame = UpdateFrame;
        this.UpdateIcons = UpdateIcons;
        this.ToggleOptions = ToggleOptions;
        this.OnUpdate = OnUpdate;
        this.GetScore = GetScore;
        this.type = "Frame";
        this.localstatus = {
        }
        this.actions = {
        }
        this.frame = frame;
        this.hider = hider;
        this.updateFrame = API_CreateFrame("Frame", OVALE + "UpdateFrame");
        this.barre = this.frame.CreateTexture();
        this.content = API_CreateFrame("Frame", undefined, this.updateFrame);
        if (Masque) {
            this.skinGroup = Masque.Group(OVALE);
        }
        this.timeSinceLastUpdate = INFINITY;
        this.obj = undefined;
        frame.obj = this;
        frame.SetWidth(100);
        frame.SetHeight(100);
        this.UpdateFrame();
        frame.SetMovable(true);
        frame.SetFrameStrata("MEDIUM");
        frame.SetScript("OnMouseDown", frameOnMouseDown);
        frame.SetScript("OnMouseUp", frameOnMouseUp);
        frame.SetScript("OnEnter", frameOnEnter);
        frame.SetScript("OnLeave", frameOnLeave);
        frame.SetScript("OnHide", frameOnClose);
        frame.SetAlpha(profile.apparence.alpha);
        this.updateFrame.SetScript("OnUpdate", frameOnUpdate);
        this.updateFrame.obj = this;
        this.barre.SetTexture(0, 0.8, 0);
        this.barre.SetPoint("TOPLEFT", 0, 0);
        this.barre.Hide();
        let content = this.content;
        content.obj = this;
        content.SetWidth(200);
        content.SetHeight(100);
        content.Hide();
        content.SetAlpha(profile.apparence.optionsAlpha);
        AceGUI.RegisterAsContainer(this);
        return this;
    }
    AceGUI.RegisterWidgetType(Type, Constructor, Version);
}
