local OVALE, Ovale = ...
require(OVALE, Ovale, "Options", { "AceConfig-3.0", "AceConfigDialog-3.0", "./Localization", "AceDB-3.0", "AceDBOptions-3.0", "LibDualSpec-1.0" }, function(__exports, AceConfig, AceConfigDialog, __Localization, AceDB, AceDBOptions, LibDualSpec)
local OvaleOptionsBase = Ovale:NewModule("OvaleOptions", "AceConsole-3.0", "AceEvent-3.0")
local _ipairs = ipairs
local _pairs = pairs
local tinsert = table.insert
local _type = type
local API_InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local self_register = {}
local OvaleOptions = __class(OvaleOptionsBase)
function OvaleOptions:OnInitialize()
    local db = AceDB:New("OvaleDB", self.defaultDB)
    self.options.args.profile = AceDBOptions:GetOptionsTable(db)
    db:RegisterCallback(self, "OnNewProfile", "HandleProfileChanges")
    db:RegisterCallback(self, "OnProfileReset", "HandleProfileChanges")
    db:RegisterCallback(self, "OnProfileChanged", "HandleProfileChanges")
    db:RegisterCallback(self, "OnProfileCopied", "HandleProfileChanges")
    Ovale.db = db
    self:UpgradeSavedVariables()
    AceConfig:RegisterOptionsTable(OVALE, self.options.args.apparence)
    AceConfig:RegisterOptionsTable(OVALE + " Profiles", self.options.args.profile)
    AceConfig:RegisterOptionsTable(OVALE + " Actions", self.options.args.actions, "Ovale")
    AceConfigDialog:AddToBlizOptions(OVALE)
    AceConfigDialog:AddToBlizOptions(OVALE + " Profiles", "Profiles", OVALE)
end
function OvaleOptions:OnEnable()
    self:HandleProfileChanges()
end
function OvaleOptions:RegisterOptions(addon)
    tinsert(self_register, addon)
end
function OvaleOptions:UpgradeSavedVariables()
end
function OvaleOptions:HandleProfileChanges()
    self:SendMessage("Ovale_ProfileChanged")
    self:SendMessage("Ovale_ScriptChanged")
    self:SendMessage("Ovale_OptionChanged", "layout")
    self:SendMessage("Ovale_OptionChanged", "visibility")
end
function OvaleOptions:ToggleConfig()
    if Ovale.db.profile.standaloneOptions then
        local appName = OVALE
        if AceConfigDialog.OpenFrames[appName] then
            AceConfigDialog:Close(appName)
        else
            AceConfigDialog:Open(appName)
        end
    else
        API_InterfaceOptionsFrame_OpenToCategory(OVALE)
        API_InterfaceOptionsFrame_OpenToCategory(OVALE)
    end
end
local options = OvaleOptions()
end))
