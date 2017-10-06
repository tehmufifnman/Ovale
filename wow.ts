// Utility interfaces
interface LuaArray<T> {
    [key:number]:T;
    n?:number;
}

interface LuaObj<T> {
    [key: number]:T;
    [key: string]:T;
}

// Global lua functions
function ipairs<T>(a:LuaArray<T>) {
    const pairs:[number, T][] = [];
    for (let k in a) {
        pairs.push([parseInt(k), a[k]]);
    }
    return pairs.sort((x,y) => x[0] < y[0] ? -1 : (x[0] == y[0] ? 0 : 1));
}

function pairs<T = any>(a:LuaObj<T>):[string, T][]
function pairs<T = any>(a:LuaArray<T>):[number, T][]
function pairs<T = any>(a:LuaObj<T>):[string|number, T][] {
    const pairs:[string, T][] = [];
    for (let k in a) {
        pairs.push([k, a[k]]);
    }
    return pairs;
}

function next<T>(a:LuaArray<T>) {
    for (let k in a) {
        return [k, a[k]];
    }
    return undefined;
}

function tonumber(a: any):number {
    return parseInt(a);
}

function tostring(s: any): string {
    return s.toString();
}

function type(a: any) : "table" | "number" | "string" | "function" | "boolean" {
    if (typeof(a) === "number") {
        return "number";
    }
    if (typeof(a) === "string") {
        return "string";
    }
    if (typeof(a) === "function") {
        return "function";
    }
    if (typeof(a) === "boolean") {
        return "boolean";
    }
    return "table";
}

function wipe(x: any) {
    const keys = [];
    for (let i in x) {
        keys.push(i);
    }
    for (const k of keys) {
        delete x[k];
    }
}

function assert(condition) {

}

function unpack<T>(t:LuaArray<T>, first?, count?):T[] {
    return undefined;
}

function tostringall(...text: object[]){
    return text.map(x => x.toString());
}

function select<T>(index: "#", t: T[]): number;
function select<T>(index: number, t: T[]): T;
function select<T>(index: number|"#", t: T[]): T|number{
    if (index == "#") return t.length;
    return t[index];
}

function strjoin(separator: string, ...text:string[]) {
    return text.join(separator);
}

function hooksecurefunc(table, methodName, hook) {

}
function error(error:string, info:number):void{}
function rawset(table: any, key, value){}
function setmetatable<T>(table: T, metatable: { __index: (o:T, key:string) => any}):T { 
    if (metatable.__index) {
        const handler = {
            get: (target, key) => {
                return key in target ? target[key] : metatable.__index(target, key);
            }
        };
        return new Proxy(table, handler);
    }
    return table;
}
function loadstring(t: string):() => void { return undefined; }
// Global lua objects
var math = {
    floor: Math.floor,
    huge: Number.MAX_VALUE,
    abs: Math.abs,
    ceil: Math.ceil,
    exp: Math.exp,
    log: Math.log,
    nan: NaN
};

var coroutine = {
    yield(key, value?){},
    wrap<T>(f:() => IterableIterator<T>) {
        return makeLuaIterable(f());
    }
}

var bit = {
    band(...other:number[]) {
        let result = other[0];
        for (let i = 1; i < other.length; i++) {
            result &= other[i];
        }
        return result;
    },
    bor(...other:number[]) {
        let result = other[0];
        for (let i = 1; i < other.length; i++) {
            result |= other[i];
        }
        return result;
    }
};

function compilePattern(pattern: string) {
    pattern = pattern.replace(/%[a-z]/g, (pattern, p1) => {
        switch (p1) {
            case "a":
                return "[A-Za-z]";
            case "d":
                return "\\d";
            case "l":
                return "[a-z]";
            case "s":
                return "\\s";
            case "u":
                return "[A-Z]";
            case "w":
                return "\\w";
            case "x":
                return "[A-Fa-f0-9]";
            case "z":
                return "\\0";
            default:
                return p1;
        }
    });
    return new RegExp(pattern);
}

interface LuaIterable<T> extends Iterable<T> {
    ():T;
}

function makeLuaIterable<T>(iterable: Iterable<T>) {
    const iterator = iterable[Symbol.iterator]();
    const ret:LuaIterable<T> = <LuaIterable<T>>(() => {
        return iterator.next().value;        
    });
    ret[Symbol.iterator] = () => iterator;
    return ret;
}

