local OVALE, Ovale = ...
require(OVALE, Ovale, "SpellFlash", { "./L", "./OvaleOptions", "./db", "./db", "./db", "./db", "./db", "./db" }, function(__exports, __L, __OvaleOptions, __db, __db, __db, __db, __db, __db)
local OvaleSpellFlash = Ovale:NewModule("OvaleSpellFlash", "AceEvent-3.0")
Ovale.OvaleSpellFlash = OvaleSpellFlash
local OvaleData = nil
local OvaleFuture = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local _pairs = pairs
local _type = type
local API_GetTime = GetTime
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitExists = UnitExists
local API_UnitIsDead = UnitIsDead
local API_UnitCanAttack = UnitCanAttack
local SpellFlashCore = nil
local colorMain = {}
local colorShortCd = {}
local colorCd = {}
local colorInterrupt = {}
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
            end,
            get = function(info)
                return Ovale.db.profile.apparence.spellFlash[info[#info]]
            end,
            set = function(info, value)
                Ovale.db.profile.apparence.spellFlash[info[#info]] = value
                __OvaleOptions.OvaleOptions:SendMessage("Ovale_OptionChanged")
            end,
            args = {
                enabled = {
                    order = 10,
                    type = "toggle",
                    name = __L.L["Enabled"],
                    desc = __L.L["Flash spells on action bars when they are ready to be cast. Requires SpellFlashCore."],
                    width = "full"
                },
                inCombat = {
                    order = 10,
                    type = "toggle",
                    name = __L.L["En combat uniquement"],
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                hasTarget = {
                    order = 20,
                    type = "toggle",
                    name = __L.L["Si cible uniquement"],
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                hasHostileTarget = {
                    order = 30,
                    type = "toggle",
                    name = __L.L["Cacher si cible amicale ou morte"],
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                hideInVehicle = {
                    order = 40,
                    type = "toggle",
                    name = __L.L["Cacher dans les véhicules"],
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                brightness = {
                    order = 50,
                    type = "range",
                    name = __L.L["Flash brightness"],
                    min = 0,
                    max = 1,
                    bigStep = 0.01,
                    isPercent = true,
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                size = {
                    order = 60,
                    type = "range",
                    name = __L.L["Flash size"],
                    min = 0,
                    max = 3,
                    bigStep = 0.01,
                    isPercent = true,
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                threshold = {
                    order = 70,
                    type = "range",
                    name = __L.L["Flash threshold"],
                    desc = __L.L["Time (in milliseconds) to begin flashing the spell to use before it is ready."],
                    min = 0,
                    max = 1000,
                    step = 1,
                    bigStep = 50,
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end
                },
                colors = {
                    order = 80,
                    type = "group",
                    name = __L.L["Colors"],
                    inline = true,
                    disabled = function()
                        return  not SpellFlashCore or  not Ovale.db.profile.apparence.spellFlash.enabled
                    end,
                    get = function(info)
                        return __db.color.r, __db.color.g, __db.color.b, 1
                    end,
                    set = function(info, r, g, b, a)
                        __db.color.r = r
                        __db.color.g = g
                        __db.color.b = b
                        __OvaleOptions.OvaleOptions:SendMessage("Ovale_OptionChanged")
                    end,
                    args = {
                        colorMain = {
                            order = 10,
                            type = "color",
                            name = __L.L["Main attack"],
                            hasAlpha = false
                        },
                        colorCd = {
                            order = 20,
                            type = "color",
                            name = __L.L["Long cooldown abilities"],
                            hasAlpha = false
                        },
                        colorShortCd = {
                            order = 30,
                            type = "color",
                            name = __L.L["Short cooldown abilities"],
                            hasAlpha = false
                        },
                        colorInterrupt = {
                            order = 40,
                            type = "color",
                            name = __L.L["Interrupts"],
                            hasAlpha = false
                        }
                    }
                }
            }
        }
    }
    for k, v in _pairs(defaultDB) do
        __OvaleOptions.OvaleOptions.defaultDB.profile.apparence[k] = v
    end
    for k, v in _pairs(options) do
        __OvaleOptions.OvaleOptions.options.args.apparence.args[k] = v
    end
    __OvaleOptions.OvaleOptions:RegisterOptions(OvaleSpellFlash)
end
local OvaleSpellFlash = __class()
function OvaleSpellFlash:OnInitialize()
    OvaleData = Ovale.OvaleData
    OvaleFuture = Ovale.OvaleFuture
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleStance = Ovale.OvaleStance
end
function OvaleSpellFlash:OnEnable()
    SpellFlashCore = _G["SpellFlashCore"]
    self:RegisterMessage("Ovale_OptionChanged")
    self:Ovale_OptionChanged()
end
function OvaleSpellFlash:OnDisable()
    SpellFlashCore = nil
    self:UnregisterMessage("Ovale_OptionChanged")
end
function OvaleSpellFlash:Ovale_OptionChanged()
    colorMain.r = __db.db.colorMain.r
    colorMain.g = __db.db.colorMain.g
    colorMain.b = __db.db.colorMain.b
    colorCd.r = __db.db.colorCd.r
    colorCd.g = __db.db.colorCd.g
    colorCd.b = __db.db.colorCd.b
    colorShortCd.r = __db.db.colorShortCd.r
    colorShortCd.g = __db.db.colorShortCd.g
    colorShortCd.b = __db.db.colorShortCd.b
    colorInterrupt.r = __db.db.colorInterrupt.r
    colorInterrupt.g = __db.db.colorInterrupt.g
    colorInterrupt.b = __db.db.colorInterrupt.b
end
function OvaleSpellFlash:IsSpellFlashEnabled()
    local enabled = (SpellFlashCore ~= nil)
    if enabled and  not __db.db.enabled then
        enabled = false
    end
    if enabled and __db.db.inCombat and  not OvaleFuture.inCombat then
        enabled = false
    end
    if enabled and __db.db.hideInVehicle and API_UnitHasVehicleUI("player") then
        enabled = false
    end
    if enabled and __db.db.hasTarget and  not API_UnitExists("target") then
        enabled = false
    end
    if enabled and __db.db.hasHostileTarget and (API_UnitIsDead("target") or  not API_UnitCanAttack("player", "target")) then
        enabled = false
    end
    return enabled
end
function OvaleSpellFlash:Flash(state, node, element, start, now)
    now = now or API_GetTime()
    if self:IsSpellFlashEnabled() and start and start - now <= __db.db.threshold / 1000 then
        if element and element.type == "action" then
            local spellId, spellInfo
            if element.lowername == "spell" then
                spellId = element.positionalParams[1]
                spellInfo = OvaleData.spellInfo[spellId]
            end
            local interrupt = spellInfo and spellInfo.interrupt
            local __db.color = nil
            local flash = element.namedParams and element.namedParams.flash
            local iconFlash = node.namedParams.flash
            local iconHelp = node.namedParams.help
            if flash and COLORTABLE[flash] then
                __db.color = COLORTABLE[flash]
            elseif iconFlash and COLORTABLE[iconFlash] then
                __db.color = COLORTABLE[iconFlash]
            elseif iconHelp and FLASH_COLOR[iconHelp] then
                __db.color = FLASH_COLOR[iconHelp]
                if interrupt == 1 and iconHelp == "cd" then
                    __db.color = colorInterrupt
                end
            end
            local size = __db.db.size * 100
            if iconHelp == "cd" then
                if interrupt ~= 1 then
                    size = size * 0.5
                end
            end
            local brightness = __db.db.brightness * 100
            if element.lowername == "spell" then
                if OvaleStance:IsStanceSpell(spellId) then
                    SpellFlashCore:FlashForm(spellId, __db.color, size, brightness)
                end
                if OvaleSpellBook:IsPetSpell(spellId) then
                    SpellFlashCore:FlashPet(spellId, __db.color, size, brightness)
                end
                SpellFlashCore:FlashAction(spellId, __db.color, size, brightness)
            elseif element.lowername == "item" then
                local itemId = element.positionalParams[1]
                SpellFlashCore:FlashItem(itemId, __db.color, size, brightness)
            end
        end
    end
end
function OvaleSpellFlash:UpgradeSavedVariables()
    if __db.profile.apparence.spellFlash and _type(__db.profile.apparence.spellFlash) ~= "table" then
        local enabled = __db.profile.apparence.spellFlash
        __db.profile.apparence.spellFlash = {}
        __db.profile.apparence.spellFlash.enabled = enabled
    end
end
end))
