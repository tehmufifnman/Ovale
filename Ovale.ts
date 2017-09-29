import __addon from "addon";
let [OVALE, Addon] = __addon;
const OvaleBase = Addon.NewModule("Ovale", "AceEvent-3.0");
import AceGUI from "AceGUI-3.0";
import { OvaleFuture } from "./Future";
import { OvaleDebug } from "./Debug";
import { L } from "./Localization";
let _assert = assert;
let format = string.format;
let _ipairs = ipairs;
let _next = next;
let _pairs = pairs;
let _select = select;
let strfind = string.find;
let _strjoin = strjoin;
let strlen = string.len;
let strmatch = string.match;
let _tostring = tostring;
let _tostringall = tostringall;
let _type = type;
let _unpack = unpack;
let _wipe = wipe;
let API_GetItemInfo = GetItemInfo;
let API_GetTime = GetTime;
let API_UnitCanAttack = UnitCanAttack;
let API_UnitClass = UnitClass;
let API_UnitExists = UnitExists;
let API_UnitGUID = UnitGUID;
let API_UnitHasVehicleUI = UnitHasVehicleUI;
let API_UnitIsDead = UnitIsDead;
let _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME;
let INFINITY = math.huge;
let OVALE_VERSION = "7.3.0.2";
let REPOSITORY_KEYWORD = "@" + "project-version" + "@";
let self_oneTimeMessage = {
}
let MAX_REFRESH_INTERVALS = 500;
let self_refreshIntervals:LuaArray<number> = {
}
let self_refreshIndex = 1;

export type Constructor<T> = new(...args: any[]) => T;

export function MakeString(s?, ...__args) {
    if (s && strlen(s) > 0) {
        if (__args.length > 0) {
            if (strfind(s, "%%%.%d") || strfind(s, "%%[%w]")) {
                s = format(s, ..._tostringall(...__args));
            } else {
                s = _strjoin(" ", s, ..._tostringall(...__args));
            }
        }
    } else {
        s = _tostring(undefined);
    }
    return s;
}

export function RegisterPrinter<T extends Constructor<AceModule>>(base: T) {
    return class extends base {
        Print(...__args) {
            let name = this.GetName();
            let s = MakeString(...__args);
            _DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
        }
        Error(...__args) {
            let s = MakeString(...__args);
            this.Print("Fatal error: %s", s);
            OvaleDebug.bug = true;
        }
        GetMethod(methodName, subModule) {
            let [func, arg] = [this[methodName], this];
            if (!func) {
                [func, arg] = [subModule[methodName], subModule];
            }
            _assert(func != undefined);
            return [func, arg];
        }
    
    }    
}

class OvaleClass extends RegisterPrinter(OvaleBase) {
    L = undefined;
    playerClass = _select(2, API_UnitClass("player"));
    playerGUID: string = undefined;
    db = undefined;
    frame = undefined;
    checkBox = {
    }
    list = {
    }
    checkBoxWidget = {
    }
    listWidget = {
    }
    refreshNeeded = {
    }
    MSG_PREFIX = OVALE;

    OnCheckBoxValueChanged(widget) {
        let name = widget.GetUserData("name");
        this.db.profile.check[name] = widget.GetValue();
        this.SendMessage("Ovale_CheckBoxValueChanged", name);
    }

    OnDropDownValueChanged = function(widget) {
        let name = widget.GetUserData("name");
        this.db.profile.list[name] = widget.GetValue();
        this.SendMessage("Ovale_ListValueChanged", name);
    }

    OnInitialize() {
        _G["BINDING_HEADER_OVALE"] = OVALE;
        let toggleCheckBox = L["Inverser la boîte à cocher "];
        _G["BINDING_NAME_OVALE_CHECKBOX0"] = toggleCheckBox + "(1)";
        _G["BINDING_NAME_OVALE_CHECKBOX1"] = toggleCheckBox + "(2)";
        _G["BINDING_NAME_OVALE_CHECKBOX2"] = toggleCheckBox + "(3)";
        _G["BINDING_NAME_OVALE_CHECKBOX3"] = toggleCheckBox + "(4)";
        _G["BINDING_NAME_OVALE_CHECKBOX4"] = toggleCheckBox + "(5)";
    }

    OnEnable() {
        this.playerGUID = API_UnitGUID("player");
        this.RegisterEvent("PLAYER_ENTERING_WORLD");
        this.RegisterEvent("PLAYER_TARGET_CHANGED");
        this.RegisterMessage("Ovale_CombatStarted");
        this.RegisterMessage("Ovale_OptionChanged");
        this.frame = AceGUI.Create(OVALE + "Frame");
        this.UpdateFrame();
    }