var string = {
    find: (t: string, pattern: string, start?:number):[number, number] => {
        if (start) {
            t = t.substring(start);
        }
        const regex = compilePattern(pattern)
        
        let pos = t.search(regex);
        if (pos == -1) return undefined;
        const length = t.match(regex)[0].length;
        pos += start;
        return [pos, pos + length];
    },
    lower: (t: string) => { return t.toLowerCase() },
    sub: (t: string, index: number, end?:number) => { return t.substring(index, end) },
    len: (t: string) => { return t.length},
    format: (format: string, ...values) => { return format; },
    gmatch: (text: string, pattern: string) => { return makeLuaIterable(text.match(pattern)); },
    gsub: (text: string, pattern: string, substitute: string|((...args:string[]) => string)) => {
        const regex = compilePattern(pattern);
         if (typeof(substitute) === "string") return text.replace(regex, substitute.replace("%", "$"));
        return text.replace(regex, (pattern:string, ...args:string[]) => substitute(...args));
    },
    match: (text: string, pattern: string) => { return text.match(pattern); },
    upper: (text: string) => { return text.toUpperCase()}
}

var table = {
    concat: <T>(t:LuaArray<T>, seperator?: string):string => {
        const result: string[] = [];
        for (let i = 1; t[i] !== undefined; i++) {
            result.push(t[i].toString());
        }

        return result.join(seperator);
    },

    insert: <T>(t:LuaArray<T>, indexOrValue:number|T, value?: T) => {
        // const l = lualength(t);
        // t[l + 1] = value;
        // t.n = l + 1;
    },
    sort: <T>(t:LuaArray<T>, compare?: (left:T,right:T) => boolean) => {
        let values:T[] = [];
        for (const key in t) {
            values.push(t[key])
        }
        wipe(t);
        if (compare) {
            values = values.sort((a, b) => a == b ? 0 : (compare(a,b) ? 1 : -1));
        }
        else {
            values = values.sort();
        }
        for (let i = 0; i < values.length; i++) {
            t[i + 1] = values[i];
        }
        t.n = values.length;
    },
    remove: <T>(t: LuaArray<T>, index?: number):T => { return t[t.n] },
}

// Utility functions
function lualength<T>(array: (LuaArray<T>|string)):number {
    if (typeof (array) === "string") return array.length;
    if (!array.n) {
        for (let i = 1; ; i++){
            if (!array[i]) {
                array.n = i;
                break;
            }
        }
    }
    return array.n;
}

// WoW Class 
type UIPosition = "TOPLEFT" | "CENTER";
type UIAnchor = "ANCHOR_BOTTOMLEFT" | "ANCHOR_NONE";

interface UIRegion {
    CanChangeProtectedState():boolean;
    ClearAllPoints():void;
    GetCenter():[number, number];
    GetWidth():number;
    GetHeight():number;
    GetParent():UIRegion;
    SetParent(parent: UIRegion):void;
    SetAllPoints(around: UIFrame):void;
    SetParent(parent:UIFrame):void;
    SetPoint(anchor: UIPosition, x:number, y: number):void;
    SetPoint(anchor: UIPosition, reference: UIFrame, refAnchor: UIPosition, x:number, y: number):void;
    SetWidth(width:number):void;
    SetHeight(height:number):void;
}

interface UIFrame  extends UIRegion {
    SetAlpha(value:number):void;
    SetScript(event:"OnMouseUp" | "OnEnter" | "OnLeave" | "OnMouseDown" | "OnHide" | "OnUpdate", func):void;
    StartMoving():void;
    StopMovingOrSizing():void;
    SetMovable(movable:boolean):void;
    SetFrameStrata(strata: "MEDIUM"):void;
    Show():void;
    Hide():void;   
    IsShown():boolean;
    CreateTexture(): UITexture;
    EnableMouse(enabled: boolean):void;
    CreateFontString(name: string, layer?: "OVERLAY", inherits?: string): UIFontString;
    SetAttribute(key: string, value: string):void;
    SetScale(scale: number):void;
    IsVisible():boolean;
}

interface UIMessageFrame extends UIFrame {
    AddMessage(message:string);
}

