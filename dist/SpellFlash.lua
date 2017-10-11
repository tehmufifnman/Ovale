local __addonName, __addon = ...
            __addon.require("./SpellFlash", { "./Localization", "./Options", "./Ovale", "./Data", "./Future", "./SpellBook", "./Stance", "./State" }, function(__exports, __Localization, __Options, __Ovale, __Data, __Future, __SpellBook, __Stance, __State)
local OvaleSpellFlashBase = __Ovale.Ovale:NewModule("OvaleSpellFlash", "AceEvent-3.0")
local _pairs = pairs
local API_GetTime = GetTime
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitExists = UnitExists
local API_UnitIsDead = UnitIsDead
local API_UnitCanAttack = UnitCanAttack
local SpellFlashCore = nil
local colorMain = {
    r = nil,
    g = nil,
    b = nil
}
local colorShortCd = {
    r = nil,
    g = nil,
    b = nil
}
local colorCd = {
    r = nil,
    g = nil,
    b = nil
}
local colorInterrupt = {
    r = nil,
    g = nil,
    b = nil
}
local FLASH_COLOR = {
    main = colorMain,
    cd = colorCd,
    shortcd = colorCd
}
local COLORTABLE = {
    aqua = {
        r = 0,
        g = 1,
        b = 1
    },
    blue = {
        r = 0,
        g = 0,
        b = 1
    },
    gray = {
        r = 0.5,
        g = 0.5,
        b = 0.5
    },
    green = {
        r = 0.1,
        g = 1,
        b = 0.1
    },
    orange = {
        r = 1,
        g = 0.5,
        b = 0.25
    },
    pink = {
        r = 0.9,
        g = 0.4,
        b = 0.4
    },
    purple = {
        r = 1,
        g = 0,
        b = 1
    },
    red = {
        r = 1,
        g = 0.1,
        b = 0.1
    },
    white = {
        r = 1,
        g = 1,
        b = 1
    },
    yellow = {
        r = 1,
        g = 1,
        b = 0
    }
}
do
    local defaultDB = {
        spellFlash = {
            brightness = 1,
            enabled = true,
            hasHostileTarget = false,
            hasTarget = false,
            hideInVehicle = false,
            inCombat = false,
            size = 2.4,
            threshold = 500,
            colorMain = {
                r = 1,
                g = 1,
                b = 1
            },
            colorShortCd = {
                r = 1,
                g = 1,
                b = 0
            },
            colorCd = {
                r = 1,
                g = 1,
                b = 0
            },
            colorInterrupt = {
                r = 0,
                g = 1,
                b = 1
            }
        }
    }
    local options = {
        spellFlash = {
            type = "group",
            name = "SpellFlash",
            disabled = function()
                return  not SpellFlashCore
            end
,
            get = function(info)
                return __Ovale.Ovale.db.profile.apparence.spellFlash[info[#info]]
            end
,
            set = function(info, value)
                __Ovale.Ovale.db.profile.apparence.spellFlash[info[#info]] = value
                __Options.OvaleOptions:SendMessage("Ovale_OptionChanged")
            end
,
            args = {
                enabled = {
                    order = 10,
                    type = "toggle",
                    name = __Localization.L["Enabled"],
                    desc = __Localization.L["Flash spells on action bars when they are ready to be cast. Requires SpellFlashCore."],
                    width = "full"
                },
                inCombat = {
                    order = 10,
                    type = "toggle",
                    name = __Localization.L["En combat uniquement"],
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                hasTarget = {
                    order = 20,
                    type = "toggle",
                    name = __Localization.L["Si cible uniquement"],
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                hasHostileTarget = {
                    order = 30,
                    type = "toggle",
                    name = __Localization.L["Cacher si cible amicale ou morte"],
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                hideInVehicle = {
                    order = 40,
                    type = "toggle",
                    name = __Localization.L["Cacher dans les véhicules"],
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                brightness = {
                    order = 50,
                    type = "range",
                    name = __Localization.L["Flash brightness"],
                    min = 0,
                    max = 1,
                    bigStep = 0.01,
                    isPercent = true,
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                size = {
                    order = 60,
                    type = "range",
                    name = __Localization.L["Flash size"],
                    min = 0,
                    max = 3,
                    bigStep = 0.01,
                    isPercent = true,
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                threshold = {
                    order = 70,
                    type = "range",
                    name = __Localization.L["Flash threshold"],
                    desc = __Localization.L["Time (in milliseconds) to begin flashing the spell to use before it is ready."],
                    min = 0,
                    max = 1000,
                    step = 1,
                    bigStep = 50,
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end

                },
                colors = {
                    order = 80,
                    type = "group",
                    name = __Localization.L["Colors"],
                    inline = true,
                    disabled = function()
                        return  not SpellFlashCore or  not __Ovale.Ovale.db.profile.apparence.spellFlash.enabled
                    end
,
                    get = function(info)
                        local color = __Ovale.Ovale.db.profile.apparence.spellFlash[info[#info]]
                        return color.r, color.g, color.b, 1
                    end
,
                    set = function(info, r, g, b, a)
                        local color = __Ovale.Ovale.db.profile.apparence.spellFlash[info[#info]]
                        color.r = r
                        color.g = g
                        color.b = b
                        __Options.OvaleOptions:SendMessage("Ovale_OptionChanged")
                    end
,
                    args = {
                        colorMain = {
                            order = 10,
                            type = "color",
                            name = __Localization.L["Main attack"],
                            hasAlpha = false
                        },
                        colorCd = {
                            order = 20,
                            type = "color",
                            name = __Localization.L["Long cooldown abilities"],
                            hasAlpha = false
                        },
                        colorShortCd = {
                            order = 30,
                            type = "color",
                            name = __Localization.L["Short cooldown abilities"],
                            hasAlpha = false
                        },
                        colorInterrupt = {
                            order = 40,
                            type = "color",
                            name = __Localization.L["Interrupts"],
                            hasAlpha = false
                        }
                    }
                }
            }
        }
    }
    for k, v in _pairs(defaultDB) do
        __Options.OvaleOptions.defaultDB.profile.apparence[k] = v
    end
    for k, v in _pairs(options) do
        __Options.OvaleOptions.options.args.apparence.args[k] = v
    end
    __Options.OvaleOptions:RegisterOptions(__exports.OvaleSpellFlash)
end
local OvaleSpellFlashClass = __addon.__class(OvaleSpellFlashBase, {
    constructor = function(self)
        OvaleSpellFlashBase.constructor(self)
        SpellFlashCore = _G["SpellFlashCore"]
        self:RegisterMessage("Ovale_OptionChanged")
        self:Ovale_OptionChanged()
    end,
    OnDisable = function(self)
        SpellFlashCore = nil
        self:UnregisterMessage("Ovale_OptionChanged")
    end,
    Ovale_OptionChanged = function(self)
        local db = __Ovale.Ovale.db.profile.apparence.spellFlash
        colorMain.r = db.colorMain.r
        colorMain.g = db.colorMain.g
        colorMain.b = db.colorMain.b
        colorCd.r = db.colorCd.r
        colorCd.g = db.colorCd.g
        colorCd.b = db.colorCd.b
        colorShortCd.r = db.colorShortCd.r
        colorShortCd.g = db.colorShortCd.g
        colorShortCd.b = db.colorShortCd.b
        colorInterrupt.r = db.colorInterrupt.r
        colorInterrupt.g = db.colorInterrupt.g
        colorInterrupt.b = db.colorInterrupt.b
    end,
    IsSpellFlashEnabled = function(self)
        local enabled = (SpellFlashCore ~= nil)
        local db = __Ovale.Ovale.db.profile.apparence.spellFlash
        if enabled and  not db.enabled then
            enabled = false
        end
        if enabled and db.inCombat and  not __Future.OvaleFuture.inCombat then
            enabled = false
        end
        if enabled and db.hideInVehicle and API_UnitHasVehicleUI("player") then
            enabled = false
        end
        if enabled and db.hasTarget and  not API_UnitExists("target") then
            enabled = false
        end
        if enabled and db.hasHostileTarget and (API_UnitIsDead("target") or  not API_UnitCanAttack("player", "target")) then
            enabled = false
        end
        return enabled
    end,
    Flash = function(self, state, node, element, start, now)
        local db = __Ovale.Ovale.db.profile.apparence.spellFlash
        now = now or API_GetTime()
        if self:IsSpellFlashEnabled() and start and start - now <= db.threshold / 1000 then
            if element and element.type == "action" then
                local spellId, spellInfo
                if element.lowername == "spell" then
                    spellId = element.positionalParams[1]
                    spellInfo = __Data.OvaleData.spellInfo[spellId]
                end
                local interrupt = spellInfo and spellInfo.interrupt
                local color = nil
                local flash = element.namedParams and element.namedParams.flash
                local iconFlash = node.namedParams.flash
                local iconHelp = node.namedParams.help
                if flash and COLORTABLE[flash] then
                    color = COLORTABLE[flash]
                elseif iconFlash and COLORTABLE[iconFlash] then
                    color = COLORTABLE[iconFlash]
                elseif iconHelp and FLASH_COLOR[iconHelp] then
                    color = FLASH_COLOR[iconHelp]
                    if interrupt == 1 and iconHelp == "cd" then
                        color = colorInterrupt
                    end
                end
                local size = db.size * 100
                if iconHelp == "cd" then
                    if interrupt ~= 1 then
                        size = size * 0.5
                    end
                end
                local brightness = db.brightness * 100
                if element.lowername == "spell" then
                    if __Stance.OvaleStance:IsStanceSpell(spellId) then
                        SpellFlashCore:FlashForm(spellId, color, size, brightness)
                    end
                    if __SpellBook.OvaleSpellBook:IsPetSpell(spellId) then
                        SpellFlashCore:FlashPet(spellId, color, size, brightness)
                    end
                    SpellFlashCore:FlashAction(spellId, color, size, brightness)
                elseif element.lowername == "item" then
                    local itemId = element.positionalParams[1]
                    SpellFlashCore:FlashItem(itemId, color, size, brightness)
                end
            end
        end
    end,
})
end)
