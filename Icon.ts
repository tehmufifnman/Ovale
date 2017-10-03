import { L } from "./Localization";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleState, baseState } from "./State";
import { Ovale } from "./Ovale";
let format = string.format;
let _next = next;
let _pairs = pairs;
let strfind = string.find;
let strsub = string.sub;
let _tostring = tostring;
let API_GetTime = GetTime;
let API_PlaySoundFile = PlaySoundFile;
let INFINITY = math.huge;
let COOLDOWN_THRESHOLD = 0.1;
const HasScriptControls = function() {
    return (_next(Ovale.checkBoxWidget) != undefined || _next(Ovale.listWidget) != undefined);
}

export class OvaleIcon {
    actionHelp: any;
    actionId: any;
    actionType: any;
    actionButton: boolean;
    namedParams: any;
    positionalParams: any;
    texture: any;
    cooldownStart: any;
    cooldownEnd: any;
    lastSound: any;
    fontScale: any;
    value: any;
    help: any;
    shouldClick: boolean;
    cdShown: boolean;
    focusText: UIFontString;
    fontFlags: any;
    fontHeight: any;
    fontName: any;
    normalTexture: any;
    cd: any;
    rangeIndicator: any;
    remains: any;
    shortcut: any;
    icone: any;
    frame: UICheckButton;

    constructor(name: string, parent: UIFrame, secure: boolean) {
        if (!secure) {
            this.frame = CreateFrame("CheckButton", name, parent, "ActionButtonTemplate");
        }        
        else{
            this.frame = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, ActionButtonTemplate");
        }
        this.OvaleIcon_OnLoad();
    }