interface UIFontString extends UIFrame {
    SetText(text: string):void;
    SetFont(font: string, height: number, flags):void;
    SetFontObject(name: "GameFontNormalSmall"):void;
    SetTextColor(r:number, g:number, b: number):void;
}

interface UICheckButton extends UIFrame {
    SetChecked(checked: boolean):void;
    GetChecked():boolean;
    RegisterForClicks(type: "AnyUp" | "AnyDown" | "LeftButtonDown" | "LeftButtonUp" | "MiddleButtonDown" | "MiddleButtonUp" | "RightButtonDown" | "RightButtonUp"):void;
}

interface UITexture extends UIFrame {
    SetTexture(r, g, b):void;
}
interface UIGameTooltip extends UIFrame {
    SetOwner(frame: UIFrame, anchor: UIAnchor):void;
    SetText(text: string, r?: number, g?: number, b?: number):void;
    AddLine(text: string, r?: number, g?: number, b?: number):void;
    ClearLines():void;
    SetInventoryItem(unit: string, slot: number):void;
    NumLines():number;
    GetText():string;
}

// WOW global functions
function GetTime() {
    return 10;
}

function UnitAura(unitId, i, filter) {
    return [];
}

function GetSpellInfo(spellId: number|string, bookType?: number) {
    return [];
}

function GetItemInfo(itemId: number|string):any[] {
return undefined;
}

function UnitCanAttack(unit:string, target: string) {
    return false;
}

function UnitClass(unit:string):[string, "WARRIOR" | "PRIEST"] {
    return ["Warrior", "WARRIOR"];
}

function UnitExists(unit:string) {
    return false;
}

function UnitGUID(unit:string) {
    return "aaaa";
}

function UnitHasVehicleUI(unit: string) {
    return false;
}

function UnitIsDead(unit: string) {
    return false;
}

function InterfaceOptionsFrame_OpenToCategory(frameName:string) {

}

function debugprofilestop() {
    return 10;
}

function GetActionInfo(slot: string) {
    return ["a", "b", "c"];
}

function GetActionText(slot: string) {
    return "ActioNText";
}

function GetBindingKey(key:string){
    return "a";
}

function GetBonusBarIndex(){

}

function GetMacroItem(spellId: number){
    return [];
}

function GetMacroSpell(spellId: number){
    return []
}

function UnitName(unitId: string) {
    return "Esside";
}

function GetActionCooldown(action: string):[number, number, boolean] {
    return undefined;    
}

function GetActionTexture(action: string){

}

function GetItemIcon(itemId: number){

}

function GetItemCooldown(itemId: number): [number, number, boolean]{
    return undefined;
}

function GetItemSpell(itemId: number){

}

function GetSpellTexture(spellId: number, bookType?: number){

}

function IsActionInRange(action: string, target: string){

}

function IsCurrentAction(action: string){

}

function IsItemInRange(itemId: number, target: string){

}

function IsUsableAction(action: string): boolean{
    return false;
}

function IsUsableItem(itemId: number): boolean {
    return false;
}

function GetNumGroupMembers(filter: number) {
    return 0;
}

