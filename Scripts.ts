import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleScripts = Ovale.NewModule("OvaleScripts", "AceEvent-3.0");
Ovale.OvaleScripts = OvaleScripts;
let AceConfig = LibStub("AceConfig-3.0");
let AceConfigDialog = LibStub("AceConfigDialog-3.0");
import { OvaleOptions } from "./OvaleOptions";
import { L } from "./L";
let OvaleEquipment = undefined;
let OvalePaperDoll = undefined;
let OvaleSpellBook = undefined;
let OvaleStance = undefined;
let format = string.format;
let gsub = string.gsub;
let _pairs = pairs;
let strlower = string.lower;
let DEFAULT_NAME = "Ovale";
let DEFAULT_DESCRIPTION = L["Script défaut"];
let CUSTOM_NAME = "custom";
let CUSTOM_DESCRIPTION = L["Script personnalisé"];
let DISABLED_NAME = "Disabled";
let DISABLED_DESCRIPTION = L["Disabled"];
{
    let defaultDB = { code: "", source: "Ovale", showHiddenScripts: false }
    let actions = { code: { name: L["Code"], type: "execute", func: function () {
        let appName = OvaleScripts.GetName();
        AceConfigDialog.SetDefaultSize(appName, 700, 550);
        AceConfigDialog.Open(appName);
    } } }
    for (const [k, v] of _pairs(defaultDB)) {
        OvaleOptions.defaultDB.profile[k] = v;
    }
    for (const [k, v] of _pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleScripts);
}
OvaleScripts.script = {  }
class OvaleScripts {
    OnInitialize() {
        OvaleEquipment = Ovale.OvaleEquipment;
        OvalePaperDoll = Ovale.OvalePaperDoll;
        OvaleSpellBook = Ovale.OvaleSpellBook;
        OvaleStance = Ovale.OvaleStance;
        this.CreateOptions();
        this.RegisterScript(undefined, undefined, DEFAULT_NAME, DEFAULT_DESCRIPTION, undefined, "script");
        this.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code, "script");
        this.RegisterScript(undefined, undefined, DISABLED_NAME, DISABLED_DESCRIPTION, undefined, "script");
    }
    OnEnable() {
        this.RegisterMessage("Ovale_StanceChanged");
    }
    OnDisable() {
        this.UnregisterMessage("Ovale_StanceChanged");
    }
    Ovale_StanceChanged(event, newStance, oldStance) {
    }
    GetDescriptions(scriptType) {
        let descriptionsTable = {  }
        for (const [name, script] of _pairs(this.script)) {
            if ((!scriptType || script.type == scriptType) && (!script.specialization || OvalePaperDoll.IsSpecialization(script.specialization))) {
                if (name == DEFAULT_NAME) {
                    descriptionsTable[name] = script.desc + " (" + this.GetScriptName(name) + ")";
                } else {
                    descriptionsTable[name] = script.desc;
                }
            }
        }
        return descriptionsTable;
    }
    RegisterScript(class, specialization, name, description, code, scriptType) {
        if (!class || class == Ovale.playerClass) {
            this.script[name] = this.script[name] || {  }
            let script = this.script[name];
            script.type = scriptType || "script";
            script.desc = description || name;
            script.specialization = specialization;
            script.code = code || "";
        }
    }
    UnregisterScript(name) {
        this.script[name] = undefined;
    }
    SetScript(name) {
        import { oldSource } from "./db";
        if (oldSource != name) {
            Ovale.db.profile.source = name;
            this.SendMessage("Ovale_ScriptChanged");
        }
    }
    GetDefaultScriptName(class, specialization) {
        let name;
        if (class == "DEATHKNIGHT") {
            if (specialization == "blood") {
                name = "icyveins_deathknight_blood";
            } else if (specialization == "frost") {
                name = "simulationcraft_death_knight_frost_t19p";
            } else if (specialization == "unholy") {
                name = "simulationcraft_death_knight_unholy_t19p";
            }
        } else if (class == "DEMONHUNTER") {
            if (specialization == "vengeance") {
                name = "icyveins_demonhunter_vengeance";
            } else if (specialization == "havoc") {
                name = "simulationcraft_demon_hunter_havoc_t19p";
            }
        } else if (class == "DRUID") {
            if (specialization == "restoration") {
                name = DISABLED_NAME;
            } else if (specialization == "guardian") {
                name = "icyveins_druid_guardian";
            }
        } else if (class == "HUNTER") {
            let short;
            if (specialization == "beast_mastery") {
                short = "bm";
            } else if (specialization == "marksmanship") {
                short = "mm";
            } else if (specialization == "survival") {
                short = "sv";
            }
            if (short) {
                name = format("simulationcraft_hunter_%s_t19p", short);
            }
        } else if (class == "MONK") {
            if (specialization == "mistweaver") {
                name = DISABLED_NAME;
            } else if (specialization == "brewmaster") {
                name = "icyveins_monk_brewmaster";
            }
        } else if (class == "PALADIN") {
            if (specialization == "holy") {
                name = "icyveins_paladin_holy";
            } else if (specialization == "protection") {
                name = "icyveins_paladin_protection";
            }
        } else if (class == "PRIEST") {
            if (specialization == "discipline") {
                name = "icyveins_priest_discipline";
            } else if (specialization == "holy") {
                name = DISABLED_NAME;
            }
        } else if (class == "SHAMAN") {
            if (specialization == "restoration") {
                name = DISABLED_NAME;
            }
        } else if (class == "WARRIOR") {
            if (specialization == "protection") {
                name = "icyveins_warrior_protection";
            }
        }
        if (!name && specialization) {
            name = format("simulationcraft_%s_%s_t19p", strlower(class), specialization);
        }
        if (!(name && this.script[name])) {
            name = DISABLED_NAME;
        }
        return name;
    }
    GetScriptName(name) {
        return (name == DEFAULT_NAME) && this.GetDefaultScriptName(Ovale.playerClass, OvalePaperDoll.GetSpecialization()) || name;
    }
    GetScript(name) {
        name = this.GetScriptName(name);
        if (name && this.script[name]) {
            return this.script[name].code;
        }
    }
    CreateOptions() {
        let options = { name: OVALE + " " + L["Script"], type: "group", args: { source: { order: 10, type: "select", name: L["Script"], width: "double", values: function (info) {
            let scriptType = !Ovale.db.profile.showHiddenScripts && "script";
            return OvaleScripts.GetDescriptions(scriptType);
        }, get: function (info) {
            return Ovale.db.profile.source;
        }, set: function (info, v) {
            this.SetScript(v);
        } }, script: { order: 20, type: "input", multiline: 25, name: L["Script"], width: "full", disabled: function () {
            return Ovale.db.profile.source != CUSTOM_NAME;
        }, get: function (info) {
            let code = OvaleScripts.GetScript(Ovale.db.profile.source);
            code = code || "";
            return gsub(code, "\t", "    ");
        }, set: function (info, v) {
            OvaleScripts.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script");
            Ovale.db.profile.code = v;
            this.SendMessage("Ovale_ScriptChanged");
        } }, copy: { order: 30, type: "execute", name: L["Copier sur Script personnalisé"], disabled: function () {
            return Ovale.db.profile.source == CUSTOM_NAME;
        }, confirm: function () {
            return L["Ecraser le Script personnalisé préexistant?"];
        }, func: function () {
            let code = OvaleScripts.GetScript(Ovale.db.profile.source);
            OvaleScripts.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script");
            Ovale.db.profile.source = CUSTOM_NAME;
            Ovale.db.profile.code = OvaleScripts.GetScript(CUSTOM_NAME);
            this.SendMessage("Ovale_ScriptChanged");
        } }, showHiddenScripts: { order: 40, type: "toggle", name: L["Show hidden"], get: function (info) {
            return Ovale.db.profile.showHiddenScripts;
        }, set: function (info, value) {
            Ovale.db.profile.showHiddenScripts = value;
        } } } }
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(appName, L["Script"], OVALE);
    }
}
