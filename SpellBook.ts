import __addon from "addon";
let [OVALE, Ovale] = __addon;
export let OvaleSpellBook:OvaleSpellBookClass;
import { L } from "./L";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
let OvaleCooldown = undefined;
let OvaleData = undefined;
let OvalePower = undefined;
let OvaleRunes = undefined;
let OvaleState = undefined;
let _ipairs = ipairs;
let _pairs = pairs;
let strmatch = string.match;
let tconcat = table.concat;
let tinsert = table.insert;
let _tonumber = tonumber;
let _tostring = tostring;
let tsort = table.sort;
let _type = type;
let _wipe = wipe;
let API_GetActiveSpecGroup = GetActiveSpecGroup;
let API_GetFlyoutInfo = GetFlyoutInfo;
let API_GetFlyoutSlotInfo = GetFlyoutSlotInfo;
let API_GetSpellBookItemInfo = GetSpellBookItemInfo;
let API_GetSpellInfo = GetSpellInfo;
let API_GetSpellCount = GetSpellCount;
let API_GetSpellLink = GetSpellLink;
let API_GetSpellTabInfo = GetSpellTabInfo;
let API_GetSpellTexture = GetSpellTexture;
let API_GetTalentInfo = GetTalentInfo;
let API_HasPetSpells = HasPetSpells;
let API_IsHarmfulSpell = IsHarmfulSpell;
let API_IsHelpfulSpell = IsHelpfulSpell;
let API_IsSpellInRange = IsSpellInRange;
let API_IsUsableItem = IsUsableItem;
let API_IsUsableSpell = IsUsableSpell;
let API_UnitIsFriend = UnitIsFriend;
let _BOOKTYPE_PET = BOOKTYPE_PET;
let _BOOKTYPE_SPELL = BOOKTYPE_SPELL;
let _MAX_TALENT_TIERS = MAX_TALENT_TIERS;
let _NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS;
let MAX_NUM_TALENTS = _NUM_TALENT_COLUMNS * _MAX_TALENT_TIERS;
let WARRIOR_INCERCEPT_SPELLID = 198304;
let WARRIOR_HEROICTHROW_SPELLID = 57755;
OvaleDebug.RegisterDebugging(OvaleSpellBook);
OvaleProfiler.RegisterProfiling(OvaleSpellBook);
{
    let debugOptions = {
        spellbook: {
            name: L["Spellbook"],
            type: "group",
            args: {
                spellbook: {
                    name: L["Spellbook"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: function (info) {
                        return OvaleSpellBook.DebugSpells();
                    }
                }
            }
        },
        talent: {
            name: L["Talents"],
            type: "group",
            args: {
                talent: {
                    name: L["Talents"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: function (info) {
                        return OvaleSpellBook.DebugTalents();
                    }
                }
            }
        }
    }
    for (const [k, v] of _pairs(debugOptions)) {
        OvaleDebug.options.args[k] = v;
    }
}
OvaleSpellBook.ready = false;
OvaleSpellBook.spell = {
}
OvaleSpellBook.spellbookId = {
    [_BOOKTYPE_PET]: {
    },
    [_BOOKTYPE_SPELL]: {
    }
}
OvaleSpellBook.isHarmful = {
}
OvaleSpellBook.isHelpful = {
}
OvaleSpellBook.texture = {
}
OvaleSpellBook.talent = {
}
OvaleSpellBook.talentPoints = {
}
const ParseHyperlink = function(hyperlink) {
    let [color, linkType, linkData, text] = strmatch(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d*):?%d?|?h?%[?([^%[%]]*)%]?|?h?|?r?");
    return [color, linkType, linkData, text];
}
const OutputTableValues = function(output, tbl) {
    let array = {
    }
    for (const [k, v] of _pairs(tbl)) {
        tinsert(array, _tostring(v) + ": " + _tostring(k));
    }
    tsort(array);
    for (const [_, v] of _ipairs(array)) {
        output[lualength(output) + 1] = v;
    }
}
class OvaleSpellBookClass extends OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleSpellBook", "AceEvent-3.0")) {
    OnInitialize() {
    }
    OnEnable() {
        this.RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Update");
        this.RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateTalents");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "Update");
        this.RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents");
        this.RegisterEvent("SPELLS_CHANGED", "UpdateSpells");
        this.RegisterEvent("UNIT_PET");
        OvaleState.RegisterState(this, this.statePrototype);
        OvaleData.RegisterRequirement("spellcount_min", "RequireSpellCountHandler", this);
        OvaleData.RegisterRequirement("spellcount_max", "RequireSpellCountHandler", this);
    }
    OnDisable() {
        OvaleData.UnregisterRequirement("spellcount_max");
        OvaleData.UnregisterRequirement("spellcount_min");
        OvaleState.UnregisterState(this);
        this.UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
        this.UnregisterEvent("CHARACTER_POINTS_CHANGED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_TALENT_UPDATE");
        this.UnregisterEvent("SPELLS_CHANGED");
        this.UnregisterEvent("UNIT_PET");
    }
    UNIT_PET(unitId) {
        if (unitId == "player") {
            this.UpdateSpells();
        }
    }
    Update() {
        this.UpdateTalents();
        this.UpdateSpells();
        this.ready = true;
    }
    UpdateTalents() {
        this.Debug("Updating talents.");
        _wipe(this.talent);
        _wipe(this.talentPoints);
        let activeTalentGroup = API_GetActiveSpecGroup();
        for (let i = 1; i <= _MAX_TALENT_TIERS; i += 1) {
            for (let j = 1; j <= _NUM_TALENT_COLUMNS; j += 1) {
                let [talentId, name, _, selected, _, _, _, _, _, _, selectedByLegendary] = API_GetTalentInfo(i, j, activeTalentGroup);
                if (talentId) {
                    let combinedSelected = selected || selectedByLegendary;
                    let index = 3 * (i - 1) + j;
                    if (index <= MAX_NUM_TALENTS) {
                        this.talent[index] = name;
                        if (combinedSelected) {
                            this.talentPoints[index] = 1;
                        } else {
                            this.talentPoints[index] = 0;
                        }
                        this.Debug("    Talent %s (%d) is %s.", name, index, combinedSelected && "enabled" || "disabled");
                    }
                }
            }
        }
        Ovale.refreshNeeded[Ovale.playerGUID] = true;
        this.SendMessage("Ovale_TalentsChanged");
    }
    UpdateSpells() {
        _wipe(this.spell);
        _wipe(this.spellbookId[_BOOKTYPE_PET]);
        _wipe(this.spellbookId[_BOOKTYPE_SPELL]);
        _wipe(this.isHarmful);
        _wipe(this.isHelpful);
        _wipe(this.texture);
        for (let tab = 1; tab <= 2; tab += 1) {
            let [name, _, offset, numSpells] = API_GetSpellTabInfo(tab);
            if (name) {
                this.ScanSpellBook(_BOOKTYPE_SPELL, numSpells, offset);
            }
        }
        let [numPetSpells, petToken] = API_HasPetSpells();
        if (numPetSpells) {
            this.ScanSpellBook(_BOOKTYPE_PET, numPetSpells);
        }
        Ovale.refreshNeeded[Ovale.playerGUID] = true;
        this.SendMessage("Ovale_SpellsChanged");
    }
    ScanSpellBook(bookType, numSpells, offset) {
        offset = offset || 0;
        this.Debug("Updating '%s' spellbook starting at offset %d.", bookType, offset);
        for (let index = offset + 1; index <= offset + numSpells; index += 1) {
            let [skillType, spellId] = API_GetSpellBookItemInfo(index, bookType);
            if (skillType == "SPELL" || skillType == "PETACTION") {
                let spellLink = API_GetSpellLink(index, bookType);
                if (spellLink) {
                    let [_, _, linkData, spellName] = ParseHyperlink(spellLink);
                    let id = _tonumber(linkData);
                    this.Debug("    %s (%d) is at offset %d (%s).", spellName, id, index, gsub(spellLink, "|", "_"));
                    this.spell[id] = spellName;
                    this.isHarmful[id] = API_IsHarmfulSpell(index, bookType);
                    this.isHelpful[id] = API_IsHelpfulSpell(index, bookType);
                    this.texture[id] = API_GetSpellTexture(index, bookType);
                    this.spellbookId[bookType][id] = index;
                    if (spellId && id != spellId) {
                        this.Debug("    %s (%d) is at offset %d.", spellName, spellId, index);
                        this.spell[spellId] = spellName;
                        this.isHarmful[spellId] = this.isHarmful[id];
                        this.isHelpful[spellId] = this.isHelpful[id];
                        this.texture[spellId] = this.texture[id];
                        this.spellbookId[bookType][spellId] = index;
                    }
                }
            } else if (skillType == "FLYOUT") {
                let flyoutId = spellId;
                let [_, _, numSlots, isKnown] = API_GetFlyoutInfo(flyoutId);
                if (numSlots > 0 && isKnown) {
                    for (let flyoutIndex = 1; flyoutIndex <= numSlots; flyoutIndex += 1) {
                        let [id, overrideId, isKnown, spellName] = API_GetFlyoutSlotInfo(flyoutId, flyoutIndex);
                        if (isKnown) {
                            this.Debug("    %s (%d) is at offset %d.", spellName, id, index);
                            this.spell[id] = spellName;
                            this.isHarmful[id] = API_IsHarmfulSpell(spellName);
                            this.isHelpful[id] = API_IsHelpfulSpell(spellName);
                            this.texture[id] = API_GetSpellTexture(index, bookType);
                            this.spellbookId[bookType][id] = undefined;
                            if (id != overrideId) {
                                this.Debug("    %s (%d) is at offset %d.", spellName, overrideId, index);
                                this.spell[overrideId] = spellName;
                                this.isHarmful[overrideId] = this.isHarmful[id];
                                this.isHelpful[overrideId] = this.isHelpful[id];
                                this.texture[overrideId] = this.texture[id];
                                this.spellbookId[bookType][overrideId] = undefined;
                            }
                        }
                    }
                }
            } else if (skillType == "FUTURESPELL") {
            } else if (!skillType) {
                break;
            }
        }
    }
    GetCastTime(spellId) {
        if (spellId) {
            let [name, _, _, castTime] = this.GetSpellInfo(spellId);
            if (name) {
                if (castTime) {
                    castTime = castTime / 1000;
                } else {
                    castTime = 0;
                }
            } else {
                castTime = undefined;
            }
            return castTime;
        }
    }
    GetSpellInfo(spellId) {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        if (index && bookType) {
            return API_GetSpellInfo(index, bookType);
        } else {
            return API_GetSpellInfo(spellId);
        }
    }
    GetSpellCount(spellId) {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        if (index && bookType) {
            let spellCount = API_GetSpellCount(index, bookType);
            this.Debug("GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s", index, bookType, spellId, spellCount);
            return spellCount;
        } else {
            let spellName = OvaleSpellBook.GetSpellName(spellId);
            let spellCount = API_GetSpellCount(spellName);
            this.Debug("GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s", spellName, spellId, spellCount);
            return spellCount;
        }
    }
    GetSpellName(spellId) {
        if (spellId) {
            let spellName = this.spell[spellId];
            if (!spellName) {
                spellName = this.GetSpellInfo(spellId);
            }
            return spellName;
        }
    }
    GetSpellTexture(spellId) {
        return this.texture[spellId];
    }
    GetTalentPoints(talentId) {
        let points = 0;
        if (talentId && this.talentPoints[talentId]) {
            points = this.talentPoints[talentId];
        }
        return points;
    }
    AddSpell(spellId, name) {
        if (spellId && name) {
            this.spell[spellId] = name;
        }
    }
    IsHarmfulSpell(spellId) {
        return (spellId && this.isHarmful[spellId]) && true || false;
    }
    IsHelpfulSpell(spellId) {
        return (spellId && this.isHelpful[spellId]) && true || false;
    }
    IsKnownSpell(spellId) {
        return (spellId && this.spell[spellId]) && true || false;
    }
    IsKnownTalent(talentId) {
        return (talentId && this.talentPoints[talentId]) && true || false;
    }
    GetSpellBookIndex(spellId) {
        let bookType = _BOOKTYPE_SPELL;
        while (true) {
            let index = this.spellbookId[bookType][spellId];
            if (index) {
                return [index, bookType];
            } else if (bookType == _BOOKTYPE_SPELL) {
                bookType = _BOOKTYPE_PET;
            } else {
                break;
            }
        }
    }
    IsPetSpell(spellId) {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        return bookType == _BOOKTYPE_PET;
    }
    IsSpellInRange(spellId, unitId) {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        let returnValue = undefined;
        if (index && bookType) {
            returnValue = API_IsSpellInRange(index, bookType, unitId);
        } else if (this.IsKnownSpell(spellId)) {
            let name = this.GetSpellName(spellId);
            returnValue = API_IsSpellInRange(name, unitId);
        }
        if ((returnValue == 1 && spellId == WARRIOR_INCERCEPT_SPELLID)) {
            return (API_UnitIsFriend("player", unitId) == 1 || OvaleSpellBook.IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId) == 1) && 1 || 0;
        }
        return returnValue;
    }
    IsUsableSpell(spellId) {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        if (index && bookType) {
            return API_IsUsableSpell(index, bookType);
        } else if (this.IsKnownSpell(spellId)) {
            let name = this.GetSpellName(spellId);
            return API_IsUsableSpell(name);
        }
    }
}
{
    let output = {
    }
class OvaleSpellBook {
        DebugSpells() {
            _wipe(output);
            OutputTableValues(output, this.spell);
            let total = 0;
            for (const [_] of _pairs(this.spell)) {
                total = total + 1;
            }
            output[lualength(output) + 1] = "Total spells: " + total;
            return tconcat(output, "\n");
        }
        DebugTalents() {
            _wipe(output);
            OutputTableValues(output, this.talent);
            return tconcat(output, "\n");
        }
}
}
class OvaleSpellBook {
    RequireSpellCountHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let count = tokens;
        if (index) {
            count = tokens[index];
            index = index + 1;
        }
        if (count) {
            count = _tonumber(count) || 1;
            let actualCount = OvaleSpellBook.GetSpellCount(spellId);
            verified = (requirement == "spellcount_min" && count <= actualCount) || (requirement == "spellcount_max" && count >= actualCount);
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a count argument.", requirement);
        }
        return [verified, requirement, index];
    }
}
OvaleSpellBook.statePrototype = {
}
let statePrototype = OvaleSpellBook.statePrototype;
statePrototype.IsUsableItem = function (state, itemId, atTime) {
    OvaleSpellBook.StartProfiling("OvaleSpellBook_state_IsUsableItem");
    let isUsable = API_IsUsableItem(itemId);
    let ii = OvaleData.ItemInfo(itemId);
    if (ii) {
        if (isUsable) {
            let unusable = state.GetItemInfoProperty(itemId, atTime, "unusable");
            if (unusable && unusable > 0) {
                state.Log("Item ID '%s' is flagged as unusable.", itemId);
                isUsable = false;
            }
        }
    }
    OvaleSpellBook.StopProfiling("OvaleSpellBook_state_IsUsableItem");
    return isUsable;
}
statePrototype.IsUsableSpell = function (state, spellId, atTime, targetGUID) {
    OvaleSpellBook.StartProfiling("OvaleSpellBook_state_IsUsableSpell");
    if (_type(atTime) == "string" && !targetGUID) {
        [atTime, targetGUID] = [undefined, atTime];
    }
    atTime = atTime || state.currentTime;
    let isUsable = OvaleSpellBook.IsKnownSpell(spellId);
    let noMana = false;
    let si = OvaleData.spellInfo[spellId];
    if (si) {
        if (isUsable) {
            let unusable = state.GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID);
            if (unusable && unusable > 0) {
                state.Log("Spell ID '%s' is flagged as unusable.", spellId);
                isUsable = false;
            }
        }
        if (isUsable) {
            let requirement;
            [isUsable, requirement] = state.CheckSpellInfo(spellId, atTime, targetGUID);
            if (!isUsable) {
                if (OvalePower.PRIMARY_POWER[requirement]) {
                    noMana = true;
                }
                if (noMana) {
                    state.Log("Spell ID '%s' does not have enough %s.", spellId, requirement);
                } else {
                    state.Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement);
                }
            }
        }
    } else {
        [isUsable, noMana] = OvaleSpellBook.IsUsableSpell(spellId);
    }
    OvaleSpellBook.StopProfiling("OvaleSpellBook_state_IsUsableSpell");
    return [isUsable, noMana];
}
statePrototype.GetTimeToSpell = function (state, spellId, atTime, targetGUID, extraPower) {
    if (_type(atTime) == "string" && !targetGUID) {
        [atTime, targetGUID] = [undefined, atTime];
    }
    atTime = atTime || state.currentTime;
    let timeToSpell = 0;
    {
        let [start, duration] = state.GetSpellCooldown(spellId);
        let seconds = (duration > 0) && (start + duration - atTime) || 0;
        if (timeToSpell < seconds) {
            timeToSpell = seconds;
        }
    }
    {
        let seconds = state.TimeToPower(spellId, atTime, targetGUID, undefined, extraPower);
        if (timeToSpell < seconds) {
            timeToSpell = seconds;
        }
    }
    {
        let runes = state.GetSpellInfoProperty(spellId, atTime, "runes", targetGUID);
        if (runes) {
            let seconds = state.GetRunesCooldown(atTime, runes);
            if (timeToSpell < seconds) {
                timeToSpell = seconds;
            }
        }
    }
    return timeToSpell;
}
statePrototype.RequireSpellCountHandler = OvaleSpellBook.RequireSpellCountHandler;
OvaleSpellBook = new OvaleSpellBookClass();