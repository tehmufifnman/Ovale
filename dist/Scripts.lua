local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Scripts", { "AceConfig-3.0", "AceConfigDialog-3.0", "./Options", "./Localization", "./PaperDoll", "./Ovale" }, function(__exports, AceConfig, AceConfigDialog, __Options, __Localization, __PaperDoll, __Ovale)
local OvaleScriptsBase = __Ovale.Ovale:NewModule("OvaleScripts", "AceEvent-3.0")
local format = string.format
local gsub = string.gsub
local _pairs = pairs
local strlower = string.lower
local DEFAULT_NAME = "Ovale"
local DEFAULT_DESCRIPTION = __Localization.L["Script défaut"]
local CUSTOM_NAME = "custom"
local CUSTOM_DESCRIPTION = __Localization.L["Script personnalisé"]
local DISABLED_NAME = "Disabled"
local DISABLED_DESCRIPTION = __Localization.L["Disabled"]
do
    local defaultDB = {
        code = "",
        source = "Ovale",
        showHiddenScripts = false
    }
    local actions = {
        code = {
            name = __Localization.L["Code"],
            type = "execute",
            func = function()
                local appName = __exports.OvaleScripts:GetName()
                AceConfigDialog:SetDefaultSize(appName, 700, 550)
                AceConfigDialog:Open(appName)
            end

        }
    }
    for k, v in _pairs(defaultDB) do
        __Options.OvaleOptions.defaultDB.profile[k] = v
    end
    for k, v in _pairs(actions) do
        __Options.OvaleOptions.options.args.actions.args[k] = v
    end
    __Options.OvaleOptions:RegisterOptions(__exports.OvaleScripts)
