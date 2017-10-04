local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Options", { "AceConfig-3.0", "AceConfigDialog-3.0", "./Localization", "AceDB-3.0", "AceDBOptions-3.0", "LibDualSpec-1.0", "./Ovale" }, function(__exports, AceConfig, AceConfigDialog, __Localization, AceDB, AceDBOptions, LibDualSpec, __Ovale)
local OvaleOptionsBase = __Ovale.Ovale:NewModule("OvaleOptions", "AceConsole-3.0", "AceEvent-3.0")
local _ipairs = ipairs
local _pairs = pairs
local tinsert = table.insert
local _type = type
local API_InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local self_register = {}
local OvaleOptionsClass = __class(OvaleOptionsBase, {
    constructor = function(self)
        self.defaultDB = {
                profile = {
                    source = nil,
                    code = nil,
                    showHiddenScripts = false,
                    overrideCode = nil,
                    check = {},
                    list = {},
                    standaloneOptions = false,
                    apparence = {
                        avecCible = false,
                        clickThru = false,
                        enCombat = false,
                        enableIcons = true,
                        hideEmpty = false,
                        hideVehicule = false,
                        margin = 4,
                        offsetX = 0,
                        offsetY = 0,
                        targetHostileOnly = false,
                        verrouille = false,
                        vertical = false,
                        alpha = 1,
                        flashIcon = true,
                        remainsFontColor = {
                            r = 1,
                            g = 1,
                            b = 1
                        },
                        fontScale = 1,
                        highlightIcon = true,
                        iconScale = 1,
                        numeric = false,
                        raccourcis = true,
                        smallIconScale = 0.8,
                        targetText = "●",
                        iconShiftX = 0,
                        iconShiftY = 0,
                        optionsAlpha = 1,
                        predictif = false,
                        secondIconScale = 1,
                        taggedEnemies = false,
                        auraLag = 400,
                        moving = false,
                        spellFlash = nil,
                        minimap = nil
                    }
                },
                global = nil
            }
        self.options = {
                type = "group",
                args = {
                    apparence = {
                        name = __Ovale.Ovale:GetName(),
                        type = "group",
                        get = function(info)
                            return __Ovale.Ovale.db.profile.apparence[info[#info]]
                        end
,
                        set = function(info, value)
                            __Ovale.Ovale.db.profile.apparence[info[#info]] = value
                            self:SendMessage("Ovale_OptionChanged", info[#info - 1])
                        end
,
                        args = {
                            standaloneOptions = {
                                order = 30,
                                name = __Localization.L["Standalone options"],
                                desc = __Localization.L["Open configuration panel in a separate, movable window."],
                                type = "toggle",
                                get = function(info)
                                    return __Ovale.Ovale.db.profile.standaloneOptions
                                end
,
                                set = function(info, value)
                                    __Ovale.Ovale.db.profile.standaloneOptions = value
                                end

                            },
                            iconGroupAppearance = {
                                order = 40,
                                type = "group",
                                name = __Localization.L["Groupe d'icônes"],
                                args = {
                                    enableIcons = {
                                        order = 10,
                                        type = "toggle",
                                        name = __Localization.L["Enabled"],
                                        width = "full",
                                        set = function(info, value)
                                            __Ovale.Ovale.db.profile.apparence.enableIcons = value
                                            self:SendMessage("Ovale_OptionChanged", "visibility")
                                        end

                                    },
                                    verrouille = {
                                        order = 10,
                                        type = "toggle",
                                        name = __Localization.L["Verrouiller position"],
                                        disabled = function()
                                            return  not __Ovale.Ovale.db.profile.apparence.enableIcons
                                        end

                                    },
                                    clickThru = {
                                        order = 20,
                                        type = "toggle",
                                        name = __Localization.L["Ignorer les clics souris"],
                                        disabled = function()
                                            return  not __Ovale.Ovale.db.profile.apparence.enableIcons
                                        end

                                    },
                                    visibility = {
                                        order = 20,
                                        type = "group",
                                        name = __Localization.L["Visibilité"],
                                        inline = true,
                                        disabled = function()
                                            return  not __Ovale.Ovale.db.profile.apparence.enableIcons
                                        end
,
                                        args = {
                                            enCombat = {
                                                order = 10,
                                                type = "toggle",
                                                name = __Localization.L["En combat uniquement"]
                                            },
                                            avecCible = {
                                                order = 20,
                                                type = "toggle",
                                                name = __Localization.L["Si cible uniquement"]
                                            },
                                            targetHostileOnly = {
                                                order = 30,
                                                type = "toggle",
                                                name = __Localization.L["Cacher si cible amicale ou morte"]
                                            },
                                            hideVehicule = {
                                                order = 40,
                                                type = "toggle",
                                                name = __Localization.L["Cacher dans les véhicules"]
                                            },
                                            hideEmpty = {
                                                order = 50,
                                                type = "toggle",
                                                name = __Localization.L["Cacher bouton vide"]
                                            }
                                        }
                                    },
                                    layout = {
                                        order = 30,
                                        type = "group",
                                        name = __Localization.L["Layout"],
                                        inline = true,
                                        disabled = function()
                                            return  not __Ovale.Ovale.db.profile.apparence.enableIcons
                                        end
,
                                        args = {
                                            moving = {
                                                order = 10,
                                                type = "toggle",
                                                name = __Localization.L["Défilement"],
                                                desc = __Localization.L["Les icônes se déplacent"]
                                            },
                                            vertical = {
                                                order = 20,
                                                type = "toggle",
                                                name = __Localization.L["Vertical"]
                                            },
                                            offsetX = {
                                                order = 30,
                                                type = "range",
                                                name = __Localization.L["Horizontal offset"],
                                                desc = __Localization.L["Horizontal offset from the center of the screen."],
                                                min = -1000,
                                                max = 1000,
                                                softMin = -500,
                                                softMax = 500,
                                                bigStep = 1
                                            },
                                            offsetY = {
                                                order = 40,
                                                type = "range",
                                                name = __Localization.L["Vertical offset"],
                                                desc = __Localization.L["Vertical offset from the center of the screen."],
                                                min = -1000,
                                                max = 1000,
                                                softMin = -500,
                                                softMax = 500,
                                                bigStep = 1
                                            },
                                            margin = {
                                                order = 50,
                                                type = "range",
                                                name = __Localization.L["Marge entre deux icônes"],
                                                min = -16,
                                                max = 64,
                                                step = 1
                                            }
                                        }
                                    }
                                }
                            },
                            iconAppearance = {
                                order = 50,
                                type = "group",
                                name = __Localization.L["Icône"],
                                args = {
                                    iconScale = {
                                        order = 10,
                                        type = "range",
                                        name = __Localization.L["Taille des icônes"],
                                        desc = __Localization.L["La taille des icônes"],
                                        min = 0.5,
                                        max = 3,
                                        bigStep = 0.01,
                                        isPercent = true
                                    },
                                    smallIconScale = {
                                        order = 20,
                                        type = "range",
                                        name = __Localization.L["Taille des petites icônes"],
                                        desc = __Localization.L["La taille des petites icônes"],
                                        min = 0.5,
                                        max = 3,
                                        bigStep = 0.01,
                                        isPercent = true
                                    },
                                    remainsFontColor = {
                                        type = "color",
                                        order = 25,
                                        name = __Localization.L["Remaining time font color"],
                                        get = function(info)
                                            local t = __Ovale.Ovale.db.profile.apparence.remainsFontColor
                                            return t.r, t.g, t.b
                                        end
,
                                        set = function(info, r, g, b)
                                            local t = __Ovale.Ovale.db.profile.apparence.remainsFontColor
                                            t.r, t.g, t.b = r, g, b
                                            __Ovale.Ovale.db.profile.apparence.remainsFontColor = t
                                        end

                                    },
                                    fontScale = {
                                        order = 30,
                                        type = "range",
                                        name = __Localization.L["Taille des polices"],
                                        desc = __Localization.L["La taille des polices"],
                                        min = 0.2,
                                        max = 2,
                                        bigStep = 0.01,
                                        isPercent = true
                                    },
                                    alpha = {
                                        order = 40,
                                        type = "range",
                                        name = __Localization.L["Opacité des icônes"],
                                        min = 0,
                                        max = 1,
                                        bigStep = 0.01,
                                        isPercent = true
                                    },
                                    raccourcis = {
                                        order = 50,
                                        type = "toggle",
                                        name = __Localization.L["Raccourcis clavier"],
                                        desc = __Localization.L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"]
                                    },
                                    numeric = {
                                        order = 60,
                                        type = "toggle",
                                        name = __Localization.L["Affichage numérique"],
                                        desc = __Localization.L["Affiche le temps de recharge sous forme numérique"]
                                    },
                                    highlightIcon = {
                                        order = 70,
                                        type = "toggle",
                                        name = __Localization.L["Illuminer l'icône"],
                                        desc = __Localization.L["Illuminer l'icône quand la technique doit être spammée"]
                                    },
                                    flashIcon = {
                                        order = 80,
                                        type = "toggle",
                                        name = __Localization.L["Illuminer l'icône quand le temps de recharge est écoulé"]
                                    },
                                    targetText = {
                                        order = 90,
                                        type = "input",
                                        name = __Localization.L["Caractère de portée"],
                                        desc = __Localization.L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"]
                                    }
                                }
                            },
                            optionsAppearance = {
                                order = 60,
                                type = "group",
                                name = __Localization.L["Options"],
                                args = {
                                    iconShiftX = {
                                        order = 10,
                                        type = "range",
                                        name = __Localization.L["Décalage horizontal des options"],
                                        min = -256,
                                        max = 256,
                                        step = 1
                                    },
                                    iconShiftY = {
                                        order = 20,
                                        type = "range",
                                        name = __Localization.L["Décalage vertical des options"],
                                        min = -256,
                                        max = 256,
                                        step = 1
                                    },
                                    optionsAlpha = {
                                        order = 30,
                                        type = "range",
                                        name = __Localization.L["Opacité des options"],
                                        min = 0,
                                        max = 1,
                                        bigStep = 0.01,
                                        isPercent = true
                                    }
                                }
                            },
                            predictiveIcon = {
                                order = 70,
                                type = "group",
                                name = __Localization.L["Prédictif"],
                                args = {
                                    predictif = {
                                        order = 10,
                                        type = "toggle",
                                        name = __Localization.L["Prédictif"],
                                        desc = __Localization.L["Affiche les deux prochains sorts et pas uniquement le suivant"]
                                    },
                                    secondIconScale = {
                                        order = 20,
                                        type = "range",
                                        name = __Localization.L["Taille du second icône"],
                                        min = 0.2,
                                        max = 1,
                                        bigStep = 0.01,
                                        isPercent = true
                                    }
                                }
                            },
                            advanced = {
                                order = 80,
                                type = "group",
                                name = "Advanced",
                                args = {
                                    taggedEnemies = {
                                        order = 10,
                                        type = "toggle",
                                        name = __Localization.L["Only count tagged enemies"],
                                        desc = __Localization.L["Only count a mob as an enemy if it is directly affected by a player's spells."]
                                    },
                                    auraLag = {
                                        order = 20,
                                        type = "range",
                                        name = __Localization.L["Aura lag"],
                                        desc = __Localization.L["Lag (in milliseconds) between when an spell is cast and when the affected aura is applied or removed"],
                                        min = 100,
                                        max = 700,
                                        step = 10
                                    }
                                }
                            }
                        }
                    },
                    actions = {
                        name = "Actions",
                        type = "group",
                        args = {
                            show = {
                                type = "execute",
                                name = __Localization.L["Afficher la fenêtre"],
                                guiHidden = true,
                                func = function()
                                    __Ovale.Ovale.db.profile.apparence.enableIcons = true
                                    self:SendMessage("Ovale_OptionChanged", "visibility")
                                end

                            },
                            hide = {
                                type = "execute",
                                name = __Localization.L["Cacher la fenêtre"],
                                guiHidden = true,
                                func = function()
                                    __Ovale.Ovale.db.profile.apparence.enableIcons = false
                                    self:SendMessage("Ovale_OptionChanged", "visibility")
                                end

                            },
                            config = {
                                name = "Configuration",
                                type = "execute",
                                func = function()
                                    self:ToggleConfig()
                                end

                            },
                            refresh = {
                                name = __Localization.L["Display refresh statistics"],
                                type = "execute",
                                func = function()
                                end

                            }
                        }
                    },
                    profile = {}
                }
            }
        OvaleOptionsBase.constructor(self)
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
