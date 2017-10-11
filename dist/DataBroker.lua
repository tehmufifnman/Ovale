local __addonName, __addon = ...
            __addon.require("./DataBroker", { "./Localization", "LibDataBroker-1.1", "LibDBIcon-1.0", "./Debug", "./Options", "./Ovale", "./Scripts", "./Version", "./Frame" }, function(__exports, __Localization, LibDataBroker, LibDBIcon, __Debug, __Options, __Ovale, __Scripts, __Version, __Frame)
local OvaleDataBrokerBase = __Ovale.Ovale:NewModule("OvaleDataBroker", "AceEvent-3.0")
local _pairs = pairs
local tinsert = table.insert
local API_CreateFrame = CreateFrame
local API_EasyMenu = EasyMenu
local API_IsShiftKeyDown = IsShiftKeyDown
local CLASS_ICONS = {
    ["DEATHKNIGHT"] = "Interface\\Icons\\ClassIcon_DeathKnight",
    ["DEMONHUNTER"] = "Interface\\Icons\\ClassIcon_DemonHunter",
    ["DRUID"] = "Interface\\Icons\\ClassIcon_Druid",
    ["HUNTER"] = "Interface\\Icons\\ClassIcon_Hunter",
    ["MAGE"] = "Interface\\Icons\\ClassIcon_Mage",
    ["MONK"] = "Interface\\Icons\\ClassIcon_Monk",
    ["PALADIN"] = "Interface\\Icons\\ClassIcon_Paladin",
    ["PRIEST"] = "Interface\\Icons\\ClassIcon_Priest",
    ["ROGUE"] = "Interface\\Icons\\ClassIcon_Rogue",
    ["SHAMAN"] = "Interface\\Icons\\ClassIcon_Shaman",
    ["WARLOCK"] = "Interface\\Icons\\ClassIcon_Warlock",
    ["WARRIOR"] = "Interface\\Icons\\ClassIcon_Warrior"
}
local self_menuFrame = nil
local self_tooltipTitle = nil
do
    local defaultDB = {
        minimap = {}
    }
    local options = {
        minimap = {
            order = 25,
            type = "toggle",
            name = __Localization.L["Show minimap icon"],
            get = function(info)
                return  not __Ovale.Ovale.db.profile.apparence.minimap.hide
            end
,
            set = function(info, value)
                __Ovale.Ovale.db.profile.apparence.minimap.hide =  not value
                __exports.OvaleDataBroker:UpdateIcon()
            end

        }
    }
    for k, v in _pairs(defaultDB) do
        __Options.OvaleOptions.defaultDB.profile.apparence[k] = v
    end
    for k, v in _pairs(options) do
        __Options.OvaleOptions.options.args.apparence.args[k] = v
    end
    __Options.OvaleOptions:RegisterOptions(__exports.OvaleDataBroker)
end
local OnClick = function(fr, button)
    if button == "LeftButton" then
        local menu = {
            [1] = {
                text = __Localization.L["Script"],
                isTitle = true
            }
        }
        local scriptType =  not __Ovale.Ovale.db.profile.showHiddenScripts and "script"
        local descriptions = __Scripts.OvaleScripts:GetDescriptions(scriptType)
        for name, description in _pairs(descriptions) do
            local menuItem = {
                text = description,
                func = function()
                    __Scripts.OvaleScripts:SetScript(name)
                end

            }
            tinsert(menu, menuItem)
        end
        self_menuFrame = self_menuFrame or API_CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate")
        API_EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU")
    elseif button == "MiddleButton" then
        __Frame.frame:ToggleOptions()
    elseif button == "RightButton" then
        if API_IsShiftKeyDown() then
            __Debug.OvaleDebug:DoTrace(true)
        else
            __Options.OvaleOptions:ToggleConfig()
        end
    end
end

local OnTooltipShow = function(tooltip)
    self_tooltipTitle = self_tooltipTitle or __Ovale.Ovale:GetName() .. " " .. __Version.OvaleVersion.version
    tooltip:SetText(self_tooltipTitle, 1, 1, 1)
    tooltip:AddLine(__Localization.L["Click to select the script."])
    tooltip:AddLine(__Localization.L["Middle-Click to toggle the script options panel."])
    tooltip:AddLine(__Localization.L["Right-Click for options."])
    tooltip:AddLine(__Localization.L["Shift-Right-Click for the current trace log."])
end

local OvaleDataBrokerClass = __addon.__class(OvaleDataBrokerBase, {
    constructor = function(self)
        self.broker = nil
        OvaleDataBrokerBase.constructor(self)
        if LibDataBroker then
            local broker = {
                type = "data source",
                text = "",
                icon = CLASS_ICONS[__Ovale.Ovale.playerClass],
                OnClick = OnClick,
                OnTooltipShow = OnTooltipShow
            }
            self.broker = LibDataBroker:NewDataObject(__Ovale.Ovale:GetName(), broker)
            if LibDBIcon then
                LibDBIcon:Register(__Ovale.Ovale:GetName(), self.broker, __Ovale.Ovale.db.profile.apparence.minimap)
            end
        end
        if self.broker then
            self:RegisterMessage("Ovale_ProfileChanged", "UpdateIcon")
            self:RegisterMessage("Ovale_ScriptChanged")
            self:Ovale_ScriptChanged()
            self:UpdateIcon()
        end
    end,
    OnDisable = function(self)
        if self.broker then
            self:UnregisterMessage("Ovale_ProfileChanged")
            self:UnregisterMessage("Ovale_ScriptChanged")
        end
    end,
    UpdateIcon = function(self)
        if LibDBIcon and self.broker then
            local minimap = __Ovale.Ovale.db.profile.apparence.minimap
            LibDBIcon:Refresh(__Ovale.Ovale:GetName(), minimap)
            if minimap and minimap.hide then
                LibDBIcon:Hide(__Ovale.Ovale:GetName())
            else
                LibDBIcon:Show(__Ovale.Ovale:GetName())
            end
        end
    end,
    Ovale_ScriptChanged = function(self)
        self.broker.text = __Ovale.Ovale.db.profile.source
    end,
})
__exports.OvaleDataBroker = OvaleDataBrokerClass()
end)
