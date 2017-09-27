local OVALE, Ovale = ...
require(OVALE, Ovale, "DataBroker", { "./L", "./OvaleDebug", "./OvaleOptions", "./db" }, function(__exports, __L, __OvaleDebug, __OvaleOptions, __db)
local OvaleDataBroker = Ovale:NewModule("OvaleDataBroker", "AceEvent-3.0")
Ovale.OvaleDataBroker = OvaleDataBroker
local LibDataBroker = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
local OvaleScripts = nil
local OvaleVersion = nil
local _pairs = pairs
local tinsert = table.insert
local API_CreateFrame = CreateFrame
local API_EasyMenu = EasyMenu
local API_IsShiftKeyDown = IsShiftKeyDown
local CLASS_ICONS = {
    ["DEATHKNIGHT"] = "Interface\Icons\ClassIcon_DeathKnight",
    ["DEMONHUNTER"] = "Interface\Icons\ClassIcon_DemonHunter",
    ["DRUID"] = "Interface\Icons\ClassIcon_Druid",
    ["HUNTER"] = "Interface\Icons\ClassIcon_Hunter",
    ["MAGE"] = "Interface\Icons\ClassIcon_Mage",
    ["MONK"] = "Interface\Icons\ClassIcon_Monk",
    ["PALADIN"] = "Interface\Icons\ClassIcon_Paladin",
    ["PRIEST"] = "Interface\Icons\ClassIcon_Priest",
    ["ROGUE"] = "Interface\Icons\ClassIcon_Rogue",
    ["SHAMAN"] = "Interface\Icons\ClassIcon_Shaman",
    ["WARLOCK"] = "Interface\Icons\ClassIcon_Warlock",
    ["WARRIOR"] = "Interface\Icons\ClassIcon_Warrior"
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
            name = __L.L["Show minimap icon"],
            get = function(info)
                return  not Ovale.db.profile.apparence.minimap.hide
            end,
            set = function(info, value)
                Ovale.db.profile.apparence.minimap.hide =  not value
                OvaleDataBroker:UpdateIcon()
            end
        }
    }
    for k, v in _pairs(defaultDB) do
        __OvaleOptions.OvaleOptions.defaultDB.profile.apparence[k] = v
    end
    for k, v in _pairs(options) do
        __OvaleOptions.OvaleOptions.options.args.apparence.args[k] = v
    end
    __OvaleOptions.OvaleOptions:RegisterOptions(OvaleDataBroker)
end
OvaleDataBroker.broker = nil
local OnClick = function(frame, button)
    if button == "LeftButton" then
        local menu = {
            1 = {
                text = __L.L["Script"],
                isTitle = true
            }
        }
        local scriptType =  not Ovale.db.profile.showHiddenScripts and "script"
        local descriptions = OvaleScripts:GetDescriptions(scriptType)
        for name, description in _pairs(descriptions) do
            local menuItem = {
                text = description,
                func = function()
                    OvaleScripts:SetScript(name)
                end
            }
            tinsert(menu, menuItem)
        end
        self_menuFrame = self_menuFrame or API_CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate")
        API_EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU")
    elseif button == "MiddleButton" then
        Ovale:ToggleOptions()
    elseif button == "RightButton" then
        if API_IsShiftKeyDown() then
            __OvaleDebug.OvaleDebug:DoTrace(true)
        else
            __OvaleOptions.OvaleOptions:ToggleConfig()
        end
    end
end
local OnTooltipShow = function(tooltip)
    self_tooltipTitle = self_tooltipTitle or OVALE + " " + OvaleVersion.version
    tooltip:SetText(self_tooltipTitle, 1, 1, 1)
    tooltip:AddLine(__L.L["Click to select the script."])
    tooltip:AddLine(__L.L["Middle-Click to toggle the script options panel."])
    tooltip:AddLine(__L.L["Right-Click for options."])
    tooltip:AddLine(__L.L["Shift-Right-Click for the current trace log."])
end
local OvaleDataBroker = __class()
function OvaleDataBroker:OnInitialize()
    __OvaleOptions.OvaleOptions = Ovale.OvaleOptions
    OvaleScripts = Ovale.OvaleScripts
    OvaleVersion = Ovale.OvaleVersion
    if LibDataBroker then
        local broker = {
            type = "data source",
            text = "",
            icon = CLASS_ICONS[Ovale.playerClass],
            OnClick = OnClick,
            OnTooltipShow = OnTooltipShow
        }
        self.broker = LibDataBroker:NewDataObject(OVALE, broker)
        if LibDBIcon then
            LibDBIcon:Register(OVALE, self.broker, Ovale.db.profile.apparence.minimap)
        end
    end
end
function OvaleDataBroker:OnEnable()
    if self.broker then
        self:RegisterMessage("Ovale_ProfileChanged", "UpdateIcon")
        self:RegisterMessage("Ovale_ScriptChanged")
        self:Ovale_ScriptChanged()
        self:UpdateIcon()
    end
end
function OvaleDataBroker:OnDisable()
    if self.broker then
        self:UnregisterMessage("Ovale_ProfileChanged")
        self:UnregisterMessage("Ovale_ScriptChanged")
    end
end
function OvaleDataBroker:UpdateIcon()
    if LibDBIcon and self.broker then
        LibDBIcon:Refresh(OVALE, __db.minimap)
        if __db.minimap.hide then
            LibDBIcon:Hide(OVALE)
        else
            LibDBIcon:Show(OVALE)
        end
    end
end
function OvaleDataBroker:Ovale_ScriptChanged()
    self.broker.text = Ovale.db.profile.source
end
end))
