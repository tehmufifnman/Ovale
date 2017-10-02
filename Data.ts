import { Ovale } from "./Ovale";
import { OvaleGUID } from "./GUID";
import { OvalePaperDoll } from "./PaperDoll";
import { OvaleState, StateModule, baseState } from "./State";
import { OvaleDebug } from "./Debug";
let OvaleDataBase = Ovale.NewModule("OvaleData");
let format = string.format;
let _type = type;
let _pairs = pairs;
let strfind = string.find;
let _tonumber = tonumber;
let _wipe = wipe;
let INFINITY = math.huge;
let floor = math.floor;
let ceil = math.ceil;
let self_requirement = {
}
let BLOODELF_CLASSES = {
    ["DEATHKNIGHT"]: true,
    ["DEMONHUNTER"]: true,
    ["DRUID"]: false,
    ["HUNTER"]: true,
    ["MAGE"]: true,
    ["MONK"]: true,
    ["PALADIN"]: true,
    ["PRIEST"]: true,
    ["ROGUE"]: true,
    ["SHAMAN"]: false,
    ["WARLOCK"]: true,
    ["WARRIOR"]: true
}
let PANDAREN_CLASSES = {
    ["DEATHKNIGHT"]: false,
    ["DEMONHUNTER"]: false,
    ["DRUID"]: false,
    ["HUNTER"]: true,
    ["MAGE"]: true,
    ["MONK"]: true,
    ["PALADIN"]: false,
    ["PRIEST"]: true,
    ["ROGUE"]: true,
    ["SHAMAN"]: true,
    ["WARLOCK"]: false,
    ["WARRIOR"]: true
}
let TAUREN_CLASSES = {
    ["DEATHKNIGHT"]: true,
    ["DEMONHUNTER"]: false,
    ["DRUID"]: true,
    ["HUNTER"]: true,
    ["MAGE"]: false,
    ["MONK"]: true,
    ["PALADIN"]: true,
    ["PRIEST"]: true,
    ["ROGUE"]: false,
    ["SHAMAN"]: true,
    ["WARLOCK"]: false,
    ["WARRIOR"]: true
}
let STAT_NAMES = {
    1: "agility",
    2: "bonus_armor",
    3: "critical_strike",
    4: "haste",
    5: "intellect",
    6: "mastery",
    7: "multistrike",
    8: "spirit",
    9: "spellpower",
    10: "strength",
    11: "versatility"
}
let STAT_SHORTNAME = {
    agility: "agi",
    critical_strike: "crit",
    intellect: "int",
    strength: "str",
    spirit: "spi"
}
let STAT_USE_NAMES = {
    1: "trinket_proc",
    2: "trinket_stacking_proc",
    3: "trinket_stacking_stat",
    4: "trinket_stat",
    5: "trinket_stack_proc"
}