    SetValue(value, actionTexture) {
        this.icone.Show();
        this.icone.SetTexture(actionTexture);
        this.icone.SetAlpha(Ovale.db.profile.apparence.alpha);
        this.cd.Hide();
        this.focusText.Hide();
        this.rangeIndicator.Hide();
        this.shortcut.Hide();
        if (value) {
            this.actionType = "value";
            this.actionHelp = undefined;
            this.value = value;
            if (value < 10) {
                this.remains.SetFormattedText("%.1f", value);
            } else if (value == INFINITY) {
                this.remains.SetFormattedText("inf");
            } else {
                this.remains.SetFormattedText("%d", value);
            }
            this.remains.Show();
        } else {
            this.remains.Hide();
        }
        this.frame.Show();
    }
    Update(element, startTime, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend) {
        this.actionType = actionType;
        this.actionId = actionId;
        this.value = undefined;
        let now = API_GetTime();
        const profile = Ovale.db.profile;
        if (startTime && actionTexture) {
            let cd = this.cd;
            let resetCooldown = false;
            if (startTime > now) {
                let duration = cd.GetCooldownDuration();
                if (duration == 0 && this.texture == actionTexture && this.cooldownStart && this.cooldownEnd) {
                    resetCooldown = true;
                }
                if (this.texture != actionTexture || !this.cooldownStart || !this.cooldownEnd) {
                    this.cooldownStart = now;
                    this.cooldownEnd = startTime;
                    resetCooldown = true;
                } else if (startTime < this.cooldownEnd - COOLDOWN_THRESHOLD || startTime > this.cooldownEnd + COOLDOWN_THRESHOLD) {
                    if (startTime - this.cooldownEnd > 0.25 || startTime - this.cooldownEnd < -0.25) {
                        this.cooldownStart = now;
                    } else {
                        let oldCooldownProgressPercent = (now - this.cooldownStart) / (this.cooldownEnd - this.cooldownStart);
                        this.cooldownStart = (now - oldCooldownProgressPercent * startTime) / (1 - oldCooldownProgressPercent);
                    }
                    this.cooldownEnd = startTime;
                    resetCooldown = true;
                }
                this.texture = actionTexture;
            } else {
                this.cooldownStart = undefined;
                this.cooldownEnd = undefined;
            }
            if (this.cdShown && profile.apparence.flashIcon && this.cooldownStart && this.cooldownEnd) {
                let [start, ending] = [this.cooldownStart, this.cooldownEnd];
                let duration = ending - start;
                if (resetCooldown && duration > COOLDOWN_THRESHOLD) {
                    cd.SetDrawEdge(false);
                    cd.SetSwipeColor(0, 0, 0, 0.8);
                    cd.SetCooldown(start, duration);
                    cd.Show();
                }
            } else {
                this.cd.Hide();
            }
            this.icone.Show();
            this.icone.SetTexture(actionTexture);
            let alpha = profile.apparence.alpha;
            if (actionUsable) {
                this.icone.SetAlpha(alpha);
            } else {
                alpha = alpha / 2;
                this.icone.SetAlpha(alpha);
            }
            if (element.namedParams.nored != 1 && actionResourceExtend && actionResourceExtend > 0) {
                this.icone.SetVertexColor(0.75, 0.2, 0.2);
            } else {
                this.icone.SetVertexColor(1, 1, 1);
            }
            this.actionHelp = element.namedParams.help;
            if (!(this.cooldownStart && this.cooldownEnd)) {
                this.lastSound = undefined;
            }
            if (element.namedParams.sound && !this.lastSound) {
                let delay = element.namedParams.soundtime || 0.5;
                if (now >= startTime - delay) {
                    this.lastSound = element.namedParams.sound;
                    API_PlaySoundFile(this.lastSound);
                }
            }
            let red = false; // TODO This value is not set anymore, find why
            if (!red && startTime > now && profile.apparence.highlightIcon) {
                let lag = 0.6;
                let newShouldClick = (startTime < now + lag);
                if (this.shouldClick != newShouldClick) {
                    if (newShouldClick) {
                        this.frame.SetChecked(true);
                    } else {
                        this.frame.SetChecked(false);
                    }
                    this.shouldClick = newShouldClick;
                }
            } else if (this.shouldClick) {
                this.shouldClick = false;
                this.frame.SetChecked(false);
            }
            if ((profile.apparence.numeric || this.namedParams.text == "always") && startTime > now) {
                this.remains.SetFormattedText("%.1f", startTime - now);
                this.remains.Show();
            } else {
                this.remains.Hide();
            }
            if (profile.apparence.raccourcis) {
                this.shortcut.Show();
                this.shortcut.SetText(actionShortcut);
            } else {
                this.shortcut.Hide();
            }
            if (actionInRange == 1) {
                this.rangeIndicator.SetVertexColor(0.6, 0.6, 0.6);
                this.rangeIndicator.Show();
            } else if (actionInRange == 0) {
                this.rangeIndicator.SetVertexColor(1.0, 0.1, 0.1);
                this.rangeIndicator.Show();
            } else {
                this.rangeIndicator.Hide();
            }
            if (element.namedParams.text) {
                this.focusText.SetText(_tostring(element.namedParams.text));
                this.focusText.Show();
            } else if (actionTarget && actionTarget != "target") {
                this.focusText.SetText(actionTarget);
                this.focusText.Show();
            } else {
                this.focusText.Hide();
            }
            this.frame.Show();
        } else {
            this.icone.Hide();
            this.rangeIndicator.Hide();
            this.shortcut.Hide();
            this.remains.Hide();
            this.focusText.Hide();
            if (profile.apparence.hideEmpty) {
                this.frame.Hide();
            } else {
                this.frame.Show();
            }
            if (this.shouldClick) {
                this.frame.SetChecked(false);
                this.shouldClick = false;
            }
        }
        return [startTime, element];
    }
    SetHelp(help) {
        this.help = help;
    }
    SetParams(positionalParams, namedParams, secure) {
        this.positionalParams = positionalParams;
        this.namedParams = namedParams;
        this.actionButton = false;
        if (secure) {
            for (const [k, v] of _pairs(namedParams)) {
                let [index] = strfind(k, "spell");
                if (index) {
                    let prefix = strsub(k, 1, index - 1);
                    let suffix = strsub(k, index + 5);
                    this.frame.SetAttribute(`${prefix}type${suffix}`, "spell");
                    this.frame.SetAttribute("unit", this.namedParams.target || "target");
                    this.frame.SetAttribute(k, OvaleSpellBook.GetSpellName(v));
                    this.actionButton = true;
                }
            }
        }
    }
    SetRemainsFont(color) {
        this.remains.SetTextColor(color.r, color.g, color.b, 1.0);
        this.remains.SetJustifyH("left");
        this.remains.SetPoint("BOTTOMLEFT", 2, 2);
    }
    SetFontScale(scale) {
        this.fontScale = scale;
        this.remains.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
        this.shortcut.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
        this.rangeIndicator.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
        this.focusText.SetFont(this.fontName, this.fontHeight * this.fontScale, this.fontFlags);
    }
    SetRangeIndicator(text) {
        this.rangeIndicator.SetText(text);
    }
    OvaleIcon_OnMouseUp() {
        if (!this.actionButton) {
            Ovale.ToggleOptions();
        }
        this.frame.SetChecked(true);
    }
    OvaleIcon_OnEnter() {
        if (this.help || this.actionType || HasScriptControls()) {
            GameTooltip.SetOwner(this.frame, "ANCHOR_BOTTOMLEFT");
            if (this.help) {
                GameTooltip.SetText(L[this.help]);
            }
            if (this.actionType) {
                let actionHelp = this.actionHelp;
                if (!actionHelp) {
                    if (this.actionType == "spell") {
                        actionHelp = OvaleSpellBook.GetSpellName(this.actionId);
                    } else if (this.actionType == "value") {
                        actionHelp = (this.value < INFINITY) && _tostring(this.value) || "infinity";
                    } else {
                        actionHelp = format("%s %s", this.actionType, _tostring(this.actionId));
                    }
                }
                GameTooltip.AddLine(actionHelp, 0.5, 1, 0.75);
            }
            if (HasScriptControls()) {
                GameTooltip.AddLine(L["Cliquer pour afficher/cacher les options"], 1, 1, 1);
            }
            GameTooltip.Show();
        }
    }
    OvaleIcon_OnLeave() {
        if (this.help || HasScriptControls()) {
            GameTooltip.Hide();
        }
    }
    OvaleIcon_OnLoad() {
        let name = Ovale.GetName();
        const profile = Ovale.db.profile;
        this.icone = _G[`${name}Icon`];
        this.shortcut = _G[`${name}HotKey`];
        this.remains = _G[`${name}Name`];
        this.rangeIndicator = _G[`${name}Count`];
        this.rangeIndicator.SetText(profile.apparence.targetText);
        this.cd = _G[`${name}Cooldown`];
        this.normalTexture = _G[`${name}NormalTexture`];
        let [fontName, fontHeight, fontFlags] = this.shortcut.GetFont();
        this.fontName = fontName;
        this.fontHeight = fontHeight;
        this.fontFlags = fontFlags;
        this.focusText = this.frame.CreateFontString(undefined, "OVERLAY");
        this.cdShown = true;
        this.shouldClick = false;
        this.help = undefined;
        this.value = undefined;
        this.fontScale = undefined;
        this.lastSound = undefined;
        this.cooldownEnd = undefined;
        this.cooldownStart = undefined;
        this.texture = undefined;
        this.positionalParams = undefined;
        this.namedParams = undefined;
        this.actionButton = false;
        this.actionType = undefined;
        this.actionId = undefined;
        this.actionHelp = undefined;
        this.frame.SetScript("OnMouseUp", () => this.OvaleIcon_OnMouseUp());
        this.frame.SetScript("OnEnter", () => this.OvaleIcon_OnEnter());
        this.frame.SetScript("OnLeave", () => this.OvaleIcon_OnLeave());
        this.focusText.SetFontObject("GameFontNormalSmall");
        this.focusText.SetAllPoints(this.frame);
        this.focusText.SetTextColor(1, 1, 1);
        this.focusText.SetText(L["Focus"]);
        this.frame.RegisterForClicks("AnyUp");
        if (profile.apparence.clickThru) {
            this.frame.EnableMouse(false);
        }
    }
}
