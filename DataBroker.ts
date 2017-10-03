import { L } from "./Localization";
import LibDataBroker from "LibDataBroker-1.1";
import LibDBIcon from "LibDBIcon-1.0";
import { OvaleDebug } from "./Debug";
import { OvaleOptions } from "./Options";
import { Ovale } from "./Ovale";
import { OvaleScripts } from "./Scripts";
import { OvaleVersion } from "./Version";
let OvaleDataBrokerBase = Ovale.NewModule("OvaleDataBroker", "AceEvent-3.0");
export let OvaleDataBroker: OvaleDataBrokerClass;

let _pairs = pairs;
let tinsert = table.insert;
let API_CreateFrame = CreateFrame;
let API_EasyMenu = EasyMenu;
let API_IsShiftKeyDown = IsShiftKeyDown;
let CLASS_ICONS = {
    ["DEATHKNIGHT"]: "Interface\\Icons\\ClassIcon_DeathKnight",
    ["DEMONHUNTER"]: "Interface\\Icons\\ClassIcon_DemonHunter",
    ["DRUID"]: "Interface\\Icons\\ClassIcon_Druid",
    ["HUNTER"]: "Interface\\Icons\\ClassIcon_Hunter",
    ["MAGE"]: "Interface\\Icons\\ClassIcon_Mage",
    ["MONK"]: "Interface\\Icons\\ClassIcon_Monk",
    ["PALADIN"]: "Interface\\Icons\\ClassIcon_Paladin",
    ["PRIEST"]: "Interface\\Icons\\ClassIcon_Priest",
    ["ROGUE"]: "Interface\\Icons\\ClassIcon_Rogue",
    ["SHAMAN"]: "Interface\\Icons\\ClassIcon_Shaman",
    ["WARLOCK"]: "Interface\\Icons\\ClassIcon_Warlock",
    ["WARRIOR"]: "Interface\\Icons\\ClassIcon_Warrior"
}
let self_menuFrame = undefined;
let self_tooltipTitle = undefined;
{
    let defaultDB = {
        minimap: {
        }
    }
    let options = {
        minimap: {
            order: 25,
            type: "toggle",
            name: L["Show minimap icon"],
            get: function (info) {
                return !Ovale.db.profile.apparence.minimap.hide;
            },
            set: function (info, value) {
                Ovale.db.profile.apparence.minimap.hide = !value;
                OvaleDataBroker.UpdateIcon();
            }
        }
    }
    for (const [k, v] of _pairs(defaultDB)) {
        OvaleOptions.defaultDB.profile.apparence[k] = v;
    }
    for (const [k, v] of _pairs(options)) {
        OvaleOptions.options.args.apparence.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleDataBroker);
}

interface MenuItem {
    text: string;
    isTitle?: boolean;
    func?: () => void;
}

const OnClick = function(frame, button) {
    if (button == "LeftButton") {
        let menu:LuaArray<MenuItem> = {
            1: {
                text: L["Script"],
                isTitle: true
            }
        }
        let scriptType = !Ovale.db.profile.showHiddenScripts && "script";
        let descriptions = OvaleScripts.GetDescriptions(scriptType);
        for (const [name, description] of _pairs(descriptions)) {
            let menuItem = {
                text: description,
                func: function () {
                    OvaleScripts.SetScript(name);
                }
            }
            tinsert(menu, menuItem);
        }
        self_menuFrame = self_menuFrame || API_CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate");
        API_EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU");
    } else if (button == "MiddleButton") {
        Ovale.ToggleOptions();
    } else if (button == "RightButton") {
        if (API_IsShiftKeyDown()) {
            OvaleDebug.DoTrace(true);
        } else {
            OvaleOptions.ToggleConfig();
        }
    }
}
const OnTooltipShow = function(tooltip) {
    self_tooltipTitle = self_tooltipTitle || `${Ovale.GetName()} ${OvaleVersion.version}`;
    tooltip.SetText(self_tooltipTitle, 1, 1, 1);
    tooltip.AddLine(L["Click to select the script."]);
    tooltip.AddLine(L["Middle-Click to toggle the script options panel."]);
    tooltip.AddLine(L["Right-Click for options."]);
    tooltip.AddLine(L["Shift-Right-Click for the current trace log."]);
}
class OvaleDataBrokerClass extends OvaleDataBrokerBase {
    broker = undefined;
    OnInitialize() {
        if (LibDataBroker) {
            let broker = {
                type: "data source",
                text: "",
                icon: CLASS_ICONS[Ovale.playerClass],
                OnClick: OnClick,
                OnTooltipShow: OnTooltipShow
            }
            this.broker = LibDataBroker.NewDataObject(Ovale.GetName(), broker);
            if (LibDBIcon) {
                LibDBIcon.Register(Ovale.GetName(), this.broker, Ovale.db.profile.apparence.minimap);
            }
        }
    }
    OnEnable() {
        if (this.broker) {
            this.RegisterMessage("Ovale_ProfileChanged", "UpdateIcon");
            this.RegisterMessage("Ovale_ScriptChanged");
            this.Ovale_ScriptChanged();
            this.UpdateIcon();
        }
    }
    OnDisable() {
        if (this.broker) {
            this.UnregisterMessage("Ovale_ProfileChanged");
            this.UnregisterMessage("Ovale_ScriptChanged");
        }
    }
    UpdateIcon() {
        if (LibDBIcon && this.broker) {
            const minimap = Ovale.db.profile.apparence.minimap
            LibDBIcon.Refresh(Ovale.GetName(), minimap);
            if (minimap.hide) {
                LibDBIcon.Hide(Ovale.GetName());
            } else {
                LibDBIcon.Show(Ovale.GetName());
            }
        }
    }
    Ovale_ScriptChanged() {
        this.broker.text = Ovale.db.profile.source;
    }
}

OvaleDataBroker = new OvaleDataBrokerClass();