class OvaleDataClass extends OvaleDebug.RegisterDebugging(OvaleDataBase) {
    STAT_NAMES = STAT_NAMES;
    STAT_SHORTNAME = STAT_SHORTNAME;
    STAT_USE_NAMES = STAT_USE_NAMES;
    BLOODELF_CLASSES = BLOODELF_CLASSES;
    PANDAREN_CLASSES = PANDAREN_CLASSES;
    TAUREN_CLASSES = TAUREN_CLASSES;
    itemInfo = {}
    itemList = {}
    spellInfo = {}
    buffSpellList = {
        fear_debuff: {
            [5246]: true,
            [5484]: true,
            [5782]: true,
            [8122]: true
        },
        incapacitate_debuff: {
            [6770]: true,
            [12540]: true,
            [20066]: true,
            [137460]: true
        },
        root_debuff: {
            [122]: true,
            [339]: true
        },
        stun_debuff: {
            [408]: true,
            [853]: true,
            [1833]: true,
            [5211]: true,
            [46968]: true
        },
        attack_power_multiplier_buff: {
            [6673]: true,
            [19506]: true,
            [57330]: true
        },
        critical_strike_buff: {
            [1459]: true,
            [24604]: true,
            [24932]: true,
            [61316]: true,
            [90309]: true,
            [90363]: true,
            [97229]: true,
            [116781]: true,
            [126309]: true,
            [126373]: true,
            [128997]: true,
            [160052]: true,
            [160200]: true
        },
        haste_buff: {
            [49868]: true,
            [55610]: true,
            [113742]: true,
            [128432]: true,
            [135678]: true,
            [160003]: true,
            [160074]: true,
            [160203]: true
        },
        mastery_buff: {
            [19740]: true,
            [24907]: true,
            [93435]: true,
            [116956]: true,
            [128997]: true,
            [155522]: true,
            [160073]: true,
            [160198]: true
        },
        multistrike_buff: {
            [24844]: true,
            [34889]: true,
            [49868]: true,
            [57386]: true,
            [58604]: true,
            [109773]: true,
            [113742]: true,
            [166916]: true,
            [172968]: true
        },
        spell_power_multiplier_buff: {
            [1459]: true,
            [61316]: true,
            [90364]: true,
            [109773]: true,
            [126309]: true,
            [128433]: true,
            [160205]: true
        },
        stamina_buff: {
            [469]: true,
            [21562]: true,
            [50256]: true,
            [90364]: true,
            [160003]: true,
            [160014]: true,
            [166928]: true,
            [160199]: true
        },
        str_agi_int_buff: {
            [1126]: true,
            [20217]: true,
            [90363]: true,
            [115921]: true,
            [116781]: true,
            [159988]: true,
            [160017]: true,
            [160077]: true,
            [160206]: true
        },
        versatility_buff: {
            [1126]: true,
            [35290]: true,
            [50518]: true,
            [55610]: true,
            [57386]: true,
            [159735]: true,
            [160045]: true,
            [160077]: true,
            [167187]: true,
            [167188]: true,
            [172967]: true
        },
        bleed_debuff: {
            [1079]: true,
            [16511]: true,
            [33745]: true,
            [77758]: true,
            [113344]: true,
            [115767]: true,
            [122233]: true,
            [154953]: true,
            [155722]: true
        },
        healing_reduced_debuff: {
            [8680]: true,
            [54680]: true,
            [115625]: true,
            [115804]: true
        },
        stealthed_buff: {
            [1784]: true,
            [5215]: true,
            [11327]: true,
            [24450]: true,
            [58984]: true,
            [90328]: true,
            [102543]: true,
            [148523]: true,
            [115191]: true,
            [115192]: true,
            [115193]: true,
            [185422]: true
        },
        burst_haste_buff: {
            [2825]: true,
            [32182]: true,
            [80353]: true,
            [90355]: true
        },
        burst_haste_debuff: {
            [57723]: true,
            [57724]: true,
            [80354]: true,
            [95809]: true
        },
        raid_movement_buff: {
            [106898]: true
        }
    }
    constructor() {
        super();
        for (const [_, useName] of _pairs(STAT_USE_NAMES)) {
            let name;
            for (const [_, statName] of _pairs(STAT_NAMES)) {
                name = useName + "_" + statName + "_buff";
                this.buffSpellList[name] = {
                }
                let shortName = STAT_SHORTNAME[statName];
                if (shortName) {
                    name = useName + "_" + shortName + "_buff";
                    this.buffSpellList[name] = {
                    }
                }
            }
            name = useName + "_any_buff";
            this.buffSpellList[name] = {}
        }

        {
            for (const [name] of _pairs(this.buffSpellList)) {
                this.DEFAULT_SPELL_LIST[name] = true;
            }
        }        
    }