function UnitPower(unit: string, type: number, segments?: number) { return 0;}
function GetPowerRegen():[number, number] {return [0, 0]}
function GetSpellPowerCost(spellId:number): LuaArray<{cost:number, type:number}> { return {1:{cost:0, type: 0}}}
function UnitPowerType(unit: string):[number,number] { return [0,0]}
function IsInGroup(filter?: number){ return false}
function IsInGuild() { return false;}
function IsInInstance(){return false}
function IsInRaid(filter?: number){return false}
function UnitLevel(target:string){ return 0;}
function GetBuildInfo():any[] { return undefined}
function GetItemCount(item:string, first?: boolean, second?: boolean){}
function GetNumTrackingTypes() {return 0}
function GetTrackingInfo(i:number):any[] {return undefined}
function GetUnitSpeed(unit: string):number { return 0;}
function GetWeaponEnchantInfo():any[] {return undefined}
function HasFullControl() {return false}
function IsSpellOverlayed() {}
function IsStealthed() {}
function UnitCastingInfo(target: string):any[] { return undefined }
function UnitChannelInfo(target: string):any[] {return undefined }
function UnitClassification(target: string){}
function UnitCreatureFamily(target: string){}
function UnitCreatureType(target: string){}
function UnitDetailedThreatSituation(unit: string, target: string):any[]{ return undefined}
function UnitInRaid(unit: string){return false}
function UnitIsFriend(unit: string, target: string){return 0}
function UnitIsPVP(unit: string){return false}
function UnitIsUnit(unit1: string, unit2: string){ return true}
function UnitPowerMax(unit: string, power: number, segment: number): number{ return 0}
function UnitRace(unit: string):any[]{return undefined}
function UnitStagger(unit: string){return 0}
function GetSpellCharges(spellId: number) {return []}
function GetSpellCooldown(type, book?):[number, number, boolean]{ return [0, 0, false]}
function GetLocale() { return "en-US"}
function CreateFrame(type:"GameTooltip", id?:string, parent?:UIFrame, template?:string):UIGameTooltip;
function CreateFrame(type:"CheckButton", id?:string, parent?:UIFrame, template?:string):UICheckButton;
function CreateFrame(type:"Dropdown", id?:string, parent?:UIFrame, template?:string):UIFrame;
function CreateFrame(type:"Frame", id?:string, parent?:UIFrame, template?:string):UIFrame;
function CreateFrame(type:string, id?:string, parent?:UIFrame, template?:string):UIFrame { return undefined}
function EasyMenu(menu, self_menuFrame, cursor, x, y, menuType) {}
function IsShiftKeyDown(){}
function GetSpecialization(){return "havoc"}
function GetSpecializationInfo(spec: string){ return 1}
function GetTalentInfoByID(talent:number, spec:number):any[]{return undefined}
function GetAuctionItemSubClasses(item:number):any[]{return undefined}
function GetInventoryItemID(unit:string, slot:number){}
function GetInventoryItemGems(){}
function RegisterStateDriver(frame, property, state){}
function UnitHealth(unit:string){return 0}
function UnitHealthMax(unit:string){return 0}
function PlaySoundFile(file:string){}
function GetCombatRating(combatRatingIdentifier:number){ return 0}
function GetCritChance(){return 0}
function GetMastery(){return 0}
function GetMasteryEffect(){return 0}
function GetMeleeHaste(){return 0}
function GetMultistrike(){return 0}
function GetMultistrikeEffect(){return 0}
function GetRangedCritChance(){return 0}
function GetRangedHaste(){return 0}
function GetSpellBonusDamage(school: number){return 0}
function GetSpellBonusHealing(){return 0}
function GetSpellCritChance(school: number){return 0}
function UnitAttackPower(unitId:string){return [0, 0, 0]}
function UnitAttackSpeed(unitId:string){return [0, 0]}
function UnitDamage(unitId:string):number[]{return undefined}
function UnitRangedAttackPower(unitId:string){return [0, 0, 0]}
function UnitSpellHaste(unitId:string){return 0}
function UnitStat(unitId:string, stat:number){return 0}
function GetRuneCooldown(slot: number){return [0, 0, 0]}
function SendAddonMessage(MSG_PREFIX, message, channel){}
//function print(s: string):void {}
function GetActiveSpecGroup() {return 0;}
function GetFlyoutInfo(flyoutId) {return[]}
function GetFlyoutSlotInfo(flyoutId, flyoutIndex) {return[]}
function GetSpellBookItemInfo(index, bookType) {return[]}
function GetSpellCount(index, bookType?){}
function GetSpellLink(index, bookType){return "aa"}
function GetSpellTabInfo(tab) { return []}
function GetTalentInfo(i, j, activeTalentGroup){
    return [];
}
function HasPetSpells():[number, string] {return[0, "a"]}
function IsHarmfulSpell(index, bookType?){}
function IsHelpfulSpell(index, bookType?){}
function IsSpellInRange(index, bookType, unitId?){return false;}
function IsUsableSpell(index, bookType?){return [];}
function GetNumShapeshiftForms() {return 0}
function GetShapeshiftForm(){}
function GetShapeshiftFormInfo(index:number){return []}
function GetTotemInfo(slot) {return[]}

var BigWigsLoader;
var UIParent: UIFrame;
var Bartender4;