    OnDisable() {
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.UnregisterMessage("Ovale_CombatEnded");
        this.UnregisterMessage("Ovale_OptionChanged");
        this.frame.Hide();
    }
    PLAYER_ENTERING_WORLD() {
        _wipe(self_refreshIntervals);
        self_refreshIndex = 1;
        this.ClearOneTimeMessages();
    }
    PLAYER_TARGET_CHANGED() {
        this.UpdateVisibility();
    }
    Ovale_CombatStarted(event, atTime) {
        this.UpdateVisibility();
    }
    Ovale_CombatEnded(event, atTime) {
        this.UpdateVisibility();
    }
    Ovale_OptionChanged(event, eventType) {
        if (eventType == "visibility") {
            this.UpdateVisibility();
        } else {
            if (eventType == "layout") {
                this.frame.UpdateFrame();
            }
            this.UpdateFrame();
        }
    }
    IsPreloaded(moduleList) {
        let preloaded = true;
        for (const [_, moduleName] of _pairs(moduleList)) {
            preloaded = preloaded && this[moduleName].ready;
        }
        return preloaded;
    }
    ToggleOptions() {
        this.frame.ToggleOptions();
    }
    UpdateVisibility() {
        let visible = true;
        let profile = this.db.profile;
        if (!profile.apparence.enableIcons) {
            visible = false;
        } else if (!this.frame.hider.IsVisible()) {
            visible = false;
        } else {
            if (profile.apparence.hideVehicule && API_UnitHasVehicleUI("player")) {
                visible = false;
            }
            if (profile.apparence.avecCible && !API_UnitExists("target")) {
                visible = false;
            }
            if (profile.apparence.enCombat && !OvaleFuture.inCombat) {
                visible = false;
            }
            if (profile.apparence.targetHostileOnly && (API_UnitIsDead("target") || !API_UnitCanAttack("player", "target"))) {
                visible = false;
            }
        }
        if (visible) {
            this.frame.Show();
        } else {
            this.frame.Hide();
        }
    }
    ResetControls() {
        _wipe(this.checkBox);
        _wipe(this.list);
    }
    UpdateControls() {
        let profile = this.db.profile;
        _wipe(this.checkBoxWidget);
        for (const [name, checkBox] of _pairs(this.checkBox)) {
            if (checkBox.text) {
                let widget = AceGUI.Create("CheckBox");
                let text = this.FinalizeString(checkBox.text);
                widget.SetLabel(text);
                if (profile.check[name] == undefined) {
                    profile.check[name] = checkBox.checked;
                }
                if (profile.check[name]) {
                    widget.SetValue(profile.check[name]);
                }
                widget.SetUserData("name", name);
                widget.SetCallback("OnValueChanged", this.OnCheckBoxValueChanged);
                this.frame.AddChild(widget);
                this.checkBoxWidget[name] = widget;
            } else {
                this.OneTimeMessage("Warning: checkbox '%s' is used but not defined.", name);
            }
        }
        _wipe(this.listWidget);
        for (const [name, list] of _pairs(this.list)) {
            if (_next(list.items)) {
                let widget = AceGUI.Create("Dropdown");
                widget.SetList(list.items);
                if (!profile.list[name]) {
                    profile.list[name] = list.default;
                }
                if (profile.list[name]) {
                    widget.SetValue(profile.list[name]);
                }
                widget.SetUserData("name", name);
                widget.SetCallback("OnValueChanged", this.OnDropDownValueChanged);
                this.frame.AddChild(widget);
                this.listWidget[name] = widget;
            } else {
                this.OneTimeMessage("Warning: list '%s' is used but has no items.", name);
            }
        }
    }
    UpdateFrame() {
        this.frame.ReleaseChildren();
        this.frame.UpdateIcons();
        this.UpdateControls();
        this.UpdateVisibility();
    }
    GetCheckBox(name) {
        let widget;
        if (_type(name) == "string") {
            widget = this.checkBoxWidget[name];
        } else if (_type(name) == "number") {
            let k = 0;
            for (const [_, frame] of _pairs(this.checkBoxWidget)) {
                if (k == name) {
                    widget = frame;
                    break;
                }
                k = k + 1;
            }
        }
        return widget;
    }
    IsChecked(name) {
        let widget = this.GetCheckBox(name);
        return widget && widget.GetValue();
    }
    GetListValue(name) {
        let widget = this.listWidget[name];
        return widget && widget.GetValue();
    }
    SetCheckBox(name, on) {
        let widget = this.GetCheckBox(name);
        if (widget) {
            let oldValue = widget.GetValue();
            if (oldValue != on) {
                widget.SetValue(on);
                this.OnCheckBoxValueChanged(widget);
            }
        }
    }
    ToggleCheckBox(name) {
        let widget = this.GetCheckBox(name);
        if (widget) {
            let on = !widget.GetValue();
            widget.SetValue(on);
            this.OnCheckBoxValueChanged(widget);
        }
    }
    AddRefreshInterval(milliseconds) {
        if (milliseconds < INFINITY) {
            self_refreshIntervals[self_refreshIndex] = milliseconds;
            self_refreshIndex = (self_refreshIndex < MAX_REFRESH_INTERVALS) && (self_refreshIndex + 1) || 1;
        }
    }
    GetRefreshIntervalStatistics() {
        let [sumRefresh, minRefresh, maxRefresh, count] = [0, INFINITY, 0, 0];
        for (const [k, v] of _ipairs(self_refreshIntervals)) {
            if (v > 0) {
                if (minRefresh > v) {
                    minRefresh = v;
                }
                if (maxRefresh < v) {
                    maxRefresh = v;
                }
                sumRefresh = sumRefresh + v;
                count = count + 1;
            }
        }
        let avgRefresh = (count > 0) && (sumRefresh / count) || 0;
        return [avgRefresh, minRefresh, maxRefresh, count];
    }
    FinalizeString(s) {
        let [item, id] = strmatch(s, "^(item:)(.+)");
        if (item) {
            s = API_GetItemInfo(id);
        }
        return s;
    }
    
    OneTimeMessage(...__args) {
        let s = MakeString(...__args);
        if (!self_oneTimeMessage[s]) {
            self_oneTimeMessage[s] = true;
        }
    }
    ClearOneTimeMessages() {
        _wipe(self_oneTimeMessage);
    }
    PrintOneTimeMessages() {
        for (const [s] of _pairs(self_oneTimeMessage)) {
            if (self_oneTimeMessage[s] != "printed") {
                this.Print(s);
                self_oneTimeMessage[s] = "printed";
            }
        }
    }
}

export const Ovale = new OvaleClass();