    DEFAULT_SPELL_LIST = {}
    OnInitialize() {
    }
    OnEnable() {
    }
    OnDisable() {
    }
    RegisterRequirement(name, method, arg) {
        self_requirement[name] = {
            1: method,
            2: arg
        }
    }
    UnregisterRequirement(name) {
        self_requirement[name] = undefined;
    }
    Reset() {
        _wipe(this.itemInfo);
        _wipe(this.spellInfo);
        for (const [k, v] of _pairs(this.buffSpellList)) {
            if (!this.DEFAULT_SPELL_LIST[k]) {
                _wipe(v);
                this.buffSpellList[k] = undefined;
            } else if (strfind(k, "^trinket_")) {
                _wipe(v);
            }
        }
    }
    SpellInfo(spellId) {
        let si = this.spellInfo[spellId];
        if (!si) {
            si = {
                aura: {
                    player: {
                    },
                    target: {
                    },
                    pet: {
                    },
                    damage: {
                    }
                },
                require: {
                }
            }
            this.spellInfo[spellId] = si;
        }
        return si;
    }
    GetSpellInfo(spellId) {
        if (_type(spellId) == "number") {
            return this.spellInfo[spellId];
        } else if (this.buffSpellList[spellId]) {
            for (const [auraId] of _pairs(this.buffSpellList[spellId])) {
                if (this.spellInfo[auraId]) {
                    return this.spellInfo[auraId];
                }
            }
        }
    }
    ItemInfo(itemId) {
        let ii = this.itemInfo[itemId];
        if (!ii) {
            ii = {
                require: {
                }
            }
            this.itemInfo[itemId] = ii;
        }
        return ii;
    }
    GetItemTagInfo(spellId) {
        return ["cd", false];
    }
    GetSpellTagInfo(spellId) {
        let tag = "main";
        let invokesGCD = true;
        let si = this.spellInfo[spellId];
        if (si) {
            invokesGCD = !si.gcd || si.gcd > 0;
            tag = si.tag;
            if (!tag) {
                let cd = si.cd;
                if (cd) {
                    if (cd > 90) {
                        tag = "cd";
                    } else if (cd > 29 || !invokesGCD) {
                        tag = "shortcd";
                    }
                } else if (!invokesGCD) {
                    tag = "shortcd";
                }
                si.tag = tag;
            }
            tag = tag || "main";
        }
        return [tag, invokesGCD];
    }
    CheckRequirements(spellId, atTime, tokens, index, targetGUID):[boolean, string, number] {
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.defaultTarget || "target");
        let name = tokens[index];
        index = index + 1;
        if (name) {
            this.Log("Checking requirements:");
            let verified = true;
            let requirement = name;
            while (verified && name) {
                let handler = self_requirement[name];
                if (handler) {
                    let method = handler[1];
                    let arg = this[method] && this || handler[2];
                    [verified, requirement, index] = arg[method](arg, spellId, atTime, name, tokens, index, targetGUID);
                    name = tokens[index];
                    index = index + 1;
                } else {
                    Ovale.OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name);
                    verified = false;
                }
            }
            return [verified, requirement, index];
        }
        return [true, undefined, undefined];
    }
    CheckSpellAuraData(auraId, spellData, atTime, guid) {
        guid = guid || OvaleGUID.UnitGUID("player");
        let index, value, data;
        if (_type(spellData) == "table") {
            value = spellData[1];
            index = 2;
        } else {
            value = spellData;
        }
        if (value == "count") {
            let N;
            if (index) {
                N = spellData[index];
                index = index + 1;
            }
            if (N) {
                data = _tonumber(N);
            } else {
                Ovale.OneTimeMessage("Warning: '%d' has '%s' missing final stack count.", auraId, value);
            }
        } else if (value == "extend") {
            let seconds;
            if (index) {
                seconds = spellData[index];
                index = index + 1;
            }
            if (seconds) {
                data = _tonumber(seconds);
            } else {
                Ovale.OneTimeMessage("Warning: '%d' has '%s' missing duration.", auraId, value);
            }
        } else {
            let asNumber = _tonumber(value);
            value = asNumber || value;
        }
        let verified = true;
        if (index) {
            [verified] = this.CheckRequirements(auraId, atTime, spellData, index, guid);
        }
        return [verified, value, data];
    }
    CheckSpellInfo(spellId, atTime, targetGUID) {
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.defaultTarget || "target");
        let verified = true;
        let requirement;
        for (const [name, handler] of _pairs(self_requirement)) {
            let value = this.GetSpellInfoProperty(spellId, atTime, name, targetGUID);
            if (value) {
                let [method, arg] = [handler[1], handler[2]];
                arg = this[method] && this || arg;
                let index = (_type(value) == "table") && 1 || undefined;
                [verified, requirement] = arg[method](arg, spellId, atTime, name, value, index, targetGUID);
                if (!verified) {
                    break;
                }
            }
        }
        return [verified, requirement];
    }
    GetItemInfoProperty(itemId, atTime, property) {
        const targetGUID = OvaleGUID.UnitGUID("player");
        let ii = this.ItemInfo(itemId);
        let value = ii && ii[property];
        let requirements = ii && ii.require[property];
        if (requirements) {
            for (const [v, requirement] of _pairs(requirements)) {
                let verified = this.CheckRequirements(itemId, atTime, requirement, 1, targetGUID);
                if (verified) {
                    value = _tonumber(v) || v;
                    break;
                }
            }
        }
        return value;
    }
    GetSpellInfoProperty(spellId, atTime, property, targetGUID) {
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.defaultTarget || "target");
        let si = this.spellInfo[spellId];
        let value = si && si[property];
        let requirements = si && si.require[property];
        if (requirements) {
            for (const [v, requirement] of _pairs(requirements)) {
                let verified = this.CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                if (verified) {
                    value = _tonumber(v) || v;
                    break;
                }
            }
        }
        if (!value || !_tonumber(value)) {
            return value;
        }
        let addpower = si && si["add" + property];
        if (addpower) {
            value = value + addpower;
        }
        let ratio = si && si[property + "_percent"];
        if (ratio) {
            ratio = ratio / 100;
        } else {
            ratio = 1;
        }
        let multipliers = si && si.require[property + '_percent'];
        if (multipliers) {
            for (const [v, requirement] of _pairs(multipliers)) {
                let verified = this.CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                if (verified) {
                    ratio = ratio * (_tonumber(v) || 0) / 100;
                }
            }
        }
        let actual = (value > 0 && floor(value * ratio)) || ceil(value * ratio);
        return actual;
    }
    GetDamage(spellId, attackpower, spellpower, mainHandWeaponDamage, offHandWeaponDamage, combo) {
        let si = this.spellInfo[spellId];
        if (!si) {
            return undefined;
        }
        let damage = si.base || 0;
        attackpower = attackpower || 0;
        spellpower = spellpower || 0;
        mainHandWeaponDamage = mainHandWeaponDamage || 0;
        offHandWeaponDamage = offHandWeaponDamage || 0;
        combo = combo || 0;
        if (si.bonusmainhand) {
            damage = damage + si.bonusmainhand * mainHandWeaponDamage;
        }
        if (si.bonusoffhand) {
            damage = damage + si.bonusoffhand * offHandWeaponDamage;
        }
        if (si.bonuscp) {
            damage = damage + si.bonuscp * combo;
        }
        if (si.bonusap) {
            damage = damage + si.bonusap * attackpower;
        }
        if (si.bonusapcp) {
            damage = damage + si.bonusapcp * attackpower * combo;
        }
        if (si.bonussp) {
            damage = damage + si.bonussp * spellpower;
        }
        return damage;
    }
    GetBaseDuration(auraId, spellcast?) {
        let combo = spellcast && spellcast.combo;
        let holy = spellcast && spellcast.holy;
        let duration = INFINITY;
        let si = this.spellInfo[auraId];
        if (si && si.duration) {
            duration = si.duration;
            if (si.addduration) {
                duration = duration + si.addduration;
            }
            if (si.adddurationcp && combo) {
                duration = duration + si.adddurationcp * combo;
            }
            if (si.adddurationholy && holy) {
                duration = duration + si.adddurationholy * (holy - 1);
            }
        }
        if (si && si.haste && spellcast) {
            let hasteMultiplier = OvalePaperDoll.GetHasteMultiplier(si.haste, spellcast);
            duration = duration / hasteMultiplier;
        }
        return duration;
    }
    GetTickLength(auraId, snapshot?) {
        let tick = 3;
        let si = this.spellInfo[auraId];
        if (si) {
            tick = si.tick || tick;
            let hasteMultiplier = OvalePaperDoll.GetHasteMultiplier(si.haste, snapshot);
            tick = tick / hasteMultiplier;
        }
        return tick;
    }
}

export class DataState implements StateModule {
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    CheckRequirements(spellId, atTime, tokens, index, targetGUID) {
        return OvaleData.CheckRequirements(spellId, atTime, tokens, index, targetGUID);
    }

    CheckSpellAuraData(auraId, spellData, atTime, guid) {
        return OvaleData.CheckSpellAuraData(auraId, spellData, atTime, guid);
    }
    CheckSpellInfo(spellId, atTime, targetGUID) {
        return OvaleData.CheckSpellInfo(spellId, atTime, targetGUID);
    }
    GetItemInfoProperty(itemId, atTime, property) {
        return OvaleData.GetItemInfoProperty(itemId, atTime, property);
    }
    GetSpellInfoProperty(spellId, atTime, property, targetGUID?) {
        return OvaleData.GetSpellInfoProperty(spellId, atTime, property, targetGUID);
    }    
}

export const dataState = new DataState();

OvaleState.RegisterState(dataState);

export const OvaleData = new OvaleDataClass();