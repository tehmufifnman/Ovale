local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Options", { "AceConfig-3.0", "AceConfigDialog-3.0", "./Localization", "AceDB-3.0", "AceDBOptions-3.0", "LibDualSpec-1.0", "./Ovale" }, function(__exports, AceConfig, AceConfigDialog, __Localization, AceDB, AceDBOptions, LibDualSpec, __Ovale)
local OvaleOptionsBase = __Ovale.Ovale:NewModule("OvaleOptions", "AceConsole-3.0", "AceEvent-3.0")
local _ipairs = ipairs
local _pairs = pairs
local tinsert = table.insert
local _type = type
local API_InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local self_register = {}
local OvaleOptionsClass = __class(OvaleOptionsBase, {
    OnInitialize = function(self)
        local ovale = __Ovale.Ovale:GetName()
        local db = AceDB:New("OvaleDB", self.defaultDB)
        self.options.args.profile = AceDBOptions:GetOptionsTable(db)
        db:RegisterCallback(self, "OnNewProfile", "HandleProfileChanges")
        db:RegisterCallback(self, "OnProfileReset", "HandleProfileChanges")
        db:RegisterCallback(self, "OnProfileChanged", "HandleProfileChanges")
        db:RegisterCallback(self, "OnProfileCopied", "HandleProfileChanges")
        __Ovale.Ovale.db = db
        self:UpgradeSavedVariables()
        AceConfig:RegisterOptionsTable(ovale, self.options.args.apparence)
        AceConfig:RegisterOptionsTable(ovale, self.options.args.profile)
        AceConfig:RegisterOptionsTable(ovale, self.options.args.actions, "Ovale")
        AceConfigDialog:AddToBlizOptions(ovale)
        AceConfigDialog:AddToBlizOptions(ovale, "Profiles", ovale)
    end,
    OnEnable = function(self)
        self:HandleProfileChanges()
    end,
    RegisterOptions = function(self, addon)
        tinsert(self_register, addon)
    end,
    UpgradeSavedVariables = function(self)
    end,
    HandleProfileChanges = function(self)
        self:SendMessage("Ovale_ProfileChanged")
        self:SendMessage("Ovale_ScriptChanged")
        self:SendMessage("Ovale_OptionChanged", "layout")
        self:SendMessage("Ovale_OptionChanged", "visibility")
    end,
    ToggleConfig = function(self)
        local appName = __Ovale.Ovale:GetName()
        if __Ovale.Ovale.db.profile.standaloneOptions then
            if AceConfigDialog.OpenFrames[appName] then
                AceConfigDialog:Close(appName)
            else
                AceConfigDialog:Open(appName)
            end
        else
            API_InterfaceOptionsFrame_OpenToCategory(appName)
            API_InterfaceOptionsFrame_OpenToCategory(appName)
        end
    end,
})
__exports.OvaleOptions = OvaleOptionsClass()
end)