end
local OvaleScriptsClass = __class(OvaleScriptsBase, {
    constructor = function(self)
        self.script = {}
        OvaleScriptsBase.constructor(self)
        self:CreateOptions()
        self:RegisterScript(nil, nil, DEFAULT_NAME, DEFAULT_DESCRIPTION, nil, "script")
        self:RegisterScript(__Ovale.Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, __Ovale.Ovale.db.profile.code, "script")
        self:RegisterScript(nil, nil, DISABLED_NAME, DISABLED_DESCRIPTION, nil, "script")
        self:RegisterMessage("Ovale_StanceChanged")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_StanceChanged")
    end,
    Ovale_StanceChanged = function(self, event, newStance, oldStance)
    end,
    GetDescriptions = function(self, scriptType)
        local descriptionsTable = {}
        for name, script in _pairs(self.script) do
            if ( not scriptType or script.type == scriptType) and ( not script.specialization or __PaperDoll.OvalePaperDoll:IsSpecialization(script.specialization)) then
                if name == DEFAULT_NAME then
                    descriptionsTable[name] = script.desc .. " (" .. self:GetScriptName(name) .. ")"
                else
                    descriptionsTable[name] = script.desc
                end
            end
        end
        return descriptionsTable
    end,
    RegisterScript = function(self, className, specialization, name, description, code, scriptType)
        if  not className or className == __Ovale.Ovale.playerClass then
            self.script[name] = self.script[name] or {}
            local script = self.script[name]
            script.type = scriptType or "script"
            script.desc = description or name
            script.specialization = specialization
            script.code = code or ""
        end
    end,
    UnregisterScript = function(self, name)
        self.script[name] = nil
    end,
    SetScript = function(self, name)
        local oldSource = __Ovale.Ovale.db.profile.source
        if oldSource ~= name then
            __Ovale.Ovale.db.profile.source = name
            self:SendMessage("Ovale_ScriptChanged")
        end
    end,
    GetDefaultScriptName = function(self, className, specialization)
        local name
        if className == "DEATHKNIGHT" then
            if specialization == "blood" then
                name = "icyveins_deathknight_blood"
            elseif specialization == "frost" then
                name = "simulationcraft_death_knight_frost_t19p"
            elseif specialization == "unholy" then
                name = "simulationcraft_death_knight_unholy_t19p"
            end
        elseif className == "DEMONHUNTER" then
            if specialization == "vengeance" then
                name = "icyveins_demonhunter_vengeance"
            elseif specialization == "havoc" then
                name = "simulationcraft_demon_hunter_havoc_t19p"
            end
        elseif className == "DRUID" then
            if specialization == "restoration" then
                name = DISABLED_NAME
            elseif specialization == "guardian" then
                name = "icyveins_druid_guardian"
            end
        elseif className == "HUNTER" then
            local short
            if specialization == "beast_mastery" then
                short = "bm"
            elseif specialization == "marksmanship" then
                short = "mm"
            elseif specialization == "survival" then
                short = "sv"
            end
            if short then
                name = format("simulationcraft_hunter_%s_t19p", short)
            end
        elseif className == "MONK" then
            if specialization == "mistweaver" then
                name = DISABLED_NAME
            elseif specialization == "brewmaster" then
                name = "icyveins_monk_brewmaster"
            end
        elseif className == "PALADIN" then
            if specialization == "holy" then
                name = "icyveins_paladin_holy"
            elseif specialization == "protection" then
                name = "icyveins_paladin_protection"
            end
        elseif className == "PRIEST" then
            if specialization == "discipline" then
                name = "icyveins_priest_discipline"
            elseif specialization == "holy" then
                name = DISABLED_NAME
            end
        elseif className == "SHAMAN" then
            if specialization == "restoration" then
                name = DISABLED_NAME
            end
        elseif className == "WARRIOR" then
            if specialization == "protection" then
                name = "icyveins_warrior_protection"
            end
        end
        if  not name and specialization then
            name = format("simulationcraft_%s_%s_t19p", strlower(className), specialization)
        end
        if  not (name and self.script[name]) then
            name = DISABLED_NAME
        end
        return name
    end,
    GetScriptName = function(self, name)
        return (name == DEFAULT_NAME) and self:GetDefaultScriptName(__Ovale.Ovale.playerClass, __PaperDoll.OvalePaperDoll:GetSpecialization()) or name
    end,
    GetScript = function(self, name)
        name = self:GetScriptName(name)
        if name and self.script[name] then
            return self.script[name].code
        end
    end,
    CreateOptions = function(self)
        local options = {
            name = __Ovale.Ovale:GetName() .. " " .. __Localization.L["Script"],
            type = "group",
            args = {
                source = {
                    order = 10,
                    type = "select",
                    name = __Localization.L["Script"],
                    width = "double",
                    values = function(info)
                        local scriptType =  not __Ovale.Ovale.db.profile.showHiddenScripts and "script"
                        return __exports.OvaleScripts:GetDescriptions(scriptType)
                    end,
                    get = function(info)
                        return __Ovale.Ovale.db.profile.source
                    end,
                    set = function(info, v)
                        self:SetScript(v)
                    end
                },
                script = {
                    order = 20,
                    type = "input",
                    multiline = 25,
                    name = __Localization.L["Script"],
                    width = "full",
                    disabled = function()
                        return __Ovale.Ovale.db.profile.source ~= CUSTOM_NAME
                    end,
                    get = function(info)
                        local code = __exports.OvaleScripts:GetScript(__Ovale.Ovale.db.profile.source)
                        code = code or ""
                        return gsub(code, "	", "    ")
                    end,
                    set = function(info, v)
                        __exports.OvaleScripts:RegisterScript(__Ovale.Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script")
                        __Ovale.Ovale.db.profile.code = v
                        self:SendMessage("Ovale_ScriptChanged")
                    end
                },
                copy = {
                    order = 30,
                    type = "execute",
                    name = __Localization.L["Copier sur Script personnalisé"],
                    disabled = function()
                        return __Ovale.Ovale.db.profile.source == CUSTOM_NAME
                    end,
                    confirm = function()
                        return __Localization.L["Ecraser le Script personnalisé préexistant?"]
                    end,
                    func = function()
                        local code = __exports.OvaleScripts:GetScript(__Ovale.Ovale.db.profile.source)
                        __exports.OvaleScripts:RegisterScript(__Ovale.Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script")
                        __Ovale.Ovale.db.profile.source = CUSTOM_NAME
                        __Ovale.Ovale.db.profile.code = __exports.OvaleScripts:GetScript(CUSTOM_NAME)
                        self:SendMessage("Ovale_ScriptChanged")
                    end
                },
                showHiddenScripts = {
                    order = 40,
                    type = "toggle",
                    name = __Localization.L["Show hidden"],
                    get = function(info)
                        return __Ovale.Ovale.db.profile.showHiddenScripts
                    end,
                    set = function(info, value)
                        __Ovale.Ovale.db.profile.showHiddenScripts = value
                    end
                }
            }
        }
        local appName = self:GetName()
        AceConfig:RegisterOptionsTable(appName, options)
        AceConfigDialog:AddToBlizOptions(appName, __Localization.L["Script"], __Ovale.Ovale:GetName())
    end,
})
__exports.OvaleScripts = OvaleScriptsClass()
end)
