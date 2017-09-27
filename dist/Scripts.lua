local OVALE, Ovale = ...
require(OVALE, Ovale, "Scripts", { "./OvaleOptions", "./L", "./db" }, function(__exports, __OvaleOptions, __L, __db)
local OvaleScripts = Ovale:NewModule("OvaleScripts", "AceEvent-3.0")
Ovale.OvaleScripts = OvaleScripts
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local OvaleEquipment = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local format = string.format
local gsub = string.gsub
local _pairs = pairs
local strlower = string.lower
local DEFAULT_NAME = "Ovale"
local DEFAULT_DESCRIPTION = __L.L["Script défaut"]
local CUSTOM_NAME = "custom"
local CUSTOM_DESCRIPTION = __L.L["Script personnalisé"]
local DISABLED_NAME = "Disabled"
local DISABLED_DESCRIPTION = __L.L["Disabled"]
do
    local defaultDB = {
        code = "",
        source = "Ovale",
        showHiddenScripts = false
    }
    local actions = {
        code = {
            name = __L.L["Code"],
            type = "execute",
            func = function()
                local appName = OvaleScripts:GetName()
                AceConfigDialog:SetDefaultSize(appName, 700, 550)
                AceConfigDialog:Open(appName)
            end
        }
    }
    for k, v in _pairs(defaultDB) do
        __OvaleOptions.OvaleOptions.defaultDB.profile[k] = v
    end
    for k, v in _pairs(actions) do
        __OvaleOptions.OvaleOptions.options.args.actions.args[k] = v
    end
    __OvaleOptions.OvaleOptions:RegisterOptions(OvaleScripts)
end
OvaleScripts.script = {}
local OvaleScripts = __class()
function OvaleScripts:OnInitialize()
    OvaleEquipment = Ovale.OvaleEquipment
    OvalePaperDoll = Ovale.OvalePaperDoll
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleStance = Ovale.OvaleStance
    self:CreateOptions()
    self:RegisterScript(nil, nil, DEFAULT_NAME, DEFAULT_DESCRIPTION, nil, "script")
    self:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code, "script")
    self:RegisterScript(nil, nil, DISABLED_NAME, DISABLED_DESCRIPTION, nil, "script")
end
function OvaleScripts:OnEnable()
    self:RegisterMessage("Ovale_StanceChanged")
end
function OvaleScripts:OnDisable()
    self:UnregisterMessage("Ovale_StanceChanged")
end
function OvaleScripts:Ovale_StanceChanged(event, newStance, oldStance)
end
function OvaleScripts:GetDescriptions(scriptType)
    local descriptionsTable = {}
    for name, script in _pairs(self.script) do
        if ( not scriptType or script.type == scriptType) and ( not script.specialization or OvalePaperDoll:IsSpecialization(script.specialization)) then
            if name == DEFAULT_NAME then
                descriptionsTable[name] = script.desc + " (" + self:GetScriptName(name) + ")"
            else
                descriptionsTable[name] = script.desc
            end
        end
    end
    return descriptionsTable
end
function OvaleScripts:RegisterScript(className, specialization, name, description, code, scriptType)
    if  not className or className == Ovale.playerClass then
        self.script[name] = self.script[name] or {}
        local script = self.script[name]
        script.type = scriptType or "script"
        script.desc = description or name
        script.specialization = specialization
        script.code = code or ""
    end
end
function OvaleScripts:UnregisterScript(name)
    self.script[name] = nil
end
function OvaleScripts:SetScript(name)
    if __db.oldSource ~= name then
        Ovale.db.profile.source = name
        self:SendMessage("Ovale_ScriptChanged")
    end
end
function OvaleScripts:GetDefaultScriptName(className, specialization)
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
end
function OvaleScripts:GetScriptName(name)
    return (name == DEFAULT_NAME) and self:GetDefaultScriptName(Ovale.playerClass, OvalePaperDoll:GetSpecialization()) or name
end
function OvaleScripts:GetScript(name)
    name = self:GetScriptName(name)
    if name and self.script[name] then
        return self.script[name].code
    end
end
function OvaleScripts:CreateOptions()
    local options = {
        name = OVALE + " " + __L.L["Script"],
        type = "group",
        args = {
            source = {
                order = 10,
                type = "select",
                name = __L.L["Script"],
                width = "double",
                values = function(info)
                    local scriptType =  not Ovale.db.profile.showHiddenScripts and "script"
                    return OvaleScripts:GetDescriptions(scriptType)
                end,
                get = function(info)
                    return Ovale.db.profile.source
                end,
                set = function(info, v)
                    self:SetScript(v)
                end
            },
            script = {
                order = 20,
                type = "input",
                multiline = 25,
                name = __L.L["Script"],
                width = "full",
                disabled = function()
                    return Ovale.db.profile.source ~= CUSTOM_NAME
                end,
                get = function(info)
                    local code = OvaleScripts:GetScript(Ovale.db.profile.source)
                    code = code or ""
                    return gsub(code, "	", "    ")
                end,
                set = function(info, v)
                    OvaleScripts:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script")
                    Ovale.db.profile.code = v
                    self:SendMessage("Ovale_ScriptChanged")
                end
            },
            copy = {
                order = 30,
                type = "execute",
                name = __L.L["Copier sur Script personnalisé"],
                disabled = function()
                    return Ovale.db.profile.source == CUSTOM_NAME
                end,
                confirm = function()
                    return __L.L["Ecraser le Script personnalisé préexistant?"]
                end,
                func = function()
                    local code = OvaleScripts:GetScript(Ovale.db.profile.source)
                    OvaleScripts:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script")
                    Ovale.db.profile.source = CUSTOM_NAME
                    Ovale.db.profile.code = OvaleScripts:GetScript(CUSTOM_NAME)
                    self:SendMessage("Ovale_ScriptChanged")
                end
            },
            showHiddenScripts = {
                order = 40,
                type = "toggle",
                name = __L.L["Show hidden"],
                get = function(info)
                    return Ovale.db.profile.showHiddenScripts
                end,
                set = function(info, value)
                    Ovale.db.profile.showHiddenScripts = value
                end
            }
        }
    }
    local appName = self:GetName()
    AceConfig:RegisterOptionsTable(appName, options)
    AceConfigDialog:AddToBlizOptions(appName, __L.L["Script"], OVALE)
end
end))