// WoW global variables
var GameTooltip:UIGameTooltip = <UIGameTooltip>{}
var MAX_COMBO_POINTS = 5;
var UNKNOWN = -1;
var DEFAULT_CHAT_FRAME:UIFrame = undefined;
var SCHOOL_MASK_NONE = 0;
var SCHOOL_MASK_ARCANE = 1;
var SCHOOL_MASK_FIRE = 2;
var SCHOOL_MASK_FROST = 4;
var SCHOOL_MASK_HOLY = 8;
var SCHOOL_MASK_NATURE = 16;
var SCHOOL_MASK_SHADOW = 32;
var SCHOOL_MASK_PHYSICAL = 64;

var INVSLOT_AMMO = 1;
var INVSLOT_BACK = 2;
var INVSLOT_BODY = 3;
var INVSLOT_CHEST = 4;
var INVSLOT_FEET = 5;
var INVSLOT_FINGER1 = 6;
var INVSLOT_FINGER2 = 7;
var INVSLOT_FIRST_EQUIPPED = 8;
var INVSLOT_HAND = 9;
var INVSLOT_HEAD = 10;
var INVSLOT_LAST_EQUIPPED = 11;
var INVSLOT_LEGS = 12;
var INVSLOT_MAINHAND = 13;
var INVSLOT_NECK = 14;
var INVSLOT_OFFHAND = 15;
var INVSLOT_RANGED = 16;
var INVSLOT_SHOULDER = 17;
var INVSLOT_TABARD = 18;
var INVSLOT_TRINKET1 = 19;
var INVSLOT_TRINKET2 = 20;
var INVSLOT_WAIST = 21;
var INVSLOT_WRIST = 22;

// Correct
var SPELL_POWER_MANA = 0;
var SPELL_POWER_RAGE = 1;
var SPELL_POWER_FOCUS = 2;
var SPELL_POWER_ENERGY = 3;
var SPELL_POWER_COMBO_POINTS = 4;
var SPELL_POWER_RUNES = 5;
var SPELL_POWER_RUNIC_POWER = 6;
var SPELL_POWER_SOUL_SHARDS = 7;
var SPELL_POWER_LUNAR_POWER = 8;
var SPELL_POWER_HOLY_POWER = 9;
var SPELL_POWER_ALTERNATE_POWER = 10;
var SPELL_POWER_MAELSTROM = 11;
var SPELL_POWER_CHI = 12;
var SPELL_POWER_INSANITY = 13;
var SPELL_POWER_ARCANE_CHARGES = 16;
var SPELL_POWER_FURY = 17;
var SPELL_POWER_PAIN = 18;

var CHI_COST = "";
var COMBO_POINTS_COST = "";
var ENERGY_COST = "";
var FOCUS_COST = "";
var HOLY_POWER_COST = "";
var MANA_COST = "";
var RAGE_COST = "";
var RUNIC_POWER_COST = "";
var SOUL_SHARDS_COST = "";
var LUNAR_POWER_COST = "";
var INSANITY_COST = "";
var MAELSTROM_COST = "";
var ARCANE_CHARGES_COST = "";
var PAIN_COST = "";
var FURY_COST = "";

var CR_CRIT_MELEE = 1;
var CR_HASTE_MELEE = 2;

var ITEM_LEVEL;

var LE_PARTY_CATEGORY_INSTANCE = 1;
var LE_PARTY_CATEGORY_HOME = 2;
var _G: any;
var DBM;

var BOOKTYPE_SPELL = 1;
var BOOKTYPE_PET = 2;

var MAX_TALENT_TIERS = 5;
var NUM_TALENT_COLUMNS = 3;

var RUNE_NAME = {};

var RAID_CLASS_COLORS = {};

var AIR_TOTEM_SLOT = 1;
var EARTH_TOTEM_SLOT = 2;
var FIRE_TOTEM_SLOT = 3;
var WATER_TOTEM_SLOT = 4;
var MAX_TOTEMS = 3;

var COMBATLOG_OBJECT_AFFILIATION_MINE = 1;
var COMBATLOG_OBJECT_AFFILIATION_PARTY = 2;
var COMBATLOG_OBJECT_AFFILIATION_RAID = 3;
var COMBATLOG_OBJECT_REACTION_FRIENDLY = 4;

